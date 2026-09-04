import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../providers/auth_provider.dart';

// ============================================================
// SELECTED CHAT — passed between screens
// ============================================================

final selectedChatProvider = StateProvider<ChatModel?>((ref) => null);

// ============================================================
// MESSAGES STREAM — for the open chat
// ============================================================

final messagesProvider =
    StreamProvider.family<List<MessageModel>, String>((ref, chatId) {
  final firestore = ref.watch(firestoreServiceProvider);
  return firestore.watchMessages(chatId);
});

// ============================================================
// USER CHATS — conversation list for the signed-in user
// ============================================================

/// Streams chats where the current user is the seeker.
final seekerChatsProvider = StreamProvider<List<ChatModel>>((ref) {
  final firestore = ref.watch(firestoreServiceProvider);
  final auth = ref.watch(authServiceProvider);
  final uid = auth.currentUser?.uid ?? '';
  if (uid.isEmpty) return const Stream.empty();
  return firestore.watchUserChats(uid, 'seekerId');
});

/// Streams chats where the current user is the employer.
final employerChatsProvider = StreamProvider<List<ChatModel>>((ref) {
  final firestore = ref.watch(firestoreServiceProvider);
  final auth = ref.watch(authServiceProvider);
  final uid = auth.currentUser?.uid ?? '';
  if (uid.isEmpty) return const Stream.empty();
  return firestore.watchUserChats(uid, 'employerId');
});
