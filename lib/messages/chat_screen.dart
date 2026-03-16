import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kobac/services/auth_provider.dart';
import 'package:kobac/services/message_service.dart';
import 'package:kobac/messages/message_time_utils.dart';

const Color _kPrimaryBlue = Color(0xFF023471);
const Color _kPrimaryGreen = Color(0xFF5AB04B);
const Color _kBgColor = Color(0xFFF5F6FA);
const Color _kTextPrimary = Color(0xFF2D3436);
const Color _kTextSecondary = Color(0xFF636E72);

/// Chat with a single user. Loads GET /api/messages/{user_id}, sends via POST /api/messages.
/// Polls every 5 seconds. Messages from current user on right, others on left.
class ChatScreen extends StatefulWidget {
  final int userId;
  final String name;

  const ChatScreen({Key? key, required this.userId, required this.name}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<MessageModel> _messages = [];
  bool _loading = true;
  String? _error;
  bool _sending = false;
  Timer? _pollTimer;
  bool _pollPaused = false; // Pause when API unreachable to avoid log spam

  int? get _currentUserId => context.read<AuthProvider>().user?.id;

  void _startPolling() {
    _pollPaused = false;
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || _pollPaused) return;
      _loadMessages(showLoading: false);
    });
  }

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages({bool showLoading = true}) async {
    if (showLoading) setState(() { _loading = true; _error = null; _pollPaused = false; });
    final result = await MessageService().getMessages(widget.userId);
    if (!mounted) return;
    setState(() {
      if (showLoading) _loading = false;
      if (result is MessageSuccess<List<MessageModel>>) {
        _messages = result.data;
        _error = null;
        _startPolling(); // Keep or resume polling when connection is back
      } else {
        if (showLoading) {
          _error = (result as MessageError).message;
        }
        // Pause polling on error to avoid log spam when API is unreachable
        _pollPaused = true;
        _pollTimer?.cancel();
      }
    });
  }

  Future<void> _send() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _sending) return;
    final currentId = _currentUserId;
    if (currentId == null || currentId <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not identify your account.'), backgroundColor: Colors.red),
        );
      }
      return;
    }
    setState(() => _sending = true);
    final result = await MessageService().sendMessage(widget.userId, text);
    if (!mounted) return;
    setState(() => _sending = false);
    if (result is MessageSuccess<MessageModel>) {
      _textController.clear();
      _messages.add(result.data);
      setState(() {});
      _scrollToBottom();
      _startPolling(); // Resume polling after successful send
      _loadMessages(showLoading: false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text((result as MessageError).message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(String createdAt) {
    if (createdAt.isEmpty) return '';
    try {
      final dt = DateTime.tryParse(createdAt);
      if (dt == null) return '';
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentId = _currentUserId ?? 0;

    return Scaffold(
      backgroundColor: _kBgColor,
      appBar: AppBar(
        title: Text(
          widget.name,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
        ),
        backgroundColor: _kPrimaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          if (_loading && _messages.isEmpty)
            const Expanded(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(color: _kPrimaryBlue),
                ),
              ),
            )
          else if (_error != null && _messages.isEmpty)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline_rounded, size: 56, color: Colors.red.shade400),
                      const SizedBox(height: 16),
                      Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: _kTextPrimary)),
                      const SizedBox(height: 24),
                      TextButton.icon(
                        onPressed: () => _loadMessages(),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Retry'),
                        style: TextButton.styleFrom(foregroundColor: _kPrimaryBlue),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (_messages.isEmpty)
            const Expanded(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded, size: 64, color: _kTextSecondary),
                      SizedBox(height: 16),
                      Text(
                        'Start the conversation',
                        style: TextStyle(fontSize: 16, color: _kTextSecondary),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: _messages.length,
                itemBuilder: (context, i) {
                  final m = _messages[i];
                  final isMe = m.senderId == currentId;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (!isMe) const SizedBox(width: 48),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isMe ? _kPrimaryBlue : Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                bottomLeft: Radius.circular(isMe ? 16 : 4),
                                bottomRight: Radius.circular(isMe ? 4 : 16),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  m.message,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: isMe ? Colors.white : _kTextPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  MessageTimeUtils.formatBubbleTime(m.createdAt),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isMe ? Colors.white70 : _kTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (isMe) const SizedBox(width: 48),
                      ],
                    ),
                  );
                },
              ),
            ),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            color: Colors.white,
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: const TextStyle(color: _kTextSecondary),
                        filled: true,
                        fillColor: _kBgColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: _sending ? _kPrimaryBlue.withOpacity(0.5) : _kPrimaryGreen,
                    borderRadius: BorderRadius.circular(24),
                    child: InkWell(
                      onTap: _sending ? null : _send,
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        child: _sending
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.send_rounded, color: Colors.white, size: 24),
                      ),
                    ),
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
