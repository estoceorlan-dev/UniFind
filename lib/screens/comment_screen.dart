import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'user_profile_2.dart';
import '../services/notification_generator.dart';


class CommentScreen extends StatefulWidget {
  final String postId;
  final String currentUser;
  final String? scrollToCommentId;

  const CommentScreen({
    Key? key,
    required this.postId,
    required this.currentUser,
    this.scrollToCommentId,
  }) : super(key: key);

  @override
  State<CommentScreen> createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Map<String, bool> _repliesExpanded = {};
  final Map<String, GlobalKey> _commentKeys = {};

  String? _replyToCommentId;
  @override
  void initState() {
    super.initState();
    if (widget.scrollToCommentId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await Future.delayed(const Duration(milliseconds: 500));
        _scrollToComment(widget.scrollToCommentId!);
      });
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inSeconds < 60) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    if (diff.inDays < 7) return "${diff.inDays}d ago";
    return "${time.month}/${time.day}/${time.year}";
  }

  Future<void> _scrollToComment(String commentId) async {
    final tileKey = _commentKeys[commentId];
    if (tileKey == null) return;

    await Future.delayed(const Duration(milliseconds: 500));

    final context = tileKey.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.2,
      );
    }
  }

  Future<void> _addComment({String? parentCommentId}) async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final newCommentRef = FirebaseFirestore.instance
        .collection("posts")
        .doc(widget.postId)
        .collection("comments")
        .doc();

    await newCommentRef.set({
      "text": text,
      "createdBy": widget.currentUser,
      "createdAt": FieldValue.serverTimestamp(),
      "likes": [],
      "parentCommentId": parentCommentId,
    });

    _commentController.clear();

    if (parentCommentId != null) {
      setState(() {
        _repliesExpanded[parentCommentId] = true;
      });
      final parentDoc = await FirebaseFirestore.instance
          .collection("posts")
          .doc(widget.postId)
          .collection("comments")
          .doc(parentCommentId)
          .get(); 
      if (parentDoc.exists) {
        final parentOwnerId = parentDoc["createdBy"];
        if (parentOwnerId != widget.currentUser) {
          await NotificationGenerator.replyComment(parentOwnerId, widget.currentUser, widget.postId, parentCommentId);
        }
      }
    } else {
      final postDoc = await FirebaseFirestore.instance
          .collection("posts")
          .doc(widget.postId)
          .get();
      final postOwnerId = postDoc["createdBy"];
      if (postOwnerId != widget.currentUser) {
        await NotificationGenerator.commentPost(postOwnerId, widget.currentUser, widget.postId);
      }
    }
  }

  Future<void> _toggleLike(String commentId, List likes, String ownerId) async {
    final commentRef = FirebaseFirestore.instance
        .collection("posts")
        .doc(widget.postId)
        .collection("comments")
        .doc(commentId);

    if (likes.contains(widget.currentUser)) {
      await commentRef.update({
        "likes": FieldValue.arrayRemove([widget.currentUser]),
      });
    } else {
      await commentRef.update({
        "likes": FieldValue.arrayUnion([widget.currentUser]),
      });

      if (ownerId != widget.currentUser) {
        await NotificationGenerator.likeComment(ownerId, widget.currentUser, widget.postId, commentId);
      }
    }
  }

  Future<void> deleteComment(String commentId) async {
    final commentRef = FirebaseFirestore.instance
        .collection("posts")
        .doc(widget.postId)
        .collection("comments")
        .doc(commentId);

    await commentRef.delete();

    final repliesSnapshot = await FirebaseFirestore.instance
        .collection("posts")
        .doc(widget.postId)
        .collection("comments")
        .where("parentCommentId", isEqualTo: commentId)
        .get();

    for (var replyDoc in repliesSnapshot.docs) {
      await replyDoc.reference.delete();
    }
  }

  Future<void> showDeleteDialog(String commentId) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Comment"),
        content: const Text("Are you sure you want to delete this comment?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("No"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 255, 255, 255),
              foregroundColor: const Color.fromARGB(255, 143, 8, 8),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Yes"),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await deleteComment(commentId);
    }
  }

  Widget _buildCommentTile(
    String commentId,
    Map<String, dynamic> data,
    Map<String, List<QueryDocumentSnapshot>> repliesByParent, {
    int depth = 0,
  }) {
    final createdBy = data["createdBy"] ?? "user";
    final text = data["text"] ?? "";
    final createdAt = data["createdAt"] != null
        ? (data["createdAt"] as Timestamp).toDate()
        : DateTime.now();
    final likes = List<String>.from(data["likes"] ?? []);
    final isLiked = likes.contains(widget.currentUser);

    final tileKey = _commentKeys.putIfAbsent(commentId, () => GlobalKey());

    final replies = (repliesByParent[commentId] ?? [])
      ..sort((a, b) {
        final aTime = (a.data() as Map<String, dynamic>)["createdAt"] as Timestamp?;
        final bTime = (b.data() as Map<String, dynamic>)["createdAt"] as Timestamp?;
        return (aTime?.compareTo(bTime ?? Timestamp(0,0))) ?? 0;
      });

    final isExpanded = _repliesExpanded[commentId] ?? false;
    final indent = depth * 20.0;

    return FutureBuilder<List<DocumentSnapshot>>(
  future: Future.wait([
    FirebaseFirestore.instance.collection("users").doc(createdBy).get(), // comment owner
    FirebaseFirestore.instance.collection("users").doc(widget.currentUser).get(), // current user
  ]),
  builder: (context, snapshots) {
    if (!snapshots.hasData) return SizedBox();

    final userSnapshot = snapshots.data![0];
    final currentUserSnapshot = snapshots.data![1];

    String displayName = createdBy;
    String fullName = "";
    String profilePicUrl = "";
    

    if (userSnapshot.exists) {
      final userData = userSnapshot.data() as Map<String, dynamic>;
      fullName =
          "${userData["firstName"] ?? ""} ${userData["lastName"] ?? ""}".trim();
      displayName = userData["username"] ?? createdBy;
      profilePicUrl = userData["profilePic"] ?? "";
    }

    // CHECK IF CURRENT USER IS ADMIN
    bool isOwner = (widget.currentUser == createdBy);
    bool isAdmin = false;


    if (currentUserSnapshot.exists) {
      final meData = currentUserSnapshot.data() as Map<String, dynamic>;
      isAdmin = (meData["role"] == "admin");
    }

        return Container(
          key: tileKey,
          padding: EdgeInsets.only(left: indent, right: 8, top: 6, bottom: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => UserProfile2(username: createdBy),
                          ),
                        );
                      },
                      child: CircleAvatar(
                        radius: 20,
                        backgroundImage: profilePicUrl.isNotEmpty
                            ? NetworkImage(profilePicUrl)
                            : const AssetImage("assets/images/defaultpfp.jpg")
                                as ImageProvider,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => UserProfile2(username: createdBy),
                                ),
                              );
                            },
                            child: Text(
                              fullName.isNotEmpty
                                  ? "$fullName @$displayName"
                                  : "@$displayName",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            text,
                            style: const TextStyle(),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: Icon(
                                  isLiked ? Icons.favorite : Icons.favorite_border,
                                  color: isLiked ? Colors.red : Colors.grey,
                                  size: 20,
                                ),
                                onPressed: () =>
                                    _toggleLike(commentId, likes, createdBy),
                              ),
                              Text("${likes.length}"),
                              const SizedBox(width: 10),
                              IconButton(
                                icon: const Icon(Icons.reply, size: 20),
                                onPressed: () {
                                  setState(() {
                                     if (data["parentCommentId"] != null) {
                                       _replyToCommentId = data["parentCommentId"]; 
                                     } else { 
                                       _replyToCommentId = commentId;
                                     }
                                  });
                                  _commentController.text = "@$createdBy ";
                                },
                              ),
                              if (isOwner || isAdmin)
                                 IconButton(
                                 icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                 onPressed: () => showDeleteDialog(commentId),
                              ),
                            ],
                          ),
                          Text(
                            _formatTime(createdAt),
                            style: const TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (replies.isNotEmpty)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _repliesExpanded[commentId] = !isExpanded;
                    });
                  },
                  child: Text(
                    isExpanded ? "Hide replies" : "View replies (${replies.length})",
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              if (isExpanded)
                Column(
                  children: replies.map((replyDoc) {
                    final replyData = replyDoc.data() as Map<String, dynamic>;
                    return _buildCommentTile(
                      replyDoc.id,
                      replyData,
                      repliesByParent,
                      depth: 1,
                    );
                  }).toList(),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
       
    return Scaffold(
      appBar: AppBar(
        title: const Text("Comments"),

        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("posts")
                  .doc(widget.postId)
                  .collection("comments")
                  .orderBy("createdAt", descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(child: Text("No comments yet"), );
                }

                final repliesByParent = <String, List<QueryDocumentSnapshot>>{};
                final topLevelComments = <QueryDocumentSnapshot>[];

                for (var doc in docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final parentId = data["parentCommentId"];
                  if (parentId == null) {
                    topLevelComments.add(doc);
                  } else {
                    repliesByParent.putIfAbsent(parentId, () => []);
                    repliesByParent[parentId]!.add(doc);
                  }
                }

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: topLevelComments.length,
                  itemBuilder: (context, index) {
                    final doc = topLevelComments[index];
                    final data = doc.data() as Map<String, dynamic>;
                    return _buildCommentTile(doc.id, data, repliesByParent);
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance.collection("users").doc(widget.currentUser).get(),
                    builder: (context, snapshot) {
                      String profilePicUrl = "";
                      if (snapshot.hasData && snapshot.data!.exists) {
                        final userData = snapshot.data!.data() as Map<String, dynamic>;
                        profilePicUrl = userData["profilePic"] ?? "";
                      }
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: CircleAvatar(
                          radius: 22,
                          backgroundImage: profilePicUrl.isNotEmpty
                              ? NetworkImage(profilePicUrl)
                              : const AssetImage("assets/images/defaultpfp.jpg") as ImageProvider,
                        ),
                      );
                    },
                  ),
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: const InputDecoration(
                        hintText: "Write a comment...",
                        border: OutlineInputBorder(),
                        filled: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                   onPressed: () async {
                     await _addComment(parentCommentId: _replyToCommentId);
                     setState(() {
                     _replyToCommentId = null; 
                     });
                     },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 5, 15, 33),
                    ),
                    child: const Text("Send"),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
