import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/login_screen.dart';
import '../admin/admin_profile.dart';
import '../admin/admin_settings.dart';
import '../screens/search.dart';
import '../admin/admin_newsfeed.dart';

class AdminAppBar extends StatefulWidget implements PreferredSizeWidget {
  const AdminAppBar({super.key});

  @override
  State<AdminAppBar> createState() => _AdminAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _AdminAppBarState extends State<AdminAppBar> {
  String? username;
  Stream<DocumentSnapshot<Map<String, dynamic>>>? _adminStream;

  @override
  void initState() {
    super.initState();
    _initAdminStream();
  }

  Future<void> _initAdminStream() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUsername = prefs.getString('username') ?? "admin";
    setState(() {
      username = savedUsername;
      _adminStream = FirebaseFirestore.instance
          .collection('users')
          .doc(savedUsername)
          .snapshots();
    });
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Yes"),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      logout();
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastUsername', username ?? 'admin');
    await prefs.remove('username');
    await prefs.remove('role');

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      automaticallyImplyLeading: false,
      title: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminNewsFeed()),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                Icons.travel_explore_rounded,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 8),
            const Flexible(
              child: Text(
                'UniFind',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -.8,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          tooltip: "Search",
          icon: const Icon(Icons.search),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => Search(username: username ?? "admin"),
              ),
            );
          },
        ),
        const SizedBox(width: 8),
        if (_adminStream != null)
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: _adminStream,
            builder: (context, snapshot) {
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const SizedBox();
              }
              final data = snapshot.data!.data()!;
              final displayName = data['username'] ?? 'Admin';
              final profilePic = data['profilePic'] ?? '';

              return Row(
                children: [
                  PopupMenuButton<String>(
                    tooltip: "Account menu for $displayName",
                    offset: const Offset(0, 50),
                    child: CircleAvatar(
                      backgroundImage: (profilePic.isNotEmpty)
                          ? NetworkImage(profilePic)
                          : const AssetImage('assets/images/defaultpfp.jpg')
                                as ImageProvider,
                    ),
                    onSelected: (value) {
                      if (value == 'logout') {
                        _confirmLogout();
                      } else if (value == 'profile') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                AdminProfile(username: username ?? "admin"),
                          ),
                        );
                      } else if (value == 'settings') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminSettings(),
                          ),
                        );
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'profile',
                        child: Row(
                          children: [
                            Icon(Icons.person, color: Colors.blue),
                            SizedBox(width: 8),
                            Text("Profile"),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'settings',
                        child: Row(
                          children: [
                            Icon(Icons.settings, color: Colors.grey),
                            SizedBox(width: 8),
                            Text("Settings"),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'logout',
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
}
