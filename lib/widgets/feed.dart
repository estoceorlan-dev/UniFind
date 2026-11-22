import 'dart:async';
import '../repositories/feed_ranking.dart';
import 'loading_skeleton.dart';
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
  static const _pageSize = 20;
  int _limit = _pageSize;
  bool _moreAvailable = false;
  bool _loadingPage = false;
  Object? _error;
  List<Map<String, dynamic>>? _recent;
  List<Map<String, dynamic>> _announcements = [];
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _recentSub,
      _announcementSub;
  Timer? _clock;
  Completer<void>? _pending;
  String? _scrolledTo;

  @override
  void initState() {
    super.initState();
    _listenToAnnouncements();
    _loadRecent();
    _clock = Timer.periodic(const Duration(minutes: 1), (_) => setState(() {}));
  }

  Map<String, dynamic> _post(QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
      {...doc.data(), 'id': doc.id};

  void _listenToAnnouncements() {
    _announcementSub?.cancel();
    _announcementSub = FirebaseFirestore.instance
        .collection('posts')
        .where('expiresAt', isGreaterThan: Timestamp.now())
        .snapshots()
        .listen(
          (snapshot) {
            if (mounted)
              setState(
                () => _announcements = snapshot.docs.map(_post).toList(),
              );
          },
          onError: (Object error) {
            // Recent announcements are still included by the main query when offline.
            if (mounted) setState(() => _announcements = []);
          },
        );
  }

  Future<void> _loadRecent() {
    _recentSub?.cancel();
    final previous = _pending;
    if (previous != null && !previous.isCompleted) previous.complete();
    final ready = _pending = Completer<void>();
    setState(() {
      _loadingPage = true;
      _error = null;
    });
    _recentSub = FirebaseFirestore.instance
        .collection('posts')
        .where(
          'createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 30)),
          ),
        )
        .orderBy('createdAt', descending: true)
        .limit(_limit + 1)
        .snapshots()
        .listen(
          (snapshot) {
            if (!mounted || ready != _pending) return;
            setState(() {
              _moreAvailable = snapshot.docs.length > _limit;
              _recent = snapshot.docs.take(_limit).map(_post).toList();
              _loadingPage = false;
            });
            if (!ready.isCompleted) ready.complete();
          },
          onError: (Object error) {
            if (!mounted || ready != _pending) return;
            setState(() {
              _loadingPage = false;
              _error = error;
            });
            if (!ready.isCompleted) ready.complete();
          },
        );
    return ready.future;
  }

  Future<void> reloadPosts() {
    _limit = _pageSize;
    _listenToAnnouncements();
    return _loadRecent();
  }

  @override
  void dispose() {
    _clock?.cancel();
    _recentSub?.cancel();
    _announcementSub?.cancel();
    if (_pending?.isCompleted == false) _pending!.complete();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_recent == null && _error == null) {
      return const LoadingSkeleton(posts: true);
    }
    final orderedPosts = rankFeed([
      ..._announcements,
      ...?_recent,
    ], DateTime.now());
    final hasFooter = _moreAvailable || _error != null || orderedPosts.isEmpty;
    if (widget.scrollToPostId != null && widget.scrollToPostId != _scrolledTo)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            widget.scrollToPostId != null &&
            widget.scrollToPostId != _scrolledTo) {
          final index = orderedPosts.indexWhere(
            (p) => p["id"] == widget.scrollToPostId,
          );
          if (index >= 0 && _scrollController.hasClients) {
            _scrolledTo = widget.scrollToPostId;
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
      physics: const AlwaysScrollableScrollPhysics(),
      findChildIndexCallback: (key) {
        if (key is! ValueKey<String>) return null;
        final index = orderedPosts.indexWhere(
          (post) => post['id'] == key.value,
        );
        return index < 0 ? null : index;
      },
      itemCount: orderedPosts.length + (hasFooter ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == orderedPosts.length) {
          if (orderedPosts.isEmpty && !_moreAvailable && _error == null) {
            return const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text('No posts in the last 30 days.')),
            );
          }
          return Center(
            child: TextButton.icon(
              onPressed: _loadingPage
                  ? null
                  : () {
                      if (_error == null) _limit += _pageSize;
                      _loadRecent();
                    },
              icon: Icon(_error == null ? Icons.expand_more : Icons.refresh),
              label: Text(
                _loadingPage
                    ? 'Loading posts...'
                    : _error != null
                    ? 'Retry loading posts'
                    : 'Load more posts',
              ),
            ),
          );
        }
        final post = orderedPosts[index];
        return PostCard(
          key: ValueKey<String>(post["id"]),
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
          likesCount: (post["likesCount"] as num?)?.toInt() ?? 0,
          likedByCurrentUser:
              (post["likes"] as List?)?.contains(widget.currentUser) ?? false,
          currentUser: widget.currentUser, // username
          postOwnerUsername:
              post["postOwnerUsername"] ??
              post["postOwner"] ??
              post["createdBy"] ??
              "Unknown",
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
  final bool? likedByCurrentUser;
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
    this.likedByCurrentUser,
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
  bool _savingLike = false;
  late Future<DocumentSnapshot> _author;
  late Stream<QuerySnapshot> _comments;

  void _bindPost() {
    _author = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.username)
        .get();
    _comments = FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('comments')
        .snapshots();
    _likesCount = widget.likesCount;
    _isLiked = widget.likedByCurrentUser ?? false;
    if (widget.likedByCurrentUser == null) _checkIfLiked();
  }

  @override
  void didUpdateWidget(PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.postId != widget.postId ||
        oldWidget.username != widget.username ||
        oldWidget.currentUser != widget.currentUser) {
      _bindPost();
    } else {
      if (oldWidget.likesCount != widget.likesCount)
        _likesCount = widget.likesCount;
      if (widget.likedByCurrentUser != null)
        _isLiked = widget.likedByCurrentUser!;
    }
  }

  @override
  void initState() {
    super.initState();
    _bindPost();
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
          Text(displayText, style: const TextStyle(fontSize: 15, height: 1.4)),

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
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
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
    final id = widget.postId;
    final doc = await FirebaseFirestore.instance
        .collection("posts")
        .doc(widget.postId)
        .get();
    if (mounted && widget.postId == id && doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      final likes = List<String>.from(data["likes"] ?? []);
      setState(() {
        _isLiked = likes.contains(widget.currentUser); // username check
      });
    }
  }

  Future<void> _toggleLike() async {
    if (_savingLike) return;
    final postId = widget.postId,
        user = widget.currentUser,
        owner = widget.postOwnerUsername;
    final ref = FirebaseFirestore.instance.collection("posts").doc(postId);
    setState(() => _savingLike = true);
    try {
      final result = await FirebaseFirestore.instance.runTransaction((
        transaction,
      ) async {
        final data = (await transaction.get(ref)).data();
        if (data == null) return null;
        final likes = Set<String>.from(data['likes'] ?? []);
        final liked = !likes.remove(user);
        if (liked) likes.add(user);
        transaction.update(ref, {
          'likes': likes.toList(),
          'likesCount': likes.length,
        });
        return (liked: liked, count: likes.length);
      });
      if (result == null) return;
      if (mounted && widget.postId == postId) {
        setState(() {
          _isLiked = result.liked;
          _likesCount = result.count;
        });
      }
      if (result.liked && owner != user) {
        await NotificationGenerator.likePost(owner, user, postId);
      }
    } on FirebaseException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not finish updating your reaction.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _savingLike = false);
    }
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

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Header (lookup by username)
          FutureBuilder<DocumentSnapshot>(
            future: _author,
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
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  UserProfile2(username: widget.username),
                            ),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isNew || isUpdated)
                              _buildStatusTag(isNew ? "NEW" : "UPDATED"),
                            Text(
                              "$firstName $lastName",
                              style: const TextStyle(
                                fontFamily: 'poppins',
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              "@${widget.username}",
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: Text(
                  '${_formatTime(created)} · '
                  "${created.hour}:${created.minute.toString().padLeft(2, '0')}",
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                onLongPress: widget.currentUser == "admin"
                    ? () {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text("Delete Post"),
                            content: const Text(
                              "Are you sure you want to remove this post?",
                            ),
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
                                child: const Text(
                                  "Delete",
                                  style: TextStyle(color: Colors.red),
                                ),
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
                    .map(
                      (t) => Text(
                        "$t",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),

          /// Images
          if (widget.imageUrls.isNotEmpty)
            AspectRatio(
              aspectRatio: 16 / 10,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  PageView.builder(
                    itemCount: widget.imageUrls.length,

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
                        children: List.generate(widget.imageUrls.length, (
                          index,
                        ) {
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
                  onPressed: _savingLike ? null : _toggleLike,
                ),

                StreamBuilder<QuerySnapshot>(
                  stream: _comments,
                  builder: (context, snapshot) {
                    final commentCount = snapshot.hasData
                        ? snapshot.data!.docs.length
                        : 0;

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
                Expanded(
                  child: Text(
                    "$_likesCount likes",
                    textAlign: TextAlign.end,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTag(String text) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colors.tertiaryContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: colors.onTertiaryContainer,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
