import 'package:cloud_firestore/cloud_firestore.dart';

enum SessionStatus { scheduled, completed, cancelled }

class SessionModel {
  final String id;
  final String requestId;
  final String senderId;
  final String receiverId;
  final String title;
  final DateTime scheduledDateTime;
  final SessionStatus status;
  final String notes;

  SessionModel({
    required this.id,
    required this.requestId,
    required this.senderId,
    required this.receiverId,
    required this.title,
    required this.scheduledDateTime,
    required this.status,
    this.notes = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'requestId': requestId,
      'senderId': senderId,
      'receiverId': receiverId,
      'title': title,
      'scheduledDateTime': Timestamp.fromDate(scheduledDateTime),
      'status': status.name,
      'notes': notes,
    };
  }

  factory SessionModel.fromMap(Map<String, dynamic> map) {
    return SessionModel(
      id: map['id'] ?? '',
      requestId: map['requestId'] ?? '',
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      title: map['title'] ?? '',
      scheduledDateTime: (map['scheduledDateTime'] as Timestamp).toDate(),
      status: SessionStatus.values.byName(map['status'] ?? 'scheduled'),
      notes: map['notes'] ?? '',
    );
  }
}
