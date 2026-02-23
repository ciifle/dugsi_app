import 'package:flutter/material.dart';

/// Brand / Style (must match your dashboard)
const Color kPrimaryBlue = Color(0xFF023471);
const Color kPrimaryGreen = Color(0xFF5AB04B);
const Color kBgColor = Color(0xFFF0F3F7);
const Color kCardColor = Colors.white;

const double kPadding = 20.0;

class MessageScreen extends StatefulWidget {
  final String? name;
  final String? message;
  final String? time;
  final String? avatarUrl;

  /// When true: do NOT render Scaffold / do NOT render bottom nav / just body
  final bool embedInParent;

  const MessageScreen({
    Key? key,
    this.name,
    this.message,
    this.time,
    this.avatarUrl,
    this.embedInParent = false,
  }) : super(key: key);

  static const List<Map<String, dynamic>> dummyMessages = [
    {'text': 'Hello, how can I help you today?', 'sent': false, 'time': '09:30'},
    {'text': 'I want to know more about the exam schedule.', 'sent': true, 'time': '09:31'},
    {'text': "Sure! The schedule will be available in your portal this week.", 'sent': false, 'time': '09:32'},
    {'text': "Thank you so much!", 'sent': true, 'time': '09:33'},
  ];

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  late List<Map<String, dynamic>> _messages;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();

    final bool hasSingleMessage = widget.message != null && widget.time != null;
    _messages = hasSingleMessage
        ? [
            {'text': widget.message ?? '', 'sent': false, 'time': widget.time ?? ''},
          ]
        : List<Map<String, dynamic>>.from(MessageScreen.dummyMessages);

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(
      _scroll.position.maxScrollExtent,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final now = TimeOfDay.now().format(context);
    setState(() {
      _messages.add({'text': text, 'sent': true, 'time': now});
    });

    _controller.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  Widget build(BuildContext context) {
    final content = Container(
      color: kBgColor,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 3D header card (no drawer, no notification icon)
            _MessagesHeaderCard(
              title: widget.name ?? "Messages",
              subtitle: null,
            ),

            // Chat list
            Expanded(
              child: ListView.separated(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                itemCount: _messages.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, idx) {
                  final msg = _messages[idx];
                  final bool isSent = (msg['sent'] as bool?) ?? false;

                  return Align(
                    alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.78,
                      ),
                      child: _ChatBubble(
                        text: (msg['text'] ?? '').toString(),
                        time: (msg['time'] ?? '').toString(),
                        isSent: isSent,
                      ),
                    ),
                  );
                },
              ),
            ),

            // Input bar (3D)
            _Composer(
              controller: _controller,
              onSend: _sendMessage,
              onAttach: () {},
            ),

            // IMPORTANT: add bottom padding so it never clashes with parent's bottom nav
            if (widget.embedInParent) const SizedBox(height: 12),
          ],
        ),
      ),
    );

    if (widget.embedInParent) return content;
    return Scaffold(backgroundColor: kBgColor, body: content);
  }
}

/// ===== Header Card (same 3D dashboard style, no menu, no notification) =====
class _MessagesHeaderCard extends StatelessWidget {
  final String title;
  final String? subtitle;

  const _MessagesHeaderCard({
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return Padding(
      padding: EdgeInsets.fromLTRB(kPadding, top + 8, kPadding, 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: kCardColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white, width: 1.4),
          boxShadow: [
            BoxShadow(color: Colors.white, blurRadius: 14, offset: const Offset(-4, -4)),
            BoxShadow(color: kPrimaryBlue.withOpacity(0.12), blurRadius: 26, offset: const Offset(8, 10)),
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 14, offset: const Offset(4, 6)),
          ],
        ),
        child: Row(
          children: [
            // Left: Messages icon (no drawer)
            const _NeumorphicCircle(
              child: Icon(Icons.chat_bubble_outline_rounded, color: kPrimaryBlue, size: 22),
            ),
            const SizedBox(width: 14),

            // Title + optional subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: kPrimaryBlue,
                    ),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ===== Chat Bubble (3D, brand colors) =====
class _ChatBubble extends StatelessWidget {
  final String text;
  final String time;
  final bool isSent;

  const _ChatBubble({
    required this.text,
    required this.time,
    required this.isSent,
  });

  @override
  Widget build(BuildContext context) {
    // Received: white neumorphic bubble
    // Sent: subtle blue tint (brand) but still “clean”, not crystal
    final bg = isSent ? const Color(0xFFEAF2FF) : kCardColor;

    final border = Border.all(
      color: isSent ? kPrimaryBlue.withOpacity(0.10) : Colors.white.withOpacity(0.9),
      width: 1.2,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(20),
          topRight: const Radius.circular(20),
          bottomLeft: Radius.circular(isSent ? 20 : 6),
          bottomRight: Radius.circular(isSent ? 6 : 20),
        ),
        border: border,
        boxShadow: [
          BoxShadow(color: Colors.white, blurRadius: 10, offset: const Offset(-3, -3)),
          BoxShadow(color: kPrimaryBlue.withOpacity(0.10), blurRadius: 18, offset: const Offset(6, 8)),
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(3, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            text,
            style: TextStyle(
              color: isSent ? kPrimaryBlue : kPrimaryBlue,
              fontWeight: FontWeight.w600,
              fontSize: 15.6,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                time,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              if (isSent) ...[
                const SizedBox(width: 4),
                Icon(Icons.done_all, size: 16, color: kPrimaryBlue.withOpacity(0.55)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// ===== Composer (3D input + send button) =====
class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onAttach;

  const _Composer({
    required this.controller,
    required this.onSend,
    required this.onAttach,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        decoration: BoxDecoration(
          color: kCardColor,
          border: const Border(
            top: BorderSide(color: Color(0xFFDFE2E7), width: 1.1),
          ),
          boxShadow: [
            BoxShadow(color: kPrimaryBlue.withOpacity(0.06), blurRadius: 18, offset: const Offset(0, -6)),
          ],
        ),
        child: Row(
          children: [
            // Attach (neumorphic circle)
            GestureDetector(
              onTap: onAttach,
              child: const _NeumorphicCircle(
                child: Icon(Icons.attach_file_rounded, color: kPrimaryGreen, size: 22),
              ),
            ),
            const SizedBox(width: 10),

            // Input (neumorphic pill)
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F6FA),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.white.withOpacity(0.9), width: 1),
                  boxShadow: [
                    BoxShadow(color: Colors.white, blurRadius: 10, offset: const Offset(-3, -3)),
                    BoxShadow(color: kPrimaryBlue.withOpacity(0.08), blurRadius: 14, offset: const Offset(4, 6)),
                  ],
                ),
                child: TextField(
                  controller: controller,
                  cursorColor: kPrimaryGreen,
                  minLines: 1,
                  maxLines: 5,
                  style: const TextStyle(
                    color: kPrimaryBlue,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: "Type a message...",
                    hintStyle: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => onSend(),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Send (3D brand button)
            GestureDetector(
              onTap: onSend,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0A4A8C), kPrimaryBlue, Color(0xFF022A5C)],
                  ),
                  border: Border.all(color: Colors.white.withOpacity(0.35), width: 1.5),
                  boxShadow: [
                    BoxShadow(color: Colors.white.withOpacity(0.35), blurRadius: 6, offset: const Offset(-2, -2)),
                    BoxShadow(color: kPrimaryBlue.withOpacity(0.45), blurRadius: 18, offset: const Offset(0, 8)),
                    BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.send_rounded, color: Colors.white, size: 22),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ===== Neumorphic Circle =====
class _NeumorphicCircle extends StatelessWidget {
  final Widget child;
  const _NeumorphicCircle({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EEF5),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.9), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.white, blurRadius: 10, offset: const Offset(-3, -3), spreadRadius: 0.5),
          BoxShadow(color: kPrimaryBlue.withOpacity(0.18), blurRadius: 14, offset: const Offset(3, 3)),
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(2, 2)),
        ],
      ),
      child: child,
    );
  }
}
