import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationGenerator {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const adminUsername = "admin";


  static Future<void> init() async {
    try {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const settings = InitializationSettings(android: androidSettings);
      await _localNotifications.initialize(settings);
    } catch (e) {
      debugPrint('Local notifications unavailable: $e');
    }

    try {
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        final notif = message.notification;
        final data = message.data;

        if (notif == null) return;

        final title = notif.title ?? "UniFind";
        final body = notif.body ?? "";
        final type = data['type'] ?? "minor";

        if (type == 'new_post' ||
            type == 'account_verified' ||
            type == 'message' ||
            type == 'reply_message') {
          await _showLocalNotification(title: title, body: body);
        }

        final username = data['username'];
        if (username != null) {
          await _saveNotification(
            username: username,
            type: type,
            title: title,
            body: body,
            extraData: data,
          );
        }
      });
    } catch (e) {
      debugPrint('Firebase messaging unavailable: $e');
    }
  }

  /// Local Android popup
  static Future<void> _showLocalNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'unifind_channel',
      'UniFind Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);
    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    try {
      await _localNotifications.show(id, title, body, details);
    } catch (e) {
      debugPrint('Failed to show local notification: $e');
    }
  }

  /// Save notification to Firestore (in-app)
  static Future<void> _saveNotification({
    required String username,
    required String type,
    required String title,
    required String body,
    Map<String, dynamic>? extraData,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(username)
          .collection('notifications')
          .add({
        'type': type,
        'title': title,
        'body': body,
        'extraData': extraData ?? {},
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    } catch (e) {
      debugPrint("⚠️ Failed to save notification: $e");
    }
  }


  static Future<void> newPost({
    required String sender,
    required String postId,
  }) async {
    final doc = await FirebaseFirestore.instance.collection('posts').doc(postId).get();
    if (!doc.exists) return;

    final postData = doc.data()!;
    final postType = postData['type'] ?? 'Post';

    String title;
    String body;

    switch (postType) {
      case 'Announcement':
        title = '📢 New Announcement';
        body = '$sender posted an announcement.';
        break;
      case 'Lost Item':
        title = '🔎 Lost Item Alert';
        body = '$sender reported a lost item.';
        break;
      case 'Found Item':
        title = '📦 Found Item Reported';
        body = '$sender posted a found item.';
        break;
      default:
        title = '📰 New Post';
        body = '$sender created a new post.';
    }

    // Save in-app notifications for all users
    final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
    for (final userDoc in usersSnapshot.docs) {
      final username = userDoc.id;
      await _saveNotification(
        username: username,
        type: 'new_post',
        title: title,
        body: body,
        extraData: {
          'postId': postId,
          'postType': postType,
          'sender': sender,
        },
      );
    }
  }

  static Future<void> accountVerified(String verifiedUser) async {
    const title = '✅ Account Verified';
    const body = 'Your UniFind account has been successfully verified.';

    await _saveNotification(
      username: verifiedUser,
      type: 'account_verified',
      title: title,
      body: body,
    );
  }

  static Future<void> likePost(String toUsername, String fromUser, String postId) async {
    await _saveNotification(
      username: toUsername,
      type: 'minor',
      title: '$fromUser liked your post',
      body: '$fromUser engaged with your content.',
      extraData: {
      'postId': postId,
      }
    );
  }

  static Future<void> commentPost(String toUsername, String fromUser, String postId) async {
    await _saveNotification(
      username: toUsername,
      type: 'minor',
      title: '$fromUser commented on your post',
      body: 'See what they wrote!',
      extraData: {
      'postId': postId,
      }
    );
  }

  static Future<void> replyComment(String toUsername, String fromUser, String postId, String commentId) async {
    await _saveNotification(
      username: toUsername,
      type: 'minor',
      title: '$fromUser replied to your comment',
      body: 'Check the reply!',
      extraData: {
      'postId': postId,
      'commentId': commentId,
      }
    );
  }

  static Future<void> reportPost({
    required String reporter,
    required String postOwner,
    required String postId,
    required String reason,
  }) async {
    await _saveNotification(
      username: adminUsername,
      type: 'minor',
      title: '⚠️ Post Reported',
      body: '$reporter reported a post by $postOwner for "$reason".',
      extraData: {
        'postOwner': postOwner,
        'reporter': reporter,
        'postId': postId,
        'reason': reason,
      },
    );
  }

  static Future<void> reportUser({
    required String reportedUser,
    required String reason,
  }) async {
    await _saveNotification(
      username: adminUsername,
      type: 'minor',
      title: '⚠️ User Reported',
      body: 'A user reported user $reportedUser for $reason.',
      extraData: {
        'reportedUser': reportedUser,
       'reason': reason,
      },
    );
  }

  static Future<void> reportComment({
    required String reporter,
    required String commentOwner,
    required String commentId,
    required String reason,
  }) async {
    await _saveNotification(
      username: adminUsername,
      type: 'minor',
      title: '⚠️ Comment Reported',
      body: '$reporter reported a comment by $commentOwner for "$reason".',
      extraData: {
        'commentOwner': commentOwner,
        'reporter': reporter,
        'commentId': commentId,
        'reason': reason,
      },
    );
  }

  static Future<void> likeComment(String toUsername, String fromUser, String postId, String commentId) async {
    await _saveNotification(
      username: toUsername,
      type: 'minor',
      title: '$fromUser liked your comment',
      body: 'Someone appreciated your comment.',
      extraData: {
      'postId': postId,
      'commentId': commentId,
      }
    );
  }

  static Future<void> postRemoved(String postOwner, String postId, String postType) async {
    await _saveNotification(
      username: postOwner,
      type: 'minor',
      title: '🚫 Post Removed',
      body: 'Your $postType post has been removed by an admin.',
      extraData: {
        'postId': postId,
        'postType': postType,
      },
    );
  }
}
