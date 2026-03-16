import 'package:flutter/material.dart';
import 'package:kobac/messages/chat_screen.dart';
import 'package:kobac/services/message_service.dart';

const Color _kPrimaryBlue = Color(0xFF023471);
const Color _kCardColor = Colors.white;
const Color _kTextPrimary = Color(0xFF2D3436);
const Color _kTextSecondary = Color(0xFF636E72);

/// Screen to pick a user and start a new conversation.
/// Calls GET /api/messages/users, then navigates to ChatScreen on tap.
class NewMessageScreen extends StatefulWidget {
  const NewMessageScreen({Key? key}) : super(key: key);

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

  String _roleLabel(String role) {
    if (role.isEmpty) return '';
    final r = role.toUpperCase().replaceAll(' ', '_');
    if (r == 'SCHOOL_ADMIN' || r == 'ADMIN') return 'Admin';
    if (r == 'TEACHER') return 'Teacher';
    if (r == 'STUDENT') return 'Student';
    if (r == 'PARENT') return 'Parent';
    return role;
  }

  @override
  Widget build(BuildContext context) {
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
      body: _loading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(color: _kPrimaryBlue),
              ),
            )
          : _error != null
              ? Center(
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
                )
              : _users.isEmpty
                  ? const Center(
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
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      itemCount: _users.length,
                      itemBuilder: (context, i) {
                        final u = _users[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChatScreen(userId: u.id, name: u.name),
                                  ),
                                );
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
                                            u.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: _kPrimaryBlue,
                                            ),
                                          ),
                                          if (u.role.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              _roleLabel(u.role),
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
                    ),
    );
  }
}
