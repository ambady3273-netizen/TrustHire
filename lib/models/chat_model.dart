import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents one conversation between a job seeker and an employer,
/// tied to a specific application.
///
/// Firestore: chats/{chatId}
class ChatModel {
  final String id;
  final String applicationId;
  final String jobId;
  final String jobTitle;
  final String seekerId;
  final String seekerName;
  final String employerId;
  final String employerName;
  final String lastMessage;
  final String lastMessageSenderId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastMessageAt;

  ChatModel({
    required this.id,
    required this.applicationId,
    required this.jobId,
    required this.jobTitle,
    required this.seekerId,
    required this.seekerName,
    required this.employerId,
    required this.employerName,
    this.lastMessage = '',
    this.lastMessageSenderId = '',
    required this.createdAt,
    required this.updatedAt,
    this.lastMessageAt,
  });

  factory ChatModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parseTs(dynamic raw) {
      if (raw is Timestamp) return raw.toDate();
      return DateTime.now();
    }

    return ChatModel(
      id: docId,
      applicationId: map['applicationId'] ?? '',
      jobId: map['jobId'] ?? '',
      jobTitle: map['jobTitle'] ?? '',
      seekerId: map['seekerId'] ?? '',
      seekerName: map['seekerName'] ?? '',
      employerId: map['employerId'] ?? '',
      employerName: map['employerName'] ?? '',
      lastMessage: map['lastMessage'] ?? '',
      lastMessageSenderId: map['lastMessageSenderId'] ?? '',
      createdAt: parseTs(map['createdAt']),
      updatedAt: parseTs(map['updatedAt']),
      lastMessageAt: map['lastMessageAt'] != null
          ? parseTs(map['lastMessageAt'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'applicationId': applicationId,
      'jobId': jobId,
      'jobTitle': jobTitle,
      'seekerId': seekerId,
      'seekerName': seekerName,
      'employerId': employerId,
      'employerName': employerName,
      'lastMessage': lastMessage,
      'lastMessageSenderId': lastMessageSenderId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'lastMessageAt':
          lastMessageAt != null ? Timestamp.fromDate(lastMessageAt!) : null,
    };
  }

  /// The chat ID is derived deterministically from applicationId so that
  /// duplicate chats can never be created for the same application.
  static String chatIdFromApplicationId(String applicationId) =>
      'chat_$applicationId';
}
