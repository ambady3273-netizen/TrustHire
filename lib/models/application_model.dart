import 'package:cloud_firestore/cloud_firestore.dart';

/// Status lifecycle: pending → shortlisted → hired | rejected
enum ApplicationStatus { pending, shortlisted, hired, rejected }

extension ApplicationStatusX on ApplicationStatus {
  String get value => toString().split('.').last;
  static ApplicationStatus fromString(String s) {
    return ApplicationStatus.values.firstWhere(
      (e) => e.value == s,
      orElse: () => ApplicationStatus.pending,
    );
  }
}

class ApplicationModel {
  final String id;
  final String jobId;
  final String jobTitle;
  final String companyName;
  final String seekerId;
  final String seekerName;
  final String seekerEmail;
  final ApplicationStatus status;
  final String? coverNote;
  final DateTime appliedAt;

  const ApplicationModel({
    required this.id,
    required this.jobId,
    required this.jobTitle,
    required this.companyName,
    required this.seekerId,
    required this.seekerName,
    required this.seekerEmail,
    required this.status,
    required this.appliedAt,
    this.coverNote,
  });

  factory ApplicationModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime appliedAt;
    final raw = map['appliedAt'];
    appliedAt = raw is Timestamp ? raw.toDate() : DateTime.now();

    return ApplicationModel(
      id: docId,
      jobId: map['jobId'] ?? '',
      jobTitle: map['jobTitle'] ?? '',
      companyName: map['companyName'] ?? '',
      seekerId: map['seekerId'] ?? '',
      seekerName: map['seekerName'] ?? '',
      seekerEmail: map['seekerEmail'] ?? '',
      status: ApplicationStatusX.fromString(map['status'] ?? 'pending'),
      coverNote: map['coverNote'],
      appliedAt: appliedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'jobId': jobId,
        'jobTitle': jobTitle,
        'companyName': companyName,
        'seekerId': seekerId,
        'seekerName': seekerName,
        'seekerEmail': seekerEmail,
        'status': status.value,
        'coverNote': coverNote,
        'appliedAt': Timestamp.fromDate(appliedAt),
      };

  ApplicationModel copyWith({ApplicationStatus? status}) => ApplicationModel(
        id: id,
        jobId: jobId,
        jobTitle: jobTitle,
        companyName: companyName,
        seekerId: seekerId,
        seekerName: seekerName,
        seekerEmail: seekerEmail,
        status: status ?? this.status,
        coverNote: coverNote,
        appliedAt: appliedAt,
      );
}
