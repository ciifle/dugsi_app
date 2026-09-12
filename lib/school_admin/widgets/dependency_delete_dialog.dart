import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kobac/services/admin_deletion_service.dart';
export 'package:kobac/services/admin_deletion_service.dart'
    show DeleteItemKind, LevelDeleteChoice, DependencyDeletePreview;
import 'package:kobac/services/delete_error_message.dart';

const _navy = Color(0xFF023471);
const _green = Color(0xFF5AB04B);

/// Production adapter: preview first, then the exact confirmed query contract.
Future<bool?> showAdminDeletionFlow(
  BuildContext context, {
  required DeleteItemKind kind,
  required int id,
  required String name,
  Future<void> Function(Map<String, dynamic> receipt)? onDeleted,
}) async {
  final service = AdminDeletionService();
  DependencyDeletePreview? current;
  Map<String, dynamic>? receipt;
  final deleted = await showDependencyDeleteDialog(
    context,
    kind: kind,
    name: name,
    loadPreview: () async => current = await service.preview(kind, id),
    confirmedDelete: (choice) async {
      try {
        receipt = await service.confirmedDelete(
          kind,
          current!,
          confirmed: true,
          confirmActive: current!.isActive,
          classChoice: choice,
        );
        return null;
      } on AdminDeleteException catch (error) {
        if (error.preview != null) current = error.preview;
        rethrow;
      }
    },
  );
  if (deleted == true && receipt != null) await onDeleted?.call(receipt!);
  return deleted;
}

/// Loads a preview before enabling deletion. A null delete result means success;
/// a returned message leaves the dialog open. API adapters own wire contracts.
Future<bool?> showDependencyDeleteDialog(
  BuildContext context, {
  required DeleteItemKind kind,
  required String name,
  required Future<DependencyDeletePreview> Function() loadPreview,
  required Future<String?> Function(LevelDeleteChoice? choice) confirmedDelete,
}) => showDialog<bool>(
  context: context,
  barrierDismissible: false,
  builder: (_) => _DependencyDeleteDialog(
    kind: kind,
    name: name,
    loadPreview: loadPreview,
    confirmedDelete: confirmedDelete,
  ),
);

class _DependencyDeleteDialog extends StatefulWidget {
  final DeleteItemKind kind;
  final String name;
  final Future<DependencyDeletePreview> Function() loadPreview;
  final Future<String?> Function(LevelDeleteChoice?) confirmedDelete;
  const _DependencyDeleteDialog({
    required this.kind,
    required this.name,
    required this.loadPreview,
    required this.confirmedDelete,
  });
  @override
  State<_DependencyDeleteDialog> createState() =>
      _DependencyDeleteDialogState();
}

class _DependencyDeleteDialogState extends State<_DependencyDeleteDialog> {
  DependencyDeletePreview? _preview;
  bool _loading = true;
  bool _deleting = false;
  bool _acknowledged = false;
  bool _activeAcknowledged = false;
  bool _finalLevelConfirmation = false;
  LevelDeleteChoice? _choice;
  String? _error;

  String get _item => switch (widget.kind) {
    DeleteItemKind.schoolClass => 'Class',
    DeleteItemKind.level => 'Level',
    DeleteItemKind.academicYear => 'Academic Year',
  };
  bool get _hasClasses =>
      widget.kind == DeleteItemKind.level &&
      (_preview?.requiresClassAction ?? false);
  bool get _deleteClasses =>
      _hasClasses && _choice == LevelDeleteChoice.deleteClasses;

  /// A level reporting zero contained classes. This is deliberately
  /// independent of `preview.canDelete`/`requiresConfirmation`/impact rows —
  /// per the confirmed contract, an empty level is unconditionally
  /// deletable once the preview has loaded, full stop. Treated as empty
  /// when the count is missing, matching the "not blocked by anything"
  /// default used everywhere else in this dialog.
  bool get _isEmptyLevel =>
      widget.kind == DeleteItemKind.level &&
      (_preview?.containedClasses ?? 0) == 0;

  bool get _canSubmit {
    if (_loading || _deleting || _preview == null) return false;
    if (_isEmptyLevel) return true;
    final preview = _preview!;
    return preview.canDelete &&
        (!preview.isActive || _activeAcknowledged) &&
        (!_hasClasses || _choice != null) &&
        (widget.kind != DeleteItemKind.academicYear || _acknowledged);
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // Clear every prior decision before loading — a fresh preview (whether
    // for a newly-opened level or a retry) must never inherit a stale
    // choice/acknowledgment/confirmation state from before.
    setState(() {
      _loading = true;
      _error = null;
      _preview = null;
      _acknowledged = false;
      _activeAcknowledged = false;
      _choice = null;
      _finalLevelConfirmation = false;
    });
    try {
      final preview = await widget.loadPreview();
      if (!mounted) return;
      setState(() {
        _preview = preview;
        _choice = preview.levelChoices.contains(LevelDeleteChoice.keepClasses)
            ? LevelDeleteChoice.keepClasses
            : null;
      });
    } on AdminDeleteException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted)
        setState(
          () => _error = 'Unable to load deletion impact. Please try again.',
        );
    } finally {
      if (mounted) setState(() => _loading = false);
      _logEmptyLevelDecision();
    }
  }

  void _logEmptyLevelDecision() {
    if (!kDebugMode || widget.kind != DeleteItemKind.level) return;
    final preview = _preview;
    debugPrint(
      '[LevelDelete] levelId=${preview?.entityId} '
      'classCount=${preview?.containedClasses} '
      'previewLoaded=${preview != null} '
      'canDelete=${preview?.canDelete} '
      'requiresClassAction=${preview?.requiresClassAction} '
      'selectedClassAction=$_choice '
      'isDeleting=$_deleting '
      'isEmptyLevel=$_isEmptyLevel '
      'FINAL_ENABLED=$_canSubmit',
    );
  }

  Future<void> _confirm() async {
    _logEmptyLevelDecision();
    if (!_canSubmit) return;
    if (_deleteClasses && !_finalLevelConfirmation) {
      setState(() => _finalLevelConfirmation = true);
      return;
    }
    setState(() {
      _deleting = true;
      _error = null;
    });
    try {
      final error = await widget.confirmedDelete(_hasClasses ? _choice : null);
      if (!mounted) return;
      if (error == null) {
        Navigator.pop(context, true);
        return;
      }
      setState(() => _error = safeDeleteError(error));
    } on AdminDeleteException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        if (error.preview != null) {
          _preview = error.preview;
          _acknowledged = false;
          _activeAcknowledged = false;
          _finalLevelConfirmation = false;
          _choice =
              _preview!.levelChoices.contains(LevelDeleteChoice.keepClasses)
              ? LevelDeleteChoice.keepClasses
              : null;
        }
      });
    } catch (_) {
      if (mounted) setState(() => _error = deleteFailureMessage);
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final preview = _preview;
    final enabled = _canSubmit;
    final nextState = _deleteClasses && !_finalLevelConfirmation;
    return PopScope(
      canPop: !_deleting,
      child: Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 12,
        shadowColor: _navy.withValues(alpha: .15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Delete $_item?',
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 18),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _card([
                          Text(
                            _item,
                            style: const TextStyle(color: Color(0xFF64748B)),
                          ),
                          Text(
                            widget.name,
                            style: const TextStyle(
                              color: _navy,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ]),
                        if (_loading)
                          const Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(
                              child: CircularProgressIndicator(color: _green),
                            ),
                          ),
                        if (preview != null) ...[
                          if (widget.kind == DeleteItemKind.academicYear &&
                              preview.isActive)
                            _card([
                              const Text(
                                'ACTIVE ACADEMIC YEAR',
                                style: TextStyle(
                                  color: Color(0xFF9A6700),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const Text(
                                'You are deleting the currently active academic year.',
                              ),
                            ]),
                          if (_finalLevelConfirmation) ...[
                            const Text('You are about to permanently delete:'),
                            Text(
                              widget.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text('${preview.containedClasses} Classes'),
                            const Text('and their related class data.'),
                          ] else ...[
                            Text(
                              widget.kind == DeleteItemKind.academicYear
                                  ? 'Deleting this academic year permanently removes all data that belongs specifically to this year.'
                                  : widget.kind == DeleteItemKind.schoolClass
                                  ? (preview.impact.isEmpty
                                        ? 'No related records were reported.'
                                        : 'This class has related data.')
                                  : (_hasClasses
                                        ? 'Review the related data before deleting this level.'
                                        : 'No classes are assigned to this level.'),
                            ),
                            if (preview.impact.isNotEmpty)
                              _card([
                                for (final entry in preview.impact.entries)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 5,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(child: Text(entry.key)),
                                        const SizedBox(width: 16),
                                        Text(
                                          '${entry.value}',
                                          style: const TextStyle(
                                            color: _navy,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ]),
                            if (_hasClasses) ...[
                              const Text(
                                'What should happen to classes in this level?',
                                style: TextStyle(
                                  color: _navy,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (preview.levelChoices.contains(
                                LevelDeleteChoice.keepClasses,
                              ))
                                _option(
                                  LevelDeleteChoice.keepClasses,
                                  'Keep Classes',
                                  'Remove the level assignment from these classes, but keep the classes.',
                                ),
                              if (preview.levelChoices.contains(
                                LevelDeleteChoice.deleteClasses,
                              ))
                                _option(
                                  LevelDeleteChoice.deleteClasses,
                                  'Delete Classes Too',
                                  'Permanently delete this level and all contained classes with their related class data.',
                                ),
                            ],
                            if (widget.kind == DeleteItemKind.academicYear) ...[
                              _card([
                                const Text(
                                  'The following will NOT be deleted:',
                                  style: TextStyle(
                                    color: _navy,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const Text(
                                  'Students • Teachers • Classes • Subjects • Levels\nTeacher Teaching Subjects • Class Subjects',
                                ),
                              ]),
                              if (preview.retainedImpact.isNotEmpty)
                                _card([
                                  const Text(
                                    'Master records kept; year links cleared:',
                                  ),
                                  for (final entry
                                      in preview.retainedImpact.entries)
                                    Text(
                                      entry.key + ': ' + entry.value.toString(),
                                    ),
                                ]),
                              if (preview.isActive)
                                CheckboxListTile(
                                  contentPadding: EdgeInsets.zero,
                                  value: _activeAcknowledged,
                                  activeColor: _green,
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  onChanged: _deleting
                                      ? null
                                      : (value) => setState(
                                          () => _activeAcknowledged =
                                              value == true,
                                        ),
                                  title: const Text(
                                    'I also confirm deletion of the currently active academic year.',
                                  ),
                                ),
                              CheckboxListTile(
                                contentPadding: EdgeInsets.zero,
                                value: _acknowledged,
                                activeColor: _green,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                onChanged: _deleting
                                    ? null
                                    : (v) => setState(
                                        () => _acknowledged = v == true,
                                      ),
                                title: const Text(
                                  "I understand that this academic year's data will be permanently deleted.",
                                ),
                              ),
                            ],
                          ],
                          const SizedBox(height: 12),
                          Text(
                            widget.kind == DeleteItemKind.schoolClass
                                ? 'Deleting this class will permanently remove the related records listed above.\n\nThis action cannot be undone.'
                                : 'This action cannot be undone.',
                          ),
                        ],
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _error!,
                            style: const TextStyle(color: Color(0xFFB42318)),
                          ),
                          if (preview == null)
                            TextButton(
                              onPressed: _loading ? null : _load,
                              child: const Text('Retry Preview'),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    OutlinedButton(
                      onPressed: _deleting
                          ? null
                          : () {
                              if (_finalLevelConfirmation) {
                                setState(() => _finalLevelConfirmation = false);
                              } else {
                                Navigator.pop(context, false);
                              }
                            },
                      child: Text(_finalLevelConfirmation ? 'Back' : 'Cancel'),
                    ),
                    FilledButton(
                      onPressed: enabled ? _confirm : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: nextState
                            ? _green
                            : const Color(0xFFB42318),
                        minimumSize: const Size(0, 48),
                      ),
                      child: _deleting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              nextState
                                  ? 'Continue'
                                  : _finalLevelConfirmation
                                  ? 'Delete Level & Classes'
                                  : 'Delete $_item',
                              textAlign: TextAlign.center,
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _option(LevelDeleteChoice choice, String title, String subtitle) =>
      Padding(
        padding: const EdgeInsets.only(top: 10),
        child: InkWell(
          onTap: _deleting ? null : () => setState(() => _choice = choice),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F7FB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _choice == choice ? _green : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  _choice == choice
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: _green,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: _navy,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(subtitle),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _card(List<Widget> children, {bool safe = false}) => Container(
    margin: const EdgeInsets.only(bottom: 14, top: 8),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: safe ? const Color(0xFFEFF8ED) : const Color(0xFFF4F7FB),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    ),
  );
}
