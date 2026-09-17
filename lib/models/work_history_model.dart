import 'package:cloud_firestore/cloud_firestore.dart';

/// A single completed job entry in a seeker's work portfolio.
/// Created automatically when an application's status → 'completed'.
class WorkHistoryModel {
  final String id;
  final String seekerId;
  final String employerId;
  final String jobId;
  final String jobTitle;
  final String companyName;
  final String location;
  final double salary;
  final String category;
  final DateTime completedAt;
  final double rating;       // employer's star rating (0 = not yet rated)
  final String review;       // employer's written review

  const WorkHistoryModel({
    required this.id,
    required this.seekerId,
    required this.employerId,
    required this.jobId,
    required this.jobTitle,
    required this.companyName,
    required this.location,
    required this.salary,
    required this.category,
    required this.completedAt,
    this.rating  = 0,
    this.review  = '',
  });

  factory WorkHistoryModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime completedAt;
    final raw = map['completedAt'];
    completedAt = raw is Timestamp ? raw.toDate() : DateTime.now();

    return WorkHistoryModel(
      id:          docId,
      seekerId:    map['seekerId']    ?? '',
      employerId:  map['employerId']  ?? '',
      jobId:       map['jobId']       ?? '',
      jobTitle:    map['jobTitle']    ?? '',
      companyName: map['companyName'] ?? '',
      location:    map['location']    ?? '',
      salary:      (map['salary']     ?? 0).toDouble(),
      category:    map['category']    ?? '',
      completedAt: completedAt,
      rating:      (map['rating']     ?? 0).toDouble(),
      review:      map['review']      ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'seekerId':    seekerId,
    'employerId':  employerId,
    'jobId':       jobId,
    'jobTitle':    jobTitle,
    'companyName': companyName,
    'location':    location,
    'salary':      salary,
    'category':    category,
    'completedAt': Timestamp.fromDate(completedAt),
    'rating':      rating,
    'review':      review,
  };
}
