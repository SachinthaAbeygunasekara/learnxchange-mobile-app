import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:learnxchange/models/session_model.dart';

class SessionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new session
  Future<void> createSession(SessionModel session) async {
    await _firestore.collection('sessions').doc(session.id).set(session.toMap());
  }

  // Get sessions for a user (where they are either sender or receiver)
  Stream<List<SessionModel>> getUserSessions(String uid) {
    return _firestore
        .collection('sessions')
        .where(Filter.or(
          Filter('senderId', isEqualTo: uid),
          Filter('receiverId', isEqualTo: uid),
        ))
        .orderBy('scheduledDateTime', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SessionModel.fromMap(doc.data()))
            .toList());
  }

  // Update session status
  Future<void> updateSessionStatus(String sessionId, SessionStatus status) async {
    await _firestore.collection('sessions').doc(sessionId).update({
      'status': status.name,
    });
  }

  // Delete a session
  Future<void> deleteSession(String sessionId) async {
    await _firestore.collection('sessions').doc(sessionId).delete();
  }
}
