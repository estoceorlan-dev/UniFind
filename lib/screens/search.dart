import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'user_profile_2.dart';
import '../widgets/feed.dart';
import '../admin/admin_newsfeed.dart';
import '../user/user_newsfeed.dart';

class Search extends StatefulWidget {
  final String username;

  const Search({Key? key, required this.username}) : super(key: key);

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = "";
  bool _showMoreUsers = false; 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _searchCtrl,
            decoration: const InputDecoration(
              hintText: "Search users or #tags...",
              border: InputBorder.none,
              icon: Icon(Icons.search, color: Colors.grey),
            ),
            onChanged: (value) {
              setState(() {
                _query = value.trim().toLowerCase();
              });
            },
          ),
        ),
        actions: [
          GestureDetector(
            onTap: () {
              if (widget.username.toLowerCase() == "admin") {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => AdminNewsFeed()),
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

      body: _query.isEmpty
          ? const Center(
              child: Text(
                "Start typing to search users or posts by #tags...",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection("users").snapshots(),
              builder: (context, userSnap) {
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection("posts")
                      .orderBy("createdAt", descending: true)
                      .snapshots(),
                  builder: (context, postSnap) {
                    if (!userSnap.hasData || !postSnap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    // ----- USERS -----
                    final allUsers = userSnap.data!.docs;
                    final users = allUsers.where((doc) {
                      final data = doc.data() as Map<String, dynamic>? ?? {};
                      final username = (data["username"] ?? "").toString().toLowerCase();
                      final firstName = (data["firstName"] ?? "").toString().toLowerCase();
                      final lastName = (data["lastName"] ?? "").toString().toLowerCase();
                      return username.contains(_query) ||
                          firstName.contains(_query) ||
                          lastName.contains(_query);
                    }).toList();

                    // ----- POSTS -----
                    final allPosts = postSnap.data!.docs;
                    final posts = allPosts.where((doc) {
                      final data = doc.data() as Map<String, dynamic>? ?? {};
                      final rawTags = data["tags"];

                      final tags = rawTags is List
                          ? rawTags.map((e) => e.toString().toLowerCase()).toList()
                          : rawTags is String
                              ? rawTags
                                  .toLowerCase()
                                  .split(",")
                                  .map((t) => t.trim())
                                  .toList()
                              : <String>[];

                      return tags.any((tag) =>
                          tag.contains(_query.replaceFirst("#", "")));
                    }).toList();

                    // ----- EMPTY -----
                    if (users.isEmpty && posts.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: 50),
                          child: Text(
                            "No users or posts match your search...",
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ),
                      );
                    }

                    // ----- RESULTS -----
                    final displayUsers =
                        _showMoreUsers ? users : users.take(5).toList();

                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ---- USER RESULTS ----
                          if (users.isNotEmpty) ...[
                            const Padding(
                              padding:
                                  EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Text(
                                "Users",
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: displayUsers.length,
                              separatorBuilder: (_, __) => Divider(
                                height: 1,
                                color: Colors.grey.shade300,
                                indent: 16,
                                endIndent: 16,
                              ),
                              itemBuilder: (context, index) {
                                final data = displayUsers[index].data()
                                        as Map<String, dynamic>? ??
                                    {};
                                final username = data["username"] ?? "Unknown";
                                final fullName =
                                    "${data["firstName"] ?? ""} ${data["lastName"] ?? ""}"
                                        .trim();
                                final profilePic = data["profilePic"] ?? "";

                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundImage: profilePic.isNotEmpty
                                        ? NetworkImage(profilePic)
                                        : const AssetImage(
                                                "assets/images/defaultpfp.jpg")
                                            as ImageProvider,
                                  ),
                                  title: Text(fullName.isNotEmpty
                                      ? fullName
                                      : "No name"),
                                  subtitle: Text(username),
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            UserProfile2(username: username),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),

                            if (users.length > 5)
                              Center(
                                child: TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _showMoreUsers = !_showMoreUsers;
                                    });
                                  },
                                  child: Text(
                                      _showMoreUsers ? "See less" : "See more"),
                                ),
                              ),
                          ],

                          // ---- POST RESULTS ----
                          if (posts.isNotEmpty) ...[
                            const Padding(
                              padding:
                                  EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Text(
                                "Posts",
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: posts.length,
                              itemBuilder: (context, index) {
                                final doc = posts[index];
                                final data =
                                    doc.data() as Map<String, dynamic>? ?? {};

                                return PostCard(
                                  key: ValueKey(doc.id),
                                  postId: doc.id,
                                  username: data["createdBy"] ?? "",
                                  caption: data["caption"] ?? "",
                                  imageUrls:
                                      List<String>.from(data["images"] ?? []),
                                  tags: (() {
                                    final raw = data["tags"];
                                    if (raw == null) return <String>[];
                                    if (raw is List) {
                                      return raw.map((e) => e.toString()).toList();
                                    }
                                    if (raw is String && raw.trim().isNotEmpty) {
                                      return raw
                                          .split(",")
                                          .map((t) => t.trim())
                                          .toList();
                                    }
                                    return <String>[];
                                  })(),
                                  createdAt:
                                      data["createdAt"] ?? Timestamp.now(),
                                  updatedAt: data["updatedAt"],
                                  likesCount: data["likesCount"] ?? 0,
                                  currentUser: widget.username,
                                  postOwnerUsername:
                                      data["createdBy"] ?? "",
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
