import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../repositories/user_repository.dart';
import '../widgets/admin_appbar.dart';
import '../widgets/admin_bottom_nav.dart';
import '../widgets/feed.dart';
import '../widgets/post_composer.dart';

class AdminNewsFeed extends StatefulWidget {
  const AdminNewsFeed({super.key});

  @override
  State<AdminNewsFeed> createState() => _AdminNewsFeedState();
}

class _AdminNewsFeedState extends State<AdminNewsFeed> {
  final int _currentIndex = 0;
  final String _username = 'admin';
  final UserRepository _userRepository = UserRepository();
  final GlobalKey<FeedState> _feedKey = GlobalKey<FeedState>();

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _adminSubscription;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _adminSubscription = _userRepository.streamUser(_username).listen((_) {});
  }

  @override
  void dispose() {
    _adminSubscription?.cancel();
    super.dispose();
  }

  Future<void> _refreshFeed() async {
    setState(() => _isRefreshing = true);
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
                currentUser: _username,
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
        return const Center(child: Text('Chats Section (Coming Soon)'));
      case 2:
        return const Center(child: Text('Notifications Section (Coming Soon)'));
      case 3:
        return const Center(child: Text('Items Section (Coming Soon)'));
      case 4:
        return const Center(child: Text('Users Section (Coming Soon)'));
      default:
        return const Center(child: Text('Admin Newsfeed Content'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 225, 225, 225),
      appBar: const AdminAppBar(),
      body: SafeArea(child: _getPageContent(_currentIndex)),
      bottomNavigationBar: AdminBottomNav(currentIndex: _currentIndex),
      floatingActionButton: _currentIndex == 0
          ? PostComposer(username: _username)
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
