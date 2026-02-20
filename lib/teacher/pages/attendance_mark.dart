import 'package:flutter/material.dart';

// ---------- WONDERFUL COLOR PALETTE (Matching Student Dashboard) ----------
const Color kPrimaryColor = Color(0xFF2A2E45); // Deep charcoal
const Color kSecondaryColor = Color(0xFF6C5CE7); // Rich purple
const Color kAccentColor = Color(0xFF00B894); // Mint green
const Color kSoftPurple = Color(0xFFA29BFE); // Light purple
const Color kSoftPink = Color(0xFFFF7675); // Soft pink
const Color kSoftOrange = Color(0xFFFDCB6E); // Warm orange
const Color kSoftBlue = Color(0xFF74B9FF); // Sky blue
const Color kBackgroundStart = Color(0xFFE8EEF9); // Light blue-gray
const Color kBackgroundEnd = Color(0xFFF5F0FF); // Light purple
const Color kCardColor = Colors.white;
const Color kTextPrimary = Color(0xFF2D3436); // Dark gray
const Color kTextSecondary = Color(0xFF64748B); // Medium slate
const Color kSuccessColor = Color(0xFF059669); // Green for present
const Color kErrorColor = Color(0xFFDC2626); // Red for absent

// ================== DATA MODEL ======================
class StudentAttendance {
  final String name;
  final String roll;
  StudentAttendance({required this.name, required this.roll});
}

// ================== MAIN SCREEN =====================
class TeacherAttendanceScreen extends StatefulWidget {
  const TeacherAttendanceScreen({Key? key}) : super(key: key);

  @override
  State<TeacherAttendanceScreen> createState() =>
      _TeacherAttendanceScreenState();
}

class _TeacherAttendanceScreenState extends State<TeacherAttendanceScreen> {
  // List of available classes
  final List<String> _availableClasses = [
    'Grade 8 - A',
    'Grade 8 - B',
    'Grade 7 - A',
    'Grade 7 - B',
    'Grade 6 - A',
    'Grade 6 - B',
    'Grade 5 - A',
    'Grade 5 - B',
    'Grade 3 - B',
  ];

  String _selectedClass = 'Grade 8 - A'; // Default selected class
  final DateTime attendanceDate = DateTime.now();

  // Student data organized by class
  final Map<String, List<StudentAttendance>> _classStudents = {
    'Grade 8 - A': [
      StudentAttendance(name: 'Ananya Verma', roll: '1'),
      StudentAttendance(name: 'Rohit Sharma', roll: '2'),
      StudentAttendance(name: 'Priya Gupta', roll: '3'),
      StudentAttendance(name: 'Rahul Singh', roll: '4'),
      StudentAttendance(name: 'Meera Patel', roll: '5'),
      StudentAttendance(name: 'Soham Desai', roll: '6'),
      StudentAttendance(name: 'Arjun Kumar', roll: '7'),
      StudentAttendance(name: 'Tanvi Rao', roll: '8'),
      StudentAttendance(name: 'Kabir Chhabra', roll: '9'),
      StudentAttendance(name: 'Sara Ali', roll: '10'),
      StudentAttendance(name: 'Saniya Biswas', roll: '11'),
      StudentAttendance(name: 'Vedant Naik', roll: '12'),
      StudentAttendance(name: 'Ira Menon', roll: '13'),
      StudentAttendance(name: 'Zaid Khan', roll: '14'),
      StudentAttendance(name: 'Riya Thakur', roll: '15'),
    ],
    'Grade 8 - B': [
      StudentAttendance(name: 'Aryan Singh', roll: '1'),
      StudentAttendance(name: 'Diya Patel', roll: '2'),
      StudentAttendance(name: 'Reyansh Kumar', roll: '3'),
      StudentAttendance(name: 'Myra Sharma', roll: '4'),
      StudentAttendance(name: 'Advik Gupta', roll: '5'),
      StudentAttendance(name: 'Ishita Verma', roll: '6'),
    ],
    'Grade 7 - A': [
      StudentAttendance(name: 'Vihaan Mehta', roll: '1'),
      StudentAttendance(name: 'Anika Reddy', roll: '2'),
      StudentAttendance(name: 'Arjun Nair', roll: '3'),
      StudentAttendance(name: 'Sanya Kapoor', roll: '4'),
      StudentAttendance(name: 'Shaurya Malhotra', roll: '5'),
    ],
    'Grade 7 - B': [
      StudentAttendance(name: 'Prisha Joshi', roll: '1'),
      StudentAttendance(name: 'Yash Das', roll: '2'),
      StudentAttendance(name: 'Kavya Menon', roll: '3'),
      StudentAttendance(name: 'Rudra Sen', roll: '4'),
    ],
    'Grade 6 - A': [
      StudentAttendance(name: 'Avni Choudhury', roll: '1'),
      StudentAttendance(name: 'Shaan Bajaj', roll: '2'),
      StudentAttendance(name: 'Kiara Khanna', roll: '3'),
    ],
    'Grade 6 - B': [
      StudentAttendance(name: 'Ranveer Singh', roll: '1'),
      StudentAttendance(name: 'Ananya Gupta', roll: '2'),
    ],
    'Grade 5 - A': [
      StudentAttendance(name: 'Ishaan Sharma', roll: '1'),
      StudentAttendance(name: 'Navya Patel', roll: '2'),
    ],
    'Grade 5 - B': [StudentAttendance(name: 'Vivaan Kumar', roll: '1')],
    'Grade 3 - B': [
      StudentAttendance(name: 'Aadhya Singh', roll: '1'),
      StudentAttendance(name: 'Kabir Sharma', roll: '2'),
    ],
  };

  late List<bool> isPresent;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<StudentAttendance> get currentClassStudents {
    return _classStudents[_selectedClass] ?? [];
  }

  List<StudentAttendance> get filteredStudents {
    final students = currentClassStudents;
    if (_searchQuery.isEmpty) return students;
    return students.where((student) {
      final query = _searchQuery.toLowerCase();
      return student.name.toLowerCase().contains(query) ||
          student.roll.contains(query);
    }).toList();
  }

  List<bool> get filteredIsPresent {
    return filteredStudents.map((s) {
      final index = currentClassStudents.indexOf(s);
      return isPresent[index];
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _updateAttendanceList();
  }

  void _updateAttendanceList() {
    isPresent = List<bool>.filled(currentClassStudents.length, true);
  }

  void _onClassChanged(String? newClass) {
    if (newClass != null) {
      setState(() {
        _selectedClass = newClass;
        _updateAttendanceList();
        _searchQuery = '';
        _searchController.clear();
      });
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
    final filteredPresent = filteredIsPresent;

    return Scaffold(
      backgroundColor: kBackgroundEnd,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ---------------- APP BAR WITH SEARCH (SMALLER SIZE) ----------------
          SliverAppBar(
            expandedHeight: _isSearching ? 90 : 100,
            pinned: true,
            backgroundColor: kPrimaryColor,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 10),
              title: _isSearching
                  ? null
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.checklist_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          "Attendance",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [kPrimaryColor, kSecondaryColor, kSoftPurple],
                    stops: const [0.1, 0.6, 1.0],
                  ),
                ),
              ),
            ),
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              if (_isSearching)
                Container(
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 18,
                    ),
                    onPressed: _stopSearch,
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(),
                  ),
                )
              else
                Container(
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.search_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    onPressed: _startSearch,
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(),
                  ),
                ),
            ],
            bottom: _isSearching
                ? PreferredSize(
                    preferredSize: const Size.fromHeight(50),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
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
                              fontSize: 12,
                            ),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color: kSoftPurple,
                              size: 16,
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: Icon(
                                      Icons.clear,
                                      color: kTextSecondary,
                                      size: 14,
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
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          style: const TextStyle(
                            color: kTextPrimary,
                            fontSize: 12,
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
                  selectedClass: _selectedClass,
                  availableClasses: _availableClasses,
                  onClassChanged: _onClassChanged,
                  studentCount: currentClassStudents.length,
                  formattedDate: _formatDate(attendanceDate),
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
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                // ---------------- STUDENTS HEADER ----------------
                if (_searchQuery.isEmpty) _buildStudentsHeader(filtered.length),

                const SizedBox(height: 12),

                // ---------------- STUDENT CARDS ----------------
                if (filtered.isNotEmpty)
                  ...List.generate(
                    filtered.length,
                    (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _StudentAttendanceCard(
                        name: filtered[index].name,
                        roll: filtered[index].roll,
                        present: filteredPresent[index],
                        onChanged: (val) {
                          final originalIndex = currentClassStudents.indexOf(
                            filtered[index],
                          );
                          setState(() {
                            isPresent[originalIndex] = val;
                          });
                        },
                      ),
                    ),
                  )
                else
                  _buildEmptyState(),

                const SizedBox(height: 20),

                // ---------------- SAVE BUTTON ----------------
                _SaveButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          'Attendance saved successfully!',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        backgroundColor: kAccentColor,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  },
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
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: kSoftOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.people_rounded,
                color: kSoftOrange,
                size: 14,
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              "Student List",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: kTextPrimary,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: kSoftPurple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            '$count students',
            style: TextStyle(
              color: kSoftPurple,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kSoftPurple.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _searchQuery.isNotEmpty
                    ? Icons.search_off_rounded
                    : Icons.people_outline_rounded,
                color: kSoftPurple,
                size: 36,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isNotEmpty ? 'No students found' : 'No students',
              style: TextStyle(
                color: kTextPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try different search terms'
                  : 'Add students to get started',
              style: TextStyle(color: kTextSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

// ================== HEADER CARD WITH DROPDOWN =====================
class _HeaderCardWithDropdown extends StatelessWidget {
  final String selectedClass;
  final List<String> availableClasses;
  final ValueChanged<String?> onClassChanged;
  final int studentCount;
  final String formattedDate;

  const _HeaderCardWithDropdown({
    required this.selectedClass,
    required this.availableClasses,
    required this.onClassChanged,
    required this.studentCount,
    required this.formattedDate,
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
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Class Dropdown
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kSoftPurple, kSoftBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: kSoftPurple.withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedClass,
                  items: availableClasses.map((String className) {
                    return DropdownMenuItem<String>(
                      value: className,
                      child: Text(
                        className,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: onClassChanged,
                  icon: const Icon(
                    Icons.arrow_drop_down_rounded,
                    color: Colors.white,
                  ),
                  isExpanded: true,
                  dropdownColor: kPrimaryColor,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Date Row
          Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 12,
                color: kTextSecondary,
              ),
              const SizedBox(width: 3),
              Text(
                formattedDate,
                style: TextStyle(color: kTextSecondary, fontSize: 11),
              ),
              const SizedBox(width: 12),
              Icon(Icons.people_rounded, size: 12, color: kTextSecondary),
              const SizedBox(width: 3),
              Text(
                "Total: $studentCount",
                style: TextStyle(
                  color: kSoftOrange,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
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
  final bool present;
  final ValueChanged<bool> onChanged;

  const _StudentAttendanceCard({
    required this.name,
    required this.roll,
    required this.present,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onChanged(!present),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                // Roll number circle
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: present
                          ? [kSuccessColor, kSuccessColor.withOpacity(0.7)]
                          : [kErrorColor, kErrorColor.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: (present ? kSuccessColor : kErrorColor)
                            .withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      roll,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Student name and status
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: kTextPrimary,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            present
                                ? Icons.check_circle_rounded
                                : Icons.cancel_rounded,
                            color: present ? kSuccessColor : kErrorColor,
                            size: 12,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            present ? "Present" : "Absent",
                            style: TextStyle(
                              color: present ? kSuccessColor : kErrorColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Checkbox
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: present ? kSuccessColor : kErrorColor,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Checkbox(
                    value: present,
                    onChanged: (checked) {
                      if (checked != null) {
                        onChanged(checked);
                      }
                    },
                    activeColor: present ? kSuccessColor : kErrorColor,
                    checkColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    side: BorderSide.none,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
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

// ================== SAVE BUTTON =====================
class _SaveButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _SaveButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 44,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kAccentColor, kAccentColor.withOpacity(0.8)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: kAccentColor.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.save_rounded, color: Colors.white, size: 18),
                SizedBox(width: 6),
                Text(
                  "Save Attendance",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
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
