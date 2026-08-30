import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:another_flushbar/flushbar.dart';
import '../services/notification_generator.dart';

class PostComposerScreen extends StatefulWidget {
  final String username;   
  final String type;

  const PostComposerScreen({
    super.key,
    required this.username,
    required this.type,
  });

  @override
  State<PostComposerScreen> createState() => _PostComposerScreenState();
}

class _PostComposerScreenState extends State<PostComposerScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();
  List<String> _tags = [];
  List<File> _pickedImages = [];
  bool isPosting = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _loadDraft();

    // 🎬 Fade-in animation
    _fadeController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  /// Draft handling
  Future<void> _saveDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("draft_caption", _captionController.text);
    await prefs.setString("draft_type", widget.type);
    await prefs.setStringList("draft_tags", _tags);
    await prefs.setStringList("draft_images", _pickedImages.map((x) => x.path).toList());
  }

  Future<void> _loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _captionController.text = prefs.getString("draft_caption") ?? "";
      _tags = prefs.getStringList("draft_tags") ?? [];
      final imagePaths = prefs.getStringList("draft_images") ?? [];
      _pickedImages = imagePaths.map((path) => File(path)).toList();
    });
  }

  Future<void> _clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("draft_caption");
    await prefs.remove("draft_type");
    await prefs.remove("draft_tags");
    await prefs.remove("draft_images");
    setState(() {
      _captionController.clear();
      _tags.clear();
      _pickedImages.clear();
    });
  }

  /// Pick multiple images
  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 80);
    if (picked.isNotEmpty) {
      setState(() {
        _pickedImages.addAll(picked.map((x) => File(x.path)));
      });
      await _saveDraft();
    }
  }

  /// Upload images to Firebase Storage
  Future<List<String>> _uploadImages(String postId) async {
    List<String> urls = [];
    for (var img in _pickedImages) {
      final ref = FirebaseStorage.instance
          .ref()
          .child("post_images")
          .child("${postId}_${DateTime.now().millisecondsSinceEpoch}.jpg");
      await ref.putFile(img);
      urls.add(await ref.getDownloadURL());
    }
    return urls;
  }

  /// Submit post
  Future<void> _submitPost(BuildContext ctx) async {
    final caption = _captionController.text.trim();
    if (caption.isEmpty) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text("Caption cannot be empty")),
      );
      return;
    }

    // ✅ Add any remaining text from _tagController
    if (_tagController.text.trim().isNotEmpty) {
    _tags.add(_tagController.text.trim());
    _tagController.clear();
    }

  //  Normalize tags (# prefix + trim)
    final normalizedTags = _tags
      .map((t) {
        t = t.trim();
        return t.startsWith("#") ? t : "#$t";
      })
      .toList();

    setState(() => isPosting = true);

    final postRef = FirebaseFirestore.instance.collection("posts").doc();
    final imageUrls = await _uploadImages(postRef.id);

    DateTime? expiresAt;
    if (widget.type == "Announcement") {
      expiresAt = DateTime.now().add(const Duration(days: 15));
    }

    try {
      await postRef.set({
        "postId": postRef.id,
        "type": widget.type,
        "typeKey": widget.type.toLowerCase(),
        "caption": caption,
        "images": imageUrls,
        "tags": normalizedTags, 
        "createdBy": widget.username,  
        "postOwner": widget.username,  
        "createdAt": FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp(),
        "likes": [],
        "likesCount": 0,
        "reports": [],
        "reportsCount": 0,
        "isAnnouncement": widget.type == "Announcement",
        "expiresAt": expiresAt,
      });

      // 🔔 Notification
      await NotificationGenerator.newPost(
        postId: postRef.id,
        sender: widget.username,
      );

      await _clearDraft();

      if (mounted) {
        Navigator.pop(ctx); // ✅ close first

        // ✅ show Flushbar *after* navigation
        Future.delayed(const Duration(milliseconds: 300), () {
          Flushbar(
            message: "Your post has been uploaded successfully.",
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.green,
            margin: const EdgeInsets.all(8),
            borderRadius: BorderRadius.circular(8),
          ).show(ctx);
        });
      }
    } catch (e) {
      debugPrint("⚠️ Failed to post: $e");
      if (mounted) {
        Flushbar(
          message: "Failed to upload post. Please try again.",
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red,
        ).show(ctx);
      }
    } finally {
      if (mounted) setState(() => isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9F9F9),
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text("New ${widget.type}"),
          backgroundColor: const Color.fromARGB(255, 142, 142, 142),
          foregroundColor: const Color.fromARGB(255, 0, 0, 0),
          actionsPadding: const EdgeInsets.only(right: 8),
          actions: [
            ElevatedButton(
              onPressed: isPosting ? null : () => _submitPost(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color.fromARGB(255, 28, 58, 114),
              ),
              child: isPosting
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text("Post"),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _captionController,
                maxLines: null,
                decoration: const InputDecoration(
                  hintText: "Add a caption.",
                  border: InputBorder.none,
                ),
                onChanged: (_) => _saveDraft(),
              ),
              const SizedBox(height: 12),

              // Tags input
              TextField(
                controller: _tagController,
                decoration: const InputDecoration(
                  labelText: "Add a #tag. Press Enter to add.",
                  hintText: "#bag #umbrella #wallet #ID",
                  border: OutlineInputBorder(),
                ),
               onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                  final parts = value
                  .split(RegExp(r"\s+")) // split by spaces
                  .map((t) => t.trim())
                  .where((t) => t.isNotEmpty)
                  .map((t) => t.startsWith("#") ? t : "#$t")
                  .toSet(); // avoid duplicates

                  setState(() {
                  _tags.addAll(parts);
                  _tagController.clear();
                  });
                  _saveDraft();
                  }
                },
              ),
              if (_tags.isNotEmpty)
                Wrap(
                  spacing: 6,
                  children: _tags
                      .map((tag) => Chip(
                            label: Text(tag),
                            deleteIcon: const Icon(Icons.close),
                            onDeleted: () {
                              setState(() => _tags.remove(tag));
                              _saveDraft();
                            },
                          ))
                      .toList(),
                ),

              const SizedBox(height: 12),

              // Image preview
              if (_pickedImages.isNotEmpty)
                SizedBox(
                  height: 250,
                  child: PageView.builder(
                    itemCount: _pickedImages.length,
                    itemBuilder: (_, index) => Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _pickedImages[index],
                            width: double.infinity,
                            height: 250,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: CircleAvatar(
                            backgroundColor: Colors.black54,
                            child: IconButton(
                              icon: const Icon(Icons.close,
                                  size: 18, color: Colors.white),
                              onPressed: () {
                                setState(() => _pickedImages.removeAt(index));
                                _saveDraft();
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _pickImages,
                icon: const Icon(Icons.photo_library),
                label: const Text("Add Images"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
