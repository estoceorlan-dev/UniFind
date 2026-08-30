import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Send a message (supports reply)
  Future<void> sendMessage({
    required String senderUsername,
    required String receiverUsername,
    required String text,
    required String senderProfilePic,
    String? replyToMessageId,
    String? replyToText,
    String? replyToSender,
  }) async {
    final message = {
      'senderUsername': senderUsername,
      'senderProfilePic': senderProfilePic,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'sent',
      'isRead': false,
      'replyToText': replyToText,
      'replyToMessageId': replyToMessageId,
      'replyToSender': replyToSender,
    };

    // Save message to sender's conversation
    await _firestore
        .collection('users')
        .doc(senderUsername)
        .collection('conversations')
        .doc(receiverUsername)
        .collection('messages')
        .add({
      ...message,
      'isRead': true, // sender automatically reads own message
    });

    // Save message to receiver's conversation
    await _firestore
        .collection('users')
        .doc(receiverUsername)
        .collection('conversations')
        .doc(senderUsername)
        .collection('messages')
        .add(message);

    // Increment unread message count for receiver
    await _firestore.collection('users').doc(receiverUsername).update({
      'unreadChatCount': FieldValue.increment(1),
    });
    // Update conversation metadata for both users
    await _updateConversationMetadata(senderUsername, receiverUsername, text);
    await _updateConversationMetadata(receiverUsername, senderUsername, text);
  }

  /// Get reactive unread count for a user
  Stream<int> getUnreadCount(String username) {
  // Listen directly to the user's document for the counter field
  return _firestore
      .collection('users')
      .doc(username)
      .snapshots()
      .map((snapshot) {
        if (snapshot.exists && snapshot.data() != null) {
          // Use our new field; default to 0 if it doesn't exist yet
          return snapshot.data()!['unreadChatCount'] ?? 0;
        }
        return 0;
      });
  }

  /// Get reactive unread count for admin
  Stream<int> getAdminUnreadCount() {
    String adminUsername = 'admin';
    return _firestore
        .collection('users')
        .doc(adminUsername)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return snapshot.data()!['unreadChatCount'] ?? 0;
      }
      return 0;
    });
  }

  /// Update conversation metadata
  Future<void> _updateConversationMetadata(
      String owner, String other, String lastMessage) async {
    await _firestore
        .collection('users')
        .doc(owner)
        .collection('conversations')
        .doc(other)
        .set({
      'lastMessage': lastMessage,
      'updatedAt': FieldValue.serverTimestamp(),
      'otherUser': other,
    }, SetOptions(merge: true));
  }

  /// Get messages between two users
  Stream<QuerySnapshot<Map<String, dynamic>>> getMessages(
      String currentUsername, String otherUsername) {
    return _firestore
        .collection('users')
        .doc(currentUsername)
        .collection('conversations')
        .doc(otherUsername)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// Get all conversations for a user
  Stream<QuerySnapshot<Map<String, dynamic>>> getUserConversations(
      String currentUsername) {
    return _firestore
        .collection('users')
        .doc(currentUsername)
        .collection('conversations')
        .orderBy('updatedAt', descending: true)
        .snapshots();
  }

  /// Marks all messages as read for a user
  Future<void> markAllMessagesAsRead(String currentUsername) async {
  // ✅ 1. Clear the summary badge immediately
  await _firestore.collection('users').doc(currentUsername).update({
    'unreadChatCount': 0,
  });

  // 2. Proceed with marking individual message documents as read (background logic)
  final userConversationsRef = _firestore
      .collection('users')
      .doc(currentUsername)
      .collection('conversations');

  final allConversations = await userConversationsRef.get();
  for (var convo in allConversations.docs) {
    final unreadMessages = await convo.reference
        .collection('messages')
        .where('isRead', isEqualTo: false)
        .where('senderUsername', isNotEqualTo: currentUsername)
        .get();

    for (var msg in unreadMessages.docs) {
      await msg.reference.update({'isRead': true});
    }
  }
  }
}
