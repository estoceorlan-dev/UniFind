import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'campus_navigation.dart';
import '../user/user_chats.dart';
import '../user/user_items.dart';
import '../user/user_newsfeed.dart';
import '../user/user_notifications.dart';
import '../services/chat_service.dart';

class UserBottomNav extends StatelessWidget {
  final int currentIndex;
  final String username;

  const UserBottomNav({
    Key? key,
    required this.currentIndex,
    required this.username,
  }) : super(key: key);

  void _onTap(BuildContext context, int index) async {
    if (index == currentIndex) return; // already on this page

    Widget targetPage;

    switch (index) {
      case 0:
        targetPage = UserNewsfeed(username: username);
        break;
      case 1:
        targetPage = UserChats(username: username);
        ChatService().markAllMessagesAsRead(username);
        break;
      case 2:
        targetPage = UserNotifications(username: username);
        break;
      case 3:
        targetPage = UserItems(username: username);
        break;
      default:
        targetPage = UserNewsfeed(username: username);
    }

    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      campusTabRoute(context, targetPage),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen to unread notifications
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("users")
          .doc(username)
          .collection("notifications")
          .where("isRead", isEqualTo: false)
          .snapshots(),
      builder: (context, notifSnapshot) {
        int unreadNotifs = 0;
        if (notifSnapshot.hasData) {
          unreadNotifs = notifSnapshot.data!.docs.length;
        }

        // Listen to unread chats
        return StreamBuilder<int>(
          stream: ChatService().getUnreadCount(username),
          builder: (context, chatSnapshot) {
            // Current snapshot value or 0 if loading/error
            int unreadMessages = chatSnapshot.data ?? 0;

            return CampusNavigation(
              index: currentIndex,
              onSelect: (index) => _onTap(context, index),
              messages: unreadMessages,
              alerts: unreadNotifs,
            );
          },
        );
      },
    );
  }
}
