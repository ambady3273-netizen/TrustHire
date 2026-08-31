import 'package:cloud_firestore/cloud_firestore.dart';

<<<<<<< HEAD
// ============================================================
// APPLICATION STATUS CONSTANTS
// Single source of truth — used in services, providers, and UI.
// ============================================================
class ApplicationStatus {
  /// Seeker just submitted the application.
  static const String applied = 'applied';

  /// Employer opened the application for review.
  static const String underReview = 'under_review';

  /// Employer shortlisted the candidate.
  static const String shortlisted = 'shortlisted';

  /// Employer accepted the candidate.
  static const String accepted = 'accepted';

  /// Employer rejected the candidate.
  static const String rejected = 'rejected';

  /// Seeker withdrew their own application.
  static const String withdrawn = 'withdrawn';

  /// Employer or admin cancelled the posting/application.
  static const String cancelled = 'cancelled';

  /// Job was completed successfully.
  static const String completed = 'completed';

  // ── UI helpers ─────────────────────────────────────────────

  /// Human-readable label for each status.
  static String label(String status) {
    switch (status) {
      case applied:
        return 'Applied';
      case underReview:
        return 'Under Review';
      case shortlisted:
        return 'Shortlisted';
      case accepted:
        return 'Accepted';
      case rejected:
        return 'Rejected';
      case withdrawn:
        return 'Withdrawn';
      case cancelled:
        return 'Cancelled';
      case completed:
        return 'Completed';
      default:
        return 'Unknown';
    }
  }

  /// Whether the employer can still act on this status.
  static bool isActionable(String status) =>
      status == applied || status == underReview || status == shortlisted;

  /// Whether the seeker can still withdraw.
  static bool isWithdrawable(String status) =>
      status == applied || status == underReview || status == shortlisted;
}

// ============================================================
// APPLICATION MODEL
// ============================================================

/// Represents a single job application stored in Firestore under
/// the `applications` collection.
=======
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

>>>>>>> origin/user1
class ApplicationModel {
  final String id;
  final String jobId;
  final String jobTitle;
  final String companyName;
<<<<<<< HEAD
  final String employerId;
  final String seekerId;
  final String seekerName;
  final String seekerEmail;

  /// One of the [ApplicationStatus] constants.
  final String status;

  final DateTime appliedAt;
  final DateTime updatedAt;

  ApplicationModel({
=======
  final String seekerId;
  final String seekerName;
  final String seekerEmail;
  final ApplicationStatus status;
  final String? coverNote;
  final DateTime appliedAt;

  const ApplicationModel({
>>>>>>> origin/user1
    required this.id,
    required this.jobId,
    required this.jobTitle,
    required this.companyName,
<<<<<<< HEAD
    required this.employerId,
    required this.seekerId,
    required this.seekerName,
    required this.seekerEmail,
    this.status = ApplicationStatus.applied,
    required this.appliedAt,
    required this.updatedAt,
  });

  // ============================================================
  // FROM FIRESTORE
  // ============================================================

  factory ApplicationModel.fromMap(
    Map<String, dynamic> map,
    String docId,
  ) {
    DateTime parseDate(dynamic raw) {
      if (raw is Timestamp) return raw.toDate();
      return DateTime.now();
    }
=======
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
>>>>>>> origin/user1

    return ApplicationModel(
      id: docId,
      jobId: map['jobId'] ?? '',
      jobTitle: map['jobTitle'] ?? '',
      companyName: map['companyName'] ?? '',
<<<<<<< HEAD
      employerId: map['employerId'] ?? '',
      seekerId: map['seekerId'] ?? '',
      seekerName: map['seekerName'] ?? '',
      seekerEmail: map['seekerEmail'] ?? '',
      status: map['status'] ?? ApplicationStatus.applied,
      appliedAt: parseDate(map['appliedAt']),
      updatedAt: parseDate(map['updatedAt'] ?? map['appliedAt']),
    );
  }

  // ============================================================
  // TO FIRESTORE
  // ============================================================

  Map<String, dynamic> toMap() {
    return {
      'jobId': jobId,
      'jobTitle': jobTitle,
      'companyName': companyName,
      'employerId': employerId,
      'seekerId': seekerId,
      'seekerName': seekerName,
      'seekerEmail': seekerEmail,
      'status': status,
      'appliedAt': Timestamp.fromDate(appliedAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // ============================================================
  // COPY WITH
  // ============================================================

  ApplicationModel copyWith({
    String? id,
    String? jobId,
    String? jobTitle,
    String? companyName,
    String? employerId,
    String? seekerId,
    String? seekerName,
    String? seekerEmail,
    String? status,
    DateTime? appliedAt,
    DateTime? updatedAt,
  }) {
    return ApplicationModel(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      jobTitle: jobTitle ?? this.jobTitle,
      companyName: companyName ?? this.companyName,
      employerId: employerId ?? this.employerId,
      seekerId: seekerId ?? this.seekerId,
      seekerName: seekerName ?? this.seekerName,
      seekerEmail: seekerEmail ?? this.seekerEmail,
      status: status ?? this.status,
      appliedAt: appliedAt ?? this.appliedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
=======
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
>>>>>>> origin/user1
}
