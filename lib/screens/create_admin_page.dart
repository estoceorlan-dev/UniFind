import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class CreateAdminPage extends StatelessWidget {
  const CreateAdminPage({super.key});

  Future<void> createAdmin(BuildContext context) async {
    try {
      final username = "admin"; // you can change this
      final password = "qwerty1234"; // you can change this
      final hashedPassword = sha256.convert(utf8.encode(password)).toString();

      await FirebaseFirestore.instance.collection('users').doc(username).set({
        'username': username,
        'password': hashedPassword,
        'email': 'estoce.orlan@gmail.com',
        'firstName': 'System',
        'lastName': 'Admin',
        'role': 'admin',
        'profilePic': '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Admin account created!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Admin")),
      body: Center(
        child: ElevatedButton(
          onPressed: () => createAdmin(context),
          child: const Text("Create Admin Account"),
        ),
      ),
    );
  }
}
