import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import 'user_profile_2.dart';

class ConvoPage extends StatefulWidget {
  final String currentUsername;
  final String otherUsername;

  const ConvoPage({
    Key? key,
    required this.currentUsername,
    required this.otherUsername,
  }) : super(key: key);

  @override
  State<ConvoPage> createState() => _ConvoPageState();
}

class _ConvoPageState extends State<ConvoPage> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();

  Stream<QuerySnapshot>? _messageStream;

  // Reply state (what the user is replying to)
  String? _replyToText;
  String? _replyToSender;
  String? _replyToMessageId;

  @override
  void initState() {
    super.initState();
    _messageStream = _chatService.getMessages(
      widget.currentUsername,
      widget.otherUsername,
    );
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final senderDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.currentUsername)
        .get();

    final senderData = senderDoc.data() ?? {};
    final senderProfilePic = senderData['profilePic'] ?? '';

    // include reply metadata if present
    await _chatService.sendMessage(
      senderUsername: widget.currentUsername,
      receiverUsername: widget.otherUsername,
      text: text,
      senderProfilePic: senderProfilePic,
      replyToText: _replyToText,
      replyToSender: _replyToSender,
      replyToMessageId: _replyToMessageId,
    );

    _messageController.clear();
    _clearReply();
  }

  void _setReply({required String text, required String sender, required String messageId}) {
    setState(() {
      _replyToText = text;
      _replyToSender = sender;
      _replyToMessageId = messageId;
    });
  }

  void _clearReply() {
    setState(() {
      _replyToText = null;
      _replyToSender = null;
      _replyToMessageId = null;
    });
  }



  //Format timestamp to "time ago"
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
      appBar: AppBar(
        elevation: 1,

        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(widget.otherUsername)
              .get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Row(
                children: const [
                  CircleAvatar(
                    backgroundColor: Colors.grey,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text("Loading...",
                      style: TextStyle(fontSize: 16)),
                ],
              );
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Colors.grey,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  Text(widget.otherUsername,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16)),
                ],
              );
            }

            final userData = snapshot.data!.data() as Map<String, dynamic>;
            final profilePicUrl = userData['profilePic'] ?? '';

            return InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UserProfile2(username: widget.otherUsername),
                  ),
                );
              },
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: profilePicUrl.isNotEmpty
                        ? NetworkImage(profilePicUrl)
                        : const AssetImage('assets/images/defaultpfp.jpg')
                            as ImageProvider,
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.otherUsername,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: _messageStream == null
                ? const Center(child: CircularProgressIndicator())
                : StreamBuilder<QuerySnapshot>(
                    stream: _messageStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text("No messages yet. Say hi!"),
                              Text(
                                "Messages shared between users cannot be deleted.\nPlease refrain from sharing sensitive informations like emails or passwords.\nUniFind is not responsible for any sensitive information shared through chats.",
                                style: TextStyle(color: Colors.grey),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }

                      final messages = snapshot.data!.docs;

                      return ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.all(12),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final doc = messages[index];
                          final msg = doc.data() as Map<String, dynamic>;

                          return MessageBubble(
                            messageId: doc.id,
                            sender: msg['senderUsername'] ?? "Unknown",
                            text: msg['text'] ?? '',
                            timestamp: (msg['timestamp'] as Timestamp?)?.toDate(),
                            isMe: (msg['senderUsername'] == widget.currentUsername),
                            status: msg['status'],
                            profilePicUrl: msg['senderProfilePic'],
                            replyToText: msg['replyToText'],
                            replyToSender: msg['replyToSender'],
                            onSwipeToReply: () {
                              // Option A: swipe right to reply (both sides)
                              final replyText = msg['text'] ?? '';
                              final replySender = msg['senderUsername'] ?? '';
                              _setReply(
                                text: replyText,
                                sender: replySender,
                                messageId: doc.id,
                              );
                            },
                            formatTime: _formatTime,
                          );
                        },
                      );
                    },
                  ),
          ),

          // Message input + reply preview area
          SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_replyToText != null)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Replying to ${_replyToSender ?? ''}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _replyToText ?? '',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: _clearReply,
                        ),
                      ],
                    ),
                  ),
                MessageInput(
                  controller: _messageController,
                  onSend: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Message bubble with swipe-to-reply and long-press to react
class MessageBubble extends StatelessWidget {
  final String messageId;
  final String sender;
  final String text;
  final DateTime? timestamp;
  final bool isMe;
  final String? status;
  final String? profilePicUrl;
  final String? replyToText;
  final String? replyToSender;

  // Callbacks
  final VoidCallback? onSwipeToReply;
  final Future<void> Function(String emoji)? onLongPressReact;

  // optional formatter for timestamps
  final String Function(DateTime)? formatTime;

  const MessageBubble({
    Key? key,
    required this.messageId,
    required this.sender,
    required this.text,
    required this.timestamp,
    required this.isMe,
    this.status,
    this.profilePicUrl,
    this.replyToText,
    this.replyToSender,
    this.onSwipeToReply,
    this.onLongPressReact,
    this.formatTime,
  }) : super(key: key);

  // detect swipe right (Option A)
  void _handleHorizontalDragEnd(BuildContext context, DragEndDetails details) {
    // primaryVelocity > 0 -> swipe to the right
    final v = details.primaryVelocity ?? 0;
    if (v > 200 && onSwipeToReply != null) {
      onSwipeToReply!();
      // small feedback
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Replying to ${sender}'), duration: const Duration(milliseconds: 700)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: GestureDetector(
        onHorizontalDragEnd: (details) => _handleHorizontalDragEnd(context, details),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // For other user's messages show avatar above the bubble
            if (!isMe) ...[
              Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundImage: (profilePicUrl != null && profilePicUrl!.isNotEmpty)
                        ? NetworkImage(profilePicUrl!)
                        : const AssetImage('assets/images/defaultpfp.jpg')
                            as ImageProvider,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    sender,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],

            // Constrain bubble width to at most half the screen
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: screenWidth * 0.66),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                decoration: BoxDecoration(
                  color: isMe ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isMe ? 16 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Reply preview within bubble 
                    if (replyToText != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue.shade700.withOpacity(0.2) : Theme.of(context).colorScheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              replyToSender ?? '',
                              style: TextStyle(
                                fontSize: 11,
                                color: isMe ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              replyToText ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: isMe ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Main message text
                    Text(
                      text,
                      style: TextStyle(
                        color: isMe ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurface,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // timestamp + status
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment:
                          isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                      children: [
                        if (timestamp != null)
                          Text(
                            (formatTime != null)
                                ? formatTime!(timestamp!)
                                : "${timestamp!.hour.toString().padLeft(2, '0')}:${timestamp!.minute.toString().padLeft(2, '0')}",
                            style: TextStyle(
                              color: isMe ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurfaceVariant,
                              fontSize: 10,
                            ),
                          ),
                        if (isMe && status != null) ...[
                          const SizedBox(width: 6),
                          Text(
                            status!,
                            style: TextStyle(
                              fontSize: 10,
                              color: isMe ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Input widget unchanged functionally but included to keep file complete
class MessageInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const MessageInput({
    Key? key,
    required this.controller,
    required this.onSend,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Colors.black12),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: "Type a message...",
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              minLines: 1,
              maxLines: 6,
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: Colors.blueAccent,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: onSend,
            ),
          ),
        ],
      ),
    );
  }
}
