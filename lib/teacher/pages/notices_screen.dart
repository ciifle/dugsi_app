import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:kobac/services/auth_provider.dart';
import 'package:kobac/services/teacher_notices_service.dart';
import 'package:kobac/teacher/widgets/teacher_web_ui.dart';

String _noticeDate(DateTime? t) => t == null
    ? 'Date not provided'
    : DateFormat('d MMM yyyy, HH:mm').format(t.toLocal());

/// Read-only list of notices the School Admin published for the teacher's
/// school (GET /api/teacher/notices). Teachers cannot create or edit notices.
class TeacherNoticesScreen extends StatefulWidget {
  /// Desktop PWA: rendered inside the teacher web shell.
  final bool embedBodyOnly;

  /// False inside the teacher mobile shell (it owns the header).
  final bool showAppBar;

  @visibleForTesting
  final TeacherNoticesService? service;

  /// Overrides the signed-in teacher's school (tests).
  @visibleForTesting
  final int? schoolId;

  const TeacherNoticesScreen({
    super.key,
    this.embedBodyOnly = false,
    this.showAppBar = true,
    this.service,
    this.schoolId,
  });

  @override
  State<TeacherNoticesScreen> createState() => _TeacherNoticesScreenState();
}

class _TeacherNoticesScreenState extends State<TeacherNoticesScreen> {
  late final TeacherNoticesService _service =
      widget.service ?? TeacherNoticesService();
  List<TeacherNotice> _notices = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  int? get _schoolId {
    if (widget.schoolId != null) return widget.schoolId;
    try {
      return Provider.of<AuthProvider?>(context, listen: false)?.user?.schoolId;
    } catch (_) {
      return null;
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = _notices.isEmpty;
      _error = null;
    });
    final res = await _service.list(schoolId: _schoolId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      switch (res) {
        case TeacherNoticesLoaded(:final notices):
          _notices = notices;
        case TeacherNoticesFailed(:final message):
          _error = message;
      }
    });
  }

  void _open(TeacherNotice n) {
    final detail = _NoticeDetail(notice: n);
    if (widget.embedBodyOnly) {
      showDialog<void>(
        context: context,
        builder: (context) => Dialog(
          insetPadding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680, maxHeight: 720),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(child: detail),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => Scaffold(
            backgroundColor: teacherWebBg,
            appBar: AppBar(
              title: const Text('Notice'),
              backgroundColor: Colors.white,
              foregroundColor: teacherWebBlue,
              elevation: 0,
            ),
            body: SafeArea(child: detail),
          ),
        ),
      );
    }
  }

  Widget _list(EdgeInsets padding) {
    final Widget content;
    if (_loading) {
      content = const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator(color: teacherWebBlue)),
      );
    } else if (_error != null && _notices.isEmpty) {
      content = TeacherErrorState(message: _error!, onRetry: _load);
    } else if (_notices.isEmpty) {
      content = const TeacherEmptyState(
        icon: Icons.campaign_outlined,
        title: 'No notices yet',
        message: 'Notices published by your School Admin will appear here.',
      );
    } else {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _error!,
                style: const TextStyle(color: Color(0xFFDC2626)),
              ),
            ),
          for (final n in _notices)
            _NoticeCard(
              key: ValueKey('notice-${n.id}'),
              notice: n,
              onTap: () => _open(n),
            ),
        ],
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: teacherWebBlue,
      child: ListView(
        key: const ValueKey('teacher-notices-list'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: padding,
        children: [content],
      ),
    );
  }

  Widget _refreshButton() => IconButton(
    key: const ValueKey('notices-refresh'),
    tooltip: 'Refresh',
    onPressed: _loading ? null : _load,
    icon: const Icon(Icons.refresh_rounded, color: teacherWebBlue),
  );

  @override
  Widget build(BuildContext context) {
    if (widget.embedBodyOnly) {
      return Container(
        color: teacherWebBg,
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TeacherWebSectionTitle(
              title: 'School Notices',
              subtitle: 'Announcements from your School Admin, newest first.',
              trailing: _refreshButton(),
            ),
            const SizedBox(height: 12),
            Expanded(child: _list(const EdgeInsets.only(bottom: 24))),
          ],
        ),
      );
    }
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 8, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _loading
                      ? 'Loading notices…'
                      : '${_notices.length} notice${_notices.length == 1 ? '' : 's'} · newest first',
                  style: const TextStyle(color: teacherWebTextSecondary),
                ),
              ),
              _refreshButton(),
            ],
          ),
        ),
        Expanded(child: _list(const EdgeInsets.fromLTRB(16, 4, 16, 24))),
      ],
    );
    if (!widget.showAppBar) return ColoredBox(color: teacherWebBg, child: body);
    return Scaffold(
      backgroundColor: teacherWebBg,
      appBar: AppBar(
        title: const Text('Notices'),
        backgroundColor: Colors.white,
        foregroundColor: teacherWebBlue,
        elevation: 0,
      ),
      body: SafeArea(child: body),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  final TeacherNotice notice;
  final VoidCallback onTap;
  const _NoticeCard({super.key, required this.notice, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: teacherWebBorder),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: teacherWebBlue.withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.campaign_rounded,
                    color: teacherWebBlue,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notice.title.isEmpty ? 'Untitled notice' : notice.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15.5,
                          color: teacherWebTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _noticeDate(notice.createdAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: teacherWebTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        notice.content,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: teacherWebTextPrimary,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Read notice',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: teacherWebBlue,
                          fontWeight: FontWeight.w700,
                        ),
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
  }
}

class _NoticeDetail extends StatelessWidget {
  final TeacherNotice notice;
  const _NoticeDetail({required this.notice});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: ValueKey('notice-detail-${notice.id}'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            notice.title.isEmpty ? 'Untitled notice' : notice.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: teacherWebBlue,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Published ${_noticeDate(notice.createdAt)}'
            '${notice.edited ? ' · Updated ${_noticeDate(notice.updatedAt)}' : ''}',
            style: const TextStyle(
              fontSize: 12.5,
              color: teacherWebTextSecondary,
            ),
          ),
          const Divider(height: 28),
          SelectableText(
            notice.content.isEmpty ? 'No content.' : notice.content,
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
              color: teacherWebTextPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
