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
}
