import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kobac/services/auth_provider.dart';

// ---- Color theme constants ----
const Color kPrimaryAccent = Color(0xFF5AB04B); // Orange
const Color kDarkBlue = Color(0xFF023471); // Dark Blue
const Color kLightGrey = Color(0xFFF4F6FA); // Light Neutral Bg
const Color kCardShadow = Color(0x2203045E);

String formatYMMMd(DateTime date) {
  String month;
  switch (date.month) {
    case 1: month = "Jan"; break;
    case 2: month = "Feb"; break;
    case 3: month = "Mar"; break;
    case 4: month = "Apr"; break;
    case 5: month = "May"; break;
    case 6: month = "Jun"; break;
    case 7: month = "Jul"; break;
    case 8: month = "Aug"; break;
    case 9: month = "Sep"; break;
    case 10: month = "Oct"; break;
    case 11: month = "Nov"; break;
    case 12: month = "Dec"; break;
    default: month = "";
  }
  return "$month ${date.day}, ${date.year}";
}

String formatYMD(DateTime date) {
  String m = date.month.toString().padLeft(2, '0');
  String d = date.day.toString().padLeft(2, '0');
  return "${date.year}-$m-$d";
}

class Student {
  final String id;
  final String name;
  final String gender;
  final String className;
  final String section;
  final DateTime admissionDate;
  final String profilePhotoUrl;
  final String status; // 'Active', 'Suspended', 'Graduated'
  final String parentName;
  final String parentPhone;
  final String parentEmail;
  final List<String> subjects;
  final Map<String, double> grades; // term: grade
  final double gpa;
  final int attendancePresent;
  final int attendanceAbsent;
  final int attendanceLate;
  final double attendancePercent;
  final int totalFee;
  final int paidFee;
  final List<Map<String, dynamic>> feeHistory;
  final List<Map<String, String>> documents;
  final List<Map<String, String>> notes;

  Student({
    required this.id,
    required this.name,
    required this.gender,
    required this.className,
    required this.section,
    required this.admissionDate,
    required this.profilePhotoUrl,
    required this.status,
    required this.parentName,
    required this.parentPhone,
    required this.parentEmail,
    required this.subjects,
    required this.grades,
    required this.gpa,
    required this.attendancePresent,
    required this.attendanceAbsent,
    required this.attendanceLate,
    required this.attendancePercent,
    required this.totalFee,
    required this.paidFee,
    required this.feeHistory,
    required this.documents,
    required this.notes,
  });
}

// Dummy student for initial display
final Student dummyStudent = Student(
  id: "STU-202406",
  name: "suriya Mehta",
  gender: "Female",
  className: "10",
  section: "A",
  admissionDate: DateTime(2020, 6, 15),
  profilePhotoUrl: "assets/images/profile.jpg",
  status: "Active",
  parentName: "Aditya Mehta",
  parentPhone: "+91 8245671234",
  parentEmail: "aditya.mehta@email.com",
  subjects: ["Math", "Science", "History", "Geography", "English"],
  grades: { "Term 1": 8.5, "Term 2": 8.8, "Term 3": 9.1, },
  gpa: 8.8,
  attendancePresent: 182,
  attendanceAbsent: 7,
  attendanceLate: 3,
  attendancePercent: 96.3,
  totalFee: 80000,
  paidFee: 65000,
  feeHistory: [
    { "date": "2024-06-01", "amount": 40000, "status": "Paid", },
    { "date": "2024-03-01", "amount": 25000, "status": "Paid", },
    { "date": "2024-01-10", "amount": 15000, "status": "Pending", },
  ],
  documents: [
    { "title": "Birth Certificate", "url": "", "date": "2020-06-10", },
    { "title": "Previous Marksheet", "url": "", "date": "2020-06-15", },
  ],
  notes: [
    {
      "date": "2024-06-08",
      "admin": "Amit S.",
      "content": "Parent meeting scheduled.",
    },
    {
      "date": "2024-05-02",
      "admin": "Priya G.",
      "content": "Commended for Science Project.",
    },
  ],
);

// --------------------------- Main Details Screen ---------------------------
class AdminStudentScreen extends StatefulWidget {
  final Student student;

  const AdminStudentScreen({super.key, required this.student});

  @override
  State<AdminStudentScreen> createState() => _AdminStudentScreenState();
}

class _AdminStudentScreenState extends State<AdminStudentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _tabControllerInitialized = false;
  bool editMode = false;
  late Student currentStudent;

  @override
  void initState() {
    super.initState();
    currentStudent = widget.student;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_tabControllerInitialized) {
      _tabControllerInitialized = true;
      final feesEnabled = context.read<AuthProvider>().feesEnabled;
      _tabController = TabController(length: feesEnabled ? 6 : 5, vsync: this);
    }
  }

  void toggleEditMode() {
    setState(() {
      editMode = !editMode;
    });
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'Active':     return kPrimaryAccent;
      case 'Suspended':  return Color(0xFFF9A602); // slightly lighter orange
      case 'Graduated':  return Colors.teal; // allowed as neutral? else fallback
      default:           return Colors.grey.shade500;
    }
  }

  void showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.shortestSide > 600;
    final divider = Divider(
      color: kLightGrey,
      thickness: 1.5,
      height: 1,
    );
    return Scaffold(
      backgroundColor: kLightGrey,
      appBar: AppBar(
        leading: BackButton(color: kPrimaryAccent),
        backgroundColor: kDarkBlue,
        elevation: 4,
        shadowColor: kCardShadow,
        title: const Text('Student Details', style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        )),
        actions: [
          // Status badge
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            child: StatusBadge(status: currentStudent.status),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: Icon(editMode ? Icons.close : Icons.edit,
                color: kPrimaryAccent,
                size: 26,
              ),
              tooltip: editMode ? 'Cancel Edit' : 'Edit',
              onPressed: toggleEditMode,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 2),
          StudentSummaryCard(
            student: currentStudent,
            onAction: (action) {
              switch (action) {
                case 'call':
                  showSnack('Calling parent...');
                  break;
                case 'message':
                  showSnack('Messaging parent...');
                  break;
                case 'documents':
                  _tabController.animateTo(context.read<AuthProvider>().feesEnabled ? 4 : 3);
                  break;
              }
            },
          ),
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicator: UnderlineTabIndicator(
                borderSide: BorderSide(width: 3.5, color: kPrimaryAccent),
                insets: EdgeInsets.symmetric(horizontal: 8.0),
              ),
              labelColor: kDarkBlue,
              unselectedLabelColor: kDarkBlue.withOpacity(0.6),
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              tabs: _buildTabs(context),
            ),
          ),
          divider,
          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _buildTabViews(context),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTabs(BuildContext context) {
    final feesEnabled = context.watch<AuthProvider>().feesEnabled;
    if (feesEnabled) {
      return const [
        Tab(child: Text("Profile")),
        Tab(child: Text("Academics")),
        Tab(child: Text("Attendance")),
        Tab(child: Text("Fees")),
        Tab(child: Text("Documents")),
        Tab(child: Text("Notes")),
      ];
    }
    return const [
      Tab(child: Text("Profile")),
      Tab(child: Text("Academics")),
      Tab(child: Text("Attendance")),
      Tab(child: Text("Documents")),
      Tab(child: Text("Notes")),
    ];
  }

  List<Widget> _buildTabViews(BuildContext context) {
    final feesEnabled = context.watch<AuthProvider>().feesEnabled;
    final views = <Widget>[
      ProfileTab(
                  student: currentStudent,
                  editable: editMode,
                  onSave: (updatedStudent) {
                    setState(() {
                      currentStudent = updatedStudent;
                      editMode = false;
                    });
                    showSnack("Profile updated!");
                  },
                  onCancel: () {
                    setState(() {
                      editMode = false;
                    });
                  },
                ),
                AcademicsTab(
                  student: currentStudent,
                  editable: editMode,
                  onUpdate: (updatedStudent) {
                    setState(() => currentStudent = updatedStudent);
                    showSnack("Academics updated!");
                  },
                ),
                AttendanceTab(student: currentStudent),
                if (feesEnabled) FeesTab(student: currentStudent),
                DocumentsTab(
                  documents: currentStudent.documents,
                  editable: editMode,
                  onUpload: (doc) {
                    setState(() => currentStudent.documents.add(doc));
                    showSnack("Document uploaded.");
                  },
                  onDelete: (index) async {
                    final confirm = await showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        title: Text("Delete Document",
                          style: TextStyle(color: kDarkBlue, fontWeight: FontWeight.bold)
                        ),
                        content: Text(
                          "Are you sure you want to delete this document?",
                          style: TextStyle(color: Colors.black87),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text("Cancel"),
                            style: TextButton.styleFrom(
                              foregroundColor: kDarkBlue,
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: kPrimaryAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              )
                            ),
                            child: const Text("Delete"),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      setState(() => currentStudent.documents.removeAt(index));
                      showSnack("Document deleted.");
                    }
                  },
                ),
                NotesTab(
                  notes: currentStudent.notes,
                  editable: editMode,
                  onAdd: (note) {
                    setState(() => currentStudent.notes.insert(0, note));
                    showSnack("Note added.");
                  },
                ),
              ];
    return views;
  }
}

// --------------------------- Status Badge ---------------------------
class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;
    switch (status) {
      case 'Active':    color = kPrimaryAccent; text = "Active";    break;
      case 'Suspended': color = Color(0xFFF9A602); text = "Suspended"; break;
      case 'Graduated': color = Colors.teal; text = "Graduated"; break;
      default:          color = Colors.grey.shade500; text = "Unknown";
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: color, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: kCardShadow.withOpacity(0.10),
            offset: Offset(1,1),
            blurRadius: 5,
          ),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 13.5,
          letterSpacing: 0.2,
          shadows: [
            Shadow(
              color: color.withOpacity(0.08),
              offset: Offset(0.25, 0.5),
              blurRadius: 1,
            ),
          ]
        ),
      ),
    );
  }
}

// --------------------- Student Summary Card (Reusable) ----------------------
class StudentSummaryCard extends StatelessWidget {
  final Student student;
  final void Function(String action) onAction;

  const StudentSummaryCard({
    super.key,
    required this.student,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final admission = formatYMMMd(student.admissionDate);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Card(
        elevation: 7,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(13),
        ),
        shadowColor: kCardShadow.withOpacity(0.20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Photo
              ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: student.profilePhotoUrl.isEmpty
                    ? Container(
                        width: 78,
                        height: 78,
                        color: kLightGrey,
                        child: Icon(Icons.person, size: 44, color: Colors.grey.shade400),
                      )
                    : Image.asset(
                        student.profilePhotoUrl,
                        width: 78,
                        height: 78,
                        fit: BoxFit.cover,
                      ),
              ),
              const SizedBox(width: 24),
              // Info Block
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        color: kDarkBlue,
                        letterSpacing: 0.05
                      ),
                    ),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 16,
                      runSpacing: 2,
                      children: [
                        Text("ID: ${student.id}",
                          style: const TextStyle(
                            color: kDarkBlue,
                            fontWeight: FontWeight.w500,
                            fontSize: 13.5
                          )),
                        Text(
                          "Class: ${student.className}${student.section}",
                          style: const TextStyle(color: kDarkBlue, fontSize: 13.5),
                        ),
                        Text("Gender: ${student.gender}",
                          style: const TextStyle(color: kDarkBlue, fontSize: 13.5)),
                        Text("Admission: $admission",
                          style: const TextStyle(color: kDarkBlue, fontSize: 13.5)),
                      ],
                    ),
                  ],
                ),
              ),
              // Quick Action Buttons
              Column(
                children: [
                  IconButton(
                    icon: Icon(Icons.phone,
                        size: 28, color: kPrimaryAccent),
                    tooltip: "Call Parent",
                    onPressed: () => onAction("call"),
                    splashRadius: 24,
                  ),
                  IconButton(
                    icon: Icon(Icons.message,
                        size: 27, color: kPrimaryAccent),
                    tooltip: "Message Parent",
                    onPressed: () => onAction("message"),
                    splashRadius: 24,
                  ),
                  IconButton(
                    icon: Icon(Icons.folder_open,
                        size: 27, color: kPrimaryAccent),
                    tooltip: "View Documents",
                    onPressed: () => onAction("documents"),
                    splashRadius: 24,
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

// ----------------------- PROFILE TAB WITH FORM -----------------------------
class ProfileTab extends StatefulWidget {
  final Student student;
  final bool editable;
  final void Function(Student) onSave;
  final VoidCallback onCancel;

  const ProfileTab({
    super.key,
    required this.student,
    required this.editable,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController nameCtrl;
  late TextEditingController genderCtrl;
  late TextEditingController classCtrl;
  late TextEditingController sectionCtrl;
  late TextEditingController parentNameCtrl;
  late TextEditingController parentPhoneCtrl;
  late TextEditingController parentEmailCtrl;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.student.name);
    genderCtrl = TextEditingController(text: widget.student.gender);
    classCtrl = TextEditingController(text: widget.student.className);
    sectionCtrl = TextEditingController(text: widget.student.section);
    parentNameCtrl = TextEditingController(text: widget.student.parentName);
    parentPhoneCtrl = TextEditingController(text: widget.student.parentPhone);
    parentEmailCtrl = TextEditingController(text: widget.student.parentEmail);
  }

  @override
  void didUpdateWidget(covariant ProfileTab oldWidget) {
    if (widget.student != oldWidget.student) {
      nameCtrl.text = widget.student.name;
      genderCtrl.text = widget.student.gender;
      classCtrl.text = widget.student.className;
      sectionCtrl.text = widget.student.section;
      parentNameCtrl.text = widget.student.parentName;
      parentPhoneCtrl.text = widget.student.parentPhone;
      parentEmailCtrl.text = widget.student.parentEmail;
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    genderCtrl.dispose();
    classCtrl.dispose();
    sectionCtrl.dispose();
    parentNameCtrl.dispose();
    parentPhoneCtrl.dispose();
    parentEmailCtrl.dispose();
    super.dispose();
  }

  void saveForm() {
    if (_formKey.currentState!.validate()) {
      widget.onSave(
        Student(
          id: widget.student.id,
          name: nameCtrl.text.trim(),
          gender: genderCtrl.text.trim(),
          className: classCtrl.text.trim(),
          section: sectionCtrl.text.trim(),
          admissionDate: widget.student.admissionDate,
          profilePhotoUrl: widget.student.profilePhotoUrl,
          status: widget.student.status,
          parentName: parentNameCtrl.text.trim(),
          parentPhone: parentPhoneCtrl.text.trim(),
          parentEmail: parentEmailCtrl.text.trim(),
          subjects: widget.student.subjects,
          grades: widget.student.grades,
          gpa: widget.student.gpa,
          attendancePresent: widget.student.attendancePresent,
          attendanceAbsent: widget.student.attendanceAbsent,
          attendanceLate: widget.student.attendanceLate,
          attendancePercent: widget.student.attendancePercent,
          totalFee: widget.student.totalFee,
          paidFee: widget.student.paidFee,
          feeHistory: widget.student.feeHistory,
          documents: widget.student.documents,
          notes: widget.student.notes,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final labelStyle = const TextStyle(
      fontWeight: FontWeight.w500,
      fontSize: 15,
      color: kDarkBlue,
    );
    InputDecoration inputDecoration(String label) => InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: kDarkBlue, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: kPrimaryAccent, width: 2),
      ),
      labelStyle: const TextStyle(color: kDarkBlue),
      fillColor: Colors.white,
      filled: true,
    );
    Widget sectionDivider() => Padding(
      padding: const EdgeInsets.symmetric(vertical: 22),
      child: Divider(
        color: kLightGrey,
        thickness: 1.5,
        height: 7,
      ),
    );
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Personal Info',
                style: const TextStyle(
                  color: kDarkBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 18
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: nameCtrl,
              enabled: widget.editable,
              decoration: inputDecoration("Full Name"),
              style: labelStyle,
              validator: (v) => v == null || v.trim().isEmpty
                  ? "Name cannot be empty" : null,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: genderCtrl,
                    enabled: widget.editable,
                    decoration: inputDecoration("Gender"),
                    style: labelStyle,
                    validator: (v) => v == null || v.trim().isEmpty
                        ? "Required" : null,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: TextFormField(
                    controller: classCtrl,
                    enabled: widget.editable,
                    decoration: inputDecoration("Class"),
                    style: labelStyle,
                    validator: (v) => v == null || v.trim().isEmpty
                        ? "Required" : null,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: TextFormField(
                    controller: sectionCtrl,
                    enabled: widget.editable,
                    decoration: inputDecoration("Section"),
                    style: labelStyle,
                    validator: (v) => v == null || v.trim().isEmpty
                        ? "Required" : null,
                  ),
                ),
              ],
            ),
            sectionDivider(),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Parent/Guardian Info',
                style: const TextStyle(
                  color: kDarkBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: parentNameCtrl,
              enabled: widget.editable,
              decoration: inputDecoration("Parent Name"),
              style: labelStyle,
              validator: (v) => v == null || v.trim().isEmpty
                  ? "Cannot be empty" : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: parentPhoneCtrl,
              enabled: widget.editable,
              decoration: inputDecoration("Parent Phone"),
              style: labelStyle,
              keyboardType: TextInputType.phone,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return "Required";
                if (!RegExp(r'^\+?\d{7,15}$').hasMatch(v.trim()))
                  return "Enter valid phone";
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: parentEmailCtrl,
              enabled: widget.editable,
              decoration: inputDecoration("Parent Email"),
              style: labelStyle,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return "Required";
                if (!v.contains("@")) return "Enter valid email";
                return null;
              },
            ),
            const SizedBox(height: 30),
            if (widget.editable)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    icon: Icon(Icons.save, color: Colors.white, size: 20),
                    onPressed: saveForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryAccent,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    label: const Text("Save"),
                  ),
                  const SizedBox(width: 18),
                  OutlinedButton.icon(
                    icon: Icon(Icons.cancel, color: kPrimaryAccent),
                    onPressed: widget.onCancel,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: kPrimaryAccent, width: 2),
                      foregroundColor: kPrimaryAccent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 17, vertical: 12),
                    ),
                    label: const Text("Cancel"),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// --------------------- ACADEMICS TAB ---------------------------------------
class AcademicsTab extends StatefulWidget {
  final Student student;
  final bool editable;
  final void Function(Student updatedStudent) onUpdate;

  const AcademicsTab({
    super.key,
    required this.student,
    required this.editable,
    required this.onUpdate,
  });

  @override
  State<AcademicsTab> createState() => _AcademicsTabState();
}

class _AcademicsTabState extends State<AcademicsTab> {
  late String _selectedClass;
  late String _selectedSection;
  final List<String> _classes = List.generate(12, (i) => (i + 1).toString());
  final List<String> _sections = ['A', 'B', 'C', 'D', 'E'];

  @override
  void initState() {
    _selectedClass = widget.student.className;
    _selectedSection = widget.student.section;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final labelStyle = const TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w500,
      color: kDarkBlue,
    );
    InputDecoration dropdownDecoration(String label) => InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 15),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: kDarkBlue, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: kPrimaryAccent, width: 2),
      ),
      labelStyle: const TextStyle(color: kDarkBlue),
      fillColor: Colors.white,
      filled: true,
    );
    Widget sectionTitle(String title) => Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 8),
      child: Text(title,
        style: const TextStyle(
          color: kDarkBlue, fontWeight: FontWeight.bold, fontSize: 18
        )
      ),
    );
    Widget sectionDivider() => Padding(
      padding: const EdgeInsets.symmetric(vertical: 19),
      child: Divider(
        color: kLightGrey,
        thickness: 1.4,
        height: 6,
      ),
    );
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          sectionTitle("Current Class & Section"),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedClass,
                  isExpanded: true,
                  decoration: dropdownDecoration("Class"),
                  items: _classes
                      .map((c) =>
                          DropdownMenuItem(child: Text(c), value: c))
                      .toList(),
                  onChanged: widget.editable
                      ? (v) {
                          setState(() => _selectedClass = v!);
                          widget.onUpdate(
                            widget.student.copyWith(
                                className: v!, section: _selectedSection),
                          );
                        }
                      : null,
                  style: labelStyle,
                  icon: Icon(Icons.arrow_drop_down, color: kPrimaryAccent),
                  disabledHint: Text(_selectedClass),
                  dropdownColor: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedSection,
                  isExpanded: true,
                  decoration: dropdownDecoration("Section"),
                  items: _sections
                      .map((s) =>
                          DropdownMenuItem(child: Text(s), value: s))
                      .toList(),
                  onChanged: widget.editable
                      ? (v) {
                          setState(() => _selectedSection = v!);
                          widget.onUpdate(
                            widget.student.copyWith(
                                className: _selectedClass, section: v!),
                          );
                        }
                      : null,
                  style: labelStyle,
                  icon: Icon(Icons.arrow_drop_down, color: kPrimaryAccent),
                  disabledHint: Text(_selectedSection),
                  dropdownColor: Colors.white,
                ),
              ),
            ],
          ),
          sectionDivider(),
          sectionTitle("Subjects"),
          const SizedBox(height: 5),
          Wrap(
            spacing: 13,
            children: widget.student.subjects
                .map((s) => Chip(
                      label: Text(s,
                          style: const TextStyle(
                              fontSize: 14,
                              color: kDarkBlue,
                              fontWeight: FontWeight.w500)),
                      backgroundColor: kPrimaryAccent.withOpacity(0.085),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                        side: BorderSide(color: kPrimaryAccent.withOpacity(0.15)),
                      ),
                    ))
                .toList(),
          ),
          sectionDivider(),
          sectionTitle("Grades per term"),
          const SizedBox(height: 9),
          Material(
            elevation: 1.7,
            borderRadius: BorderRadius.circular(8),
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(
                kDarkBlue.withOpacity(0.05),
              ),
              dataRowColor: MaterialStateProperty.all(
                Colors.white,
              ),
              columns: const [
                DataColumn(label: Text("Term",
                  style: TextStyle(
                    color: kDarkBlue,
                    fontWeight: FontWeight.bold,
                  ),
                )),
                DataColumn(label: Text("Grade",
                  style: TextStyle(
                    color: kDarkBlue,
                    fontWeight: FontWeight.bold,
                  ),
                )),
              ],
              rows: widget.student.grades.entries
                  .map(
                    (e) => DataRow(cells: [
                      DataCell(Text(e.key,
                        style: TextStyle(color: kDarkBlue, fontWeight: FontWeight.w600))),
                      DataCell(Text(e.value.toStringAsFixed(2),
                        style: TextStyle(color: kPrimaryAccent, fontWeight: FontWeight.bold))),
                    ]),
                  )
                  .toList(),
              dividerThickness: 0.0,
              horizontalMargin: 9,
              columnSpacing: 18,
              dataTextStyle: const TextStyle(fontSize: 15, color: kDarkBlue),
            ),
          ),
          sectionDivider(),
          Row(
            children: [
              const Text(
                "GPA:",
                style: TextStyle(
                  color: kDarkBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                )
              ),
              const SizedBox(width: 11),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5.5),
                decoration: BoxDecoration(
                  color: kPrimaryAccent.withOpacity(0.11),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  widget.student.gpa.toStringAsFixed(2),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: kPrimaryAccent,
                    letterSpacing: 0.3
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// For student copyWith, needed for updating
extension StudentCopyWith on Student {
  Student copyWith({
    String? id,
    String? name,
    String? gender,
    String? className,
    String? section,
    DateTime? admissionDate,
    String? profilePhotoUrl,
    String? status,
    String? parentName,
    String? parentPhone,
    String? parentEmail,
    List<String>? subjects,
    Map<String, double>? grades,
    double? gpa,
    int? attendancePresent,
    int? attendanceAbsent,
    int? attendanceLate,
    double? attendancePercent,
    int? totalFee,
    int? paidFee,
    List<Map<String, dynamic>>? feeHistory,
    List<Map<String, String>>? documents,
    List<Map<String, String>>? notes,
  }) {
    return Student(
      id: id ?? this.id,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      className: className ?? this.className,
      section: section ?? this.section,
      admissionDate: admissionDate ?? this.admissionDate,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      status: status ?? this.status,
      parentName: parentName ?? this.parentName,
      parentPhone: parentPhone ?? this.parentPhone,
      parentEmail: parentEmail ?? this.parentEmail,
      subjects: subjects ?? this.subjects,
      grades: grades ?? this.grades,
      gpa: gpa ?? this.gpa,
      attendancePresent: attendancePresent ?? this.attendancePresent,
      attendanceAbsent: attendanceAbsent ?? this.attendanceAbsent,
      attendanceLate: attendanceLate ?? this.attendanceLate,
      attendancePercent: attendancePercent ?? this.attendancePercent,
      totalFee: totalFee ?? this.totalFee,
      paidFee: paidFee ?? this.paidFee,
      feeHistory: feeHistory ?? this.feeHistory,
      documents: documents ?? this.documents,
      notes: notes ?? this.notes,
    );
  }
}

// -------------------- ATTENDANCE TAB ---------------------------------------
class AttendanceTab extends StatelessWidget {
  final Student student;
  const AttendanceTab({super.key, required this.student});
  @override
  Widget build(BuildContext context) {
    final present = student.attendancePresent;
    final absent = student.attendanceAbsent;
    final late = student.attendanceLate;
    final percent = student.attendancePercent;
    final months = [ "Jan", "Feb", "Mar", "Apr", "May", "Jun" ];
    final List<Map<String, dynamic>> monthly = List.generate(
      months.length,
      (i) => {
        "month": months[i],
        "present": (18 - i),
        "absent": i,
        "late": (i % 3),
      },
    );
    Widget sectionTitle(String text) => Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 7, top: 3),
      child: Text(
        text,
        style: const TextStyle(
          color: kDarkBlue, fontWeight: FontWeight.bold, fontSize: 18
        ),
      ),
    );
    return SingleChildScrollView(
      padding: const EdgeInsets.all(17),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Card(
                  color: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                  shadowColor: kCardShadow.withOpacity(0.16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text('${percent.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: kPrimaryAccent,
                            )),
                        const SizedBox(height: 7),
                        const Text('Attendance',
                            style: TextStyle(
                                color: kDarkBlue,
                                fontSize: 16,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 13),
                        // Circular Progress
                        SizedBox(
                          width: 56,
                          height: 56,
                          child: CircularProgressIndicator(
                            value: percent / 100,
                            color: kPrimaryAccent,
                            backgroundColor: kPrimaryAccent.withOpacity(0.19),
                            strokeWidth: 7.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Card(
                  color: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                  shadowColor: kCardShadow.withOpacity(0.15),
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _AttendanceCount(
                                label: "Present",
                                count: present,
                                color: kPrimaryAccent),
                            _AttendanceCount(
                                label: "Absent",
                                count: absent,
                                color: Colors.black54),
                            _AttendanceCount(
                                label: "Late",
                                count: late,
                                color: Colors.grey),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          sectionTitle("Monthly Attendance"),
          SizedBox(height: 7),
          ...monthly.map(
            (m) => Card(
              color: Colors.white,
              elevation: 2,
              shadowColor: kCardShadow.withOpacity(0.08),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: kPrimaryAccent,
                  foregroundColor: Colors.white,
                  child: Text(m["month"]!,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white)),
                ),
                title: Text(
                  "Present: ${m["present"]}, Absent: ${m["absent"]}, Late: ${m["late"]}",
                  style: const TextStyle(
                    color: kDarkBlue,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceCount extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _AttendanceCount(
      {required this.label, required this.count, required this.color});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('$count',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 21)),
        Text(label, style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w500, color: kDarkBlue)),
      ],
    );
  }
}

// -------------------- FEES TAB ---------------------------------------------
class FeesTab extends StatelessWidget {
  final Student student;
  const FeesTab({super.key, required this.student});
  @override
  Widget build(BuildContext context) {
    final feeDue = student.totalFee - student.paidFee;
    final statusColor = feeDue == 0
        ? kPrimaryAccent
        : feeDue <= 10000
            ? Color(0xFFF9A602)
            : Colors.red.shade400;

    Widget legendDot(Color color, String text) => Row(
      children: [
        Container(
          width: 13,
          height: 13,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1),
          ),
        ),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(
          color: kDarkBlue,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        )),
      ],
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: Colors.white,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13),
            ),
            shadowColor: kCardShadow.withOpacity(0.14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              child: Row(
                children: [
                  _FeeTile(
                    label: "Total Fee",
                    amount: student.totalFee,
                    color: kDarkBlue,
                  ),
                  _FeeTile(
                    label: "Paid",
                    amount: student.paidFee,
                    color: kPrimaryAccent,
                  ),
                  _FeeTile(
                    label: "Due",
                    amount: feeDue,
                    color: statusColor,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 19),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              legendDot(kPrimaryAccent, "Paid"),
              const SizedBox(width: 19),
              legendDot(Color(0xFFF9A602), "Partial"),
              const SizedBox(width: 19),
              legendDot(Colors.red.shade400, "Pending"),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 19),
            child: Divider(color: kLightGrey, thickness: 1.5),
          ),
          Text("Payment History",
            style: const TextStyle(
              color: kDarkBlue,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            )),
          const SizedBox(height: 8),
          ...student.feeHistory.map(
            (fh) => Card(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
              color: Colors.white,
              elevation: 2.2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9)),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                leading: Icon(
                  fh["status"] == "Paid"
                      ? Icons.check_circle
                      : Icons.hourglass_empty,
                  color: fh["status"] == "Paid"
                      ? kPrimaryAccent
                      : Colors.red.shade400,
                  size: 30,
                ),
                title: Text("₹${fh["amount"]}",
                  style: const TextStyle(
                    color: kDarkBlue,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  )),
                subtitle: Text(
                    "Date: ${fh["date"]}",
                    style: const TextStyle(
                        fontWeight: FontWeight.w500, color: Colors.black54)),
                trailing: Text(
                  fh["status"],
                  style: TextStyle(
                      color: fh["status"] == "Paid"
                          ? kPrimaryAccent
                          : Colors.red.shade400,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeeTile extends StatelessWidget {
  final String label;
  final int amount;
  final Color color;
  const _FeeTile(
      {required this.label, required this.amount, required this.color});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: const TextStyle(
            color: kDarkBlue, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Text(
            "₹$amount",
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 18, color: color),
          ),
        ],
      ),
    );
  }
}

// -------------------- DOCUMENTS TAB ----------------------------------------
class DocumentsTab extends StatelessWidget {
  final List<Map<String, String>> documents;
  final bool editable;
  final void Function(Map<String, String> doc) onUpload;
  final void Function(int index) onDelete;

  const DocumentsTab({
    super.key,
    required this.documents,
    required this.editable,
    required this.onUpload,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    Widget sectionDivider() => Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Divider(color: kLightGrey, thickness: 1.25),
    );
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (editable)
            OutlinedButton.icon(
              icon: Icon(Icons.upload, color: kPrimaryAccent, size: 22),
              label: const Text("Upload Document",
                style: TextStyle(
                  color: kPrimaryAccent, fontWeight: FontWeight.bold, fontSize: 16)),
              onPressed: () async {
                // Simulate doc upload
                final now = formatYMD(DateTime.now());
                onUpload({
                  "title": "New Document",
                  "url": "",
                  "date": now,
                });
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: kPrimaryAccent, width: 2),
                foregroundColor: kPrimaryAccent,
                padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          if (editable) sectionDivider(),
          ...documents.asMap().entries.map(
            (entry) {
              int i = entry.key;
              final doc = entry.value;
              return Card(
                elevation: 2.2,
                color: Colors.white,
                shadowColor: kCardShadow.withOpacity(0.13),
                margin: const EdgeInsets.symmetric(vertical: 7, horizontal: 0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  leading: Icon(Icons.insert_drive_file, color: kPrimaryAccent, size: 27),
                  title: Text(doc["title"] ?? "",
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: kDarkBlue,
                        fontSize: 15)),
                  subtitle: Text("Uploaded: ${doc["date"]}",
                    style: const TextStyle(color: Colors.black54, fontSize: 13)),
                  trailing: editable
                      ? IconButton(
                          icon: Icon(Icons.delete, color: Colors.red.shade400),
                          tooltip: "Delete",
                          onPressed: () => onDelete(i),
                        )
                      : null,
                  onTap: () {
                    // Preview - Show dialog
                    showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(13),
                              ),
                              title: Text(
                                doc["title"] ?? "Document",
                                style: const TextStyle(
                                    color: kDarkBlue,
                                    fontWeight: FontWeight.bold),
                              ),
                              content: const Text("Preview not available."),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text("Close"),
                                  style: TextButton.styleFrom(
                                    foregroundColor: kPrimaryAccent,
                                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                )
                              ],
                            ));
                  },
                ),
              );
            },
          ),
          if (documents.isEmpty)
            Padding(
              padding: const EdgeInsets.all(18.0),
              child: Text("No documents uploaded.",
                style: const TextStyle(color: kDarkBlue, fontSize: 15.5)),
            ),
        ],
      ),
    );
  }
}

// -------------------- NOTES TAB --------------------------------------------
class NotesTab extends StatefulWidget {
  final List<Map<String, String>> notes;
  final bool editable;
  final void Function(Map<String, String> note) onAdd;

  const NotesTab({
    super.key,
    required this.notes,
    required this.editable,
    required this.onAdd,
  });

  @override
  State<NotesTab> createState() => _NotesTabState();
}

class _NotesTabState extends State<NotesTab> {
  final _controller = TextEditingController();

  void addNote() {
    String note = _controller.text.trim();
    if (note.isEmpty) return;
    widget.onAdd({
      "date": formatYMD(DateTime.now()),
      "admin": "Amit S.",
      "content": note,
    });
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    Widget sectionDivider() => Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Divider(color: kLightGrey, thickness: 1.1),
    );
    return SingleChildScrollView(
      padding: const EdgeInsets.all(17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.editable)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    maxLines: 1,
                    decoration: InputDecoration(
                      hintText: "Add new note...",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: kDarkBlue, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(color: kPrimaryAccent, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 13),
                      fillColor: Colors.white,
                      filled: true,
                    ),
                    style: const TextStyle(color: kDarkBlue, fontSize: 15),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  icon: Icon(Icons.send, color: Colors.white),
                  label: const Text("Add"),
                  onPressed: addNote,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryAccent,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 15, vertical: 13),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          if (widget.editable) sectionDivider(),
          Text(
            "Notes Timeline",
            style: const TextStyle(
                color: kDarkBlue,
                fontWeight: FontWeight.bold,
                fontSize: 18),
          ),
          const SizedBox(height: 10),
          ...widget.notes.map(
            (n) => Card(
              margin: const EdgeInsets.symmetric(vertical: 9, horizontal: 0),
              color: Colors.white,
              elevation: 2.2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: kPrimaryAccent.withOpacity(0.13),
                  child: Text(
                    n["admin"]?.substring(0, 2) ?? "",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: kDarkBlue,
                        fontSize: 14.5),
                  ),
                ),
                title: Text(n["content"] ?? "",
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: kDarkBlue,
                        fontSize: 15.5)),
                subtitle: Text(
                    "${n["date"] ?? ""} by ${n["admin"] ?? "Admin"}",
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Colors.black54)),
              ),
            ),
          ),
          if (widget.notes.isEmpty)
            Padding(
              padding: const EdgeInsets.all(19),
              child: Text("No notes available.",
                style: const TextStyle(color: kDarkBlue, fontSize: 15.5)),
            ),
        ],
      ),
    );
  }
}

/*
  To use this AdminStudentScreen, push it from your student list page:
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminStudentScreen(student: dummyStudent),
      ),
    );
*/
