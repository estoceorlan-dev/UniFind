import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../admin/admin_newsfeed.dart';
import '../core/theme/appearance.dart';
import '../repositories/user_repository.dart';
import '../services/password_hasher.dart';
import '../user/user_newsfeed.dart';
import 'forgot_password_screen.dart';
import 'sign_up_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final UserRepository _userRepository = UserRepository();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadLastUsername();
  }

  Future<void> _loadLastUsername() async {
    final prefs = await SharedPreferences.getInstance();
    final lastUsername = prefs.getString('lastUsername');
    if (mounted && lastUsername != null) {
      setState(() {
        usernameController.text = lastUsername;
      });
    }
  }

  Future<void> login() async {
    if (isLoading) return;
    final username = usernameController.text.trim();
    final password = passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      _showError('Please enter both username and password');
      return;
    }

    setState(() => isLoading = true);

    try {
      final user = await _userRepository.fetchUser(username);
      if (!mounted) return;

      if (user == null) {
        _showError('User not found!');
        return;
      }

      if (user.passwordHash != PasswordHasher.hash(password)) {
        _showError('Incorrect password');
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('username', user.username);
      await prefs.setString('lastUsername', user.username);
      await prefs.setString('role', user.role);
      if (!mounted) return;

      final nextPage = user.role == 'admin'
          ? const AdminNewsFeed()
          : UserNewsfeed(username: user.username);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => nextPage),
      );
    } catch (_) {
      if (!mounted) return;
      _showError('Unexpected error occurred. Please try again.');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
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

  bool _hidePassword = true;

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final compact =
        MediaQuery.sizeOf(context).width < 380 ||
        MediaQuery.textScalerOf(context).scale(16) >= 24;
    return Scaffold(
      appBar: AppBar(
        title: const Text('UniFind'),
        actions: const [AppearanceMenu()],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(compact ? 12 : 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      color: const Color(0xff174d44),
                      padding: EdgeInsets.all(compact ? 16 : 24),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Campus lost\nand found',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                height: 1.08,
                                letterSpacing: -1.2,
                              ),
                            ),
                          ),
                          if (!compact)
                            DecoratedBox(
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xffccedb3),
                              ),
                              child: const Padding(
                                padding: EdgeInsets.all(16),
                                child: Icon(
                                  Icons.travel_explore_rounded,
                                  size: 42,
                                  color: Color(0xff174d44),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: AutofillGroup(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Log in',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 20),
                            TextField(
                              controller: usernameController,
                              autofillHints: const [AutofillHints.username],
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Username',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: passwordController,
                              obscureText: _hidePassword,
                              autofillHints: const [AutofillHints.password],
                              onSubmitted: (_) => login(),
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  tooltip: _hidePassword
                                      ? 'Show password'
                                      : 'Hide password',
                                  onPressed: () => setState(
                                    () => _hidePassword = !_hidePassword,
                                  ),
                                  icon: Icon(
                                    _hidePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const ForgotPasswordScreen(),
                                  ),
                                ),
                                child: const Text('Forgot Password?'),
                              ),
                            ),
                            FilledButton(
                              onPressed: isLoading ? null : login,
                              child: isLoading
                                  ? const SizedBox.square(
                                      dimension: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        semanticsLabel: 'Logging in',
                                      ),
                                    )
                                  : const Text('Log In'),
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SignUpScreen(),
                                ),
                              ),
                              child: const Text('Create Account'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
