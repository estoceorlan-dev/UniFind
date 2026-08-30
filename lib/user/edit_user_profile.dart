import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:crypto/crypto.dart';
import 'package:another_flushbar/flushbar.dart';
import 'user_newsfeed.dart';

class EditUserProfile extends StatefulWidget {
  final String username;

  const EditUserProfile({super.key, required this.username});

  @override
  State<EditUserProfile> createState() => _EditUserProfileState();
}

class _EditUserProfileState extends State<EditUserProfile> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  late TextEditingController _emailCtrl;
  late TextEditingController _courseCtrl;
  late TextEditingController _passwordCtrl;

  String? firstName;
  String? lastName;
  String? schoolId;
  String? profilePicUrl;
  File? _newImage;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController();
    _courseCtrl = TextEditingController();
    _passwordCtrl = TextEditingController();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.username)
        .get();
    final data = doc.data();
    if (data != null && mounted) {
      setState(() {
        _emailCtrl.text = data['email'] ?? '';
        _courseCtrl.text = data['course'] ?? '';
        firstName = data['firstName'] ?? '';
        lastName = data['lastName'] ?? '';
        schoolId = data['schoolId'] ?? '';
        profilePicUrl = data['profilePic'];
      });
    }
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );
    if (picked != null) {
      setState(() => _newImage = File(picked.path));
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      String newEmail = _emailCtrl.text.trim();
      String newCourse = _courseCtrl.text.trim();
      String newPassword = _passwordCtrl.text.trim();

      String? newProfilePicUrl = profilePicUrl;

      // Upload new profile picture if selected
      if (_newImage != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('profile_pics')
            .child('${widget.username}_${DateTime.now().millisecondsSinceEpoch}.jpg');
        await ref.putFile(_newImage!);
        newProfilePicUrl = await ref.getDownloadURL();
      }

      final userDocRef =
          FirebaseFirestore.instance.collection('users').doc(widget.username);
      final oldData = (await userDocRef.get()).data() ?? {};

      // Build updated data
      final updatedData = {
        ...oldData,
        'email': newEmail,
        'course': newCourse,
        'profilePic': newProfilePicUrl,
      };

      // Hash new password if provided
      if (newPassword.isNotEmpty) {
        final hashedPassword =
            sha256.convert(utf8.encode(newPassword)).toString();
        updatedData['password'] = hashedPassword;
      }

      await userDocRef.set(updatedData, SetOptions(merge: true));

      if (!mounted) return;

      // Show success notification first
      await Flushbar(
        message: "Profile updated successfully.",
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.white,
        messageColor: Colors.black,
        icon: const Icon(Icons.check_circle, color: Colors.green),
        margin: const EdgeInsets.all(8),
        borderRadius: BorderRadius.circular(8),
        flushbarPosition: FlushbarPosition.TOP,
      ).show(context);

      // Pop after flushbar finishes
      if (mounted) {
        Navigator.pop(context, widget.username);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Edit Profile"),
        backgroundColor: const Color.fromARGB(255, 120, 120, 120),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: GestureDetector(
              onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                builder: (_) => UserNewsfeed(username: widget.username),
                ),
              );
              },
              child: CircleAvatar(
              radius: 18,
              backgroundImage: const AssetImage("assets/images/logo2.jpg"),
              backgroundColor: Colors.transparent,
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Profile picture
                        GestureDetector(
                          onTap: _pickImage,
                          child: CircleAvatar(
                            radius: 50,
                            backgroundImage: _newImage != null
                                ? FileImage(_newImage!)
                                : (profilePicUrl != null &&
                                        profilePicUrl!.isNotEmpty)
                                    ? NetworkImage(profilePicUrl!)
                                    : const AssetImage(
                                            "assets/images/defaultpfp.jpg")
                                        as ImageProvider,
                          ),
                        ),
                        Text(
                          "Tap image to change profile picture",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Fixed username display (not editable)
                        Text(
                          widget.username,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color.fromARGB(255, 120, 120, 120),
                          ),
                        ),
                        Text(
                          "$firstName $lastName",
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "ID: ${schoolId ?? "N/A"}",
                          style: const TextStyle(
                              fontSize: 16,
                              color: Color.fromARGB(255, 120, 120, 120)),
                        ),
                        const Divider(height: 30, thickness: 1.2),

                        const Text(
                          "ℹ️ Do not change or skip a field if you want to keep it the same.",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const Divider(height: 30, thickness: 1.2),

                        TextFormField(
                          controller: _emailCtrl,
                          decoration: const InputDecoration(
                            labelText: "Email",
                            border: OutlineInputBorder(),
                          ),
                          validator: (val) =>
                              val == null || val.isEmpty ? "Required" : null,
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _courseCtrl,
                          decoration: const InputDecoration(
                            labelText: "Course",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _passwordCtrl,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: "New Password (leave blank to keep current)",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 25),

                        // Save button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _saveProfile,
                            icon: const Icon(Icons.save),
                            label: const Text("Save"),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
