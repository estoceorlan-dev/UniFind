import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/notification_generator.dart';
import '../screens/edit_post_screen.dart';

class FeedMenu extends StatelessWidget {
  final String currentUser;
  final String postOwner;
  final String postId;
  final String caption;
  final List<String> tags; 
  final List<String> postImages;

  const FeedMenu({
    Key? key,
    required this.currentUser,
    required this.postOwner,
    required this.postId,
    required this.caption,
    required this.tags,
    required this.postImages,
  }) : super(key: key);


  Future<void> _deletePost(BuildContext context, String postId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Post"),
        content: const Text("Are you sure you want to delete this post?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Yes")),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection("posts").doc(postId).delete();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Post deleted")));
    }
  }

  Future<void> _removePost(BuildContext context, String postId) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Remove Post"),
      content: const Text("Are you sure you want to remove this post?"),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text("Yes"),
        ),
      ],
    ),
  );

  if (confirm != true) return;

  final postDoc = await FirebaseFirestore.instance
      .collection("posts")
      .doc(postId)
      .get();

  if (!postDoc.exists) return;

  final postData = postDoc.data()!;
  final postOwner = postData['username']; // owner username
  final postType = postData['type'] ?? 'post'; // get post type (default 'post')
  final currentUserId = currentUser; // admin removing the post

  // Delete the post
  await FirebaseFirestore.instance.collection("posts").doc(postId).delete();
  ScaffoldMessenger.of(context)
      .showSnackBar(const SnackBar(content: Text("Post removed")));

  // Send notification to the owner
  if (postOwner != null && postOwner != currentUserId) {
    await NotificationGenerator.postRemoved(
      postOwner,
      postId,
      postType,
    );
  }
}

  Future<void> _reportPost(BuildContext context, String postId) async {
    String? selectedReason;
    final TextEditingController otherController = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Report Post"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Are you sure you want to report this post?"),
              const Divider(),
              ...["Spam", "Inappropriate", "Harassment", "Other"].map((reason) {
                return RadioListTile<String>(
                  title: Text(reason),
                  value: reason,
                  groupValue: selectedReason,
                  onChanged: (value) => setState(() => selectedReason = value),
                );
              }),
              if (selectedReason == "Other")
                TextField(
                  controller: otherController,
                  decoration: const InputDecoration(hintText: "Enter details..."),
                  maxLength: 20,
                ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Submit")),
          ],
        ),
      ),
    );

    if (confirm == true && selectedReason != null) {
    final reason = selectedReason == "Other"
      ? otherController.text.trim()
      : selectedReason!;

  await FirebaseFirestore.instance.collection("reports").add({
    "postId": postId,
    "reportedBy": currentUser,
    "reason": reason, 
    "reportedAt": FieldValue.serverTimestamp(),
  });

  ScaffoldMessenger.of(context)
      .showSnackBar(const SnackBar(content: Text("Post reported")));

  await NotificationGenerator.reportPost(
    reporter: currentUser,
    postOwner: postOwner,
    postId: postId,
    reason: reason,
  );
  }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection("users").doc(currentUser).get(),
      builder: (context, snapshot) {
        String role = '';
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          role = data["role"] ?? '';
        }

        if (currentUser == postOwner) {
          return PopupMenuButton<String>(
            onSelected: (value) {
              if (value == "edit") {
               Navigator.push(
               context,
               MaterialPageRoute(
                 builder: (_) => EditPostScreen(
                 postId: postId,
                  initialCaption: caption,
                   initialTags: tags,
                   initialImages: postImages,
                 ),
                ),
               );
              }
              if (value == "delete") _deletePost(context, postId);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          );
        } else if (role == 'admin') {
          return PopupMenuButton<String>(
            onSelected: (value) {
              if (value == "remove") _removePost(context, postId);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'remove', child: Text('Remove')),
            ],
          );
        } else {
          return PopupMenuButton<String>(
            onSelected: (value) {
              if (value == "report") _reportPost(context, postId);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'report', child: Text('Report')),
            ],
          );
        }
      },
    );
  }
}
