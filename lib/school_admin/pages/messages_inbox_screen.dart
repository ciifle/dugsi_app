import 'package:flutter/material.dart';
import 'package:kobac/school_admin/pages/mesaage_screen.dart';

/// Brand / Design (match your dashboard)
const Color kPrimaryBlue = Color(0xFF023471);
const Color kPrimaryGreen = Color(0xFF5AB04B);
const Color kBgColor = Color(0xFFF0F3F7);
const Color kCardColor = Colors.white;

const double kPadding = 20.0;

class MessagesInboxScreen extends StatefulWidget {
  final bool embedInParent;

  /// Optional: handle opening a chat thread
  final void Function(ChatThread thread)? onOpenChat;

  const MessagesInboxScreen({
    super.key,
    this.embedInParent = false,
    this.onOpenChat,
  });

  @override
  State<MessagesInboxScreen> createState() => _MessagesInboxScreenState();
}

class _MessagesInboxScreenState extends State<MessagesInboxScreen> {
  final TextEditingController _search = TextEditingController();

  // Dummy threads (replace with API later)
  final List<ChatThread> _threads = [
    ChatThread(
      name: "Mrs. Gable (Math)",
      role: "TEACHER",
      message: "Don't forget the calculus quiz tomorrow!",
      timeLabel: "10:45 AM",
      unread: 2,
      isRead: false,
      isTyping: false,
      isOnline: true,
    ),
    ChatThread(
      name: "James Wilson",
      role: "STUDENT",
      message: "Are we meeting at the library at...",
      timeLabel: "9:12 AM",
      unread: 1,
      isRead: false,
      isTyping: false,
      isOnline: true,
    ),
    ChatThread(
      name: "Principal Skinner",
      role: "ADMIN",
      message: "The assembly has been rescheduled...",
      timeLabel: "Yesterday",
      unread: 0,
      isRead: true,
      isTyping: false,
      isOnline: false,
    ),
    ChatThread(
      name: "Maria Garcia",
      role: "PARENT",
      message: "Thanks for the notes, they really helped.",
      timeLabel: "Yesterday",
      unread: 0,
      isRead: true,
      isTyping: false,
      isOnline: false,
    ),
  ];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _threads.where((t) {
      final q = _search.text.trim().toLowerCase();
      if (q.isEmpty) return true;
      return t.name.toLowerCase().contains(q) || t.message.toLowerCase().contains(q);
    }).toList();

    final unreadCount = _threads.fold<int>(0, (sum, t) => sum + (t.unread));

    final page = Container(
      color: kBgColor,
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ===== Title ONLY (no menu, no notification) =====
                Padding(
                  padding: const EdgeInsets.fromLTRB(kPadding, 18, kPadding, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Messages",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: kPrimaryBlue,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        unreadCount == 0
                            ? "You're all caught up"
                            : "$unreadCount unread from faculty",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                // ===== Search =====
                Padding(
                  padding: const EdgeInsets.fromLTRB(kPadding, 8, kPadding, 10),
                  child: _NeumorphicPill(
                    child: Row(
                      children: [
                        Icon(Icons.search_rounded, color: Colors.grey.shade500),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _search,
                            onChanged: (_) => setState(() {}),
                            style: const TextStyle(
                              color: kPrimaryBlue,
                              fontWeight: FontWeight.w700,
                            ),
                            decoration: InputDecoration(
                              hintText: "Search teachers, students...",
                              hintStyle: TextStyle(
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w600,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                        if (_search.text.trim().isNotEmpty)
                          GestureDetector(
                            onTap: () => setState(() => _search.clear()),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: kPrimaryBlue.withOpacity(0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close_rounded, size: 18, color: kPrimaryBlue),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // ===== Active Now =====
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                  child: _NeumorphicCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              "ACTIVE NOW",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: kPrimaryBlue,
                                letterSpacing: 0.6,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: kPrimaryGreen,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          height: 92,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            children: const [
                              _ActiveAvatar(name: "Prof. Alex"),
                              _ActiveAvatar(name: "Sarah M."),
                              _ActiveAvatar(name: "Coach Mike"),
                              _ActiveAvatar(name: "Lisa Ch"),
                              _ActiveAvatar(name: "Office"),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 4),

                // ===== Threads List =====
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                    physics: const BouncingScrollPhysics(),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final t = filtered[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ThreadTile(
                          thread: t,
                          onTap: () {
                            if (widget.onOpenChat != null) {
                              widget.onOpenChat!(t);
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MessageScreen(
                                    name: t.name,
                                    message: t.message,
                                    time: t.timeLabel,
                                    embedInParent: widget.embedInParent,
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),

                // a little extra breathing room above your parent bottom nav
                if (widget.embedInParent) const SizedBox(height: 10),
              ],
            ),

            // ===== Floating Compose (optional) =====
            Positioned(
              right: 18,
              bottom: widget.embedInParent ? 86 : 26,
              child: _ComposeFab(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MessageScreen(
                        name: null,
                        embedInParent: widget.embedInParent,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );

    if (widget.embedInParent) return page;
    return Scaffold(backgroundColor: kBgColor, body: page);
  }
}

/// ===================== MODELS =====================
class ChatThread {
  final String name;
  final String role;
  final String message;
  final String timeLabel;
  final int unread;
  final bool isRead;
  final bool isTyping;
  final bool isOnline;

  ChatThread({
    required this.name,
    required this.role,
    required this.message,
    required this.timeLabel,
    required this.unread,
    required this.isRead,
    required this.isTyping,
    required this.isOnline,
  });
}

/// ===================== UI: ACTIVE AVATAR =====================
class _ActiveAvatar extends StatelessWidget {
  final String name;
  const _ActiveAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 14),
      child: SizedBox(
        width: 78,
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: kPrimaryBlue.withOpacity(0.10), blurRadius: 14, offset: const Offset(0, 8)),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: kPrimaryBlue.withOpacity(0.10),
                    child: const Icon(Icons.person, color: kPrimaryBlue),
                  ),
                ),
                Positioned(
                  right: 4,
                  bottom: 4,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: kPrimaryGreen,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kPrimaryBlue),
            ),
          ],
        ),
      ),
    );
  }
}

/// ===================== UI: THREAD TILE =====================
class _ThreadTile extends StatelessWidget {
  final ChatThread thread;
  final VoidCallback onTap;

  const _ThreadTile({required this.thread, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final subtitle = thread.isTyping ? "••• typing..." : thread.message;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: _NeumorphicCard(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Avatar
              Stack(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: kPrimaryBlue.withOpacity(0.10),
                    child: const Icon(Icons.person, color: kPrimaryBlue),
                  ),
                  if (thread.isOnline)
                    Positioned(
                      right: 2,
                      bottom: 2,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: kPrimaryGreen,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),

              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            thread.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: thread.unread > 0 ? kPrimaryBlue : kPrimaryBlue.withOpacity(0.65),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          thread.timeLabel,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: thread.unread > 0 ? kPrimaryBlue : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: thread.isTyping ? kPrimaryGreen : Colors.grey.shade700,
                              fontWeight: thread.isTyping ? FontWeight.w800 : FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Unread badge OR read check
                        if (thread.unread > 0)
                          Container(
                            width: 30,
                            height: 30,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(color: kPrimaryGreen, shape: BoxShape.circle),
                            child: Text(
                              thread.unread.toString(),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          )
                        else if (thread.isRead)
                          Icon(Icons.done_all_rounded, color: kPrimaryBlue.withOpacity(0.45), size: 20)
                        else
                          const SizedBox(width: 20),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ===================== UI: COMPOSE FAB =====================
class _ComposeFab extends StatelessWidget {
  final VoidCallback onTap;
  const _ComposeFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
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
            BoxShadow(color: kPrimaryBlue.withOpacity(0.45), blurRadius: 20, offset: const Offset(0, 10)),
            BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 12, offset: const Offset(0, 6)),
          ],
        ),
        child: const Center(
          child: Icon(Icons.add_rounded, color: Colors.white, size: 34),
        ),
      ),
    );
  }
}

/// ===================== UI: NEUMORPHIC CARD =====================
class _NeumorphicCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const _NeumorphicCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.85), width: 1),
        boxShadow: [
          const BoxShadow(color: Colors.white, blurRadius: 14, offset: Offset(-4, -4)),
          BoxShadow(color: kPrimaryBlue.withOpacity(0.12), blurRadius: 26, offset: const Offset(8, 10)),
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 14, offset: const Offset(4, 6)),
        ],
      ),
      child: child,
    );
  }
}

/// ===================== UI: NEUMORPHIC PILL (SEARCH) =====================
class _NeumorphicPill extends StatelessWidget {
  final Widget child;
  const _NeumorphicPill({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FA),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.9), width: 1),
        boxShadow: [
          const BoxShadow(color: Colors.white, blurRadius: 10, offset: Offset(-3, -3)),
          BoxShadow(color: kPrimaryBlue.withOpacity(0.08), blurRadius: 14, offset: const Offset(4, 6)),
        ],
      ),
      child: child,
    );
  }
}
