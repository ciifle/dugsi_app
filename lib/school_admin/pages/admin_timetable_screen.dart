import 'package:flutter/material.dart';
import 'package:kobac/services/timetables_service.dart';
import 'package:kobac/services/classes_service.dart';
import 'package:kobac/services/subjects_service.dart';
import 'package:kobac/services/teachers_service.dart';
import 'package:kobac/services/school_admin_assignments_service.dart';
import 'package:kobac/services/api_error_helpers.dart';
import 'package:kobac/school_admin/pages/admin_assignments_screen.dart';
import 'package:kobac/school_admin/pages/timetable_detail_page.dart';
import 'package:kobac/school_admin/widgets/delete_confirm_dialog.dart';
import 'package:kobac/widgets/form_3d/form_3d.dart';
import 'package:kobac/services/periods_service.dart';

const Color kPrimaryBlue = Color(0xFF023471);
const Color kPrimaryGreen = Color(0xFF5AB04B);
const Color kBgColor = Color(0xFFF0F3F7);
const Color kTextPrimary = Color(0xFF2D3436);
const double kCardRadius = 28.0;

const List<String> kDays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

class AdminTimetableScreen extends StatefulWidget {
  final bool openAddSlotOnLoad;

  const AdminTimetableScreen({Key? key, this.openAddSlotOnLoad = false}) : super(key: key);

  @override
  State<AdminTimetableScreen> createState() => _AdminTimetableScreenState();
}

class _AdminTimetableScreenState extends State<AdminTimetableScreen> {
  int? _selectedClassId; // null = All classes
  String _selectedDay = 'MON';
  late Future<TimetableResult<List<TimetableSlotModel>>> _timetablesFuture;
  List<ClassModel> _classes = [];
  List<SubjectModel> _subjects = [];
  List<TeacherModel> _teachers = [];
  bool _refDataLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadRefData();
    _loadTimetables();
  }

  Future<void> _loadRefData() async {
    final classesResult = await ClassesService().listClasses();
    final subjectsResult = await SubjectsService().listSubjects();
    final teachersResult = await TeachersService().listTeachers();
    if (!mounted) return;
    setState(() {
      if (classesResult is ClassSuccess<List<ClassModel>>) _classes = classesResult.data;
      if (subjectsResult is SubjectSuccess<List<SubjectModel>>) _subjects = subjectsResult.data;
      if (teachersResult is TeacherSuccess<List<TeacherModel>>) _teachers = teachersResult.data;
      _refDataLoaded = true;
    });
    if (widget.openAddSlotOnLoad && mounted) {
      _openAddSlot();
    }
  }

  void _loadTimetables() {
    setState(() {
      _timetablesFuture = TimetablesService().listTimetables(classId: _selectedClassId);
    });
  }

  String _className(int id) {
    for (final c in _classes) {
      if (c.id == id) return c.name;
    }
    return '—';
  }
  String _subjectName(int id) {
    for (final s in _subjects) {
      if (s.id == id) return s.name;
    }
    return '—';
  }
  String _teacherName(int id) {
    for (final t in _teachers) {
      if (t.id == id) return t.fullName;
    }
    return '—';
  }

  List<TimetableSlotModel> _slotsForDay(List<TimetableSlotModel> slots) {
    final list = slots.where((s) => s.day.toUpperCase() == _selectedDay).toList();
    list.sort((a, b) => a.startTime.compareTo(b.startTime));
    return list;
  }

  Future<void> _openAddSlot() async {
    if (!_refDataLoaded) return;
    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => _TimetableSlotFormDialog(
        classes: _classes,
        subjects: _subjects,
        initialClassId: _selectedClassId,
        initialDay: _selectedDay,
        isCreate: true,
        onSave: _createSlotFromDialog,
      ),
    );
    if (created == true && mounted) {
      _loadTimetables();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Timetable slot created'), backgroundColor: kPrimaryGreen),
      );
    }
  }

  Future<bool> _createSlotFromDialog(BuildContext ctx, Map<String, dynamic> payload) async {
    final result = await TimetablesService().createTimetableSlot(payload);
    if (result is TimetableSuccess) return true;
    if (ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(content: Text((result as TimetableError).message), backgroundColor: Colors.red),
      );
    }
    return false;
  }

  Future<void> _openEditSlot(TimetableSlotModel slot) async {
    final updated = await showDialog<bool>(
      context: context,
      builder: (ctx) => _TimetableSlotFormDialog(
        classes: _classes,
        subjects: _subjects,
        initialClassId: slot.classId,
        initialSubjectId: slot.subjectId,
        initialTeacherId: slot.teacherId,
        initialDay: slot.day,
        initialPeriodId: slot.periodId,
        slotId: slot.id,
        isCreate: false,
        onSave: (ctx, payload) => _updateSlotFromDialog(ctx, slot.id, payload),
      ),
    );
    if (updated == true && mounted) {
      _loadTimetables();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Timetable slot updated'), backgroundColor: kPrimaryGreen),
      );
    }
  }

  Future<bool> _updateSlotFromDialog(BuildContext ctx, int id, Map<String, dynamic> payload) async {
    final result = await TimetablesService().updateTimetable(id, payload);
    if (result is TimetableSuccess) return true;
    if (ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(content: Text((result as TimetableError).message), backgroundColor: Colors.red),
      );
    }
    return false;
  }

  Future<void> _deleteSlot(TimetableSlotModel slot) async {
    final subjectName = _subjectName(slot.subjectId);
    final confirmed = await showDeleteConfirmDialog(
      context,
      title: 'Delete timetable slot?',
      message: 'Delete this slot ($subjectName, ${slot.startTime}-${slot.endTime}, ${slot.day})?',
    );
    if (confirmed != true) return;
    final result = await TimetablesService().deleteTimetable(slot.id);
    if (!mounted) return;
    if (result is TimetableSuccess) {
      _loadTimetables();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Slot deleted'), backgroundColor: kPrimaryGreen),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text((result as TimetableError).message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      body: SafeArea(
        child: Container(
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
                    _BackButton(onPressed: () => Navigator.pop(context)),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        "Timetable",
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kPrimaryBlue),
                      ),
                    ),
                    _AddButton(onPressed: _openAddSlot),
                  ],
                ),
              ),
              if (_refDataLoaded) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: FormCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int?>(
                        value: _selectedClassId,
                        isExpanded: true,
                        hint: const Text('All classes'),
                        items: [
                          const DropdownMenuItem<int?>(value: null, child: Text('All classes')),
                          ..._classes.map((c) => DropdownMenuItem<int?>(value: c.id, child: Text(c.name))),
                        ],
                        onChanged: (v) {
                          setState(() {
                            _selectedClassId = v;
                            _loadTimetables();
                          });
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: kDays.map((day) {
                      final isSelected = _selectedDay == day;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => setState(() => _selectedDay = day),
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected ? kPrimaryBlue : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [BoxShadow(color: kPrimaryBlue.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))],
                              ),
                              child: Text(
                                day,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? Colors.white : kPrimaryBlue,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => _loadTimetables(),
                  color: kPrimaryGreen,
                  child: FutureBuilder<TimetableResult<List<TimetableSlotModel>>>(
                    future: _timetablesFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: kPrimaryGreen));
                      }
                      if (snapshot.hasError) {
                        final msg = userFriendlyMessage(snapshot.error!, null, 'AdminTimetableScreen');
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                                const SizedBox(height: 12),
                                Text(msg, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey[800])),
                                const SizedBox(height: 16),
                                TextButton.icon(onPressed: _loadTimetables, icon: const Icon(Icons.refresh), label: const Text('Retry')),
                              ],
                            ),
                          ),
                        );
                      }
                      final result = snapshot.data;
                      if (result == null) return const Center(child: Text('No data'));
                      if (result is TimetableError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                                const SizedBox(height: 12),
                                Text(result.message, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey[800])),
                                const SizedBox(height: 16),
                                TextButton.icon(onPressed: _loadTimetables, icon: const Icon(Icons.refresh), label: const Text('Retry')),
                              ],
                            ),
                          ),
                        );
                      }
                      final slots = _slotsForDay((result as TimetableSuccess<List<TimetableSlotModel>>).data);
                      if (slots.isEmpty) {
                        return ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                            Center(
                              child: Column(
                                children: [
                                  Icon(Icons.schedule_rounded, size: 60, color: Colors.grey[300]),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No slots for $_selectedDay yet',
                                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                                  ),
                                  const SizedBox(height: 16),
                                  TextButton.icon(
                                    onPressed: _openAddSlot,
                                    icon: const Icon(Icons.add_rounded),
                                    label: const Text('Add Slot'),
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
                        itemCount: slots.length,
                        itemBuilder: (context, index) {
                          final slot = slots[index];
                          return _SlotCard(
                            slot: slot,
                            subjectName: _subjectName(slot.subjectId),
                            teacherName: _teacherName(slot.teacherId),
                            className: _selectedClassId == null ? _className(slot.classId) : null,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => TimetableDetailPage(slotId: slot.id),
                              ),
                            ),
                            onEdit: () => _openEditSlot(slot),
                            onDelete: () => _deleteSlot(slot),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SlotCard extends StatelessWidget {
  final TimetableSlotModel slot;
  final String subjectName;
  final String teacherName;
  final String? className;
  final VoidCallback? onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SlotCard({
    required this.slot,
    required this.subjectName,
    required this.teacherName,
    this.className,
    this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  String _formatShift(String? shift) {
    if (shift == null || shift.isEmpty) return '';
    final s = shift.toLowerCase();
    if (s == 'morning') return 'Morning';
    if (s == 'afternoon') return 'Afternoon';
    return shift;
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = '${_timeDisplay(slot.startTime)} - ${_timeDisplay(slot.endTime)}';
    final shift = _formatShift(slot.period?.shift);
    final isAfternoon = slot.period?.shift.toLowerCase() == 'afternoon';
    final periodName = slot.period != null ? (slot.period!.name.isNotEmpty ? slot.period!.name : 'Period ${slot.period!.periodNumber}') : null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(kCardRadius),
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(kCardRadius),
            boxShadow: [
              BoxShadow(color: kPrimaryBlue.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 6)),
            ],
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(kCardRadius),
            child: Stack(
              children: [
                // Shift indicator bar
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 4,
                    color: isAfternoon ? Colors.orange : kPrimaryBlue,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: (isAfternoon ? Colors.orange : kPrimaryBlue).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          isAfternoon ? Icons.wb_twilight_rounded : Icons.wb_sunny_rounded,
                          color: isAfternoon ? Colors.orange : kPrimaryBlue,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                if (periodName != null)
                                  Text(
                                    periodName,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: kPrimaryBlue,
                                    ),
                                  ),
                                if (shift.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: (isAfternoon ? Colors.orange : kPrimaryBlue).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      shift.toUpperCase(),
                                      style: TextStyle(
                                        color: isAfternoon ? Colors.orange : kPrimaryBlue,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subjectName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: kTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(Icons.person_outline_rounded, size: 14, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    teacherName,
                                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            if (className != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Row(
                                  children: [
                                    Icon(Icons.class_outlined, size: 14, color: Colors.grey[500]),
                                    const SizedBox(width: 4),
                                    Text(className!, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(Icons.access_time_rounded, size: 14, color: kPrimaryGreen),
                                const SizedBox(width: 4),
                                Text(
                                  timeStr,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: kPrimaryGreen,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20, color: kPrimaryGreen),
                            onPressed: onEdit,
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(8),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline, size: 20, color: Colors.red[400]),
                            onPressed: onDelete,
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(8),
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
  }

  String _timeDisplay(String t) {
    final parts = t.split(':');
    if (parts.length >= 2) return '${parts[0]}:${parts[1]}';
    return t;
  }
}

class _TimetableSlotFormDialog extends StatefulWidget {
  final List<ClassModel> classes;
  final List<SubjectModel> subjects;
  final int? initialClassId;
  final int? initialSubjectId;
  final int? initialTeacherId;
  final String initialDay;
  final int? initialPeriodId;
  final int? slotId;
  final bool isCreate;
  final Future<bool> Function(BuildContext ctx, Map<String, dynamic> payload) onSave;

  const _TimetableSlotFormDialog({
    required this.classes,
    required this.subjects,
    this.initialClassId,
    this.initialSubjectId,
    this.initialTeacherId,
    this.initialDay = 'MON',
    this.initialPeriodId,
    this.slotId,
    required this.isCreate,
    required this.onSave,
  });

  @override
  State<_TimetableSlotFormDialog> createState() => _TimetableSlotFormDialogState();
}

class _TimetableSlotFormDialogState extends State<_TimetableSlotFormDialog> {
  late int? _classId;
  late int? _subjectId;
  late int? _teacherId;
  late String _day;
  late int? _periodId;
  bool _submitting = false;
  List<TeacherModel> _classTeachers = [];
  List<ClassSubjectItem> _classSubjects = [];
  List<PeriodModel> _periods = [];
  bool _loadingTeachers = false;
  bool _loadingSubjects = false;
  bool _loadingPeriods = true;

  @override
  void initState() {
    super.initState();
    _classId = widget.initialClassId;
    _subjectId = widget.initialSubjectId;
    _teacherId = widget.initialTeacherId;
    _day = widget.initialDay;
    _periodId = widget.initialPeriodId;
    _loadPeriods();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialClassId != null && widget.initialClassId! > 0) {
        _loadClassSubjects(widget.initialClassId!);
      }
      if (widget.initialClassId != null && widget.initialSubjectId != null) {
        _loadTeachers(widget.initialClassId!, widget.initialSubjectId!);
      }
    });
  }

  Future<void> _loadClassSubjects(int classId) async {
    setState(() => _loadingSubjects = true);
    final result = await SchoolAdminAssignmentsService().listClassSubjects(classId);
    if (!mounted) return;
    setState(() {
      _loadingSubjects = false;
      if (result is AssignmentSuccess<List<ClassSubjectItem>>) {
        _classSubjects = result.data;
        final currentId = _subjectId;
        final inList = currentId != null && _classSubjects.any((s) => s.id == currentId);
        if (!inList) _subjectId = null;
      } else {
        _classSubjects = [];
        _subjectId = null;
      }
    });
  }

  Future<void> _loadTeachers(int classId, int subjectId) async {
    setState(() => _loadingTeachers = true);
    final result = await SchoolAdminAssignmentsService().listClassSubjectTeachers(classId, subjectId);
    if (!mounted) return;
    setState(() {
      _loadingTeachers = false;
      if (result is AssignmentSuccess<List<TeacherModel>>) {
        _classTeachers = result.data;
        final currentId = _teacherId;
        final inList = currentId != null && _classTeachers.any((t) => t.id == currentId);
        if (!inList) _teacherId = null;
      } else {
        _classTeachers = [];
        _teacherId = null;
      }
    });
  }

  Future<void> _loadPeriods() async {
    final result = await PeriodsService().getPeriods();
    if (!mounted) return;
    setState(() {
      _loadingPeriods = false;
      if (result is PeriodSuccess<List<PeriodModel>>) {
        _periods = result.data;
        if (_periodId != null && !_periods.any((p) => p.id == _periodId)) {
          _periodId = null;
        }
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// Subject value for dropdown: only set if it exists in _classSubjects to avoid Flutter assertion.
  int? get _effectiveSubjectId {
    if (_subjectId == null) return null;
    if (_classSubjects.any((s) => s.id == _subjectId)) return _subjectId;
    return null;
  }

  List<DropdownMenuItem<int?>> get _subjectDropdownItems {
    final items = <DropdownMenuItem<int?>>[
      DropdownMenuItem<int?>(
        value: null,
        child: Text(
          _loadingSubjects ? 'Loading...' : (_classId == null ? 'Select class first' : 'Select subject'),
        ),
      ),
    ];
    final seen = <int>{};
    for (final s in _classSubjects) {
      if (seen.add(s.id)) items.add(DropdownMenuItem<int?>(value: s.id, child: Text(s.name)));
    }
    return items;
  }

  /// Teacher value for dropdown: only set if it exists in _classTeachers.
  int? get _effectiveTeacherId {
    if (_teacherId == null) return null;
    if (_classTeachers.any((t) => t.id == _teacherId)) return _teacherId;
    return null;
  }
  
  int? get _effectivePeriodId {
    if (_periodId == null) return null;
    if (_periods.any((p) => p.id == _periodId)) return _periodId;
    return null;
  }

  bool _canSubmit() {
    if (_submitting) return false;
    if (widget.isCreate) {
      if (_classId == null || _subjectId == null || _teacherId == null || _periodId == null) return false;
    }
    return true;
  }

  Future<void> _submit() async {
    if (widget.isCreate && (_classId == null || _subjectId == null || _teacherId == null || _periodId == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select class, subject, teacher and period'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_submitting) return;
    setState(() => _submitting = true);
    final payload = <String, dynamic>{
      'day': _day,
    };
    if (_periodId != null) {
      payload['period_id'] = _periodId!;
    }
    if (widget.isCreate) {
      if (_classId == null || _subjectId == null || _teacherId == null) {
        setState(() => _submitting = false);
        return;
      }
      payload['class_id'] = _classId!;
      payload['subject_id'] = _subjectId!;
      payload['teacher_id'] = _teacherId!;
    } else {
      if (_classId != null) payload['class_id'] = _classId!;
      if (_subjectId != null) payload['subject_id'] = _subjectId!;
      if (_teacherId != null) payload['teacher_id'] = _teacherId!;
    }
    final ok = await widget.onSave(context, payload);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
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
                widget.isCreate ? 'Add Timetable Slot' : 'Edit Timetable Slot',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kPrimaryBlue),
              ),
              const SizedBox(height: 20),
              Select3D<int?>(
                value: _classId,
                label: 'Class',
                items: [
                  const DropdownMenuItem<int?>(value: null, child: Text('Select class')),
                  ...widget.classes.map((c) => DropdownMenuItem<int?>(value: c.id, child: Text(c.name))),
                ],
                onChanged: (v) {
                  setState(() {
                    _classId = v;
                    _subjectId = null;
                    _teacherId = null;
                    _classTeachers = [];
                    _classSubjects = [];
                  });
                  if (v != null && v > 0) _loadClassSubjects(v);
                },
              ),
              const SizedBox(height: 16),
              Select3D<int?>(
                value: _effectiveSubjectId,
                label: 'Subject',
                items: _subjectDropdownItems,
                onChanged: _loadingSubjects ? null : (v) {
                  setState(() {
                    _subjectId = v;
                    _teacherId = null;
                    _classTeachers = [];
                  });
                  if (v != null && _classId != null) _loadTeachers(_classId!, v);
                },
              ),
              if (_classId != null && !_loadingSubjects && _classSubjects.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'No subjects for this class. Add subjects via class timetable or create subjects first.',
                    style: TextStyle(fontSize: 13, color: Colors.orange[800]),
                  ),
                ),
              const SizedBox(height: 16),
              Select3D<int?>(
                value: _effectiveTeacherId,
                label: 'Teacher',
                items: [
                  DropdownMenuItem<int?>(
                    value: null,
                    child: Text(
                      _loadingTeachers
                          ? 'Loading...'
                          : _subjectId == null
                              ? 'Select subject first'
                              : _classTeachers.isEmpty
                                  ? 'No teacher for this class+subject'
                                  : 'Select teacher',
                    ),
                  ),
                  ..._classTeachers.map((t) => DropdownMenuItem<int?>(value: t.id, child: Text(t.fullName ?? t.email ?? 'Teacher ${t.id}'))),
                ],
                onChanged: (_subjectId == null || _loadingTeachers) ? null : (v) => setState(() => _teacherId = v),
              ),
              if (_classId != null && _subjectId != null && !_loadingTeachers && _classTeachers.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'No teacher assigned for this class & subject yet. Assign a teacher or choose another subject.',
                        style: TextStyle(fontSize: 13, color: Colors.orange[800]),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop(false);
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminAssignmentsScreen()));
                        },
                        icon: const Icon(Icons.assignment_rounded, size: 18),
                        label: const Text('Go to Assignments'),
                        style: TextButton.styleFrom(foregroundColor: kPrimaryBlue),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              Select3D<String>(
                value: _day,
                label: 'Day',
                items: kDays.map((d) => DropdownMenuItem<String>(value: d, child: Text(d))).toList(),
                onChanged: (v) => setState(() => _day = v ?? 'MON'),
              ),
              const SizedBox(height: 16),
              Select3D<int?>(
                value: _effectivePeriodId,
                label: 'Period',
                items: [
                  DropdownMenuItem<int?>(
                    value: null,
                    child: Text(_loadingPeriods ? 'Loading periods...' : 'Select period'),
                  ),
                  ..._periods.map((p) => DropdownMenuItem<int?>(
                    value: p.id,
                    child: Text('${p.name.isNotEmpty ? p.name : 'Period ${p.periodNumber}'} (${p.shift.isNotEmpty ? p.shift : 'No Shift'}) - ${p.startTime.substring(0, 5)} to ${p.endTime.substring(0, 5)}'),
                  )),
                ],
                onChanged: _loadingPeriods ? null : (v) => setState(() => _periodId = v),
              ),
              const SizedBox(height: 24),
              Row(
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
                      label: widget.isCreate ? 'Create' : 'Save',
                      onPressed: _canSubmit() ? _submit : null,
                      loading: _submitting,
                      height: 48,
                    ),
                  ),
                ],
              ),
            ],
          ),
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
