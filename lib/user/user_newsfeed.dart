import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../repositories/user_repository.dart';
import '../widgets/feed.dart';
import '../widgets/post_composer.dart';
import '../widgets/user_appbar.dart';
import '../widgets/user_bottom_nav.dart';

class UserNewsfeed extends StatefulWidget {
  const UserNewsfeed({super.key, required this.username});

  final String username;

  @override
  State<UserNewsfeed> createState() => _UserNewsFeedState();
}

class _UserNewsFeedState extends State<UserNewsfeed> {
  final int _currentIndex = 0;
  final UserRepository _userRepository = UserRepository();
  final GlobalKey<FeedState> _feedKey = GlobalKey<FeedState>();

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userSubscription;
  DocumentSnapshot<Map<String, dynamic>>? _userSnapshot;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _initUserStream();
  }

  void _initUserStream() {
    _userSubscription = _userRepository.streamUser(widget.username).listen((snapshot) {
      if (!mounted) return;
      setState(() {
        _userSnapshot = snapshot;
      });
    });
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }

  Future<void> _refreshFeed() async {
    setState(() => _isRefreshing = true);

    final snapshot = await _userRepository.getRawUser(widget.username);
    if (!mounted) return;

    setState(() {
      _userSnapshot = snapshot;
    });

    await _feedKey.currentState?.reloadPosts();
    await Future.delayed(const Duration(milliseconds: 600));

    if (mounted) {
      setState(() => _isRefreshing = false);
    }
  }

  Widget _getPageContent(int index) {
    switch (index) {
      case 0:
        return Stack(
          children: [
            RefreshIndicator(
              onRefresh: _refreshFeed,
              child: Feed(
                key: _feedKey,
                currentUser: widget.username,
              ),
            ),
            if (_isRefreshing)
              Container(
                color: Colors.black.withValues(alpha: 0.1),
                child: const Center(
                  child: SizedBox(
                    height: 40,
                    width: 40,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
                    ),
                  ),
                ),
              ),
          ],
        );
      case 1:
        return const Center(child: Text('Chats Page'));
      case 2:
        return const Center(child: Text('Notifications Page'));
      case 3:
        return const Center(child: Text('Items Page'));
      default:
        return const Center(child: Text('Newsfeed Page'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isVerified = _userSnapshot?.data()?['isVerified'] ?? true;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 225, 225, 225),
      appBar: UserAppBar(
        username: widget.username,
        userStream: _userSnapshot != null ? Stream.value(_userSnapshot!) : null,
      ),
      body: Column(
        children: [
          if (!isVerified)
            Container(
              width: double.infinity,
              color: Colors.orange.withValues(alpha: 0.2),
              padding: const EdgeInsets.all(8),
              child: const Text(
                'Some features like posting are not available until your account is verified by the admin.',
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          Expanded(child: _getPageContent(_currentIndex)),
        ],
      ),
      bottomNavigationBar: UserBottomNav(
        currentIndex: _currentIndex,
        username: widget.username,
      ),
      floatingActionButton: (_currentIndex == 0 && isVerified)
          ? PostComposer(username: widget.username)
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
