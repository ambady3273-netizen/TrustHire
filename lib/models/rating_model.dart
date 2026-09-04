import 'package:cloud_firestore/cloud_firestore.dart';

/// A rating left by one participant for the other after a job completes.
///
/// Firestore: ratings/{ratingId}
class RatingModel {
  final String id;
  final String applicationId;
  final String jobId;
  final String jobTitle;

  /// The user who is writing the review.
  final String reviewerId;
  final String reviewerName;

  /// The user being reviewed.
  final String revieweeId;
  final String revieweeName;

  /// 1–5 stars.
  final int stars;
  final String comment;
  final DateTime createdAt;

  RatingModel({
    required this.id,
    required this.applicationId,
    required this.jobId,
    required this.jobTitle,
    required this.reviewerId,
    required this.reviewerName,
    required this.revieweeId,
    required this.revieweeName,
    required this.stars,
    this.comment = '',
    required this.createdAt,
  });

  factory RatingModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parseTs(dynamic raw) {
      if (raw is Timestamp) return raw.toDate();
      return DateTime.now();
    }

    return RatingModel(
      id: docId,
      applicationId: map['applicationId'] ?? '',
      jobId: map['jobId'] ?? '',
      jobTitle: map['jobTitle'] ?? '',
      reviewerId: map['reviewerId'] ?? '',
      reviewerName: map['reviewerName'] ?? '',
      revieweeId: map['revieweeId'] ?? '',
      revieweeName: map['revieweeName'] ?? '',
      stars: (map['stars'] ?? 0).toInt(),
      comment: map['comment'] ?? '',
      createdAt: parseTs(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'applicationId': applicationId,
      'jobId': jobId,
      'jobTitle': jobTitle,
      'reviewerId': reviewerId,
      'reviewerName': reviewerName,
      'revieweeId': revieweeId,
      'revieweeName': revieweeName,
      'stars': stars,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
