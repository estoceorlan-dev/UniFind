import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:crypto/crypto.dart';
import 'package:another_flushbar/flushbar.dart';
import 'admin_newsfeed.dart';

class EditAdminProfile extends StatefulWidget {
  final String username;

  const EditAdminProfile({super.key, required this.username});

  @override
  State<EditAdminProfile> createState() => _EditAdminProfileState();
}

class _EditAdminProfileState extends State<EditAdminProfile> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _loading = false;
  String? profilePicUrl;
  File? _newImage;
  String? username; // keep admin username for display

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.username)
        .get();

    if (snapshot.exists) {
      final data = snapshot.data()!;
      username = data['username']; // keep for display
      _firstNameCtrl.text = data['firstName'] ?? '';
      _lastNameCtrl.text = data['lastName'] ?? '';
      _emailCtrl.text = data['email'] ?? '';
      profilePicUrl = data['profilePic'];
      setState(() {});
    }
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _newImage = File(picked.path));
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      String newFirstName = _firstNameCtrl.text.trim();
      String newLastName = _lastNameCtrl.text.trim();
      String newEmail = _emailCtrl.text.trim();
      String newPassword = _passwordCtrl.text.trim();

      String? newProfilePicUrl = profilePicUrl;

      if (_newImage != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('profile_pics')
            .child('${username!}.jpg');
        await ref.putFile(_newImage!);
        newProfilePicUrl = await ref.getDownloadURL();
      }

      final docRef =
          FirebaseFirestore.instance.collection('users').doc(widget.username);

      final oldData = (await docRef.get()).data() ?? {};

      final updatedData = {
        ...oldData,
        'firstName': newFirstName,
        'lastName': newLastName,
        'email': newEmail,
        'profilePic': newProfilePicUrl,
      };

      if (newPassword.isNotEmpty) {
        final hashedPassword =
            sha256.convert(utf8.encode(newPassword)).toString();
        updatedData['password'] = hashedPassword;
      }

      await docRef.update(updatedData);

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

      if (mounted) {
        Navigator.pop(context, widget.username);
      }
    } catch (e) {
      Flushbar(
        message: "Error: ${e.toString()}",
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.white,
        messageColor: Colors.black,
        icon: const Icon(Icons.error, color: Colors.red),
        margin: const EdgeInsets.all(8),
        borderRadius: BorderRadius.circular(8),
        flushbarPosition: FlushbarPosition.TOP,
      ).show(context);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Admin Profile"),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
         Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: GestureDetector(
              onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                builder: (_) => AdminNewsFeed(),
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
              padding: const EdgeInsets.all(16.0),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 4,
                color: Theme.of(context).colorScheme.surface,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _pickImage,
                          child: CircleAvatar(
                            radius: 55,
                            backgroundImage: _newImage != null
                                ? FileImage(_newImage!)
                                : (profilePicUrl != null
                                    ? NetworkImage(profilePicUrl!)
                                    : const AssetImage("assets/images/defaultpfp.jpg"))
                                    as ImageProvider,
                          ),
                        ),
                        Text(
                          "Tap image to change profile picture",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (username != null)
                          Text(
                            "@$username",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Color.fromARGB(255, 0, 0, 0),
                            ),
                          ),
                        const SizedBox(height: 20),
                        const Text(
                          "ℹ️ Do not change or just directly skip a field if you want to keep it the same.",
                          style: TextStyle(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const Divider(height: 30, thickness: 1.2),
                        TextFormField(
                          controller: _firstNameCtrl,
                          decoration:
                              const InputDecoration(labelText: "First Name"),
                          validator: (value) =>
                              value == null || value.isEmpty ? "Required" : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _lastNameCtrl,
                          decoration:
                              const InputDecoration(labelText: "Last Name"),
                          validator: (value) =>
                              value == null || value.isEmpty ? "Required" : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _emailCtrl,
                          decoration: const InputDecoration(labelText: "Email"),
                          validator: (value) =>
                              value == null || value.isEmpty ? "Required" : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _passwordCtrl,
                          decoration:
                              const InputDecoration(labelText: "New Password"),
                          obscureText: true,
                        ),
                        const SizedBox(height: 25),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _saveProfile,
                            icon: const Icon(Icons.save),
                            label: const Text("Save Changes"),
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
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
