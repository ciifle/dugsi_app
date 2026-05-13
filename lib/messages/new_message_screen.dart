import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kobac/messages/chat_screen.dart';
import 'package:kobac/services/message_service.dart';
import 'package:kobac/teacher/widgets/teacher_web_ui.dart';

const Color _kPrimaryBlue = Color(0xFF023471);
const Color _kCardColor = Colors.white;
const Color _kTextPrimary = Color(0xFF2D3436);
const Color _kTextSecondary = Color(0xFF636E72);

/// Screen to pick a user and start a new conversation.
/// Calls GET /api/messages/users, then navigates to ChatScreen on tap.
class NewMessageScreen extends StatefulWidget {
  final bool embedBodyOnly;
  final void Function(String pageKey, {Object? arguments})? onNavigateToPage;

  const NewMessageScreen({
    Key? key,
    this.embedBodyOnly = false,
    this.onNavigateToPage,
  }) : super(key: key);

  @override
  State<NewMessageScreen> createState() => _NewMessageScreenState();
}

class _NewMessageScreenState extends State<NewMessageScreen> {
  List<MessageUserModel> _users = [];
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
    final result = await MessageService().getUsers();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result is MessageSuccess<List<MessageUserModel>>) {
        _users = result.data;
        _error = null;
      } else {
        _users = [];
        _error = (result as MessageError).message;
      }
    });
  }

  bool _usesTeacherDesktopShell(BuildContext context) {
    return widget.embedBodyOnly && widget.onNavigateToPage != null;
  }

  void _openChat(MessageUserModel user) {
    if (_usesTeacherDesktopShell(context)) {
      widget.onNavigateToPage!.call(
        'chat',
        arguments: {
          'userId': user.id,
          'name': user.name,
        },
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(userId: user.id, name: user.name),
      ),
    );
  }

  void _cancel() {
    if (_usesTeacherDesktopShell(context)) {
      widget.onNavigateToPage!.call('messages');
      return;
    }
    Navigator.pop(context);
  }

  String _roleLabel(String role) {
    if (role.isEmpty) return '';
    final r = role.toUpperCase().replaceAll(' ', '_');
    if (r == 'SCHOOL_ADMIN' || r == 'ADMIN') return 'Admin';
    if (r == 'TEACHER') return 'Teacher';
    if (r == 'STUDENT') return 'Student';
    if (r == 'PARENT') return 'Parent';
    return role;
  }

  Widget _buildUserList() {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(color: _kPrimaryBlue),
        ),
      );
    }
    if (_error != null) {
      return Center(
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
      );
    }
    if (_users.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_outline_rounded, size: 64, color: _kTextSecondary),
              SizedBox(height: 16),
              Text(
                'No users available',
                style: TextStyle(fontSize: 16, color: _kTextSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: _users.length,
      itemBuilder: (context, i) {
        final user = _users[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _openChat(user),
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
                            user.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _kPrimaryBlue,
                            ),
                          ),
                          if (user.role.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              _roleLabel(user.role),
                              style: const TextStyle(fontSize: 14, color: _kTextSecondary),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: _kTextSecondary),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTeacherDesktopBody() {
    return TeacherWebSurface(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TeacherWebCard(
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Select a recipient to start a conversation.',
                        style: TextStyle(
                          fontSize: 14,
                          color: teacherWebTextSecondary,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _cancel,
                      child: const Text('Cancel'),
                    ),
                    if (!_loading && _error == null)
                      IconButton(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh_rounded, color: teacherWebBlue),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TeacherWebCard(
                padding: EdgeInsets.zero,
                child: _loading || _error != null || _users.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: _buildUserList(),
                      )
                    : Column(
                        children: [
                          const TeacherWebTableHeader(columns: ['Recipient', 'Role', '']),
                          ...List.generate(_users.length, (index) {
                            final user = _users[index];
                            return TeacherWebTableRow(
                              onTap: () => _openChat(user),
                              cells: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: teacherWebBlue.withValues(alpha: 0.1),
                                      child: const Icon(Icons.person_rounded, color: teacherWebBlue, size: 18),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        user.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  _roleLabel(user.role),
                                  style: const TextStyle(color: _kTextSecondary),
                                ),
                                const Align(
                                  alignment: Alignment.centerRight,
                                  child: Icon(Icons.chevron_right_rounded, color: _kTextSecondary),
                                ),
                              ],
                            );
                          }),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_usesTeacherDesktopShell(context)) {
      return _buildTeacherDesktopBody();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0F3F7),
      appBar: AppBar(
        title: const Text('New message', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: _kPrimaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!_loading && _error == null)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _load,
            ),
        ],
      ),
      body: _buildUserList(),
    );
  }
}
