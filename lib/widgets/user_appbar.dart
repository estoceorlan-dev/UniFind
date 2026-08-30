import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../screens/login_screen.dart';
import '../user/user_profile.dart';
import '../user/user_settings.dart';
import '../screens/search.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../user/user_newsfeed.dart';

class UserAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String username;
  final Stream<DocumentSnapshot<Map<String, dynamic>>>? userStream;

  const UserAppBar({
    Key? key,
    required this.username,
    required this.userStream,
  }) : super(key: key);

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastUsername', username);
    await prefs.remove('username');
    await prefs.remove('role');

    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text("Logout"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _logout(context);
            },
            child: const Text(
              "Yes",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => UserNewsfeed(username: username),
                ),
              );
            },
            child: const CircleAvatar(
              backgroundImage: AssetImage('assets/images/logo2.jpg'),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => UserNewsfeed(username: username),
                ),
              );
            },
            child: Text(
            "UniFind",
            style: GoogleFonts.poppins(
              textStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Color.fromARGB(255, 5, 12, 72),
              ),
            ),
          ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: Colors.black),
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => Search(username: username)));
          },
        ),
        const SizedBox(width: 8),
        if (userStream != null)
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: userStream,
            builder: (context, snapshot) {
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const SizedBox();
              }
              final data = snapshot.data!.data()!;
              final displayName = data['username'] ?? 'User';
              final profilePic = data['profilePic'] ?? '';

              return Row(
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    offset: const Offset(0, 50),
                    child: CircleAvatar(
                      backgroundImage: (profilePic.isNotEmpty)
                          ? NetworkImage(profilePic)
                          : const AssetImage('assets/images/defaultpfp.jpg')
                              as ImageProvider,
                    ),
                    onSelected: (value) {
                      if (value == "logout") {
                        _showLogoutDialog(context);
                      } else if (value == "profile") {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                UserProfile(username: username),
                          ),
                        );
                      } else if (value == "settings") {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const UserSettings(),
                          ),
                        );
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: "profile",
                        child: Row(
                          children: [
                            Icon(Icons.person, color: Colors.black54),
                            SizedBox(width: 8),
                            Text("Profile"),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: "settings",
                        child: Row(
                          children: [
                            Icon(Icons.settings, color: Colors.black54),
                            SizedBox(width: 8),
                            Text("Settings"),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: "logout",
                        child: Row(
                          children: [
                            Icon(Icons.logout, color: Colors.red),
                            SizedBox(width: 8),
                            Text("Logout"),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                ],
              );
            },
          )
        else
          const SizedBox(),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
