import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/chat_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';

/// Lists all conversations for the signed-in user.
/// Seekers see chats where they are the seeker.
/// Employers see chats where they are the employer.
class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);
    final role = userAsync.maybeWhen(
      data: (u) => u?.role ?? '',
      orElse: () => '',
    );

    final chatsAsync = role == 'employer'
        ? ref.watch(employerChatsProvider)
        : ref.watch(seekerChatsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: chatsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline,
                    size: 48, color: Color(0xFFE15B4F)),
                const SizedBox(height: 12),
                Text('Could not load messages.\n$e',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFF5B6478))),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: role == 'employer'
                      ? () => ref.invalidate(employerChatsProvider)
                      : () => ref.invalidate(seekerChatsProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B2A4A),
                      foregroundColor: Colors.white),
                ),
              ],
            ),
          ),
        ),
        data: (chats) {
          if (chats.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.chat_bubble_outline,
                        size: 64, color: Color(0xFF5B6478)),
                    const SizedBox(height: 16),
                    Text(
                      role == 'employer'
                          ? 'No conversations yet.\nAccept an applicant to start chatting.'
                          : 'No conversations yet.\nYour chats will appear here once an employer accepts your application.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Color(0xFF5B6478), height: 1.5),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.only(top: 8, bottom: 24),
            itemCount: chats.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, indent: 72),
            itemBuilder: (context, i) =>
                _ChatTile(chat: chats[i], role: role),
          );
        },
      ),
    );
  }
}

class _ChatTile extends ConsumerWidget {
  final ChatModel chat;
  final String role;
  const _ChatTile({required this.chat, required this.role});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final otherName =
        role == 'employer' ? chat.seekerName : chat.employerName;
    final timeLabel = chat.lastMessageAt != null
        ? _formatTime(chat.lastMessageAt!)
        : '';

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: const Color(0xFF1B2A4A).withAlpha(20),
        child: Text(
          otherName.isNotEmpty ? otherName[0].toUpperCase() : '?',
          style: const TextStyle(
              color: Color(0xFF1B2A4A),
              fontWeight: FontWeight.w700,
              fontSize: 17),
        ),
      ),
      title: Text(
        otherName,
        style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13.5,
            color: Color(0xFF1B2A4A)),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            chat.jobTitle,
            style:
                const TextStyle(fontSize: 11, color: Color(0xFF5B6478)),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            chat.lastMessage.isNotEmpty
                ? chat.lastMessage
                : 'No messages yet',
            style: TextStyle(
              fontSize: 12,
              color: chat.lastMessage.isNotEmpty
                  ? const Color(0xFF1F2430)
                  : const Color(0xFF5B6478),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      trailing: timeLabel.isNotEmpty
          ? Text(timeLabel,
              style: const TextStyle(
                  fontSize: 10.5, color: Color(0xFF5B6478)))
          : null,
      onTap: () {
        ref.read(selectedChatProvider.notifier).state = chat;
        Navigator.pushNamed(context, '/chatScreen');
      },
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return DateFormat('h:mm a').format(dt);
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return DateFormat('EEE').format(dt);
    return DateFormat('d MMM').format(dt);
  }
}
