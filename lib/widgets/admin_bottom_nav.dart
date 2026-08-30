import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../admin/admin_newsfeed.dart';
import '../admin/admin_chats.dart';
import '../admin/admin_items.dart';
import '../admin/admin_notifications.dart';
import '../admin/admin_users.dart';
import '../services/chat_service.dart'; 

class AdminBottomNav extends StatelessWidget {
  final int currentIndex;
  final String adminUsername = 'admin'; 

  const AdminBottomNav({
    super.key,
    required this.currentIndex,
  });

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

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
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


              return BottomNavigationBar(
                currentIndex: currentIndex,
                onTap: (index) async => _onItemTapped(context, index),
                backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                selectedItemColor:
                    const Color.fromARGB(255, 7, 18, 80),
                unselectedItemColor: Colors.black87,
                type: BottomNavigationBarType.fixed,
                items: [
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.dashboard),
                    label: 'Newsfeed',
                  ),

                  // ✅ CHATS TAB WITH UNREAD BADGE
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
                    label: 'Chats',
                  ),

                  // ✅ NOTIFICATIONS TAB
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
                    label: 'Notifs',
                  ),

                  const BottomNavigationBarItem(
                    icon: Icon(Icons.backpack),
                    label: 'Items',
                  ),

                  // ✅ USERS TAB (pending verification)
                  BottomNavigationBarItem(
                    icon: Stack(
                      children: [
                        const Icon(Icons.people),
                        if (pendingUsers > 0)
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
                                '$pendingUsers',
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
                    label: 'Users',
                    
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
          },
        );
  }
}
