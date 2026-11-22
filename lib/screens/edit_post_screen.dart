import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditPostScreen extends StatefulWidget {
  final String postId;
  final String initialCaption;
  final List<String> initialTags;
  final List<dynamic> initialImages;

  const EditPostScreen({
    super.key,
    required this.postId,
    required this.initialCaption,
    required this.initialTags,
    required this.initialImages,
  });

  @override
  State<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();

  List<String> _tags = [];
  List<String> _images = []; // just display

  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    _captionController.text = widget.initialCaption;
    _tags = List.from(widget.initialTags);
    _images = widget.initialImages.map((e) => e.toString()).toList();
  }

  /// SAVE EDITED POST (NO IMAGE UPLOAD ANYMORE)
  Future<void> _savePost(BuildContext context) async {
    setState(() => isSaving = true);

    try {
      final newCaption = _captionController.text.trim();

      final finalTags = _tags
          .map((t) => t.trim().startsWith("#") ? t.trim() : "#${t.trim()}")
          .toList();

      await FirebaseFirestore.instance.collection("posts").doc(widget.postId).update({
        "caption": newCaption,
        "tags": finalTags,
        "updatedAt": FieldValue.serverTimestamp(),
      });

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      debugPrint("EDIT ERROR: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update post")),
      );
    }

    if (mounted) setState(() => isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Post"),

        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: isSaving ? null : () => _savePost(context),
            child: isSaving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text("Save"),
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // CAPTION
            TextField(
              controller: _captionController,
              maxLines: null,
              decoration: const InputDecoration(
                hintText: "Edit your caption...",
                border: InputBorder.none,
              ),
            ),

            const SizedBox(height: 12),

            // TAG INPUT
            TextField(
              controller: _tagController,
              decoration: const InputDecoration(
                labelText: "Add a #tag. Press Enter",
                border: OutlineInputBorder(),
              ),
              onSubmitted: (value) {
                if (value.trim().isEmpty) return;

                final parts = value
                    .split(RegExp(r"\s+"))
                    .map((t) => t.trim())
                    .where((t) => t.isNotEmpty);

                setState(() {
                  _tags.addAll(parts);
                  _tagController.clear();
                });
              },
            ),

            Wrap(
              spacing: 6,
              children: _tags
                  .map((tag) => Chip(
                        label: Text(tag),
                        deleteIcon: const Icon(Icons.close),
                        onDeleted: () {
                          setState(() => _tags.remove(tag));
                        },
                      ))
                  .toList(),
            ),

            const SizedBox(height: 20),

            // DISPLAY IMAGES ONLY
            if (_images.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Post Images", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _images.map((url) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          url,
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
