import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  const AppUser({
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.gender,
    required this.schoolId,
    required this.course,
    required this.passwordHash,
    required this.profilePic,
    required this.schoolIdFrontPhoto,
    required this.schoolIdBackPhoto,
    required this.isVerified,
    required this.role,
    this.createdAt,
  });

  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String gender;
  final String schoolId;
  final String course;
  final String passwordHash;
  final String profilePic;
  final String schoolIdFrontPhoto;
  final String schoolIdBackPhoto;
  final bool isVerified;
  final String role;
  final Object? createdAt;

  factory AppUser.fromMap(Map<String, dynamic> data) {
    return AppUser(
      username: (data['username'] ?? '') as String,
      email: (data['email'] ?? '') as String,
      firstName: (data['firstName'] ?? '') as String,
      lastName: (data['lastName'] ?? '') as String,
      gender: (data['gender'] ?? '') as String,
      schoolId: (data['schoolId'] ?? '') as String,
      course: (data['course'] ?? '') as String,
      passwordHash: (data['password'] ?? '') as String,
      profilePic: (data['profilePic'] ?? '') as String,
      schoolIdFrontPhoto: (data['schoolIdFrontPhoto'] ?? '') as String,
      schoolIdBackPhoto: (data['schoolIdBackPhoto'] ?? '') as String,
      isVerified: (data['isVerified'] ?? false) as bool,
      role: (data['role'] ?? 'user') as String,
      createdAt: data['createdAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'gender': gender,
      'schoolId': schoolId,
      'course': course,
      'password': passwordHash,
      'profilePic': profilePic,
      'schoolIdFrontPhoto': schoolIdFrontPhoto,
      'schoolIdBackPhoto': schoolIdBackPhoto,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'isVerified': isVerified,
      'role': role,
    };
  }
}
