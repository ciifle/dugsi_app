import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kobac/services/auth_provider.dart';
import 'package:kobac/services/message_service.dart';
import 'package:kobac/messages/message_time_utils.dart';

const Color _kPrimaryBlue = Color(0xFF023471);
const Color _kPrimaryGreen = Color(0xFF5AB04B);
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

  @override
  Widget build(BuildContext context) {
    final currentId = _currentUserId ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC), // Modern light chat background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: false,
        leadingWidth: 40,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _kTextPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: _kPrimaryBlue.withOpacity(0.1),
              child: Text(
                widget.name.isNotEmpty ? widget.name[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: _kPrimaryBlue, 
                  fontWeight: FontWeight.bold, 
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.name,
                    style: const TextStyle(
                      fontSize: 16, 
                      fontWeight: FontWeight.bold, 
                      color: _kTextPrimary,
                    ),
                  ),
                  const Text(
                    'Online',
                    style: TextStyle(
                      fontSize: 11, 
                      color: _kPrimaryGreen, 
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert_rounded, color: _kTextSecondary),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading && _messages.isEmpty
                ? const Center(child: CircularProgressIndicator(color: _kPrimaryBlue, strokeWidth: 3))
                : _messages.isEmpty
                    ? Center(child: _buildEmptyState())
                    : RefreshIndicator(        
                        onRefresh: () => _loadMessages(showLoading: false),
                        color: _kPrimaryGreen,
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
                          physics: const BouncingScrollPhysics(),
                          itemCount: _messages.length,
                          itemBuilder: (context, i) {
                            final m = _messages[i];
                            final isMe = m.senderId == currentId;
                            final showTime = i == 0 || _shouldShowTime(m, _messages[i-1]);

                            return Column(
                              children: [
                                if (showTime)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    child: Center(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(10),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.03),
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                        child: Text(
                                          MessageTimeUtils.formatMessageDate(m.createdAt),
                                          style: TextStyle(fontSize: 11, color: _kTextSecondary, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ),
                                  ),
                                Align(
                                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                                  child: Container(
                                    margin: EdgeInsets.only(
                                      bottom: 6,
                                      left: isMe ? 60 : 0,
                                      right: isMe ? 0 : 60,
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isMe ? _kPrimaryBlue : Colors.white,
                                      borderRadius: BorderRadius.only(
                                        topLeft: const Radius.circular(18),
                                        topRight: const Radius.circular(18),
                                        bottomLeft: Radius.circular(isMe ? 18 : 4),
                                        bottomRight: Radius.circular(isMe ? 4 : 18),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.04),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          m.message,
                                          style: TextStyle(
                                            color: isMe ? Colors.white : _kTextPrimary,
                                            fontSize: 15,
                                            height: 1.3,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          MessageTimeUtils.formatBubbleTime(m.createdAt),
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: isMe ? Colors.white.withOpacity(0.7) : _kTextSecondary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
          ),
          if (_error != null)
            Container(
              color: Colors.red.shade50,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.error_outline, size: 16, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
              ),
            ],
          ),
          child: Icon(Icons.chat_bubble_outline_rounded, size: 48, color: _kPrimaryBlue.withOpacity(0.2)),
        ),
        const SizedBox(height: 16),
        Text(
          'Say hello to ${widget.name.split(' ')[0]}!',
          style: TextStyle(color: _kTextSecondary, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildInput() {
    return Container(
      padding: EdgeInsets.fromLTRB(12, 8, 12, 8 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F3F6),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _textController,
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(color: _kTextSecondary, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
                maxLines: 4,
                minLines: 1,
                style: const TextStyle(fontSize: 15, color: _kTextPrimary),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _sending ? null : _send,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _sending ? _kPrimaryBlue.withOpacity(0.5) : _kPrimaryBlue,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _kPrimaryBlue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: _sending
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  bool _shouldShowTime(MessageModel current, MessageModel previous) {
    try {
      final cAt = DateTime.parse(current.createdAt);
      final pAt = DateTime.parse(previous.createdAt);
      return cAt.difference(pAt).inMinutes > 30;
    } catch (_) {
      return false;
    }
  }
}
