import 'package:cloud_firestore/cloud_firestore.dart';

/// Notification types used across all roles.
enum NotificationType {
  jobApproved,     // employer: their posted job passed AI check
  jobRejected,     // employer: job was flagged / rejected by admin
  newApplicant,    // employer: someone applied to their job
  applicationSent, // seeker:   their application was submitted
  shortlisted,     // seeker:   employer shortlisted them
  escrowFunded,    // seeker:   employer deposited escrow for their job
  paymentReleased, // seeker:   escrow was released to them
  reviewReceived,  // both:     they got a new review
  kycApproved,     // both:     identity verification passed
  kycRejected,     // both:     identity verification failed
  general,         // catch-all
}

extension NotificationTypeX on NotificationType {
  String get value => toString().split('.').last;

  static NotificationType fromString(String s) {
    return NotificationType.values.firstWhere(
      (e) => e.value == s,
      orElse: () => NotificationType.general,
    );
  }
}

class NotificationModel {
  final String id;
  final String userId;       // owner of this notification
  final String title;
  final String body;
  final NotificationType type;
  final bool isRead;
  final String? actionRoute;  // optional deep-link route (e.g. '/jobDetails')
  final String? actionId;     // optional document id for deep-link
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.actionRoute,
    this.actionId,
  });

  // ── Firestore ──────────────────────────────────────────────

  factory NotificationModel.fromMap(
    Map<String, dynamic> map,
    String docId,
  ) {
    DateTime createdAt;
    final raw = map['createdAt'];
    if (raw is Timestamp) {
      createdAt = raw.toDate();
    } else {
      createdAt = DateTime.now();
    }

    return NotificationModel(
      id: docId,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      type: NotificationTypeX.fromString(map['type'] ?? ''),
      isRead: map['isRead'] ?? false,
      actionRoute: map['actionRoute'],
      actionId: map['actionId'],
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'title': title,
        'body': body,
        'type': type.value,
        'isRead': isRead,
        'actionRoute': actionRoute,
        'actionId': actionId,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  NotificationModel copyWith({bool? isRead}) => NotificationModel(
        id: id,
        userId: userId,
        title: title,
        body: body,
        type: type,
        isRead: isRead ?? this.isRead,
        actionRoute: actionRoute,
        actionId: actionId,
        createdAt: createdAt,
      );
}
