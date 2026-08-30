import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/admin_bottom_nav.dart';
import '../widgets/admin_appbar.dart';
import '../screens/user_profile_2.dart';
import 'verify_users.dart';

class AdminUsers extends StatefulWidget {
  final String adminUsername;
  const AdminUsers({super.key, required this.adminUsername});

  @override
  State<AdminUsers> createState() => _AdminUsersState();
}

class _AdminUsersState extends State<AdminUsers> {
  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE0F7FA),
      appBar: const AdminAppBar(),
      body: Column(
        children: [
          // Verify Users button with badge
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'user')
                  .where('isVerified', isEqualTo: false)
                  .snapshots(),
              builder: (context, snapshot) {
                int pendingCount = 0;
                if (snapshot.hasData) {
                  pendingCount = snapshot.data!.docs.length;
                }

                return Stack(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const VerifyUsers(),
                            ),
                          );
                        },
                        child: const Text(
                          "Verify Users",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    if (pendingCount > 0)
                      Positioned(
                        right: 12,
                        top: 6,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            pendingCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: "Search users...",
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // List of verified users
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'user')
                  .where('isVerified', isEqualTo: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No verified users found."));
                }

                // Filter users client-side
                final users = snapshot.data!.docs.where((doc) {
                  final user = doc.data() as Map<String, dynamic>;
                  final username = (user['username'] ?? '').toString().toLowerCase();
                  final firstName = (user['firstName'] ?? '').toString().toLowerCase();
                  final lastName = (user['lastName'] ?? '').toString().toLowerCase();
                  final fullName = "$firstName $lastName";

                  return username.contains(searchQuery) ||
                      firstName.contains(searchQuery) ||
                      lastName.contains(searchQuery) ||
                      fullName.contains(searchQuery);
                }).toList();

                if (users.isEmpty) {
                  return const Center(child: Text("No matching users."));
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final doc = users[index];
                    final user = doc.data() as Map<String, dynamic>;
                    final userId = doc.id;
                    final username = user['username'] ?? '';
                    final firstName = user['firstName'] ?? '';
                    final lastName = user['lastName'] ?? '';
                    final profilePic = user['profilePic'] ?? '';

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                      child: ListTile(
                        leading: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    UserProfile2(username: username),
                              ),
                            );
                          },
                          child: CircleAvatar(
                            radius: 26,
                            backgroundImage: profilePic.isNotEmpty
                                ? NetworkImage(profilePic)
                                : const AssetImage('assets/defaultpfp.jpg')
                                    as ImageProvider,
                          ),
                        ),
                        title: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    UserProfile2(username: username),
                              ),
                            );
                          },
                          child: Text(
                            "$firstName $lastName",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        subtitle: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    UserProfile2(username: username),
                              ),
                            );
                          },
                          child: Text("@$username"),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.remove_circle, color: Colors.red),
                          onPressed: () {
                            _showRemoveDialog(context, userId, username);
                          },
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 2,
                          vertical: 8,
                        ),
                      ),
                    );
                  },
                  separatorBuilder: (context, index) => const Divider(
                    thickness: 0.3,
                    height: 5,
                    color: Colors.black26,
                    indent: 16,
                    endIndent: 16,
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar:
          AdminBottomNav(currentIndex: 4),
    );
  }

  void _showRemoveDialog(BuildContext context, String userId, String username) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Remove User"),
        content: Text("Are you sure you want to remove @$username?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color.fromARGB(255, 255, 255, 255)),
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .delete();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("User @$username removed")),
              );
            },
            child: const Text("Remove"),
          ),
        ],
      ),
    );
  }
}
