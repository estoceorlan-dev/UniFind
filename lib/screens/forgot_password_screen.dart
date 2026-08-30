import 'dart:math';

import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../repositories/user_repository.dart';
import '../services/email_service.dart';
import '../services/password_hasher.dart';
import 'login_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController codeController = TextEditingController();
  final TextEditingController newPassController = TextEditingController();
  final TextEditingController confirmPassController = TextEditingController();
  final UserRepository _userRepository = UserRepository();
  final EmailService _emailService = EmailService();

  String? email;
  String? firstName;
  String? lastName;
  String? sentCode;
  bool codeSent = false;
  bool codeVerified = false;

  Future<void> sendCode() async {
    final username = usernameController.text.trim();
    if (username.isEmpty) return;

    final user = await _userRepository.fetchUser(username);
    if (!mounted) return;

    if (user == null) {
      _showError('User not found.');
      return;
    }

    email = user.email;
    firstName = user.firstName;
    lastName = user.lastName;
    sentCode = (100000 + Random().nextInt(900000)).toString();

    await _userRepository.saveResetCode(username, sentCode!);
    await _emailService.sendResetEmail(
      email!,
      '''
      Hi $firstName $lastName,<br><br>
      Your password reset code is: <b>$sentCode</b><br><br>
      If you didn't request this, ignore this email.<br><br>
      <i>If you don't see this email in your inbox within a few minutes, please check your Spam or Junk folder.</i>
      ''',
    );

    if (mounted) {
      setState(() => codeSent = true);
    }
  }

  Future<void> verifyCode() async {
    if (codeController.text.trim() == sentCode) {
      setState(() => codeVerified = true);
      return;
    }

    _showError('Invalid code. Please try again.');
  }

  Future<void> saveNewPassword() async {
    if (newPassController.text != confirmPassController.text) {
      _showError('Passwords do not match.');
      return;
    }

    final username = usernameController.text.trim();
    await _userRepository.updatePasswordHash(
      username,
      PasswordHasher.hash(newPassController.text),
    );
    if (!mounted) return;

    Flushbar(
      message: 'Password updated!',
      duration: const Duration(seconds: 2),
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      messageColor: const Color.fromARGB(255, 0, 0, 0),
      icon: const Icon(Icons.check_circle, color: Colors.green),
      margin: const EdgeInsets.all(8),
      borderRadius: BorderRadius.circular(8),
      flushbarPosition: FlushbarPosition.TOP,
    ).show(context);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _showError(String message) {
    Flushbar(
      message: message,
      duration: const Duration(seconds: 2),
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      messageColor: const Color.fromARGB(255, 0, 0, 0),
      icon: const Icon(Icons.error, color: Colors.red),
      margin: const EdgeInsets.all(8),
      borderRadius: BorderRadius.circular(8),
      flushbarPosition: FlushbarPosition.TOP,
    ).show(context);
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: uniFindPrimary),
        filled: true,
        fillColor: lightpurple.withValues(alpha: 0.2),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: uniFindPrimary, width: 2),
          borderRadius: BorderRadius.circular(15),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: uniFindGrey),
          borderRadius: BorderRadius.circular(15),
        ),
      ),
    );
  }

  Widget _buildButton(
    String text,
    VoidCallback onPressed, {
    Color color = darkBlue,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        title: const Text(
          'Forgot Password',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(255, 39, 44, 53),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              children: [
                Hero(
                  tag: 'logo',
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/logo2.jpg',
                      width: 130,
                      height: 130,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  'Password Recovery',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: uniFindPrimary,
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  'Enter your username to receive a verification code via your registered email.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54, fontSize: 14),
                ),
              ],
            ),
            if (!codeSent) ...[
              _buildTextField(usernameController, 'Enter Username'),
              const SizedBox(height: 20),
              _buildButton(
                'Send Verification Code',
                () {
                  sendCode();
                },
                color: const Color.fromARGB(255, 6, 0, 190),
              ),
            ] else if (!codeVerified) ...[
              Text(
                'Hi $firstName, we sent a code to $email',
                style: const TextStyle(
                  color: uniFindPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "If no email appears in your inbox within a few minutes, please check your Spam or Junk folder.",
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 20),
              _buildTextField(codeController, 'Enter Code'),
              const SizedBox(height: 20),
              _buildButton('Verify Code', () {
                verifyCode();
              }, color: uniFindAccent),
            ] else ...[
              _buildTextField(newPassController, 'New Password', obscure: true),
              const SizedBox(height: 20),
              _buildTextField(
                confirmPassController,
                'Confirm Password',
                obscure: true,
              ),
              const SizedBox(height: 20),
              _buildButton('Save Password', () {
                saveNewPassword();
              }),
            ],
          ],
        ),
      ),
    );
  }
}
