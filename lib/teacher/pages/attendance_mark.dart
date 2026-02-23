import 'package:flutter/material.dart';

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
                        fontSize: 14,
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
                      padding: const EdgeInsets.only(bottom: 12),
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
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        backgroundColor: kPrimaryGreen,
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
                  : 'Add students to get started',
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
                          fontSize: 16,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: onClassChanged,
                  icon: const Icon(
                    Icons.arrow_drop_down_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                  isExpanded: true,
                  dropdownColor: kPrimaryBlue,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
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
                size: 16,
                color: kTextSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                formattedDate,
                style: TextStyle(color: kTextSecondary, fontSize: 13),
              ),
              const SizedBox(width: 12),
              Container(width: 1, height: 16, color: Colors.grey.shade300),
              const SizedBox(width: 12),
              Icon(Icons.people_rounded, size: 16, color: kPrimaryGreen),
              const SizedBox(width: 4),
              Text(
                "Total: $studentCount",
                style: TextStyle(
                  color: kPrimaryGreen,
                  fontSize: 13,
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
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onChanged(!present),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Roll number circle
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: present
                          ? [kPrimaryGreen, kPrimaryGreen.withOpacity(0.7)]
                          : [kErrorColor, kErrorColor.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: (present ? kPrimaryGreen : kErrorColor)
                            .withOpacity(0.3),
                        blurRadius: 6,
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
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

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
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: (present ? kPrimaryGreen : kErrorColor)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              present
                                  ? Icons.check_circle_rounded
                                  : Icons.cancel_rounded,
                              color: present ? kPrimaryGreen : kErrorColor,
                              size: 15,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              present ? "Present" : "Absent",
                              style: TextStyle(
                                color: present ? kPrimaryGreen : kErrorColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Checkbox
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: present ? kPrimaryGreen : kErrorColor,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Checkbox(
                    value: present,
                    onChanged: (checked) {
                      if (checked != null) {
                        onChanged(checked);
                      }
                    },
                    activeColor: present ? kPrimaryGreen : kErrorColor,
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
    );
  }
}
