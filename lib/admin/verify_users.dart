import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../repositories/user_repository.dart';
import '../screens/user_profile_2.dart';
import '../services/notification_generator.dart';
import 'admin_newsfeed.dart';

class VerifyUsers extends StatefulWidget {
  const VerifyUsers({super.key});

  @override
  State<VerifyUsers> createState() => _VerifyUsersState();
}

class _VerifyUsersState extends State<VerifyUsers> {
  final UserRepository _userRepository = UserRepository();
  String searchQuery = "";

  void filterUsers(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 221, 248, 255),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 80, 188, 255),
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Verify Users",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminNewsFeed()),
                );
              },
              child: const CircleAvatar(
                radius: 18,
                backgroundImage: AssetImage("assets/images/logo2.jpg"),
                backgroundColor: Colors.transparent,
              ),
            ),
          ),
        ],
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search by first or last name...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: filterUsers,
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _userRepository.streamPendingUsers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                      child: Text("No users pending verification."));
                }

                // SAFE LOCAL lists
                final List<QueryDocumentSnapshot> docs = snapshot.data!.docs;

                final filtered = searchQuery.isEmpty
                    ? docs
                    : docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final first = (data['firstName'] ?? '')
                            .toString()
                            .toLowerCase();
                        final last =
                            (data['lastName'] ?? '').toString().toLowerCase();
                        return first.contains(searchQuery) ||
                            last.contains(searchQuery);
                      }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text("No users found."));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final doc = filtered[index];
                    final user = doc.data() as Map<String, dynamic>;
                    final docId = doc.id;

                    final username = user['username'] ?? '';
                    final firstName = user['firstName'] ?? '';
                    final lastName = user['lastName'] ?? '';
                    final profilePic = user['profilePic'] ?? '';
                    final schoolIdFront = user['schoolIdFrontPhoto'] ?? '';
                    final schoolIdBack = user['schoolIdBackPhoto'] ?? '';

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    UserProfile2(username: username),
                              ),
                            );
                          },
                          child: CircleAvatar(
                            radius: 20,
                            backgroundImage: profilePic.isNotEmpty
                                ? NetworkImage(profilePic)
                                : const AssetImage('assets/images/defaultpfp.jpg')
                                    as ImageProvider,
                          ),
                        ),
                        title: Text(
                          "$firstName $lastName",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        subtitle: Text("@$username", style: const TextStyle(fontSize: 12)),

                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.badge, color: Colors.blue),
                              tooltip: "View School ID",
                              onPressed: () {
                                if (schoolIdFront.isNotEmpty ||
                                    schoolIdBack.isNotEmpty) {
                                  _showSchoolIdDialog(
                                    context,
                                    username,
                                    schoolIdFront,
                                    schoolIdBack,
                                  );
                                } else {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("No school ID for @$username"),
                                    ),
                                  );
                                }
                              },
                            ),

                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              ),
                              onPressed: () async {
                                try {
                                  await _userRepository.verifyUser(docId);
                                  try {
                                    await NotificationGenerator.accountVerified(docId);
                                  } catch (_) {
                                    await NotificationGenerator.accountVerified(username);
                                  }

                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("Verified @$username")),
                                  );
                                } catch (e) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("Failed to verify @$username: $e"),
                                    ),
                                  );
                                }
                              },
                              child: const Text("Verify"),
                            ),
                            const SizedBox(height: 40),
                          ],
                          
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
    );
  }

  // ------------------ ID VIEWER ------------------
  void _showSchoolIdDialog(
    BuildContext context,
    String username,
    String frontUrl,
    String backUrl,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("School ID - @$username",
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              if (frontUrl.isNotEmpty)
                Column(
                  children: [
                    const Text("Front"),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () =>
                          _showFullScreenImage(context, frontUrl, "Front ID"),
                      child: Image.network(frontUrl, height: 200),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),

              if (backUrl.isNotEmpty)
                Column(
                  children: [
                    const Text("Back"),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () =>
                          _showFullScreenImage(context, backUrl, "Back ID"),
                      child: Image.network(backUrl, height: 200),
                    ),
                  ],
                ),

              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Close"),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _showFullScreenImage(
      BuildContext context, String url, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            title: Text(title),
          ),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4,
              child: Image.network(url),
            ),
          ),
        ),
      ),
    );
  }
}
