import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/job_provider.dart';
import '../../theme.dart';

/// Real-time chat screen.
/// Reads the active chat from [selectedChatProvider].
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  bool _sending = false;

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool animated = true}) {
    if (!_scroll.hasClients) return;
    final target = _scroll.position.maxScrollExtent;
    if (animated) {
      _scroll.animateTo(target,
          duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
    } else {
      _scroll.jumpTo(target);
    }
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty) return;

    final chat = ref.read(selectedChatProvider);
    final uid = ref.read(currentFirebaseUserProvider)?.uid;
    if (chat == null || uid == null) return;

    final isSeeker = uid == chat.seekerId;
    final receiverId = isSeeker ? chat.employerId : chat.seekerId;

    setState(() => _sending = true);
    _input.clear();

    try {
      await ref.read(firestoreServiceProvider).sendMessage(
            chatId: chat.id,
            senderId: uid,
            receiverId: receiverId,
            text: text,
          );
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _scrollToBottom());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to send: $e'),
        backgroundColor: AppColors.coral,
      ));
      // Restore text so the user doesn't lose their message.
      _input.text = text;
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chat = ref.watch(selectedChatProvider);
    final uid = ref.watch(currentFirebaseUserProvider)?.uid;

    if (chat == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chat')),
        body: const Center(child: Text('No conversation selected.')),
      );
    }

    final isSeeker = uid == chat.seekerId;
    final otherName = isSeeker ? chat.employerName : chat.seekerName;
    final messagesAsync = ref.watch(messagesProvider(chat.id));

    // Mark messages as read whenever the screen is open.
    if (uid != null) {
      ref.read(firestoreServiceProvider).markMessagesRead(
            chatId: chat.id,
            receiverId: uid,
          );
    }

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.ink.withAlpha(20),
              child: Text(
                otherName.isNotEmpty ? otherName[0].toUpperCase() : '?',
                style: const TextStyle(
                    color: AppColors.ink, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(otherName,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis),
                  Text(chat.jobTitle,
                      style: const TextStyle(
                          fontSize: 10.5, color: AppColors.mute),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── message list ──────────────────────────────────
          Expanded(
            child: messagesAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text('Error: $e',
                    style: const TextStyle(color: AppColors.coral)),
              ),
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.chat_bubble_outline,
                            size: 56, color: AppColors.mute),
                        const SizedBox(height: 12),
                        Text(
                          'No messages yet.\nSay hello to ${otherName.split(' ').first}!',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: AppColors.mute, height: 1.5),
                        ),
                      ],
                    ),
                  );
                }

                // Scroll to bottom when new messages arrive.
                WidgetsBinding.instance.addPostFrameCallback(
                    (_) => _scrollToBottom(animated: false));

                return ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    final msg = messages[i];
                    final isMine = msg.senderId == uid;
                    return _MessageBubble(
                        message: msg, isMine: isMine);
                  },
                );
              },
            ),
          ),

          // ── input bar ─────────────────────────────────────
          Container(
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(
                12,
                8,
                12,
                8 + MediaQuery.of(context).viewInsets.bottom),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      minLines: 1,
                      maxLines: 4,
                      textCapitalization:
                          TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Type a message…',
                        filled: true,
                        fillColor: AppColors.paper,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedBuilder(
                    animation: _input,
                    builder: (context, _) {
                      final hasText = _input.text.trim().isNotEmpty;
                      return GestureDetector(
                        onTap: (hasText && !_sending) ? _send : null,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: (hasText && !_sending)
                                ? AppColors.ink
                                : AppColors.border,
                            shape: BoxShape.circle,
                          ),
                          child: _sending
                              ? const Padding(
                                  padding: EdgeInsets.all(10),
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white))
                              : const Icon(Icons.send_rounded,
                                  color: Colors.white, size: 20),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Message bubble
// ─────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final dynamic message;
  final bool isMine;
  const _MessageBubble({required this.message, required this.isMine});

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('h:mm a').format(message.sentAt);

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.72),
        margin: EdgeInsets.only(
          top: 4,
          bottom: 4,
          left: isMine ? 48 : 0,
          right: isMine ? 0 : 48,
        ),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMine ? AppColors.ink : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMine ? 16 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 16),
          ),
          border: isMine
              ? null
              : Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: isMine
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                fontSize: 13.5,
                color: isMine ? Colors.white : AppColors.text,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(
                fontSize: 10,
                color: isMine
                    ? Colors.white.withAlpha(160)
                    : AppColors.mute,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
