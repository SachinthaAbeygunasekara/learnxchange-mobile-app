import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String id;
  final String reviewerId;
  final String reviewerName;
  final String reviewerPhoto;
  final String comment;
  final double rating;
  final DateTime timestamp;

  ReviewModel({
    required this.id,
    required this.reviewerId,
    required this.reviewerName,
    required this.reviewerPhoto,
    required this.comment,
    required this.rating,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reviewerId': reviewerId,
      'reviewerName': reviewerName,
      'reviewerPhoto': reviewerPhoto,
      'comment': comment,
      'rating': rating,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory ReviewModel.fromMap(Map<String, dynamic> map) {
    return ReviewModel(
      id: map['id'] ?? '',
      reviewerId: map['reviewerId'] ?? '',
      reviewerName: map['reviewerName'] ?? '',
      reviewerPhoto: map['reviewerPhoto'] ?? '',
      comment: map['comment'] ?? '',
      rating: (map['rating'] ?? 0).toDouble(),
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }
}
