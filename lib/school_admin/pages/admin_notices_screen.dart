import 'package:flutter/material.dart';
import 'package:kobac/school_admin/widgets/admin_responsive_layout.dart';
import 'package:kobac/services/notices_service.dart';
import 'package:kobac/services/api_error_helpers.dart';
import 'package:kobac/school_admin/widgets/delete_confirm_dialog.dart';
import 'package:kobac/widgets/form_3d/form_3d.dart';

const Color kPrimaryBlue = Color(0xFF023471);
const Color kPrimaryGreen = Color(0xFF5AB04B);
const Color kBgColor = Color(0xFFF0F3F7);
const double kCardRadius = 28.0;

class AdminNoticesScreen extends StatefulWidget {
  final bool openCreateOnLoad;
  final bool embedBodyOnly;
  final void Function(String, {Object? arguments})? onNavigateToPage;

  const AdminNoticesScreen({
    Key? key,
    this.openCreateOnLoad = false,
    this.embedBodyOnly = false,
    this.onNavigateToPage,
  }) : super(key: key);

  @override
  State<AdminNoticesScreen> createState() => _AdminNoticesScreenState();
}

class _AdminNoticesScreenState extends State<AdminNoticesScreen> {
  late Future<NoticeResult<List<NoticeModel>>> _noticesFuture;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadNotices();
    if (widget.openCreateOnLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openCreateNotice());
    }
  }

  void _loadNotices() {
    setState(() {
      _noticesFuture = NoticesService().listNotices();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<NoticeModel> _filterNotices(List<NoticeModel> notices) {
    if (_searchQuery.trim().isEmpty) return notices;
    final query = _searchQuery.trim().toLowerCase();
    return notices.where((notice) {
      return notice.title.toLowerCase().contains(query) ||
          notice.content.toLowerCase().contains(query);
    }).toList();
  }

  void _openNoticeDetail(NoticeModel notice) {
    if (isEmbeddedDesktopAdminBody(context, widget.embedBodyOnly)) {
      showDialog<void>(
        context: context,
        builder: (ctx) => _NoticeDetailDialog(
          notice: notice,
          onEdit: () {
            Navigator.pop(ctx);
            _openEditNotice(notice);
          },
          onDelete: () async {
            Navigator.pop(ctx);
            await _deleteNotice(notice);
          },
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _NoticeDetailScreen(
          notice: notice,
          onEdit: () => _openEditNotice(notice),
          onDelete: () => _deleteNotice(notice, onSuccess: () => Navigator.pop(context)),
          onPop: () => _loadNotices(),
        ),
      ),
    ).then((_) => _loadNotices());
  }

  Future<void> _openCreateNotice() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => _NoticeFormDialog(
        title: 'Create Notice',
        initialTitle: '',
        initialContent: '',
        submitLabel: 'Publish',
        onSave: (t, c) async {
          final result = await NoticesService().createNotice({'title': t, 'content': c});
          if (result is NoticeSuccess) return true;
          if (ctx.mounted) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(content: Text((result as NoticeError).message), backgroundColor: Colors.red),
            );
          }
          return false;
        },
      ),
    );
    if (created == true && mounted) {
      _loadNotices();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notice published'), backgroundColor: kPrimaryGreen),
      );
    }
  }

  Future<void> _openEditNotice(NoticeModel notice) async {
    final updated = await showDialog<bool>(
      context: context,
      builder: (ctx) => _NoticeFormDialog(
        title: 'Edit Notice',
        initialTitle: notice.title,
        initialContent: notice.content,
        submitLabel: 'Save',
        onSave: (t, c) async {
          final result = await NoticesService().updateNotice(notice.id, {'title': t, 'content': c});
          if (result is NoticeSuccess) return true;
          if (ctx.mounted) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(content: Text((result as NoticeError).message), backgroundColor: Colors.red),
            );
          }
          return false;
        },
      ),
    );
    if (updated == true && mounted) {
      _loadNotices();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notice updated'), backgroundColor: kPrimaryGreen),
      );
    }
  }

  Future<void> _deleteNotice(NoticeModel notice, {VoidCallback? onSuccess}) async {
    final confirmed = await showDeleteConfirmDialog(
      context,
      title: 'Delete notice?',
      message: 'Delete notice "${notice.title}"?',
    );
    if (confirmed != true) return;
    final result = await NoticesService().deleteNotice(notice.id);
    if (!mounted) return;
    if (result is NoticeSuccess) {
      onSuccess?.call();
      _loadNotices();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notice deleted'), backgroundColor: kPrimaryGreen),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text((result as NoticeError).message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = isEmbeddedDesktopAdminBody(context, widget.embedBodyOnly)
        ? _buildDesktopPageBody(context)
        : _buildMobilePageBody(context);

    if (isEmbeddedDesktopAdminBody(context, widget.embedBodyOnly)) {
      return body;
    }

    return Scaffold(
      backgroundColor: kBgColor,
      body: SafeArea(child: body),
    );
  }

  Widget _buildMobilePageBody(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [kBgColor, kPrimaryBlue.withOpacity(0.02)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Row(
              children: [
                if (!isEmbeddedDesktopAdminBody(context, widget.embedBodyOnly)) ...[
                  _BackButton(onPressed: () => Navigator.pop(context)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'School Announcements',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kPrimaryBlue),
                    ),
                  ),
                ] else
                  const Spacer(),
                _AddButton(onPressed: _openCreateNotice),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
                  onRefresh: () async => _loadNotices(),
                  color: kPrimaryGreen,
                  child: FutureBuilder<NoticeResult<List<NoticeModel>>>(
                    future: _noticesFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: kPrimaryGreen));
                      }
                      if (snapshot.hasError) {
                        final msg = userFriendlyMessage(snapshot.error!, null, 'AdminNoticesScreen');
                        return _ErrorState(message: msg, onRetry: _loadNotices);
                      }
                      final result = snapshot.data;
                      if (result == null) return const Center(child: Text('No data'));
                      if (result is NoticeError) {
                        return _ErrorState(message: result.message, onRetry: _loadNotices);
                      }
                      final notices = (result as NoticeSuccess<List<NoticeModel>>).data;
                      if (notices.isEmpty) {
                        return ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                            Center(
                              child: Column(
                                children: [
                                  Icon(Icons.campaign_rounded, size: 60, color: Colors.grey[300]),
                                  const SizedBox(height: 12),
                                  Text('No notices yet', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                                  const SizedBox(height: 16),
                                  TextButton.icon(
                                    onPressed: _openCreateNotice,
                                    icon: const Icon(Icons.add_rounded),
                                    label: const Text('Create Notice'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }
                      return ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        itemCount: notices.length,
                        itemBuilder: (context, index) {
                          final notice = notices[index];
                          return _NoticeCard(
                            notice: notice,
                            onTap: () => _openNoticeDetail(notice),
                            onEdit: () => _openEditNotice(notice),
                            onDelete: () => _deleteNotice(notice),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildDesktopPageBody(BuildContext context) {
    return Container(
      color: const Color(0xFFF8F9FC),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE8ECF2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 900;
                  final searchField = Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _searchQuery = value),
                      decoration: InputDecoration(
                        hintText: 'Search notices...',
                        hintStyle: TextStyle(color: Colors.grey.shade500),
                        prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade500),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: Colors.grey),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  );
                  final addButton = SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _openCreateNotice,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add Notice'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  );
                  final refreshButton = OutlinedButton.icon(
                    onPressed: _loadNotices,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Refresh'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kPrimaryBlue,
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );

                  if (isWide) {
                    return Row(
                      children: [
                        Expanded(child: searchField),
                        const SizedBox(width: 16),
                        refreshButton,
                        const SizedBox(width: 12),
                        addButton,
                      ],
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      searchField,
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.end,
                        children: [refreshButton, addButton],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _loadNotices(),
              color: kPrimaryGreen,
              child: FutureBuilder<NoticeResult<List<NoticeModel>>>(
                future: _noticesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: kPrimaryBlue));
                  }
                  if (snapshot.hasError) {
                    final msg = userFriendlyMessage(snapshot.error!, null, 'AdminNoticesScreen');
                    return _ErrorState(message: msg, onRetry: _loadNotices);
                  }
                  final result = snapshot.data;
                  if (result == null) return const Center(child: Text('No data'));
                  if (result is NoticeError) {
                    return _ErrorState(message: result.message, onRetry: _loadNotices);
                  }

                  final notices = _filterNotices((result as NoticeSuccess<List<NoticeModel>>).data);
                  if (notices.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(24),
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                        Center(
                          child: Text(
                            _searchQuery.isEmpty ? 'No notices found' : 'No notices match your search',
                            style: TextStyle(color: Colors.grey[600], fontSize: 16),
                          ),
                        ),
                      ],
                    );
                  }

                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE8ECF2)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              decoration: const BoxDecoration(
                                border: Border(bottom: BorderSide(color: Color(0xFFE8ECF2), width: 1)),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Text('Title', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
                                  ),
                                  Expanded(
                                    flex: 4,
                                    child: Text('Content', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text('Date', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
                                  ),
                                  const SizedBox(width: 88),
                                ],
                              ),
                            ),
                            ...notices.map((notice) {
                              return _NoticeRow(
                                notice: notice,
                                onTap: () => _openNoticeDetail(notice),
                                onEdit: () => _openEditNotice(notice),
                                onDelete: () => _deleteNotice(notice),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

bool _isDesktopAdminModal(BuildContext context) => isDesktopWebAdminLayout(context);

class _NoticeRow extends StatelessWidget {
  final NoticeModel notice;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _NoticeRow({
    required this.notice,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final preview = notice.content.length > 90 ? '${notice.content.substring(0, 90)}...' : notice.content;
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFE8ECF2), width: 1)),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  notice.title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kPrimaryBlue),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 4,
                child: Text(
                  preview,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  notice.createdAt ?? '—',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20, color: kPrimaryGreen),
                onPressed: onEdit,
                tooltip: 'Edit',
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, size: 20, color: Colors.red[400]),
                onPressed: onDelete,
                tooltip: 'Delete',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoticeDetailDialog extends StatelessWidget {
  final NoticeModel notice;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _NoticeDetailDialog({
    required this.notice,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 720,
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Notice Details',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: kPrimaryBlue),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notice.title,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kPrimaryBlue),
                    ),
                    if (notice.createdAt != null) ...[
                      const SizedBox(height: 8),
                      Text(notice.createdAt!, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                    ],
                    const SizedBox(height: 20),
                    Text(
                      notice.content,
                      style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: onDelete,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                      side: BorderSide(color: Colors.red.shade100),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Delete'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: onEdit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Edit'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey[800])),
            const SizedBox(height: 16),
            TextButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  final NoticeModel notice;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _NoticeCard({
    required this.notice,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final preview = notice.content.length > 80 ? '${notice.content.substring(0, 80)}...' : notice.content;
    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(kCardRadius),
          boxShadow: [
            BoxShadow(color: kPrimaryBlue.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 6)),
            BoxShadow(color: kPrimaryBlue.withOpacity(0.03), blurRadius: 32, offset: const Offset(0, 12)),
          ],
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(kCardRadius),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: kPrimaryBlue.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.campaign_rounded, color: kPrimaryBlue, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      notice.title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kPrimaryBlue),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 22, color: kPrimaryGreen),
                    onPressed: onEdit,
                    tooltip: 'Edit',
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline, size: 22, color: Colors.red[400]),
                    onPressed: onDelete,
                    tooltip: 'Delete',
                  ),
                ],
              ),
              if (preview.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  preview,
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (notice.createdAt != null) ...[
                const SizedBox(height: 8),
                Text(
                  notice.createdAt!,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _NoticeDetailScreen extends StatelessWidget {
  final NoticeModel notice;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onPop;

  const _NoticeDetailScreen({
    required this.notice,
    required this.onEdit,
    required this.onDelete,
    required this.onPop,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: kPrimaryBlue.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
                      ),
                      child: const Icon(Icons.arrow_back_rounded, color: kPrimaryBlue, size: 24),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text('Notice', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kPrimaryBlue)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: kPrimaryGreen),
                    onPressed: onEdit,
                    tooltip: 'Edit',
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.red[400]),
                    onPressed: onDelete,
                    tooltip: 'Delete',
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: FormCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        notice.title,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kPrimaryBlue),
                      ),
                      if (notice.createdAt != null) ...[
                        const SizedBox(height: 8),
                        Text(notice.createdAt!, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                      ],
                      const SizedBox(height: 20),
                      Text(
                        notice.content,
                        style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoticeFormDialog extends StatefulWidget {
  final String title;
  final String initialTitle;
  final String initialContent;
  final String submitLabel;
  final Future<bool> Function(String title, String content) onSave;

  const _NoticeFormDialog({
    required this.title,
    required this.initialTitle,
    required this.initialContent,
    required this.submitLabel,
    required this.onSave,
  });

  @override
  State<_NoticeFormDialog> createState() => _NoticeFormDialogState();
}

class _NoticeFormDialogState extends State<_NoticeFormDialog> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _contentController = TextEditingController(text: widget.initialContent);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title is required'), backgroundColor: Colors.red),
      );
      return;
    }
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Content is required'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_submitting) return;
    setState(() => _submitting = true);
    final ok = await widget.onSave(title, content);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = _isDesktopAdminModal(context);
    final formContent = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Input3D(
          controller: _titleController,
          label: 'Title',
          hint: 'Notice title',
          textCapitalization: TextCapitalization.sentences,
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: TextField(
            controller: _contentController,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Content',
              hintText: 'Notice content...',
              contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              border: InputBorder.none,
              alignLabelWithHint: true,
            ),
          ),
        ),
      ],
    );

    final footer = isDesktop
        ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: _submitting ? null : () => Navigator.of(context).pop(false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF374151),
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(widget.submitLabel),
                ),
              ],
            ),
          )
        : Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: _submitting ? null : () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: PrimaryButton3D(
                  label: widget.submitLabel,
                  onPressed: _submit,
                  loading: _submitting,
                  height: 48,
                ),
              ),
            ],
          );

    if (!isDesktop) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: FormCard(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kPrimaryBlue),
                ),
                const SizedBox(height: 20),
                formContent,
                const SizedBox(height: 24),
                footer,
              ],
            ),
          ),
        ),
      );
    }

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 700,
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: kPrimaryBlue),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    icon: const Icon(Icons.close_rounded),
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: formContent,
              ),
            ),
            const Divider(height: 1),
            footer,
          ],
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _BackButton({required this.onPressed});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: kPrimaryBlue.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: const Icon(Icons.arrow_back_rounded, color: kPrimaryBlue, size: 24),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _AddButton({required this.onPressed});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: kPrimaryGreen.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: kPrimaryGreen.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: const Icon(Icons.add_rounded, color: kPrimaryGreen, size: 24),
      ),
    );
  }
}
