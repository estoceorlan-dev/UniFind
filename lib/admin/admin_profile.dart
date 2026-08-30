import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_admin_profile.dart';
import '../widgets/feed.dart';
import 'admin_newsfeed.dart';

class AdminProfile extends StatefulWidget {
  final String username; 

  const AdminProfile({super.key, required this.username});

  @override
  State<AdminProfile> createState() => _AdminProfileState();
}

class _AdminProfileState extends State<AdminProfile> {
  late String _username;

  @override
  void initState() {
    super.initState();
    _username = widget.username;
  }

  Future<Map<String, dynamic>?> _getAdminData() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('users').doc(_username).get();
    return snapshot.data();
  }

  void _showFullImage(BuildContext context, ImageProvider imageProvider) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: InteractiveViewer(
            panEnabled: true,
            minScale: 0.8,
            maxScale: 4.0,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image(image: imageProvider, fit: BoxFit.cover),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _navigateToEdit() async {
    final updatedUsername = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditAdminProfile(username: _username),
      ),
    );

    if (updatedUsername != null && updatedUsername is String) {
      setState(() {
        _username = updatedUsername;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      appBar: AppBar(
        title: const Text("Admin Profile"),
        backgroundColor: const Color.fromARGB(255, 120, 120, 120),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: GestureDetector(
              onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                builder: (_) => AdminNewsFeed(),
                ),
              );
              },
              child: CircleAvatar(
              radius: 18,
              backgroundImage: const AssetImage("assets/images/logo2.jpg"),
              backgroundColor: Colors.transparent,
              ),
            ),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _getAdminData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("No admin data found."));
          }

          final adminData = snapshot.data!;
          final profilePic = adminData['profilePic']?.isNotEmpty == true
              ? NetworkImage(adminData['profilePic'])
              : const AssetImage("assets/images/defaultpfp.jpg")
                  as ImageProvider;

          return SingleChildScrollView(
            child: Column(
              children: [
                // Profile Card
                Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 6,
                    shadowColor: Colors.grey.withOpacity(0.25),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 22, vertical: 32),
                      child: Column(
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              GestureDetector(
                                onTap: () => _showFullImage(context, profilePic),
                                child: CircleAvatar(
                                  radius: 60,
                                  backgroundImage: profilePic,
                                ),
                              ),
                                Positioned(
                                  right: 6,
                                  top: 6,
                                  child: CircleAvatar(
                                    radius: 16,
                                    backgroundColor: Colors.white,
                                    child: const Icon(Icons.settings,
                                        color: Color.fromARGB(255, 27, 38, 64), size: 30),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            "@${adminData['username'] ?? "admin"}",
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "${adminData['firstName'] ?? ""} ${adminData['lastName'] ?? ""}",
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const Divider(height: 35, thickness: 1.3),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Email:",
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600, fontSize: 16)),
                              Flexible(
                                child: Text(
                                  adminData['email'] ?? "Not set",
                                  textAlign: TextAlign.right,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Role:",
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600, fontSize: 16)),
                              Text(adminData['role'] ?? "Administrator"),
                            ],
                          ),
                          const SizedBox(height: 28),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _navigateToEdit,
                              icon: const Icon(Icons.edit),
                              label: const Text("Edit Profile"),
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 3,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 15),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Divider for posts
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    "Admin Posts",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color.fromARGB(137, 0, 0, 0)),
                  ),
                ),

                // Admin posts (real-time, locally sorted)
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection("posts")
                      .where("createdBy", isEqualTo: _username)
                      .snapshots(),
                  builder: (context, postSnap) {
                    if (postSnap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!postSnap.hasData || postSnap.data!.docs.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text("No posts yet."),
                      );
                    }

                    final posts = postSnap.data!.docs.toList()
                      ..sort((a, b) {
                        final aTime =
                            (a['createdAt'] as Timestamp?)?.toDate() ??
                                DateTime(0);
                        final bTime =
                            (b['createdAt'] as Timestamp?)?.toDate() ??
                                DateTime(0);
                        return bTime.compareTo(aTime);
                      });

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: posts.length,
                      itemBuilder: (context, index) {
                        final doc = posts[index];
                        return PostCard(
  key: ValueKey(doc.id),
  postId: doc.id,
  username: doc["createdBy"], // ✅ always username
  caption: doc["caption"] ?? "",
  imageUrls: List<String>.from(doc["images"] ?? []),
  tags: (() {
    final rawTags = doc["tags"];
    if (rawTags == null) return <String>[];
    if (rawTags is List) return rawTags.map((e) => e.toString()).toList();
    if (rawTags is String && rawTags.trim().isNotEmpty) {
      return rawTags.split(",").map((t) => t.trim()).toList();
    }
    return <String>[];
  })(),
  createdAt: doc["createdAt"] ?? Timestamp.now(),
  updatedAt: doc["updatedAt"],
  likesCount: doc["likesCount"] ?? 0,
  currentUser: _username, // logged-in username
  postOwnerUsername: doc["createdBy"], // ✅ same
);

                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
