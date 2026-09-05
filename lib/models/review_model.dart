import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String reviewId;
  final String jobId;
  final String applicationId;
  final String reviewerId;
  final String reviewedUserId;
  final String reviewerRole;
  final int rating;
  final String comment;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  ReviewModel({
    required this.reviewId,
    required this.jobId,
    required this.applicationId,
    required this.reviewerId,
    required this.reviewedUserId,
    required this.reviewerRole,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ReviewModel.fromMap(Map<String, dynamic> map, String documentId) {
    return ReviewModel(
      reviewId: documentId,
      jobId: map['jobId'] ?? '',
      applicationId: map['applicationId'] ?? '',
      reviewerId: map['reviewerId'] ?? '',
      reviewedUserId: map['reviewedUserId'] ?? '',
      reviewerRole: map['reviewerRole'] ?? '',
      rating: (map['rating'] ?? 0).toInt(),
      comment: map['comment'] ?? '',
      createdAt: map['createdAt'] is Timestamp
          ? map['createdAt']
          : Timestamp.now(),
      updatedAt: map['updatedAt'] is Timestamp
          ? map['updatedAt']
          : Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'jobId': jobId,
      'applicationId': applicationId,
      'reviewerId': reviewerId,
      'reviewedUserId': reviewedUserId,
      'reviewerRole': reviewerRole,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
