import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../widgets/admin_bottom_nav.dart';
import '../widgets/admin_appbar.dart';
import '../services/chat_service.dart';
import '../screens/convo_page.dart';

class AdminChats extends StatefulWidget {
  final String adminUsername;

  const AdminChats({
    Key? key,
    this.adminUsername = 'admin',
  }) : super(key: key);

  @override
  State<AdminChats> createState() => _AdminChatsState();
}

class _AdminChatsState extends State<AdminChats> {
  final ChatService _chatService = ChatService();
  Stream<QuerySnapshot>? _convoStream;

  @override
  void initState() {
    super.initState();
    _loadConversations();
     ChatService().markAllMessagesAsRead('admin');
  }


  void _loadConversations() {
    _convoStream = _chatService.getUserConversations(widget.adminUsername);
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
          .doc(widget.adminUsername)
          .collection("conversations")
          .doc(otherUsername)
          .delete();
      // also delete from the other user’s side
      await FirebaseFirestore.instance
          .collection("users")
          .doc(otherUsername)
          .collection("conversations")
          .doc(widget.adminUsername)
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
      appBar: const AdminAppBar(),
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
              itemCount: convos.length + 1, // +1 for the header
              itemBuilder: (context, index) {
                // Show "Recent Chats" header
                if (index == 0) {
                  return const Padding(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Text(
                      "Recent Chats",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  );
                }

                final convo = convos[index - 1].data() as Map<String, dynamic>;

                final otherUsername = convo['otherUser'] ?? '';
                final lastMessage = convo['lastMessage'] ?? '';
                final updatedAt = (convo['updatedAt'] as Timestamp?)?.toDate();

                if (otherUsername.isEmpty) return const SizedBox();

                return FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .where('username', isEqualTo: otherUsername)
                      .limit(1)
                      .get(),
                  builder: (context, userSnapshot) {
                    if (!userSnapshot.hasData ||
                        userSnapshot.data!.docs.isEmpty) {
                      return const SizedBox();
                    }

                    final userData = userSnapshot.data!.docs.first.data()
                        as Map<String, dynamic>;
                    final fullName =
                        "${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}"
                            .trim();
                    final profilePic = userData['profilePic'] ?? '';

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      leading: CircleAvatar(
                        radius: 28,
                        backgroundImage: profilePic.isNotEmpty &&
                                profilePic.startsWith("http")
                            ? NetworkImage(profilePic)
                            : const AssetImage('assets/defaultpfp.jpg')
                                as ImageProvider,
                      ),
                      title: Text(
                        fullName.isNotEmpty ? fullName : otherUsername,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      subtitle: Text(
                        lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.black54),
                      ),
                      trailing: updatedAt != null
                          ? Text(
                                _formatTime(updatedAt),
                              style: const TextStyle(fontSize: 12),
                            )
                          : null,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ConvoPage(
                              currentUsername: widget.adminUsername,
                              otherUsername: otherUsername,
                            ),
                          ),
                        );
                      },
                      onLongPress: () {
                        _deleteConversation(otherUsername);
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),
      bottomNavigationBar: AdminBottomNav(
        currentIndex: 1,
      ),
    );
  }
}
