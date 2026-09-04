import 'package:cloud_firestore/cloud_firestore.dart';

/// A single message inside a chat.
///
/// Firestore: chats/{chatId}/messages/{messageId}
class MessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final bool isRead;
  final DateTime sentAt;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    this.isRead = false,
    required this.sentAt,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parseTs(dynamic raw) {
      if (raw is Timestamp) return raw.toDate();
      return DateTime.now();
    }

    return MessageModel(
      id: docId,
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      text: map['text'] ?? '',
      isRead: map['isRead'] ?? false,
      sentAt: parseTs(map['sentAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'isRead': isRead,
      'sentAt': Timestamp.fromDate(sentAt),
    };
  }
}
