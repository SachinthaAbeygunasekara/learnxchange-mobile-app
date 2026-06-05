import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:learnxchange/models/user_model.dart';

class MatchingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Finds users who have a mutual skill match with the current user.
  /// User A offers X, wants Y.
  /// User B offers Y, wants X.
  Future<List<UserModel>> findMatches(UserModel currentUser) async {
    if (currentUser.wantedSkills.isEmpty || currentUser.offeredSkills.isEmpty) {
      return [];
    }

    try {
      // 1. Find users who OFFER what current user WANTS
      // Firestore 'array-contains-any' limit is 10 items. 
      // For now we'll take the first 10 wanted skills if there are more.
      List<String> limitedWantedSkills = currentUser.wantedSkills.take(10).toList();

      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .where('offeredSkills', arrayContainsAny: limitedWantedSkills)
          .get();

      List<UserModel> potentialMatches = querySnapshot.docs
          .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
          .where((user) => user.uid != currentUser.uid) // Exclude self
          .toList();

      // 2. Filter potential matches who WANT what current user OFFERS (Mutual Match)
      List<UserModel> mutualMatches = potentialMatches.where((potentialUser) {
        // Check if any of potential user's wanted skills are offered by current user
        return potentialUser.wantedSkills.any((skill) => 
          currentUser.offeredSkills.contains(skill)
        );
      }).toList();

      return mutualMatches;
    } catch (e) {
      print("Error finding matches: $e");
      return [];
    }
  }

  /// Finds users who offer what you want, even if they don't want what you have (One-way)
  Future<List<UserModel>> findPotentialMatches(UserModel currentUser) async {
    if (currentUser.wantedSkills.isEmpty) return [];

    try {
      List<String> limitedWantedSkills = currentUser.wantedSkills.take(10).toList();

      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .where('offeredSkills', arrayContainsAny: limitedWantedSkills)
          .get();

      return querySnapshot.docs
          .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
          .where((user) => user.uid != currentUser.uid)
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Searches for users based on name or skills, and optionally filters by category and rating.
  Future<List<UserModel>> searchUsers({
    required String query,
    String? category,
    double? minRating,
    UserModel? currentUser,
  }) async {
    try {
      QuerySnapshot querySnapshot = await _firestore.collection('users').get();

      List<UserModel> allUsers = querySnapshot.docs
          .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
          .where((user) => user.uid != currentUser?.uid)
          .toList();

      return allUsers.where((user) {
        bool matchesQuery = true;
        if (query.isNotEmpty) {
          final lowercaseQuery = query.toLowerCase();
          matchesQuery = user.name.toLowerCase().contains(lowercaseQuery) ||
              user.offeredSkills.any((skill) => skill.toLowerCase().contains(lowercaseQuery));
        }

        bool matchesCategory = true;
        if (category != null && category.isNotEmpty) {
          final lowercaseCategory = category.toLowerCase();
          matchesCategory = user.offeredSkills.any((skill) => 
            skill.toLowerCase().contains(lowercaseCategory) || 
            _getCategoryForSkill(skill).toLowerCase() == lowercaseCategory
          );
        }

        bool matchesRating = true;
        if (minRating != null) {
          matchesRating = user.rating >= minRating;
        }

        return matchesQuery && matchesCategory && matchesRating;
      }).toList();
    } catch (e) {
      print("Error searching users: $e");
      return [];
    }
  }

  // Helper to map common skills to categories if not explicitly stored
  String _getCategoryForSkill(String skill) {
    final s = skill.toLowerCase();
    if (s.contains('code') || s.contains('python') || s.contains('java') || s.contains('flutter') || s.contains('dart') || s.contains('web') || s.contains('programming')) {
      return 'Coding';
    }
    if (s.contains('design') || s.contains('ui') || s.contains('ux') || s.contains('brush') || s.contains('art') || s.contains('graphic')) {
      return 'Design';
    }
    if (s.contains('language') || s.contains('english') || s.contains('spanish') || s.contains('french') || s.contains('speak')) {
      return 'Language';
    }
    if (s.contains('music') || s.contains('guitar') || s.contains('piano') || s.contains('sing')) {
      return 'Music';
    }
    if (s.contains('photo') || s.contains('camera') || s.contains('video') || s.contains('edit')) {
      return 'Photo';
    }
    return '';
  }
}
