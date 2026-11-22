import '../widgets/campus_scaffold.dart';
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

  @override
  void initState() {
    super.initState();
    _initUserStream();
  }

  void _initUserStream() {
    _userSubscription = _userRepository.streamUser(widget.username).listen((
      snapshot,
    ) {
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
    final snapshot = await _userRepository.getRawUser(widget.username);
    if (!mounted) return;

    setState(() {
      _userSnapshot = snapshot;
    });

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
                    child: Feed(key: _feedKey, currentUser: widget.username),
                  ),
                ),
              ],
            ),
          ),
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

    return CampusScaffold(
      appBar: UserAppBar(
        username: widget.username,
        userStream: _userSnapshot != null ? Stream.value(_userSnapshot!) : null,
      ),
      body: Column(
        children: [
          if (!isVerified)
            Container(
              width: double.infinity,
              color: Theme.of(context).colorScheme.tertiaryContainer,
              padding: const EdgeInsets.all(8),
              child: Text(
                'Some features like posting are not available until your account is verified by the admin.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onTertiaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          Expanded(child: _getPageContent(_currentIndex)),
        ],
      ),
      navigation: UserBottomNav(
        currentIndex: _currentIndex,
        username: widget.username,
      ),
      floatingActionButton: (_currentIndex == 0 && isVerified)
          ? PostComposer(username: widget.username)
          : null,

    );
  }
}
