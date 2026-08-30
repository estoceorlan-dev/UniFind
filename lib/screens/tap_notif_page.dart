import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../repositories/post_repository.dart';
import '../widgets/feed.dart';

class TapNotifPage extends StatefulWidget {
  const TapNotifPage({
    super.key,
    required this.postId,
    required this.currentUser,
  });

  final String postId;
  final String currentUser;

  @override
  State<TapNotifPage> createState() => _TapNotifPageState();
}

class _TapNotifPageState extends State<TapNotifPage> {
  final PostRepository _postRepository = PostRepository();

  Future<Map<String, dynamic>?> _getPostData() async {
    final doc = await _postRepository.fetchPost(widget.postId);
    if (!doc.exists) return null;

    final data = doc.data()!;
    data['id'] = doc.id;
    return data;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 193, 193, 193),
      appBar: AppBar(
        title: const Text('Post'),
        backgroundColor: Colors.grey[800],
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _getPostData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Post not found.'));
          }

          final post = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: PostCard(
              key: ValueKey(post['id']),
              postId: post['id'],
              username: post['createdBy'] ?? 'Unknown',
              caption: post['caption'] ?? '',
              imageUrls: List<String>.from(post['images'] ?? []),
              tags: (() {
                final rawTags = post['tags'];
                if (rawTags == null) return <String>[];
                if (rawTags is List) {
                  return rawTags.map((tag) => tag.toString()).toList();
                }
                if (rawTags is String && rawTags.trim().isNotEmpty) {
                  return rawTags.split(',').map((tag) => tag.trim()).toList();
                }
                return <String>[];
              })(),
              createdAt: post['createdAt'] ?? Timestamp.now(),
              updatedAt: post['updatedAt'],
              likesCount: post['likesCount'] ?? 0,
              currentUser: widget.currentUser,
              postOwnerUsername: post['createdBy'],
            ),
          );
        },
      ),
    );
  }
}
