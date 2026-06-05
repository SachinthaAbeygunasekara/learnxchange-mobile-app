import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:learnxchange/models/request_model.dart';
import 'package:learnxchange/models/user_model.dart';

class RequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Send a new request
  Future<void> sendRequest({
    required UserModel sender,
    required UserModel receiver,
    required String skillOffered,
    required String skillWanted,
  }) async {
    final docRef = _firestore.collection('requests').doc();
    
    final request = RequestModel(
      id: docRef.id,
      senderId: sender.uid,
      receiverId: receiver.uid,
      senderName: sender.name,
      receiverName: receiver.name,
      senderPhoto: sender.photoUrl,
      receiverPhoto: receiver.photoUrl,
      skillOffered: skillOffered,
      skillWanted: skillWanted,
      status: RequestStatus.pending,
      timestamp: DateTime.now(),
    );

    await docRef.set(request.toMap());
  }

  // Get incoming requests
  Stream<List<RequestModel>> getIncomingRequests(String uid) {
    return _firestore
        .collection('requests')
        .where('receiverId', isEqualTo: uid)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RequestModel.fromMap(doc.data()))
            .toList());
  }

  // Get outgoing requests
  Stream<List<RequestModel>> getOutgoingRequests(String uid) {
    return _firestore
        .collection('requests')
        .where('senderId', isEqualTo: uid)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RequestModel.fromMap(doc.data()))
            .toList());
  }

  // Update request status
  Future<void> updateRequestStatus(String requestId, RequestStatus status) async {
    await _firestore.collection('requests').doc(requestId).update({
      'status': status.name,
    });
  }
}
