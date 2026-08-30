import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/admin_bottom_nav.dart';
import '../widgets/admin_appbar.dart';
import 'reports.dart';
import '../screens/tap_notif_page.dart';
import '../screens/comment_screen.dart';
import '../screens/user_profile_2.dart';

class AdminNotifications extends StatefulWidget {
  final String username;
  const AdminNotifications({super.key, required this.username});

  @override
  State<AdminNotifications> createState() => _AdminNotificationsState();
}

class _AdminNotificationsState extends State<AdminNotifications> {
  @override
  void initState() {
    super.initState();
  }


  bool _isRelevant(Map<String, dynamic> notif) {
  final title = (notif['title'] ?? '').toString().toLowerCase();
  if (title.contains("message")) return false;
  return true; // show everything else
  }


  void _handleNotificationTap(Map<String, dynamic> notif) {
    final data = notif['extraData'] ?? {};
    final postId = data['postId'];
    final commentId = data['commentId'];

    if (data.containsKey('postId') && postId != null && commentId == null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TapNotifPage(
            postId: data['postId'],
            currentUser: widget.username,
          ),
        ),
      );
      return;
    }

    if (data.containsKey('commentId') && commentId != null && postId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CommentScreen(
            postId: data['postId'],
            currentUser: widget.username,
            scrollToCommentId: data['commentId'],
          ),
        ),
      );
      return;
    }

    if (data.containsKey('reportedUser')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => UserProfile2(username: data['reportedUser']),
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
        .doc('admin')
        .collection('notifications')
        .orderBy('createdAt', descending: true);

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 193, 193, 193),
      appBar: const AdminAppBar(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ReportsPage()),
                  );
                },
                icon: const Icon(Icons.report, color: Colors.white),
                label: const Text("View Reports"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[700],
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: notifCollection.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final notifications = snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  data['id'] = doc.id;
                  return data;
                }).where(_isRelevant).toList();

                if (notifications.isEmpty) {
                  return const Center(
                    child: Text(
                      "No notifications yet 📭",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 90, left: 10, right: 10),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notif = notifications[index];
                    final displayText = notif['title'] ?? "UniFind";
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
                            .doc('admin')
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
                                "Are you sure you want to delete this notification?"),
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
                              .doc('admin')
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
                        color: isRead ? Colors.white : Colors.blue[50],
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          leading: Icon(
                            _getIconForTitle(displayText),
                            color: isRead ? Colors.grey : Colors.blueAccent,
                            size: 30,
                          ),
                          title: Text(
                            displayText,
                            style: TextStyle(
                              fontWeight:
                                  isRead ? FontWeight.normal : FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              "$body\n$createdAt",
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
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
          ),
        ],
      ),
      bottomNavigationBar: const AdminBottomNav(currentIndex: 2),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inSeconds < 60) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    if (diff.inDays < 7) return "${diff.inDays}d ago";
    return "${time.month}/${time.day}/${time.year}";
  }

  IconData _getIconForTitle(String title) {
    title = title.toLowerCase();
    if (title.contains("report")) return Icons.report;
    if (title.contains("announcement")) return Icons.campaign;
    if (title.contains("lost")) return Icons.search;
    if (title.contains("found")) return Icons.inventory;
    if (title.contains("removed")) return Icons.delete;
    if (title.contains("verified")) return Icons.verified;
    if (title.contains("like")) return Icons.thumb_up;
    if (title.contains("comment")) return Icons.comment;
    return Icons.notifications;
  }
}
