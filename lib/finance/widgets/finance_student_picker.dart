import 'dart:async';

import 'package:flutter/material.dart';

import 'package:kobac/school_admin/widgets/admin_desktop_kit.dart';
import 'package:kobac/school_admin/widgets/admin_feature_dialog.dart';

import 'package:kobac/finance/widgets/finance_ui.dart';

/// A student returned by a Finance student search. Only fields the backing
/// API actually returned are set.
class FinanceStudentChoice {
  final int id;
  final String name;
  final String? emis;
  final String? className;
  const FinanceStudentChoice({
    required this.id,
    required this.name,
    this.emis,
    this.className,
  });

  String get subtitle => [
    if (emis != null && emis!.trim().isNotEmpty) emis!.trim(),
    if (className != null && className!.trim().isNotEmpty) className!.trim(),
  ].join(' · ');
}

/// Result of one search: the matches, or a user-facing [error].
class FinanceStudentSearchResult {
  final List<FinanceStudentChoice> students;
  final String? error;
  const FinanceStudentSearchResult(this.students, [this.error]);
}

typedef FinanceStudentSearch =
    Future<FinanceStudentSearchResult> Function(String query);

/// The one Finance student selector (Student Discounts for both roles).
///
/// Keyboard-safe by construction: it is an [AdminFeatureDialog], whose
/// [Dialog] shell already insets by `MediaQuery.viewInsets`. The header and
/// the search field are pinned; only the results area flexes and scrolls, so
/// with the keyboard open nothing has a fixed height that could overflow.
Future<FinanceStudentChoice?> showFinanceStudentPicker(
  BuildContext context, {
  required FinanceStudentSearch search,
  String? note,
}) => showDialog<FinanceStudentChoice>(
  context: context,
  barrierColor: Colors.black38,
  builder: (_) => _FinanceStudentPickerDialog(search: search, note: note),
);

enum _PickerState { initial, loading, results, empty, error }

class _FinanceStudentPickerDialog extends StatefulWidget {
  final FinanceStudentSearch search;
  final String? note;
  const _FinanceStudentPickerDialog({required this.search, this.note});

  @override
  State<_FinanceStudentPickerDialog> createState() =>
      _FinanceStudentPickerDialogState();
}

class _FinanceStudentPickerDialogState
    extends State<_FinanceStudentPickerDialog> {
  static const _minChars = 2;
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();
  Timer? _debounce;
  int _request = 0;
  _PickerState _state = _PickerState.initial;
  List<FinanceStudentChoice> _results = const [];
  String? _error;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    if (value.trim().length < _minChars) {
      _request++; // drop any in-flight response
      setState(() => _state = _PickerState.initial);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 250), () => _run(value));
  }

  Future<void> _run(String value) async {
    final query = value.trim();
    if (query.isEmpty) return;
    final request = ++_request;
    setState(() => _state = _PickerState.loading);
    final result = await widget.search(query);
    if (!mounted || request != _request) return;
    setState(() {
      _results = result.students;
      _error = result.error;
      _state = result.error != null
          ? _PickerState.error
          : result.students.isEmpty
          ? _PickerState.empty
          : _PickerState.results;
    });
  }

  void _close([FinanceStudentChoice? choice]) {
    FocusManager.instance.primaryFocus?.unfocus(); // dismiss the keyboard first
    Navigator.pop(context, choice);
  }

  Widget _message(IconData icon, String text, {Color? color}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 20),
    child: Column(
      children: [
        Icon(
          icon,
          size: 30,
          color: (color ?? kAdminNavy).withValues(alpha: .45),
        ),
        const SizedBox(height: 8),
        Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(color: color ?? kAdminTextSecondary, height: 1.35),
        ),
      ],
    ),
  );

  Widget _body() {
    switch (_state) {
      case _PickerState.initial:
        return _message(
          Icons.person_search_rounded,
          'Search by name or EMIS to find a student.',
        );
      case _PickerState.loading:
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: CircularProgressIndicator(color: kAdminNavy)),
        );
      case _PickerState.empty:
        return _message(Icons.search_off_rounded, 'No students found.');
      case _PickerState.error:
        return Column(
          children: [
            FinanceInlineError(
              _error ?? 'Could not load students. Please try again.',
            ),
            const SizedBox(height: 8),
            AdminSecondaryButton(
              label: 'Retry',
              icon: Icons.refresh_rounded,
              onPressed: () => _run(_controller.text),
            ),
          ],
        );
      case _PickerState.results:
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kAdminBorder),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < _results.length; i++) ...[
                if (i > 0) const Divider(height: 1, color: kAdminBorder),
                InkWell(
                  onTap: () => _close(_results[i]),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        FinanceInitialAvatar(_results[i].name, size: 36),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _results[i].name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: kAdminNavy,
                                ),
                              ),
                              if (_results[i].subtitle.isNotEmpty)
                                Text(
                                  _results[i].subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: kAdminTextSecondary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: kAdminTextSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) => AdminFeatureDialog(
    title: 'Select Student',
    onClose: _close,
    // Only the search field is pinned; everything else (including the note)
    // scrolls, so the pinned part stays small enough for any keyboard.
    pinned: FinanceSearchField(
      controller: _controller,
      focusNode: _focus,
      hint: 'Search by name or EMIS',
      autofocus: true,
      onChanged: _onChanged,
      onSubmitted: _run,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.note != null) ...[
          Text(
            widget.note!,
            style: const TextStyle(fontSize: 12.5, color: kAdminTextSecondary),
          ),
          const SizedBox(height: 4),
        ],
        _body(),
      ],
    ),
  );
}
