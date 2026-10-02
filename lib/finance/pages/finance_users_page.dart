import 'package:flutter/material.dart';
import 'package:kobac/finance/widgets/finance_ui.dart';

import 'package:kobac/school_admin/widgets/admin_desktop_kit.dart';
import 'package:kobac/school_admin/widgets/admin_feature_dialog.dart';
import 'package:kobac/school_admin/widgets/delete_confirm_dialog.dart';
import 'package:kobac/widgets/form_3d/form_3d.dart';

import 'package:kobac/finance/models/finance_user.dart';
import 'package:kobac/finance/services/finance_base.dart';
import 'package:kobac/finance/services/finance_user_service.dart';

const int _kUsersPageSize = 50;

/// School Admin only — never mounted for the FINANCE role.
class FinanceUsersPage extends StatefulWidget {
  final bool embedBodyOnly;
  final void Function(String pageKey, {Object? arguments})? onNavigateToPage;

  const FinanceUsersPage({
    super.key,
    this.embedBodyOnly = false,
    this.onNavigateToPage,
  });

  @override
  State<FinanceUsersPage> createState() => _FinanceUsersPageState();
}

class _FinanceUsersPageState extends State<FinanceUsersPage> {
  final ScrollController _pageScroll = ScrollController();

  final FinanceUserService _service = FinanceUserService();
  List<FinanceUser> _users = [];
  int _page = 1;
  int _total = 0;
  bool _deleting = false;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pageScroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await _service.list(page: _page, limit: _kUsersPageSize);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result is FinanceSuccess<FinanceUserPage>) {
        _users = result.data.users;
        _total = result.data.total;
      } else {
        _users = [];
        _error = (result as FinanceError).message;
      }
    });
  }

  void _goToPage(int page) {
    _page = page;
    if (_pageScroll.hasClients) _pageScroll.jumpTo(0);
    _load();
  }

  void _toast(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red : kAdminGreen,
      ),
    );
  }

  Future<void> _openCreateDialog() async {
    final created = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black38,
      builder: (_) => const _FinanceUserFormDialog(),
    );
    if (created == true && mounted) {
      _toast('Finance user added.');
      _load();
    }
  }

  Future<void> _openEditDialog(FinanceUser user) async {
    final result = await _service.getById(user.id);
    if (!mounted) return;
    if (result is FinanceError) {
      _toast(result.message, error: true);
      return;
    }
    user = (result as FinanceSuccess<FinanceUser>).data;
    final saved = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black38,
      builder: (_) => _FinanceUserFormDialog(user: user),
    );
    if (saved == true && mounted) {
      _toast('Finance user updated.');
      _load();
    }
  }

  Future<void> _delete(FinanceUser user) async {
    if (_deleting) return;
    _deleting = true;
    final confirmed = await showDeleteConfirmDialog(
      context,
      title: 'Delete Finance User?',
      message: 'Are you sure you want to delete this finance user?',
    );
    if (!mounted) return;
    if (confirmed != true) {
      _deleting = false;
      return;
    }
    final result = await _service.delete(user.id);
    _deleting = false;
    if (!mounted) return;
    if (result is FinanceError) {
      if (result.code == 'FINANCE_USER_HAS_PAYMENT_HISTORY') {
        await showFinanceMessageDialog(
          context,
          title: 'Cannot Delete Finance User',
          message:
              'This finance user cannot be deleted because they have recorded payment history.',
          icon: Icons.lock_outline_rounded,
          iconColor: const Color(0xFFF59E0B),
        );
      } else {
        _toast(result.message, error: true);
      }
      return;
    }
    _toast('Finance user deleted.');
    // Deleting the last row of a later page would otherwise leave an empty page.
    if (_users.length == 1 && _page > 1) _page--;
    _load();
  }

  @override
  Widget build(BuildContext context) => FinancePageFrame(
    embedBodyOnly: widget.embedBodyOnly,
    scrollController: _pageScroll,
    child: _buildBody(),
  );

  Widget _buildBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FinancePageHeader(
          title: 'Finance Users',
          subtitle: "Manage staff who can access the school's finance module.",
          primaryAction: AdminPrimaryButton(
            label: 'Add Finance User',
            icon: Icons.person_add_alt_rounded,
            onPressed: _openCreateDialog,
          ),
        ),
        const SizedBox(height: 16),
        if (_loading) const LinearProgressIndicator(),
        AbsorbPointer(absorbing: _loading, child: _buildContent()),
        if (!_loading && _error == null && _total > 0) ...[
          const SizedBox(height: 12),
          AdminPaginationBar(
            page: _page,
            pageSize: _kUsersPageSize,
            total: _total,
            singular: 'user',
            plural: 'users',
            onPageChanged: _goToPage,
          ),
        ],
      ],
    );
  }

  Widget _buildContent() {
    if (_loading && _users.isEmpty)
      return const Center(child: CircularProgressIndicator(color: kAdminNavy));
    if (_error != null) {
      return AdminErrorState(
        title: 'Could not load finance users',
        message: _error!,
        onRetry: _load,
      );
    }
    if (_users.isEmpty) {
      return AdminEmptyState(
        icon: Icons.people_outline_rounded,
        title: 'No finance users found.',
        message:
            'Add a finance user so they can collect payments and manage fees.',
        action: AdminPrimaryButton(
          label: 'Add Finance User',
          icon: Icons.person_add_alt_rounded,
          onPressed: _openCreateDialog,
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, box) =>
          box.maxWidth >= 720 ? _buildTable() : _buildCards(),
    );
  }

  Widget _menu(FinanceUser user) => FinanceActionMenu(
    actions: [
      FinanceMenuAction(
        'View / Edit',
        Icons.edit_outlined,
        () => _openEditDialog(user),
      ),
      FinanceMenuAction(
        'Delete',
        Icons.delete_outline_rounded,
        () => _delete(user),
        destructive: true,
      ),
    ],
  );

  Widget _buildTable() => AdminTableCard(
    columns: const [
      AdminTableColumn('Name', flex: 3),
      AdminTableColumn('Email', flex: 3),
      AdminTableColumn('Created', flex: 2),
      AdminTableColumn('Actions', flex: 1, align: TextAlign.right),
    ],
    rows: [
      for (final u in _users)
        AdminTableRow(
          flexes: const [3, 3, 2, 1],
          onTap: () => _openEditDialog(u),
          cells: [
            Row(
              children: [
                FinanceInitialAvatar(u.name, size: 36),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    u.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: kAdminNavy,
                    ),
                  ),
                ),
              ],
            ),
            Text(u.email, maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(formatFinanceDate(u.createdAt)),
            Align(alignment: Alignment.centerRight, child: _menu(u)),
          ],
        ),
    ],
  );

  Widget _buildCards() => Column(
    children: [
      for (final u in _users)
        FinanceRecordCard(
          leading: FinanceInitialAvatar(u.name),
          title: u.name,
          subtitle: u.email,
          details: [('Created', formatFinanceDate(u.createdAt))],
          trailing: _menu(u),
          onTap: () => _openEditDialog(u),
        ),
    ],
  );
}

class _FinanceUserFormDialog extends StatefulWidget {
  final FinanceUser? user;
  const _FinanceUserFormDialog({this.user});

  @override
  State<_FinanceUserFormDialog> createState() => _FinanceUserFormDialogState();
}

class _FinanceUserFormDialogState extends State<_FinanceUserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.user != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user?.name ?? '');
    _emailController = TextEditingController(text: widget.user?.email ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final service = FinanceUserService();
    final result = _isEdit
        ? await service.update(
            widget.user!.id,
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text.isEmpty
                ? null
                : _passwordController.text,
          )
        : await service.create(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
    if (!mounted) return;
    if (result is FinanceSuccess) {
      Navigator.pop(context, true);
      return;
    }
    setState(() {
      _saving = false;
      _error = (result as FinanceError).message;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_saving,
      child: AdminFeatureDialog(
        title: _isEdit ? 'Edit Finance User' : 'Add Finance User',
        onClose: _saving ? () {} : null,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Input3D(
                controller: _nameController,
                label: 'Name',
                textCapitalization: TextCapitalization.words,
                enabled: !_saving,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 10),
              Input3D(
                controller: _emailController,
                label: 'Email',
                keyboardType: TextInputType.emailAddress,
                enabled: !_saving,
                validator: (v) =>
                    v == null ||
                        !RegExp(
                          r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                        ).hasMatch(v.trim())
                    ? 'Enter a valid email address'
                    : null,
              ),
              const SizedBox(height: 10),
              PasswordInput3D(
                controller: _passwordController,
                label: _isEdit ? 'New Password (optional)' : 'Password',
                validator: (v) {
                  if (_isEdit && (v == null || v.isEmpty)) return null;
                  if (v == null || v.length < 8) return 'Minimum 8 characters';
                  return null;
                },
              ),
              const SizedBox(height: 10),
              PasswordInput3D(
                controller: _confirmController,
                label: 'Confirm Password',
                validator: (v) {
                  if (_isEdit && _passwordController.text.isEmpty) return null;
                  if (v != _passwordController.text)
                    return 'Passwords do not match';
                  return null;
                },
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                FinanceInlineError(_error!),
              ],
              const SizedBox(height: 18),
              FinanceDialogActions(
                primaryLabel: 'Save User',
                busy: _saving,
                onPrimary: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
