import '../widgets/campus_scaffold.dart';
import '../widgets/loading_skeleton.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../widgets/user_bottom_nav.dart';
import '../widgets/user_appbar.dart';
import '../screens/tap_notif_page.dart';
import '../screens/comment_screen.dart';

class UserNotifications extends StatefulWidget {
  final String username;

  const UserNotifications({Key? key, required this.username}) : super(key: key);

  @override
  State<UserNotifications> createState() => _UserNotificationsState();
}

class _UserNotificationsState extends State<UserNotifications> {
  Stream<DocumentSnapshot<Map<String, dynamic>>>? _userStream;

  @override
  void initState() {
    super.initState();
    _initUserStream();
  }

  Future<void> _initUserStream() async {
    setState(() {
      _userStream = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.username)
          .snapshots();
    });
  }

  /// 🔎 Filter only relevant notifications (exclude messages and reports)
  bool _isRelevant(Map<String, dynamic> notif) {
    final title = (notif['title'] ?? '').toString().toLowerCase();
    final extra = notif['extraData'] ?? {};
    final isReport = title.contains("report") || extra['reportType'] != null;

    if (title.contains("message")) if (isReport) return false;
    return true;
  }

  void _handleNotificationTap(Map<String, dynamic> notif) {
    final data = notif['extraData'] ?? {};
    final postId = data['postId'];
    final commentId = data['commentId'];

    // Navigate based on type
    if (data.containsKey('postId') && postId != null && commentId == null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              TapNotifPage(currentUser: widget.username, postId: postId),
        ),
      );
      return;
    }

    if (data.containsKey('commentId') && commentId != null && postId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CommentScreen(
            postId: postId,
            currentUser: widget.username,
            scrollToCommentId: commentId,
          ),
        ),
      );
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Firestore collection reference for notifications
    final notifCollection = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.username)
        .collection('notifications')
        .orderBy('createdAt', descending: true);

    return CampusScaffold(
      appBar: UserAppBar(username: widget.username, userStream: _userStream),
      body: StreamBuilder<QuerySnapshot>(
        stream: notifCollection.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                "Could not load notifications. Please try again later.",
              ),
            );
          }
          if (!snapshot.hasData) {
            return const LoadingSkeleton();
          }

          final notifications = snapshot.data!.docs
              .map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                data['id'] = doc.id;
                return data;
              })
              .where(_isRelevant)
              .toList();

          if (notifications.isEmpty) {
            return const Center(
              child: Text(
                "No notifications yet 📭",
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 90, left: 10, right: 10),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notif = notifications[index];
              final displayText = notif['title'] ?? "";
              final body = notif['body'] ?? "";
              final timestamp = notif['createdAt'];
              final createdAt = timestamp is Timestamp
                  ? _formatTime(timestamp.toDate())
                  : "";
              final isRead = notif['isRead'] == true;

              return GestureDetector(
                onTap: () {
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(widget.username)
                      .collection('notifications')
                      .doc(notif['id'])
                      .update({'isRead': true});

                  _handleNotificationTap(notif);
                },
                onLongPress: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("Delete Notification"),
                      content: const Text(
                        "Are you sure you want to delete this notification?",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text("Cancel"),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text("Delete"),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(widget.username)
                        .collection('notifications')
                        .doc(notif['id'])
                        .delete();

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Notification deleted."),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                child: Card(
                  color: isRead
                      ? Theme.of(context).colorScheme.surface
                      : Theme.of(context).colorScheme.secondaryContainer,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    textColor: isRead
                        ? Theme.of(context).colorScheme.onSurface
                        : Theme.of(context).colorScheme.onSecondaryContainer,
                    leading: Icon(
                      _getIconForTitle(displayText),
                      color: isRead
                          ? Theme.of(context).colorScheme.onSurfaceVariant
                          : Theme.of(context).colorScheme.onSecondaryContainer,
                      size: 30,
                    ),
                    title: Text(
                      displayText,
                      style: TextStyle(
                        fontWeight: isRead
                            ? FontWeight.normal
                            : FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        "$body\n$createdAt",
                        style: TextStyle(
                          fontSize: 13,
                          color: isRead
                              ? Theme.of(context).colorScheme.onSurfaceVariant
                              : Theme.of(
                                  context,
                                ).colorScheme.onSecondaryContainer,
                          height: 1.3,
                        ),
                      ),
                    ),
                    isThreeLine: true,
                  ),
                ),
              );
            },
          );
        },
      ),
      navigation: UserBottomNav(currentIndex: 2, username: widget.username),
    );
  }

  /// 🕒 Format timestamp to "time ago"
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inSeconds < 60) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    if (diff.inDays < 7) return "${diff.inDays}d ago";
    return "${time.month}/${time.day}/${time.year}";
  }

  /// 🧩 Icon selector based on notification text
  IconData _getIconForTitle(String title) {
    title = title.toLowerCase();
    if (title.contains("like")) return Icons.favorite;
    if (title.contains("comment")) return Icons.comment;
    if (title.contains("reply")) return Icons.reply;
    if (title.contains("post")) return Icons.article;
    if (title.contains("announcement")) return Icons.campaign;
    if (title.contains("verified")) return Icons.verified;
    return Icons.notifications;
  }
}
