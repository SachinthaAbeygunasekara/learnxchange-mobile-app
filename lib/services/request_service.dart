import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:learnxchange/models/request_model.dart';
import 'package:learnxchange/models/user_model.dart';
import 'package:learnxchange/models/review_model.dart';
import 'package:learnxchange/services/user_service.dart';

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

  // Rate partner and update request flag
  Future<void> ratePartner({
    required String requestId,
    required String reviewerId,
    required String reviewerName,
    required String reviewerPhoto,
    required String partnerId,
    required double rating,
    required String comment,
    required bool isSender,
  }) async {
    final userService = UserService();
    
    // 1. Update the partner's user rating
    await userService.updateUserRating(partnerId, rating);

    // 2. Add review details
    final review = ReviewModel(
      id: _firestore.collection('users').doc(partnerId).collection('reviews').doc().id,
      reviewerId: reviewerId,
      reviewerName: reviewerName,
      reviewerPhoto: reviewerPhoto,
      comment: comment,
      rating: rating,
      timestamp: DateTime.now(),
    );
    await userService.addUserReview(partnerId, review);

    // 3. Mark the request as rated by this user
    final field = isSender ? 'isRatedBySender' : 'isRatedByReceiver';
    await _firestore.collection('requests').doc(requestId).update({
      field: true,
    });
  }
}
