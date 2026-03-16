import 'package:flutter/material.dart';
import 'package:kobac/messages/chat_screen.dart';
import 'package:kobac/messages/new_message_screen.dart';
import 'package:kobac/services/message_service.dart';
import 'package:kobac/messages/message_time_utils.dart';

const Color _kPrimaryBlue = Color(0xFF023471);
const Color _kPrimaryGreen = Color(0xFF5AB04B);
const Color _kBgColor = Color(0xFFF0F3F7);
const Color _kCardColor = Colors.white;
const Color _kTextPrimary = Color(0xFF2D3436);
const Color _kTextSecondary = Color(0xFF636E72);

/// Shared Messages (conversations list) screen for all roles.
/// Calls GET /api/messages and opens ChatScreen on tap.
class MessagesScreen extends StatefulWidget {
  /// When true, screen is embedded (e.g. in school admin bottom nav) and may omit scaffold chrome.
  final bool embedInParent;

  const MessagesScreen({Key? key, this.embedInParent = false}) : super(key: key);

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  List<ConversationModel> _conversations = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await MessageService().getConversations();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result is MessageSuccess<List<ConversationModel>>) {
        _conversations = result.data;
        _error = null;
      } else {
        _conversations = [];
        _error = (result as MessageError).message;
      }
    });
  }

  void _openNewMessage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const NewMessageScreen(),
      ),
    ).then((_) {
      if (mounted) _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final content = Container(
      color: _kBgColor,
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Messages',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _kPrimaryBlue),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _conversations.isEmpty && !_loading ? "No messages yet" : "${_conversations.length} conversation(s)",
                    style: const TextStyle(fontSize: 14, color: _kTextSecondary, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            if (_loading)
              const Expanded(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(color: _kPrimaryBlue),
                  ),
                ),
              )
            else if (_error != null)
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline_rounded, size: 56, color: Colors.red.shade400),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16, color: _kTextPrimary),
                        ),
                        const SizedBox(height: 24),
                        TextButton.icon(
                          onPressed: _load,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Retry'),
                          style: TextButton.styleFrom(foregroundColor: _kPrimaryBlue),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else if (_conversations.isEmpty)
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
                          'No messages yet',
                          style: TextStyle(fontSize: 18, color: _kTextSecondary, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _load,
                  color: _kPrimaryGreen,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    itemCount: _conversations.length,
                    itemBuilder: (context, i) {
                      final c = _conversations[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatScreen(
                                    userId: c.userId,
                                    name: c.name,
                                  ),
                                ),
                              ).then((_) => _load());
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _kCardColor,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: _kPrimaryBlue.withOpacity(0.06),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 26,
                                    backgroundColor: _kPrimaryBlue.withOpacity(0.12),
                                    child: const Icon(Icons.person_rounded, color: _kPrimaryBlue, size: 28),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          c.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: _kPrimaryBlue,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          c.lastMessage.isEmpty ? '—' : c.lastMessage,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 14, color: _kTextSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    MessageTimeUtils.formatConversationTime(c.createdAt),
                                    style: const TextStyle(fontSize: 12, color: _kTextSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
            Positioned(
              right: 18,
              bottom: widget.embedInParent ? 86 : 24,
              child: FloatingActionButton(
                onPressed: _openNewMessage,
                backgroundColor: _kPrimaryGreen,
                child: const Icon(Icons.add_rounded, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );

    if (widget.embedInParent) return content;
    return Scaffold(
      backgroundColor: _kBgColor,
      appBar: AppBar(
        title: const Text('Messages', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: _kPrimaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: content,
    );
  }
}
