import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:learnxchange/models/user_model.dart';
import 'package:learnxchange/models/review_model.dart';

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

  // Update user rating logic
  Future<void> updateUserRating(String uid, double newRating) async {
    final userRef = _firestore.collection('users').doc(uid);
    
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);
      if (!snapshot.exists) return;

      final userData = UserModel.fromMap(snapshot.data()!);
      
      double currentRating = userData.rating;
      int currentCount = userData.ratingCount;
      
      double totalRatingScore = (currentRating * currentCount) + newRating;
      int newCount = currentCount + 1;
      double newAverageRating = totalRatingScore / newCount;

      transaction.update(userRef, {
        'rating': newAverageRating,
        'ratingCount': newCount,
      });
    });
  }

  // Add review to a user
  Future<void> addUserReview(String targetUid, ReviewModel review) async {
    await _firestore
        .collection('users')
        .doc(targetUid)
        .collection('reviews')
        .doc(review.id)
        .set(review.toMap());
  }

  // Get user reviews stream
  Stream<List<ReviewModel>> getUserReviews(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('reviews')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReviewModel.fromMap(doc.data()))
            .toList());
  }

  // Workaround: Convert image to Base64 and store in Firestore
  Future<String> uploadProfileImage(String uid, File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      if (bytes.lengthInBytes > 800000) {
        throw "The selected image is too large. Please choose a photo smaller than 800KB.";
      }
      final base64String = base64Encode(bytes);
      final dataUrl = 'data:image/jpeg;base64,$base64String';
      await updatePhotoUrl(uid, dataUrl);
      return dataUrl;
    } catch (e) {
      if (e is String) rethrow;
      throw "We couldn't process your profile picture. Please try a different image.";
    }
  }

  Future<void> updatePhotoUrl(String uid, String photoUrl) async {
    await _firestore.collection('users').doc(uid).update({
      'photoUrl': photoUrl,
    });
  }

  // Admin Methods
  Stream<List<UserModel>> getAllUsers() {
    return _firestore.collection('users').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList());
  }

  Future<void> toggleUserSuspension(String uid, bool suspend) async {
    await _firestore.collection('users').doc(uid).update({
      'isSuspended': suspend,
    });
  }

  Stream<List<ReviewModel>> getAllReviews() {
    // This is tricky because reviews are in subcollections.
    // For a simple admin dashboard, we might want to use a collection group query or just fetch per user.
    // For now, let's use collection group if enabled, or just provide a placeholder if it's too complex for this project structure.
    return _firestore.collectionGroup('reviews').orderBy('timestamp', descending: true).snapshots().map(
        (snapshot) => snapshot.docs.map((doc) => ReviewModel.fromMap(doc.data())).toList());
  }
}
