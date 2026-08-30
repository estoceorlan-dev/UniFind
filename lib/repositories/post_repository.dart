import 'package:cloud_firestore/cloud_firestore.dart';

class PostRepository {
  PostRepository({FirebaseFirestore? firestore})
      : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _posts =>
      _db.collection('posts');

  Future<DocumentSnapshot<Map<String, dynamic>>> fetchPost(String postId) {
    return _posts.doc(postId).get();
  }
}
