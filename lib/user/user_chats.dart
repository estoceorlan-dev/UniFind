import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../widgets/user_bottom_nav.dart';
import '../widgets/user_appbar.dart';
import '../services/chat_service.dart';
import '../screens/convo_page.dart';

class UserChats extends StatefulWidget {
  final String username;

  const UserChats({
    Key? key,
    required this.username,
  }) : super(key: key);

  @override
  State<UserChats> createState() => _UserChatsState();
}

class _UserChatsState extends State<UserChats> {
  final ChatService _chatService = ChatService();
  Stream<QuerySnapshot>? _convoStream;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  void _loadConversations() {
    _convoStream = _chatService.getUserConversations(widget.username);
  }

  Future<void> _refreshConversations() async {
    _loadConversations();
    setState(() {});
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<void> _deleteConversation(String otherUsername) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Conversation"),
        content: Text(
            "Are you sure you want to delete your conversation with $otherUsername?"),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(ctx, false),
          ),
          TextButton(
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(widget.username)
          .collection("conversations")
          .doc(otherUsername)
          .delete();
      // also delete from the other user’s side
      await FirebaseFirestore.instance
          .collection("users")
          .doc(otherUsername)
          .collection("conversations")
          .doc(widget.username)
          .delete();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 247, 254, 255),
      appBar: UserAppBar(
        username: widget.username,
        userStream: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.username)
            .snapshots(),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshConversations,
        child: StreamBuilder<QuerySnapshot>(
          stream: _convoStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 200),
                  Center(child: Text("No conversations yet.")),
                ],
              );
            }

            final convos = snapshot.data!.docs;

            return ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: convos.length + 1, // +1 for header
              itemBuilder: (context, index) {

                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12 , vertical: 16), // 
                    child: const Text(
                      'Recent Chats',
                      style: TextStyle(
                        
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  );
                }
                
                final convo = convos[index - 1].data() as Map<String, dynamic>;

                // conversations are stored under each user with otherUsername as docId
                final otherUsername = convos[index - 1].id;
                final lastMessage = convo['lastMessage'] ?? '';
                final lastSender = convo['lastSender'] ?? '';
                final lastTime =
                    (convo['updatedAt'] as Timestamp?)?.toDate();

                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(otherUsername)
                      .get(),
                  builder: (context, userSnapshot) {
                    if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                      return const SizedBox();
                    }

                    final userData =
                        userSnapshot.data!.data() as Map<String, dynamic>;
                    final fullName =
                        "${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}".trim();
                    final profilePic = userData['profilePic'] ?? '';

                    ImageProvider avatarProvider;
                    if (profilePic.isNotEmpty && profilePic.startsWith("http")) {
                      avatarProvider = NetworkImage(profilePic);
                    } else {
                      avatarProvider =
                          const AssetImage('assets/defaultpfp.jpg');
                    }

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      leading: CircleAvatar(
                        radius: 28,
                        backgroundImage: avatarProvider,
                      ),
                      title: Text(
                        fullName.isNotEmpty ? fullName : otherUsername,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      subtitle: Text(
                        "$lastSender: $lastMessage",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.black54),
                      ),
                      trailing: lastTime != null
                          ? Text(
                               _formatTime(lastTime),
                              style: const TextStyle(fontSize: 12),
                            )
                          : null,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ConvoPage(
                              currentUsername: widget.username,
                              otherUsername: otherUsername,
                            ),
                          ),
                        );
                      },
                      onLongPress: () =>
                          _deleteConversation(otherUsername), // ✅ long press delete
                    );
                  },
                );
              },
            );
          },
        ),
      ),
      bottomNavigationBar: UserBottomNav(
        currentIndex: 1,
        username: widget.username,
      ),
    );
  }
}
