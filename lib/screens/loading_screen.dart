import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../admin/admin_chats.dart';
import '../admin/admin_notifications.dart';
import '../admin/admin_newsfeed.dart';
import '../services/notification_generator.dart';
import '../user/user_chats.dart';
import '../user/user_newsfeed.dart';
import '../user/user_notifications.dart';
import 'login_screen.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  bool _hasConnection = true;
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _initSetup();
  }

  Future<void> _initSetup() async {
    await NotificationGenerator.init();
    await _checkConnection();
  }

  Future<void> _checkConnection() async {
    setState(() {
      _isChecking = true;
      _hasConnection = true;
    });

    final connectivityResults = await Connectivity().checkConnectivity();
    final isOffline = connectivityResults.contains(ConnectivityResult.none);

    if (isOffline) {
      if (!mounted) return;
      setState(() {
        _hasConnection = false;
        _isChecking = false;
      });
      return;
    }

    await Future.delayed(const Duration(seconds: 5));
    if (!mounted) return;

    final retryResults = await Connectivity().checkConnectivity();
    if (retryResults.contains(ConnectivityResult.none)) {
      setState(() {
        _hasConnection = false;
        _isChecking = false;
      });
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final savedUser = prefs.getString('username');
    final role = prefs.getString('role');
    final redirect = prefs.getString('redirect');

    Widget nextPage;
    if (savedUser != null && role != null) {
      if (redirect == 'notifications') {
        nextPage = role == 'admin'
            ? const AdminNotifications(username: 'admin')
            : UserNotifications(username: savedUser);
      } else if (redirect == 'chats') {
        nextPage = role == 'admin'
            ? const AdminChats(adminUsername: 'admin')
            : UserChats(username: savedUser);
      } else {
        nextPage = role == 'admin'
            ? const AdminNewsFeed()
            : UserNewsfeed(username: savedUser);
      }
    } else {
      nextPage = const LoginScreen();
    }

    await prefs.remove('redirect');
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => nextPage),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return _buildSplash();
    }

    if (!_hasConnection) {
      return Scaffold(
        body: Center(
          child: Card(
            elevation: 4,
            margin: const EdgeInsets.all(20),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.wifi_off, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'No Internet Connection',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Please check your network and try again.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _checkConnection,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return _buildSplash();
  }

  Widget _buildSplash() {
    return Scaffold(
      backgroundColor: const Color(0xFFE0F7FA),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Hero(
              tag: 'logo',
              child: ClipOval(
                child: Image.asset(
                  'assets/images/logo2.jpg',
                  width: 160,
                  height: 160,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Text('Loading...'),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 100),
              child: Text('Copyright 2025 UniFind. All rights reserved.'),
            ),
          ],
        ),
      ),
    );
  }
}
