import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'campus_navigation.dart';
import '../admin/admin_newsfeed.dart';
import '../admin/admin_chats.dart';
import '../admin/admin_items.dart';
import '../admin/admin_notifications.dart';
import '../admin/admin_users.dart';
import '../services/chat_service.dart';

class AdminBottomNav extends StatelessWidget {
  final int currentIndex;
  final String adminUsername = 'admin';

  const AdminBottomNav({super.key, required this.currentIndex});

  void _onItemTapped(BuildContext context, int index) async {
    if (index == currentIndex) return; // already on this page

    Widget page;

    switch (index) {
      case 0:
        page = const AdminNewsFeed();
        break;
      case 1:
        page = const AdminChats(adminUsername: 'admin');
        break;
      case 2:
        await _markAllNotificationsRead();
        page = const AdminNotifications(username: 'admin');
        break;
      case 3:
        page = const AdminItems(username: 'admin');
        break;
      case 4:
        page = AdminUsers(adminUsername: adminUsername);
        break;
      default:
        page = const AdminNewsFeed();
    }

    if (!context.mounted) return;
    Navigator.pushReplacement(context, campusTabRoute(context, page));
  }

  /// ✅ Mark all unread notifications as read
  Future<void> _markAllNotificationsRead() async {
    final snapshot = await FirebaseFirestore.instance
        .collection("admins")
        .doc(adminUsername)
        .collection("notifications")
        .where("isRead", isEqualTo: false)
        .get();

    for (var doc in snapshot.docs) {
      await doc.reference.update({"isRead": true});
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Listen to unread notifications
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("users")
          .doc(adminUsername)
          .collection("notifications")
          .where("isRead", isEqualTo: false)
          .snapshots(),
      builder: (context, notifSnapshot) {
        int unreadNotifs = 0;
        if (notifSnapshot.hasData) {
          unreadNotifs = notifSnapshot.data!.docs.length;
        }

        // ✅ Listen to pending user verifications
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection("users")
              .where("role", isEqualTo: "user")
              .where("isVerified", isEqualTo: false)
              .snapshots(),
          builder: (context, userSnapshot) {
            int pendingUsers = 0;
            if (userSnapshot.hasData) {
              pendingUsers = userSnapshot.data!.docs.length;
            }

            // Listen to unread chats
            return StreamBuilder<int>(
              stream: ChatService().getUnreadCount(adminUsername),
              builder: (context, chatSnapshot) {
                // Current snapshot value or 0 if loading/error
                int unreadMessages = chatSnapshot.data ?? 0;

                return CampusNavigation(
                  index: currentIndex,
                  onSelect: (index) => _onItemTapped(context, index),
                  messages: unreadMessages,
                  alerts: unreadNotifs,
                  pending: pendingUsers,
                );
              },
            );
          },
        );
      },
    );
  }
}
