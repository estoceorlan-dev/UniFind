import 'dart:io';

import 'package:another_flushbar/flushbar.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/theme/app_colors.dart';
import '../models/app_user.dart';
import '../repositories/user_repository.dart';
import '../services/password_hasher.dart';
import 'login_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController schoolIdController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final UserRepository _userRepository = UserRepository();

  String? selectedGender;
  final List<String> genderOptions = ['Male', 'Female', 'LGBTQ+', 'Other'];

  String? selectedCourse;
  final List<String> courseOptions = [
    'BSIT',
    'BEED',
    'BSED - English',
    'BSED - Math',
    'BSHM',
    'BSCRIM',
  ];

  File? profilePic;
  File? schoolIdFrontPhoto;
  File? schoolIdBackPhoto;
  bool agreedToTerms = false;
  bool isLoading = false;

  Future<void> pickImage(String type) async {
    final source = await _chooseSource();
    final pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 80,
    );
    if (pickedFile == null) return;

    setState(() {
      final file = File(pickedFile.path);
      if (type == 'profile') {
        profilePic = file;
      } else if (type == 'front') {
        schoolIdFrontPhoto = file;
      } else if (type == 'back') {
        schoolIdBackPhoto = file;
      }
    });
  }

  Future<ImageSource> _chooseSource() async {
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Image Source'),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context, ImageSource.camera),
            icon: const Icon(Icons.camera_alt),
            label: const Text('Camera'),
          ),
          TextButton.icon(
            onPressed: () => Navigator.pop(context, ImageSource.gallery),
            icon: const Icon(Icons.image),
            label: const Text('Gallery'),
          ),
        ],
      ),
    );
    return source ?? ImageSource.gallery;
  }

  Future<String> uploadFile(File file, String folder, String username) async {
    final ref = FirebaseStorage.instance.ref().child(
      '$folder/$username-${DateTime.now().millisecondsSinceEpoch}',
    );
    await ref.putFile(file);
    return ref.getDownloadURL();
  }

  void _showTermsAndConditions() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color.fromARGB(255, 214, 214, 214),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            controller: scrollController,
            child: const Text('''Terms and Conditions of Use

Effective Date: Testing Date
Application: UniFind - Lost & Found Platform for Buenavista Community College (BCC)

1. Acceptance of Terms

By creating an account or using UniFind, you agree to these Terms and Conditions. If you do not agree, please do not use the platform. These terms apply to all students, staff, and alumni who access or use the app.

2. Purpose of the Platform

UniFind is an educational platform developed for BCC to help students and staff report, locate, and retrieve lost and found items within the college community. The app serves only as a communication tool and does not physically handle or guarantee the recovery of items.

3. Eligibility and Account Verification

Registration requires submission of accurate personal details and a valid school ID photo for admin approval and verification.

4. User Responsibilities

Users agree to post truthful information, communicate respectfully, and avoid spam, scams, harassment, or misuse of the platform.

5. Content Guidelines

Submitted content must be relevant, appropriate, and related to lost-and-found activity.

6. Admin Responsibilities and Limitations

Admins may approve, remove, or review accounts and content, but they do not guarantee item recovery or continuous moderation.

7. Privacy and Data Protection

Collected personal information is used for verification and account identification inside the app.

8. Limitations of Liability

UniFind acts only as a communication platform. Users handle item recovery and exchanges at their own risk.

9. Prohibited Conduct

Users may not impersonate others, submit fake credentials, harass other users, or attempt to disrupt the app.

10. Updates to Terms

UniFind may update these terms over time. Continued use means you accept the latest version.
''', style: TextStyle(fontSize: 14, height: 1.4)),
          ),
        ),
      ),
    );
  }

  Future<void> handleSignUp() async {
    final email = emailController.text.trim();
    final firstName = firstNameController.text.trim();
    final lastName = lastNameController.text.trim();
    final gender = selectedGender;
    final username = usernameController.text.trim();
    final password = passwordController.text;
    final course = selectedCourse;
    final schoolId = schoolIdController.text.trim();

    if (email.isEmpty ||
        firstName.isEmpty ||
        lastName.isEmpty ||
        gender == null ||
        username.isEmpty ||
        password.isEmpty ||
        schoolId.isEmpty ||
        course == null ||
        schoolIdFrontPhoto == null ||
        schoolIdBackPhoto == null) {
      _showMessage(
        message:
            'Please fill all required fields and upload your school ID photo',
        icon: Icons.warning,
      );
      return;
    }

    if (username.toLowerCase() == 'admin') {
      _showMessage(message: 'This username is reserved.', icon: Icons.warning);
      return;
    }

    if (password.length < 8 ||
        !password.contains(RegExp(r'[0-9]')) ||
        !password.contains(RegExp(r'[a-z]')) ||
        !password.contains(RegExp(r'[A-Z]'))) {
      _showMessage(
        message:
            'Password must contain at least 8 characters, including uppercase, lowercase, and numbers.',
        icon: Icons.error,
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      if (await _userRepository.usernameExists(username)) {
        if (!mounted) return;
        _showMessage(message: 'Username already exists.', icon: Icons.error);
        return;
      }

      if (await _userRepository.emailExists(email)) {
        if (!mounted) return;
        _showMessage(message: 'Email already in use.', icon: Icons.error);
        return;
      }

      final hashedPassword = PasswordHasher.hash(password);
      var profilePicUrl = '';
      if (profilePic != null) {
        profilePicUrl = await uploadFile(profilePic!, 'profilePics', username);
      }

      final schoolIdFrontUrl = await uploadFile(
        schoolIdFrontPhoto!,
        'schoolIds',
        '${username}_front',
      );
      final schoolIdBackUrl = await uploadFile(
        schoolIdBackPhoto!,
        'schoolIds',
        '${username}_back',
      );

      await _userRepository.createUser(
        AppUser(
          username: username,
          email: email,
          firstName: firstName,
          lastName: lastName,
          gender: gender,
          schoolId: schoolId,
          course: course,
          passwordHash: hashedPassword,
          profilePic: profilePicUrl,
          schoolIdFrontPhoto: schoolIdFrontUrl,
          schoolIdBackPhoto: schoolIdBackUrl,
          isVerified: false,
          role: 'user',
        ),
      );
      if (!mounted) return;

      _showMessage(
        message: 'Account created successfully!',
        icon: Icons.check_circle,
        iconColor: Colors.green,
      );

      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      });
    } catch (_) {
      if (!mounted) return;
      _showMessage(message: 'Sign up failed.', icon: Icons.error);
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _showMessage({
    required String message,
    required IconData icon,
    Color iconColor = Colors.red,
  }) {
    Flushbar(
      message: message,
      duration: const Duration(seconds: 2),
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      messageColor: const Color.fromARGB(255, 0, 0, 0),
      icon: Icon(icon, color: iconColor),
      margin: const EdgeInsets.all(8),
      borderRadius: BorderRadius.circular(8),
      flushbarPosition: FlushbarPosition.TOP,
    ).show(context);
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create account")),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                  color: Theme.of(context).colorScheme.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () => pickImage('profile'),
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: lightpurple.withValues(alpha: 0.3),
                            backgroundImage: profilePic != null
                                ? FileImage(profilePic!)
                                : null,
                            child: profilePic == null
                                ? const Icon(Icons.camera_alt, size: 40)
                                : null,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Upload a profile picture (optional)',
                          style: TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 20),
                        const Row(
                          children: [
                            Icon(Icons.warning, color: Colors.red, size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Please ensure that the information provided is accurate for verification purposes.',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        _buildTextField(emailController, 'Email', Icons.email),
                        const SizedBox(height: 15),
                        _buildTextField(
                          firstNameController,
                          'First Name',
                          Icons.person,
                        ),
                        const SizedBox(height: 15),
                        _buildTextField(
                          lastNameController,
                          'Last Name',
                          Icons.person_outline,
                        ),
                        const SizedBox(height: 15),
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          initialValue: selectedGender,
                          decoration: InputDecoration(
                            labelText: 'Gender',
                            prefixIcon: const Icon(Icons.wc),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: genderOptions
                              .map(
                                (gender) => DropdownMenuItem(
                                  value: gender,
                                  child: Text(gender),
                                ),
                              )
                              .toList(),
                          onChanged: (value) =>
                              setState(() => selectedGender = value),
                        ),
                        const SizedBox(height: 15),
                        _buildTextField(
                          usernameController,
                          'Username',
                          Icons.account_circle,
                        ),
                        const SizedBox(height: 15),
                        _buildTextField(
                          passwordController,
                          'Password',
                          Icons.lock,
                          isPassword: true,
                        ),
                        const SizedBox(height: 15),
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          initialValue: selectedCourse,
                          decoration: InputDecoration(
                            labelText: 'Course',
                            prefixIcon: const Icon(Icons.school),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: courseOptions
                              .map(
                                (course) => DropdownMenuItem(
                                  value: course,
                                  child: Text(course),
                                ),
                              )
                              .toList(),
                          onChanged: (value) =>
                              setState(() => selectedCourse = value),
                        ),
                        const SizedBox(height: 15),
                        _buildTextField(
                          schoolIdController,
                          'School ID Number',
                          Icons.badge,
                        ),
                        const SizedBox(height: 15),
                        ElevatedButton.icon(
                          onPressed: () => pickImage('front'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: uniFindAccent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.upload_file),
                          label: Text(
                            schoolIdFrontPhoto == null
                                ? 'Upload School ID Front'
                                : 'Change School ID Front',
                          ),
                        ),
                        if (schoolIdFrontPhoto != null) ...[
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(schoolIdFrontPhoto!, height: 120),
                          ),
                        ],
                        const SizedBox(height: 15),
                        ElevatedButton.icon(
                          onPressed: () => pickImage('back'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: uniFindAccent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.upload_file),
                          label: Text(
                            schoolIdBackPhoto == null
                                ? 'Upload School ID Back'
                                : 'Change School ID Back',
                          ),
                        ),
                        if (schoolIdBackPhoto != null) ...[
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(schoolIdBackPhoto!, height: 120),
                          ),
                        ],
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Checkbox(
                              value: agreedToTerms,
                              onChanged: (value) {
                                setState(() => agreedToTerms = value ?? false);
                              },
                              activeColor: uniFindPrimary,
                            ),
                            const Expanded(
                              child: Text(
                                'I agree to the Terms and Conditions',
                              ),
                            ),
                            TextButton(
                              onPressed: _showTermsAndConditions,
                              child: const Text(
                                'View',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: uniFindPrimary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: (agreedToTerms && !isLoading)
                              ? handleSignUp
                              : null,
                          child: isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  'Create Account',
                                  style: TextStyle(fontSize: 16),
                                ),
                        ),
                        const SizedBox(height: 15),
                        Wrap(
                          alignment: WrapAlignment.center,
                          children: [
                            const Text('Already have an account? '),
                            GestureDetector(
                              onTap: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const LoginScreen(),
                                  ),
                                );
                              },
                              child: const Text(
                                'Log In',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
