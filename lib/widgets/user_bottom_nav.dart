import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
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

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => targetPage),
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

            return BottomNavigationBar(
              currentIndex: currentIndex,
              onTap: (index) => _onTap(context, index),
              backgroundColor: const Color.fromARGB(255, 255, 255, 255),
              selectedItemColor: const Color.fromARGB(255, 7, 18, 80),
              unselectedItemColor: Colors.black87,
              type: BottomNavigationBarType.fixed,
              items: [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard),
                  label: "Newsfeed",
                ),

                // CHATS TAB WITH UNREAD BADGE
                BottomNavigationBarItem(
                  icon: Stack(
                    children: [
                      const Icon(Icons.chat_bubble_outline),
                      if (unreadMessages > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              '$unreadMessages',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                  label: "Chats",
                ),

                // NOTIFICATIONS TAB WITH UNREAD BADGE
                BottomNavigationBarItem(
                  icon: Stack(
                    children: [
                      const Icon(Icons.notifications),
                      if (unreadNotifs > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              '$unreadNotifs',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                  label: "Notifications",
                ),

                const BottomNavigationBarItem(
                  icon: Icon(Icons.backpack),
                  label: "Items",
                ),
              ],
              selectedLabelStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              unselectedLabelStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            );
          },
        );
      },
    );
  }
}
