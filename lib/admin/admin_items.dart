import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/feed.dart';
import '../widgets/admin_bottom_nav.dart';
import '../widgets/admin_appbar.dart';

class AdminItems extends StatefulWidget {
  final String username;

  const AdminItems({super.key, required this.username});

  @override
  State<AdminItems> createState() => _AdminItemsState();
}


class _AdminItemsState extends State<AdminItems> {
  String selectedType = "lost item"; // default tab
  final TextEditingController _tagCtrl = TextEditingController();
  String _tagQuery = "";

  int lostCount = 0;
  int foundCount = 0;

  bool _isTagSearch() => _tagQuery.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _loadPostCounts();
  }

  Future<void> _loadPostCounts() async {
    final lostSnapshot = await FirebaseFirestore.instance
        .collection("posts")
        .where("typeKey", isEqualTo: "lost item")
        .get();
    final foundSnapshot = await FirebaseFirestore.instance
        .collection("posts")
        .where("typeKey", isEqualTo: "found item")
        .get();

    setState(() {
      lostCount = lostSnapshot.docs.length;
      foundCount = foundSnapshot.docs.length;
    });
  }

  Widget _buildTypeButton(String label, String typeKey, int count) {
    final isSelected = selectedType == typeKey;
    return ElevatedButton(
      onPressed: () {
        setState(() {
          selectedType = typeKey;
          _tagQuery = "";
          _tagCtrl.clear();
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.cyan : Colors.white,
        foregroundColor: isSelected ? Colors.white : Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      child: Text("$label ($count)"),
    );
  }

  Future<void> _refresh() async {
    await _loadPostCounts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE0F7FA),
      appBar: const AdminAppBar(),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: Column(
          children: [
            // Tabs with post counts
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildTypeButton("Lost Items", "lost item", lostCount),
                  const SizedBox(width: 12),
                  _buildTypeButton("Found Items", "found item", foundCount),
                ],
              ),
            ),

            // Tag search
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _tagCtrl,
                decoration: InputDecoration(
                  hintText: "Filter by tag (e.g. #wallet)",
                  prefixIcon: const Icon(Icons.tag),
                  suffixIcon: _tagQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _tagQuery = "";
                              _tagCtrl.clear();
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                   _tagQuery = value.trim().toLowerCase();
                  });
                },
              ),
            ),

            // Posts feed
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection("posts")
                    .orderBy("createdAt", descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        "No posts found.",
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  //  Local filtering
                  final filteredPosts = snapshot.data!.docs.where((doc) {
                    final data = doc.data();

                    final typeMatches = data["typeKey"] == selectedType;

                   bool tagMatches = true;
if (_isTagSearch()) {
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

  tagMatches = tags.any(
    (tag) => tag.contains(_tagQuery.replaceFirst("#", "")),
  );
}

                    return typeMatches && tagMatches;
                  }).toList();

                  if (filteredPosts.isEmpty) {
                    return const Center(
                      child: Text(
                        "No posts match your filter.",
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: filteredPosts.length,
                    itemBuilder: (context, index) {
                      final doc = filteredPosts[index];
                      final data = doc.data();

                      return PostCard(
                        key: ValueKey(doc.id),
                        postId: doc.id,
                        username: data["createdBy"] ?? "",
                        caption: data["caption"] ?? "",
                        imageUrls: List<String>.from(data["images"] ?? []),
                        tags: (() {
                          final rawTags = data["tags"];
                          if (rawTags == null) return <String>[];
                          if (rawTags is List) {
                            return rawTags.map((e) => e.toString()).toList();
                          }
                          if (rawTags is String &&
                              rawTags.trim().isNotEmpty) {
                            return rawTags
                                .split(",")
                                .map((t) => t.trim())
                                .toList();
                          }
                          return <String>[];
                        })(),
                        createdAt: data["createdAt"] ?? Timestamp.now(),
                        updatedAt: data["updatedAt"],
                        likesCount: data["likesCount"] ?? 0,
                        currentUser: widget.username,
                        postOwnerUsername: data["createdBy"] ?? "",
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AdminBottomNav(
        currentIndex: 3,
      ),
    );
  }
}
