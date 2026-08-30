import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/comment_screen.dart';
import '../screens/user_profile_2.dart';
import '../widgets/feed_menu.dart';
import '../widgets/full_screen.dart';
import '../services/notification_generator.dart';

class Feed extends StatefulWidget {
  final String currentUser;
  final String? scrollToPostId;

  const Feed({Key? key, required this.currentUser, this.scrollToPostId})
      : super(key: key);

  @override
  FeedState createState() => FeedState();
}

class FeedState extends State<Feed> {
  final ScrollController _scrollController = ScrollController();
  int _limit = 10;

  

  Future <void> reloadPosts() async {
    setState(() {
      _limit = 10; 
    });
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 100) {
        setState(() {
          _limit += 5;
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  
// Build the feed with posts from Firestore
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final thirtyDaysAgo = Timestamp.fromDate(now.subtract(const Duration(days: 30)));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("posts")
          .where("createdAt", isGreaterThanOrEqualTo: thirtyDaysAgo) // only last 30 days
          .orderBy("createdAt", descending: true)
          .limit(_limit)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final posts = snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data["id"] = doc.id;
          return data;
        }).toList();

        final announcements = posts.where((p) {
          return p["isAnnouncement"] == true &&
              p["expiresAt"] != null &&
              (p["expiresAt"] as Timestamp).toDate().isAfter(now);
        }).toList();

        final trending = posts.where((p) {
          if ((p["likesCount"] ?? 0) > 0 && p["createdAt"] != null) {
            final created = (p["createdAt"] as Timestamp).toDate();
            return now.difference(created).inDays <= 7;
          }
          return false;
        }).toList()
          ..sort((a, b) =>
              (b["likesCount"] ?? 0).compareTo(a["likesCount"] ?? 0));

        final regular = posts.where((p) => !announcements.contains(p)).toList();

        final orderedPosts = [
          ...announcements,
          ...regular,
          ...trending.where((p) => !regular.contains(p)),
        ];

        if (orderedPosts.isEmpty) {
          return const Center(child: Text("No recent posts for this month"));
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (widget.scrollToPostId != null) {
            final index = orderedPosts
                .indexWhere((p) => p["id"] == widget.scrollToPostId);
            if (index >= 0 && _scrollController.hasClients) {
              _scrollController.animateTo(
                index * 350.0,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
              );
            }
          }
        });
        // Each post is represented by a PostCard widget, data is passed as props
        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.only(bottom: 120),
          itemCount: orderedPosts.length,
          itemBuilder: (context, index) {
            final post = orderedPosts[index];
            return PostCard(
              key: ValueKey(post["id"]),
              postId: post["id"],
              username: post["createdBy"] ?? "Unknown", // createdBy is username
              caption: post["caption"] ?? "",
              imageUrls: List<String>.from(post["images"] ?? []),
              tags: (() {
                final rawTags = post["tags"];
                if (rawTags == null) return <String>[];

                if (rawTags is List) {
                return rawTags.map((e) => e.toString()).toList();
                } else if (rawTags is String && rawTags.trim().isNotEmpty) {
                return rawTags.split(",").map((t) => t.trim()).toList();
                } else {
                return <String>[];
                }
              })(),
              createdAt: post["createdAt"] ?? Timestamp.now(),
              updatedAt: post["updatedAt"],
              likesCount: post["likesCount"] ?? 0,
              currentUser: widget.currentUser, // username
              postOwnerUsername: post["postOwnerUsername"] ?? post["createdBy"],
            );
          },
        );
      },
    );
  }
}

// Individual post card widget
class PostCard extends StatefulWidget {
  final String postId;
  final String username; // creator username
  final String caption;
  final List<String> imageUrls;
  final List<String> tags;
  final Timestamp createdAt;
  final Timestamp? updatedAt;
  final int likesCount;
  final String currentUser; // username
  final String postOwnerUsername;

  const PostCard({
    Key? key,
    required this.postId,
    required this.username,
    required this.caption,
    required this.imageUrls,
    required this.tags,
    required this.createdAt,
    this.updatedAt,
    required this.likesCount,
    required this.currentUser,
    required this.postOwnerUsername,
  }) : super(key: key);

  @override
  State<PostCard> createState() => _PostCardState();
}

// State for individual post card, handling likes and UI
class _PostCardState extends State<PostCard> {
  bool _isLiked = false;
  int _likesCount = 0;
  bool _isExpanded = false;
  final int _captionLimit = 150;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _likesCount = widget.likesCount;
    _checkIfLiked();
  }
   Widget _buildCaption() {
      final fullText = widget.caption;
      final isLong = fullText.length > _captionLimit;

      final displayText = _isExpanded
        ? fullText
        : (isLong ? fullText.substring(0, _captionLimit) + "..." : fullText);

      return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            displayText,
            style: const TextStyle(fontSize: 15, height: 1.4, color: Color.fromARGB(221, 0, 0, 0)),
          ),

          if (isLong)
            GestureDetector(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _isExpanded ? "See less" : "See more",
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    ),
  );
  }

  Future<void> _checkIfLiked() async {
    final doc = await FirebaseFirestore.instance
        .collection("posts")
        .doc(widget.postId)
        .get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      final likes = List<String>.from(data["likes"] ?? []);
      setState(() {
        _isLiked = likes.contains(widget.currentUser); // username check
      });
    }
  }

  Future<void> _toggleLike() async {
    final ref = FirebaseFirestore.instance.collection("posts").doc(widget.postId);
    final doc = await ref.get();
    if (!doc.exists) return;

    final data = doc.data() as Map<String, dynamic>;
    final likes = List<String>.from(data["likes"] ?? []);

    if (_isLiked) {
      likes.remove(widget.currentUser);
    } else {
      likes.add(widget.currentUser);

      // Notify only when liking
      if (widget.postOwnerUsername != widget.currentUser) {
        await NotificationGenerator.likePost(
          widget.postOwnerUsername, // target username
          widget.currentUser,
          widget.postId,       
        );
      }
    }

    await ref.update({
      "likes": likes,
      "likesCount": likes.length,
    });

    setState(() {
      _isLiked = !_isLiked;
      _likesCount = likes.length;
    });
  }
   
   // Format timestamp to "time ago"
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inSeconds < 60) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    if (diff.inDays < 7) return "${diff.inDays}d ago";
    return "${time.month}/${time.day}/${time.year}";
  }

  // post card UI
  @override
  Widget build(BuildContext context) {
    final created = widget.createdAt.toDate();
    final updated = widget.updatedAt?.toDate() ?? created;
    final now = DateTime.now();

    final isNew = now.difference(created).inMinutes <= 10;
    final isUpdated =
        updated.isAfter(created) && now.difference(updated).inMinutes <= 10;

    // Post card layout
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Header (lookup by username)
          FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection("users")
                .doc(widget.username)
                .get(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const ListTile(
                  leading: CircleAvatar(
                    backgroundImage: AssetImage("assets/images/defaultpfp.jpg"),
                  ),
                  title: Text("Unknown User"),
                );
              }

              final data = snapshot.data!.data() as Map<String, dynamic>;
              final profilePic = data["profilePic"] as String?;
              final firstName = data["firstName"] ?? "";
              final lastName = data["lastName"] ?? "";

              return ListTile(
                leading: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UserProfile2(username: widget.username),
                      ),
                    );
                  },
                  child: CircleAvatar(
                    backgroundImage: profilePic != null && profilePic.isNotEmpty
                        ? NetworkImage(profilePic)
                        : const AssetImage("assets/images/defaultpfp.jpg")
                            as ImageProvider,
                  ),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: 
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UserProfile2(username: widget.username),
                      ),
                    );
                  },
                  child:
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("$firstName $lastName",
                              style: const TextStyle(
                                  fontFamily: 'poppins',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                          Text(
                            "@${widget.username}",
                            style: const TextStyle(
                                fontSize: 14, color: Colors.black54),
                          ),
                        ],
                      ),
                      ),
                    ),
                    if (isNew)
                      _buildStatusTag("NEW", Colors.green)
                    else if (isUpdated)
                      _buildStatusTag("UPDATED", Colors.orange),
                  ],
                ),
                subtitle: Text(
                  '${_formatTime(created)} · '
                  "${created.hour}:${created.minute.toString().padLeft(2, '0')}",
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                onLongPress: widget.currentUser == "admin"
                              ? () {
                                showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                title: const Text("Delete Post"),
                                content: const Text("Are you sure you want to remove this post?"),
                                actions: [
                                  TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text("Cancel"),
                                  ),
                                  TextButton(
                                  onPressed: () async {
                                    await FirebaseFirestore.instance
                                      .collection("posts")
                                      .doc(widget.postId)
                                      .delete();
                                    if (context.mounted) Navigator.pop(context);
                                  },
                                  child: const Text("Delete", style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                                ),
                                );
                              }
                              : null,
                trailing: FeedMenu(
                  currentUser: widget.currentUser, // username
                  postOwner: widget.postOwnerUsername, // username
                  postId: widget.postId,
                  caption: widget.caption,
                  tags: widget.tags,
                  postImages: widget.imageUrls,
                ),
              );
            },
          ),

          /// Caption
          if (widget.caption.isNotEmpty) _buildCaption(),

          /// Tags
          if (widget.tags.isNotEmpty) 
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Wrap(
                spacing: 8,
                children: widget.tags
                    .map((t) => Text(
                          "$t",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color.fromARGB(255, 0, 0, 0),
                          ),
                        ))
                    .toList(),
              ),
            ),

          /// Images
  if (widget.imageUrls.isNotEmpty)
  SizedBox(
    height: 280,
    child: Stack(
      alignment: Alignment.bottomCenter,
      children: [
        PageView.builder(
          itemCount: widget.imageUrls.length,
          controller: PageController(),
          onPageChanged: (index) {
            setState(() {
              _currentImageIndex = index; 
            });
          },
          itemBuilder: (_, index) => GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FullScreenImageViewer(
                    images: widget.imageUrls,
                    initialIndex: index,
                  ),
                ),
              );
            },
            child: ClipRRect(
  borderRadius: BorderRadius.circular(8),
  child: Image.network(
    widget.imageUrls[index],
    fit: BoxFit.cover,
    width: double.infinity,

    // Shows grey box + loader until image loads
    loadingBuilder: (context, child, loadingProgress) {
      if (loadingProgress == null) return child;
      return Container(
        color: Colors.grey[300],
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    },

    // Shows grey box with broken-icon if internet is gone
    errorBuilder: (context, error, stackTrace) {
      return Container(
        color: Colors.grey[400],
        child: const Center(
          child: Icon(
            Icons.broken_image,
            size: 40,
            color: Colors.white70,
          ),
        ),
      );
    },
  ),
),
          ),
        ),

        // Dot indicator
        if (widget.imageUrls.length > 1)
          Positioned(
            bottom: 8,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(widget.imageUrls.length, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentImageIndex == index
                        ? Colors.white
                        : Colors.white54,
                  ),
                );
              }),
            ),
          ),
      ],
    ),
  ),
          const SizedBox(height: 8),

          /// Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    _isLiked ? Icons.favorite : Icons.favorite_border,
                    color: _isLiked ? Colors.red : null,
                  ),
                  onPressed: _toggleLike,
                ),
                
               StreamBuilder<QuerySnapshot>(
  stream: FirebaseFirestore.instance
      .collection('posts')
      .doc(widget.postId)
      .collection('comments')
      .snapshots(),
  builder: (context, snapshot) {
    final commentCount = snapshot.hasData ? snapshot.data!.docs.length : 0;

    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.chat_bubble_outline),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CommentScreen(
                  postId: widget.postId,
                  currentUser: widget.currentUser,
                ),
              ),
            );
          },
        ),
        Text(
          "$commentCount",
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ],
    );
  },
),
                const Spacer(),
                Text("$_likesCount likes",
                    style: const TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text,
          style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
    );
  }

}
