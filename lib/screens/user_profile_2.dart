import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'convo_page.dart';
import '../widgets/feed.dart';
import '../admin/admin_newsfeed.dart';
import '../user/user_newsfeed.dart';
import '../services/notification_generator.dart';

class UserProfile2 extends StatefulWidget {
  final String username;

  const UserProfile2({super.key, required this.username});

  @override
  State<UserProfile2> createState() => _UserProfile2State();
}

class _UserProfile2State extends State<UserProfile2> {
  late String _username;
  String? _currentUsername;

  @override
  void initState() {
    super.initState();
    _username = widget.username;
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUsername = prefs.getString('username'); // ✅ use username only
    });
  }

  Future<Map<String, dynamic>?> _getUserData() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(_username)
        .get();
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
              child: Image(
                image: imageProvider,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _reportUser(String reason) async {
    await FirebaseFirestore.instance.collection("reports").add({
      "reportedUser": _username,
      "reportedBy": _currentUsername,
      "reason": reason,
      "reportedAt": Timestamp.now(),
    });
    NotificationGenerator.reportUser(reportedUser: _username, reason: reason);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("User reported successfully")),
    );
  }

  void _showReportDialog() {
    String selectedReason = 'Harassment';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Report User"),
        content: StatefulBuilder(
          builder: (context, setStateDialog) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Select a reason for reporting:"),
              const SizedBox(height: 10),
              DropdownButton<String>(
                value: selectedReason,
                isExpanded: true,
                items: [
                  'Harassment',
                  'Bullying',
                  'Hate Speech',
                  'Spamming',
                  'Spreading Misinformation',
                  'Others'
                ].map((reason) {
                  return DropdownMenuItem(
                    value: reason,
                    child: Text(reason),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) setStateDialog(() => selectedReason = value);
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              _reportUser(selectedReason);
              Navigator.pop(context);
            },
            child: const Text("Report"),
          ),
        ],
      ),
    );
  }

  Future<void> _removeUser() async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Confirm Removal"),
      content: Text(
        "Are you sure you want to remove user $_username? "
        "This action cannot be undone.",
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text(
            "Remove",
            style: TextStyle(color: Colors.red),
          ),
        ),
      ],
    ),
  );

  if (confirm != true) return;

  try {
    // Remove user document
    await FirebaseFirestore.instance.collection("users").doc(_username).delete();

    // Optionally remove posts made by the user
    final posts = await FirebaseFirestore.instance
        .collection("posts")
        .where("createdBy", isEqualTo: _username)
        .get();
    for (final doc in posts.docs) {
      await doc.reference.delete();
    }

    // Optionally remove reports related to the user
    final reports = await FirebaseFirestore.instance
        .collection("reports")
        .where("reportedUser", isEqualTo: _username)
        .get();
    for (final doc in reports.docs) {
      await doc.reference.delete();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("User $_username has been removed.")),
    );

    // Navigate back after removal
    Navigator.pop(context);
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Failed to remove user: $e")),
    );
  }
  }

  @override
  Widget build(BuildContext context) {
    final isOwnProfile = _currentUsername == _username;
    final isAdmin = _username == "admin"; 

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 120, 120, 120),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: FutureBuilder<Map<String, dynamic>?>(
          future: _getUserData(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data == null) {
              return const Text("Profile");
            }
            final userData = snapshot.data!;
            return Text("${userData['firstName'] ?? 'User'}'s Profile");
          },
        ),
        actions: [
          GestureDetector(
            onTap: () {
              if (widget.username.toLowerCase() == "admin") {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => AdminNewsFeed(),
                  ),
                );
              } else {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => UserNewsfeed(username: widget.username),
                  ),
                );
              }
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: CircleAvatar(
                backgroundImage: const AssetImage("assets/images/logo2.jpg"),
                radius: 18,
              ),
            ),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _getUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("No user data found."));
          }

          final userData = snapshot.data!;
          final profilePic = userData['profilePic']?.isNotEmpty == true
              ? NetworkImage(userData['profilePic'])
              : const AssetImage("assets/images/defaultpfp.jpg")
                  as ImageProvider;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              children: [
                // Profile Card
                Card(
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
                            if (userData['isVerified'] == true)
                              Positioned(
                                right: 6,
                                top: 6,
                                child: CircleAvatar(
                                  radius: 16,
                                  backgroundColor: Colors.white,
                                  child: const Icon(Icons.check_circle,
                                      color: Colors.green, size: 30),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          userData['course'] ?? "No course",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "@${userData['username']}",
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "${userData['firstName']} ${userData['lastName']}",
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Gender
                        if (userData['gender'] != null)
                          Text(
                            "Gender: ${userData['gender']}",
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color.fromARGB(255, 0, 0, 0),
                            ),
                          ),

                          if (_currentUsername == "admin" && userData['schoolId'] != null)
                            Text(
                              "School ID: ${userData['schoolId']}",
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color.fromARGB(255, 0, 0, 0),
                              ),
                            ),
                            
                        const Divider(height: 35, thickness: 1.3),

                        // Message & Report buttons
                        if (!isOwnProfile) ...[
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                if (_currentUsername == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Error: User not logged in."),
                                    ),
                                  );
                                  return;
                                }

                                try {
                                  final otherUsername = userData['username'];
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ConvoPage(
                                        currentUsername: _currentUsername!,
                                        otherUsername: otherUsername,
                                      ),
                                    ),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("Error: $e")),
                                  );
                                }
                              },
                              icon: const Icon(Icons.message),
                              label: const Text("Message"),
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
                          const SizedBox(height: 4),
                          
                          if (_currentUsername == "admin")
    SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _removeUser,
        icon: const Icon(Icons.delete),
        label: const Text("Remove User"),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 220, 220, 220),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 3,
          padding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    )
  else if (!isAdmin)
    SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _showReportDialog,
        icon: const Icon(Icons.flag),
        label: const Text("Report"),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 37, 29, 29),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 3,
          padding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    ),
    
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  "Posts by ${userData['firstName'] ?? 'User'}",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 0, 0, 0),
                  ),
                ),

                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection("posts")
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

                    final userPosts = postSnap.data!.docs
                        .where((doc) => doc["createdBy"] == _username)
                        .toList();

                    userPosts.sort((a, b) {
                      final aTime = (a["createdAt"] as Timestamp?)?.toDate() ??
                          DateTime.now();
                      final bTime = (b["createdAt"] as Timestamp?)?.toDate() ??
                          DateTime.now();
                      return bTime.compareTo(aTime);
                    });

                    if (userPosts.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text("No posts yet."),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: userPosts.length,
                      itemBuilder: (context, index) {
                        final doc = userPosts[index];
                        return PostCard(
                          key: ValueKey(doc.id),
                          postId: doc.id,
                          username: doc["createdBy"],
                          caption: doc["caption"] ?? "",
                          imageUrls: List<String>.from(doc["images"] ?? []),
                          tags: (() {
                            final rawTags = doc["tags"];
                            if (rawTags == null) return <String>[];
                            if (rawTags is List) {
                              return rawTags.map((e) => e.toString()).toList();
                            }
                            if (rawTags is String && rawTags.trim().isNotEmpty) {
                              return rawTags
                                  .split(",")
                                  .map((t) => t.trim())
                                  .toList();
                            }
                            return <String>[];
                          })(),
                          createdAt: doc["createdAt"] ?? Timestamp.now(),
                          updatedAt: doc["updatedAt"],
                          likesCount: doc["likesCount"] ?? 0,
                          currentUser: _currentUsername ?? '',
                          postOwnerUsername: doc["createdBy"],
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
