import 'package:cloud_firestore/cloud_firestore.dart';

enum RequestStatus { pending, accepted, rejected, completed }

class RequestModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String senderName;
  final String receiverName;
  final String senderPhoto;
  final String receiverPhoto;
  final String skillOffered; // What the sender gives
  final String skillWanted;  // What the sender gets
  final RequestStatus status;
  final DateTime timestamp;
  final bool isRatedBySender;
  final bool isRatedByReceiver;

  RequestModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.senderName,
    required this.receiverName,
    required this.senderPhoto,
    required this.receiverPhoto,
    required this.skillOffered,
    required this.skillWanted,
    required this.status,
    required this.timestamp,
    this.isRatedBySender = false,
    this.isRatedByReceiver = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'senderName': senderName,
      'receiverName': receiverName,
      'senderPhoto': senderPhoto,
      'receiverPhoto': receiverPhoto,
      'skillOffered': skillOffered,
      'skillWanted': skillWanted,
      'status': status.name,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRatedBySender': isRatedBySender,
      'isRatedByReceiver': isRatedByReceiver,
    };
  }

  factory RequestModel.fromMap(Map<String, dynamic> map) {
    return RequestModel(
      id: map['id'] ?? '',
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      senderName: map['senderName'] ?? '',
      receiverName: map['receiverName'] ?? '',
      senderPhoto: map['senderPhoto'] ?? '',
      receiverPhoto: map['receiverPhoto'] ?? '',
      skillOffered: map['skillOffered'] ?? '',
      skillWanted: map['skillWanted'] ?? '',
      status: RequestStatus.values.byName(map['status'] ?? 'pending'),
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      isRatedBySender: map['isRatedBySender'] ?? false,
      isRatedByReceiver: map['isRatedByReceiver'] ?? false,
    );
  }
}
