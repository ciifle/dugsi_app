import 'package:flutter/material.dart';
import 'package:kobac/services/teacher_service.dart';

// ---------- COLOR PALETTE (Matching Student Dashboard) ----------
const Color kPrimaryBlue = Color(0xFF023471); // Dark blue
const Color kPrimaryGreen = Color(0xFF5AB04B); // Green

// Derived colors (shades/tints of the two main colors)
const Color kSoftBlue = Color(0xFFE6F0FF); // Light tint of blue
const Color kSoftGreen = Color(0xFFEDF7EB); // Light tint of green
const Color kDarkGreen = Color(0xFF3A7A30); // Darker shade of green
const Color kDarkBlue = Color(0xFF01255C); // Darker shade of blue
const Color kTextPrimary = Color(0xFF2D3436); // Dark gray
const Color kTextSecondary = Color(0xFF636E72); // Medium gray
const Color kErrorColor = Color(0xFFEF4444); // Red
const Color kSoftOrange = Color(0xFFF59E0B); // Amber
const Color kSuccessColor = Color(0xFF5AB04B); // Green for present
const Color kCardColor = Colors.white;

// ================== MAIN SCREEN =====================
class TeacherAttendanceScreen extends StatefulWidget {
  const TeacherAttendanceScreen({Key? key}) : super(key: key);

  @override
  State<TeacherAttendanceScreen> createState() =>
      _TeacherAttendanceScreenState();
}

class _TeacherAttendanceScreenState extends State<TeacherAttendanceScreen> {
  List<TeacherAssignmentModel> _assignments = [];
  int? _selectedClassId;
  String _selectedClassName = 'Select class';
  DateTime _attendanceDate = DateTime.now();
  List<TeacherStudentModel> _students = [];
  List<String> _statusList = []; // PRESENT | ABSENT | LATE, same order as _students
  bool _studentsLoading = false;
  String? _studentsError; // e.g. 404 message
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<TeacherStudentModel> get currentClassStudents => _students;

  List<TeacherStudentModel> get filteredStudents {
    if (_searchQuery.isEmpty) return _students;
    final q = _searchQuery.toLowerCase();
    return _students.where((s) {
      final name = (s.name ?? '').toLowerCase();
      final emis = (s.emisNumber ?? '').toLowerCase();
      return name.contains(q) || emis.contains(q);
    }).toList();
  }

  List<String> get filteredStatusList {
    return filteredStudents.map((s) {
      final i = _students.indexOf(s);
      return i >= 0 && i < _statusList.length ? _statusList[i] : 'PRESENT';
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadAssignments();
  }

  Future<void> _loadAssignments() async {
    final result = await TeacherService().listAssignments();
    if (!mounted) return;
    setState(() {
      if (result is TeacherSuccess<List<TeacherAssignmentModel>>) {
        _assignments = result.data;
        if (_assignments.isNotEmpty && _selectedClassId == null) {
          final first = _assignments.first;
          _selectedClassId = first.classId;
          _selectedClassName = first.className.isEmpty ? 'Class ${first.classId}' : first.className;
          _loadStudents(first.classId);
        }
      }
    });
  }

  Future<void> _loadStudents(int classId) async {
    setState(() {
      _studentsLoading = true;
      _studentsError = null;
      _students = [];
      _statusList = [];
    });
    final result = await TeacherService().listStudentsByClass(classId);
    if (!mounted) return;
    setState(() {
      _studentsLoading = false;
      if (result is TeacherSuccess<List<TeacherStudentModel>>) {
        _students = result.data;
        _statusList = List.filled(_students.length, 'PRESENT');
        _studentsError = null;
      } else {
        _studentsError = (result as TeacherError).message;
      }
    });
  }

  void _onClassChanged(int? classId) {
    if (classId == null) return;
    final a = _assignments.cast<TeacherAssignmentModel?>().firstWhere(
          (e) => e?.classId == classId,
          orElse: () => null,
        );
    final name = a?.className.isEmpty == true ? 'Class $classId' : (a?.className ?? 'Class $classId');
    setState(() {
      _selectedClassId = classId;
      _selectedClassName = name;
      _searchQuery = '';
      _searchController.clear();
    });
    _loadStudents(classId);
  }

  /// Unique classes from assignments (by classId).
  List<({int id, String name})> get _uniqueClasses {
    final seen = <int>{};
    final out = <({int id, String name})>[];
    for (final a in _assignments) {
      if (seen.add(a.classId)) {
        out.add((id: a.classId, name: a.className.isEmpty ? 'Class ${a.classId}' : a.className));
      }
    }
    return out;
  }

  void _setStatus(int studentIndex, String status) {
    if (studentIndex < 0 || studentIndex >= _statusList.length) return;
    setState(() {
      _statusList[studentIndex] = status;
    });
  }

  void _onDateTapped() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _attendanceDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && mounted) setState(() => _attendanceDate = picked);
  }

  Future<void> _saveAttendance() async {
    if (_selectedClassId == null || _students.isEmpty) return;
    final dateStr = '${_attendanceDate.year}-${_attendanceDate.month.toString().padLeft(2, '0')}-${_attendanceDate.day.toString().padLeft(2, '0')}';
    final records = <TeacherAttendanceRecord>[];
    for (var i = 0; i < _students.length; i++) {
      records.add(TeacherAttendanceRecord(
        studentId: _students[i].id,
        status: i < _statusList.length ? _statusList[i] : 'PRESENT',
      ));
    }
    final result = await TeacherService().takeAttendance(
      classId: _selectedClassId!,
      date: dateStr,
      records: records,
    );
    if (!mounted) return;
    if (result is TeacherSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Attendance saved.'),
          backgroundColor: kPrimaryGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text((result as TeacherError).message),
          backgroundColor: kErrorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
    });
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  void _updateSearchQuery(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return "${date.day} ${months[date.month - 1]} ${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    final filtered = filteredStudents;
    final filteredStatus = filteredStatusList;
    final uniqueClasses = _uniqueClasses;

    return Scaffold(
      backgroundColor: kSoftBlue,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ---------------- APP BAR WITH BIG TEXT ----------------
          SliverAppBar(
            expandedHeight: _isSearching ? 100 : 120, // Kor u qaaday height
            pinned: true,
            backgroundColor: kPrimaryBlue,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [kPrimaryBlue, kPrimaryBlue, kPrimaryGreen],
                  stops: const [0.3, 0.7, 1.0],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(
                  bottom: 20,
                ), // Kor u qaaday text-ka
                centerTitle: true,
                title: _isSearching
                    ? null
                    : const Text(
                        "Attendance",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 28, // FONT SIZE AAD U WEYN
                        ),
                      ),
              ),
            ),
            leading: Container(
              margin: const EdgeInsets.only(left: 12, top: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                  size: 28, // ICON WEYN
                ),
                onPressed: () => Navigator.pop(context),
                padding: const EdgeInsets.all(10),
              ),
            ),
            actions: [
              if (_isSearching)
                Container(
                  margin: const EdgeInsets.only(right: 12, top: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: _stopSearch,
                    padding: const EdgeInsets.all(10),
                    constraints: const BoxConstraints(),
                  ),
                )
              else
                Container(
                  margin: const EdgeInsets.only(right: 12, top: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.search_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: _startSearch,
                    padding: const EdgeInsets.all(10),
                    constraints: const BoxConstraints(),
                  ),
                ),
            ],
            bottom: _isSearching
                ? PreferredSize(
                    preferredSize: const Size.fromHeight(60),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          autofocus: true,
                          onChanged: _updateSearchQuery,
                          decoration: InputDecoration(
                            hintText: 'Search students...',
                            hintStyle: TextStyle(
                              color: kTextSecondary,
                              fontSize: 15,
                            ),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color: kPrimaryBlue,
                              size: 22,
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: Icon(
                                      Icons.clear,
                                      color: kTextSecondary,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                      _updateSearchQuery('');
                                    },
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                          style: const TextStyle(
                            color: kTextPrimary,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  )
                : null,
          ),

          // ---------------- MAIN CONTENT ----------------
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ---------------- HEADER CARD WITH DROPDOWN ----------------
                _HeaderCardWithDropdown(
                  uniqueClasses: uniqueClasses,
                  selectedClassId: _selectedClassId,
                  selectedClassName: _selectedClassName,
                  onClassChanged: _onClassChanged,
                  studentCount: currentClassStudents.length,
                  formattedDate: _formatDate(_attendanceDate),
                  onDateTap: _onDateTapped,
                  studentsLoading: _studentsLoading,
                ),

                const SizedBox(height: 20),

                // ---------------- SEARCH RESULT COUNT ----------------
                if (_searchQuery.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 6),
                    child: Text(
                      'Found ${filtered.length} student${filtered.length != 1 ? 's' : ''}',
                      style: TextStyle(
                        color: kTextSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                // ---------------- STUDENTS HEADER ----------------
                if (_searchQuery.isEmpty) _buildStudentsHeader(filtered.length),

                const SizedBox(height: 12),

                // ---------------- STUDENT LIST ERROR (e.g. 404) ----------------
                if (_studentsError != null && !_studentsLoading) _buildStudentsError(),

                // ---------------- STUDENT CARDS ----------------
                if (filtered.isNotEmpty && _studentsError == null)
                  ...List.generate(
                    filtered.length,
                    (index) {
                      final student = filtered[index];
                      final status = filteredStatus[index];
                      final originalIndex = _students.indexOf(student);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _StudentAttendanceCard(
                          name: student.name ?? 'Student ${student.id}',
                          roll: student.emisNumber ?? '${student.id}',
                          status: status,
                          onStatusChanged: (newStatus) => _setStatus(originalIndex, newStatus),
                        ),
                      );
                    },
                  )
                else if (_studentsError == null && !_studentsLoading)
                  _buildEmptyState(),

                const SizedBox(height: 20),

                // ---------------- SAVE BUTTON ----------------
                _SaveButton(
                  onPressed: _students.isEmpty || _selectedClassId == null ? null : _saveAttendance,
                ),

                const SizedBox(height: 16),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsHeader(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kPrimaryBlue, kPrimaryGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.people_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              "Student List",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: kTextPrimary,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: kPrimaryGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count students',
            style: TextStyle(
              color: kPrimaryGreen,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStudentsError() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: kPrimaryBlue.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, color: kSoftOrange, size: 28),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Student list endpoint is missing. Ask admin to enable teacher student listing.',
                  style: TextStyle(fontSize: 14, color: kTextPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Attendance cannot be taken until students are available for your assigned classes.',
            style: TextStyle(fontSize: 12, color: kTextSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kSoftBlue,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _searchQuery.isNotEmpty
                    ? Icons.search_off_rounded
                    : Icons.people_outline_rounded,
                color: kPrimaryBlue,
                size: 56,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isNotEmpty ? 'No students found' : 'No students',
              style: TextStyle(
                color: kTextPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try different search terms'
                  : 'Select a class to load students',
              style: TextStyle(color: kTextSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

// ================== HEADER CARD WITH DROPDOWN =====================
class _HeaderCardWithDropdown extends StatelessWidget {
  final List<({int id, String name})> uniqueClasses;
  final int? selectedClassId;
  final String selectedClassName;
  final ValueChanged<int?> onClassChanged;
  final int studentCount;
  final String formattedDate;
  final VoidCallback? onDateTap;
  final bool studentsLoading;

  const _HeaderCardWithDropdown({
    required this.uniqueClasses,
    required this.selectedClassId,
    required this.selectedClassName,
    required this.onClassChanged,
    required this.studentCount,
    required this.formattedDate,
    this.onDateTap,
    this.studentsLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kPrimaryBlue.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Class Dropdown
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kPrimaryBlue, kPrimaryGreen],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: kPrimaryBlue.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: selectedClassId,
                  items: [
                    if (uniqueClasses.isEmpty)
                      const DropdownMenuItem<int>(value: null, child: Text('No classes assigned', style: TextStyle(color: Colors.white, fontSize: 16))),
                    ...uniqueClasses.map((c) => DropdownMenuItem<int>(
                          value: c.id,
                          child: Text(
                            c.name,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
                          ),
                        )),
                  ],
                  onChanged: uniqueClasses.isEmpty ? null : onClassChanged,
                  icon: const Icon(Icons.arrow_drop_down_rounded, color: Colors.white, size: 28),
                  isExpanded: true,
                  dropdownColor: kPrimaryBlue,
                  hint: Text(selectedClassName, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Date Row (tappable)
          Row(
            children: [
              GestureDetector(
                onTap: onDateTap,
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 16, color: kTextSecondary),
                    const SizedBox(width: 4),
                    Text(formattedDate, style: TextStyle(color: kTextSecondary, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(width: 1, height: 16, color: Colors.grey.shade300),
              const SizedBox(width: 12),
              if (studentsLoading)
                const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: kPrimaryGreen))
              else
                Icon(Icons.people_rounded, size: 16, color: kPrimaryGreen),
              const SizedBox(width: 4),
              Text(
                "Total: $studentCount",
                style: TextStyle(color: kPrimaryGreen, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============== STUDENT ATTENDANCE CARD ==============
class _StudentAttendanceCard extends StatelessWidget {
  final String name;
  final String roll;
  final String status; // PRESENT | ABSENT | LATE
  final ValueChanged<String> onStatusChanged;

  const _StudentAttendanceCard({
    required this.name,
    required this.roll,
    required this.status,
    required this.onStatusChanged,
  });

  static const List<String> _statusCycle = ['PRESENT', 'ABSENT', 'LATE'];

  @override
  Widget build(BuildContext context) {
    final isPresent = status == 'PRESENT';
    final isLate = status == 'LATE';
    final statusColor = isPresent ? kPrimaryGreen : (isLate ? kSoftOrange : kErrorColor);
    final statusLabel = status == 'LATE' ? 'Late' : (isPresent ? 'Present' : 'Absent');
    final nextStatus = _statusCycle[(_statusCycle.indexOf(status) + 1) % _statusCycle.length];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 3))],
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onStatusChanged(nextStatus),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [statusColor, statusColor.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: statusColor.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2))],
                  ),
                  child: Center(
                    child: Text(
                      roll,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: kTextPrimary, fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isPresent ? Icons.check_circle_rounded : (isLate ? Icons.schedule_rounded : Icons.cancel_rounded),
                              color: statusColor,
                              size: 15,
                            ),
                            const SizedBox(width: 4),
                            Text(statusLabel, style: TextStyle(color: statusColor, fontWeight: FontWeight.w600, fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.touch_app_rounded, size: 20, color: kTextSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ================== SAVE BUTTON =====================
class _SaveButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const _SaveButton({this.onPressed});

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Opacity(
      opacity: enabled ? 1 : 0.6,
      child: Container(
        width: double.infinity,
        height: 55,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [kPrimaryBlue, kPrimaryGreen],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: kPrimaryBlue.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(18),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.save_rounded, color: Colors.white, size: 22),
                  SizedBox(width: 10),
                  Text(
                    "Save Attendance",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
