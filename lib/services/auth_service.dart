import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:learnxchange/models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      await _updateUserData(userCredential.user);
      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  // Helper to update user data in Firestore if it's a new user
  Future<void> _updateUserData(User? user) async {
    if (user == null) return;

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    
    if (!userDoc.exists) {
      UserModel newUser = UserModel(
        uid: user.uid,
        name: user.displayName ?? 'New User',
        email: user.email ?? '',
        bio: '',
        photoUrl: user.photoURL ?? '',
        offeredSkills: [],
        wantedSkills: [],
        rating: 0,
        ratingCount: 0,
        role: 'user',
        isSuspended: false,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(user.uid).set(newUser.toMap());
    }
  }
}
