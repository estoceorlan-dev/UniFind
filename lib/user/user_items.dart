import '../widgets/campus_scaffold.dart';
import '../widgets/loading_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/feed.dart';
import '../widgets/user_bottom_nav.dart';
import '../widgets/user_appbar.dart';

class UserItems extends StatefulWidget {
  final String username;

  const UserItems({Key? key, required this.username}) : super(key: key);

  @override
  State<UserItems> createState() => _UserItemsState();
}

class _UserItemsState extends State<UserItems> {
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

    if (!mounted) return;
    setState(() {
      lostCount = lostSnapshot.docs.length;
      foundCount = foundSnapshot.docs.length;
    });
  }

  Future<void> _refresh() async {
    await _loadPostCounts();
  }

  @override
  Widget build(BuildContext context) {
    return CampusScaffold(
      appBar: UserAppBar(
        username: widget.username,
        userStream: FirebaseFirestore.instance
            .collection("users")
            .doc(widget.username)
            .snapshots(),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: Column(
          children: [
            // Tabs with counts
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: SegmentedButton<String>(
                segments: [
                  ButtonSegment(
                    value: 'lost item',
                    label: Text('Lost ($lostCount)'),
                    icon: const Icon(Icons.search),
                  ),
                  ButtonSegment(
                    value: 'found item',
                    label: Text('Found ($foundCount)'),
                    icon: const Icon(Icons.inventory_2_outlined),
                  ),
                ],
                selected: {selectedType},
                showSelectedIcon: false,
                onSelectionChanged: (selection) => setState(() {
                  selectedType = selection.single;
                  _tagQuery = '';
                  _tagCtrl.clear();
                }),
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
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text(
                        "Could not load items. Please try again later.",
                      ),
                    );
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const LoadingSkeleton(posts: true);
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("No posts found."));
                  }

                  // ✅ Filter locally
                  final posts = snapshot.data!.docs.where((doc) {
                    final data = doc.data();
                    final typeMatches = data["typeKey"] == selectedType;

                    bool tagMatches = true;
                    if (_isTagSearch()) {
                      final rawTags = data["tags"];

                      final tags = rawTags is List
                          ? rawTags
                                .map((e) => e.toString().toLowerCase())
                                .toList()
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

                  if (posts.isEmpty) {
                    return const Center(
                      child: Text("No posts match your filter."),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      final doc = posts[index];
                      final data = doc.data();

                      return PostCard(
                        key: ValueKey(doc.id),
                        postId: doc.id,
                        username: data["createdBy"] ?? "Unknown",
                        caption: data["caption"] ?? "",
                        imageUrls: List<String>.from(data["images"] ?? []),
                        tags: (() {
                          final rawTags = data["tags"];
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
      navigation: UserBottomNav(currentIndex: 3, username: widget.username),
    );
  }
}
