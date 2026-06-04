import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String bio;
  final String photoUrl;
  final List<String> offeredSkills;
  final List<String> wantedSkills;
  final double rating;
  final int ratingCount;
  final String role;
  final DateTime? createdAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.bio,
    required this.photoUrl,
    required this.offeredSkills,
    required this.wantedSkills,
    required this.rating,
    required this.ratingCount,
    required this.role,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'bio': bio,
      'photoUrl': photoUrl,
      'offeredSkills': offeredSkills,
      'wantedSkills': wantedSkills,
      'rating': rating,
      'ratingCount': ratingCount,
      'role': role,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      bio: map['bio'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
      offeredSkills: List<String>.from(map['offeredSkills'] ?? []),
      wantedSkills: List<String>.from(map['wantedSkills'] ?? []),
      rating: (map['rating'] ?? 0).toDouble(),
      ratingCount: map['ratingCount'] ?? 0,
      role: map['role'] ?? 'user',
      createdAt: map['createdAt'] != null ? (map['createdAt'] as Timestamp).toDate() : null,
    );
  }
}
