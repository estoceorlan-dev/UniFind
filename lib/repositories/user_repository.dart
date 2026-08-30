import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';

class UserRepository {
  UserRepository({FirebaseFirestore? firestore})
      : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  Future<DocumentSnapshot<Map<String, dynamic>>> getRawUser(String username) {
    return _users.doc(username).get();
  }

  Future<AppUser?> fetchUser(String username) async {
    final snapshot = await getRawUser(username);
    final data = snapshot.data();
    if (!snapshot.exists || data == null) return null;
    return AppUser.fromMap(data);
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> streamUser(String username) {
    return _users.doc(username).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamPendingUsers() {
    return _users
        .where('role', isEqualTo: 'user')
        .where('isVerified', isEqualTo: false)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamAllUsers() {
    return _users.snapshots();
  }

  Future<bool> usernameExists(String username) async {
    final snapshot = await _users.doc(username).get();
    return snapshot.exists;
  }

  Future<bool> emailExists(String email) async {
    final snapshot = await _users.where('email', isEqualTo: email).limit(1).get();
    return snapshot.docs.isNotEmpty;
  }

  Future<void> createUser(AppUser user) {
    return _users.doc(user.username).set(user.toMap());
  }

  Future<void> verifyUser(String username) {
    return _users.doc(username).update({'isVerified': true});
  }

  Future<void> updatePasswordHash(String username, String passwordHash) {
    return _users.doc(username).update({'password': passwordHash});
  }

  Future<void> saveResetCode(String username, String code) {
    return _db.collection('resetCodes').doc(username).set({
      'code': code,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }
}
