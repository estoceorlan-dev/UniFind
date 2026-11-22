import '../widgets/campus_scaffold.dart';
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

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
  _adminSubscription;

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
    await _feedKey.currentState?.reloadPosts();
  }

  Widget _getPageContent(int index) {
    switch (index) {
      case 0:
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                  child: Text(
                    'Campus feed',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1,
                    ),
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refreshFeed,
                    child: Feed(key: _feedKey, currentUser: _username),
                  ),
                ),
              ],
            ),
          ),
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
    return CampusScaffold(
      appBar: const AdminAppBar(),
      body: SafeArea(child: _getPageContent(_currentIndex)),
      navigation: AdminBottomNav(currentIndex: _currentIndex),
      floatingActionButton: _currentIndex == 0
          ? PostComposer(username: _username)
          : null,

    );
  }
}
