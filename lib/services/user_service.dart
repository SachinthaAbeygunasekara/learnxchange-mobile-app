import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:learnxchange/models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get user data stream
  Stream<UserModel> getUserData(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        throw Exception("User not found");
      }
      return UserModel.fromMap(snapshot.data()!);
    });
  }

  // Update user profile
  Future<void> updateProfile({
    required String uid,
    required String name,
    required String bio,
    required List<String> offeredSkills,
    required List<String> wantedSkills,
  }) async {
    await _firestore.collection('users').doc(uid).update({
      'name': name,
      'bio': bio,
      'offeredSkills': offeredSkills,
      'wantedSkills': wantedSkills,
    });
  }

  // Workaround: Convert image to Base64 and store in Firestore
  Future<String> uploadProfileImage(String uid, File imageFile) async {
    try {
      // 1. Read file as bytes
      final bytes = await imageFile.readAsBytes();
      
      // 2. Check size (Firestore docs have a 1MB limit, but let's be safe)
      if (bytes.lengthInBytes > 800000) {
        throw Exception("Image is too large. Please select a smaller photo (under 800KB).");
      }

      // 3. Convert to Base64 string
      final base64String = base64Encode(bytes);
      final dataUrl = 'data:image/jpeg;base64,$base64String';
      
      // 4. Update Firestore
      await updatePhotoUrl(uid, dataUrl);
      return dataUrl;
    } catch (e) {
      throw Exception("Failed to process image: $e");
    }
  }

  // Update photo URL
  Future<void> updatePhotoUrl(String uid, String photoUrl) async {
    await _firestore.collection('users').doc(uid).update({
      'photoUrl': photoUrl,
    });
  }
}
