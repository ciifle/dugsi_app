import 'package:flutter/material.dart';
import 'package:kobac/messages/chat_screen.dart';
import 'package:kobac/messages/new_message_screen.dart';
import 'package:kobac/services/message_service.dart';
import 'package:kobac/messages/message_time_utils.dart';

const Color _kPrimaryBlue = Color(0xFF023471);
const Color _kPrimaryGreen = Color(0xFF5AB04B);
const Color _kBgColor = Color(0xFFF0F3F7);
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
  List<ConversationModel> _filteredConversations = [];
  bool _loading = true;
  String? _error;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    print('[Messages Search] query: $query');
    print('[Messages Search] page: MessagesScreen');
    
    setState(() {
      if (query.isEmpty) {
        _filteredConversations = _conversations;
      } else {
        _filteredConversations = _conversations.where((conversation) {
          return conversation.name.toLowerCase().contains(query) ||
                 conversation.lastMessage.toLowerCase().contains(query);
        }).toList();
      }
      print('[Messages Search] total conversations before filter: ${_conversations.length}');
      print('[Messages Search] total conversations after filter: ${_filteredConversations.length}');
    });
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
        _filteredConversations = result.data; // Initialize filtered list
        _error = null;
      } else {
        _conversations = [];
        _filteredConversations = []; // Initialize filtered list
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
      color: Colors.white, // Modern light background
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
                        style: TextStyle(
                          fontSize: 32, 
                          fontWeight: FontWeight.w800, 
                          color: _kPrimaryBlue,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Search Bar
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: _kPrimaryBlue.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search conversations...',
                            prefixIcon: const Icon(Icons.search, color: _kPrimaryBlue),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: _kPrimaryBlue.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _conversations.isEmpty && !_loading ? "No conversations" : "${_filteredConversations.length} Active Chats",
                          style: const TextStyle(
                            fontSize: 12, 
                            color: _kPrimaryBlue, 
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_loading)
                  const Expanded(
                    child: Center(
                      child: CircularProgressIndicator(color: _kPrimaryBlue, strokeWidth: 3),
                    ),
                  )
                else if (_error != null)
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.error_outline_rounded, size: 48, color: Colors.red.shade400),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 16, color: _kTextPrimary, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: _load,
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Try Again'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _kPrimaryBlue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else if (_filteredConversations.isEmpty)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(30),
                            decoration: BoxDecoration(
                              color: _kBgColor,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.chat_bubble_outline_rounded, size: 80, color: _kPrimaryBlue.withOpacity(0.3)),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'No conversations yet',
                            style: TextStyle(fontSize: 20, color: _kPrimaryBlue, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Start a conversation with teachers,\nparents or students.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 15, color: _kTextSecondary.withOpacity(0.8), height: 1.5),
                          ),
                          const SizedBox(height: 32),
                          ElevatedButton(
                            onPressed: _openNewMessage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _kPrimaryBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                              elevation: 8,
                              shadowColor: _kPrimaryBlue.withOpacity(0.4),
                            ),
                            child: const Text('Start Chatting', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _load,
                      color: _kPrimaryGreen,
                      edgeOffset: 20,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                        physics: const BouncingScrollPhysics(),
                        itemCount: _filteredConversations.length,
                        itemBuilder: (context, i) {
                          final c = _filteredConversations[i];
                          final hasUnread = c.unreadCount > 0;
                          
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
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
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _kPrimaryBlue.withOpacity(0.08),
                                        blurRadius: 15,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                    border: Border.all(
                                      color: hasUnread ? _kPrimaryBlue.withOpacity(0.1) : Colors.transparent,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Stack(
                                        children: [
                                          CircleAvatar(
                                            radius: 30,
                                            backgroundColor: _kPrimaryBlue.withOpacity(0.1),
                                            child: Text(
                                              c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                                              style: const TextStyle(
                                                color: _kPrimaryBlue,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 22,
                                              ),
                                            ),
                                          ),
                                          if (hasUnread)
                                            Positioned(
                                              right: 0,
                                              top: 0,
                                              child: Container(
                                                width: 14,
                                                height: 14,
                                                decoration: BoxDecoration(
                                                  color: _kPrimaryGreen,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(color: Colors.white, width: 2),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    c.name,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontSize: 17,
                                                      fontWeight: hasUnread ? FontWeight.w800 : FontWeight.bold,
                                                      color: _kTextPrimary,
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  MessageTimeUtils.formatConversationTime(c.createdAt),
                                                  style: TextStyle(
                                                    fontSize: 12, 
                                                    color: hasUnread ? _kPrimaryBlue : _kTextSecondary,
                                                    fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    c.lastMessage.isEmpty ? 'Tap to start chatting' : c.lastMessage,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontSize: 14, 
                                                      color: hasUnread ? _kTextPrimary : _kTextSecondary,
                                                      fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                                                    ),
                                                  ),
                                                ),
                                                if (hasUnread)
                                                  Container(
                                                    margin: const EdgeInsets.only(left: 8),
                                                    padding: const EdgeInsets.all(6),
                                                    decoration: const BoxDecoration(
                                                      color: _kPrimaryBlue,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: Text(
                                                      '${c.unreadCount}',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
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
              right: 20,
              bottom: widget.embedInParent ? 86 : 24,
              child: FloatingActionButton.extended(
                onPressed: _openNewMessage,
                backgroundColor: _kPrimaryBlue,
                elevation: 12,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                icon: const Icon(Icons.add_comment_rounded, color: Colors.white),
                label: const Text('New Chat', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
