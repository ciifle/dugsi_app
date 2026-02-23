import 'package:flutter/material.dart';

// --- Premium 3D Design Constants ---
const Color kPrimaryBlue = Color(0xFF023471);
const Color kPrimaryGreen = Color(0xFF5AB04B);
const Color kBgColor = Color(0xFFF0F3F7);
const double kCardRadius = 28.0;

class StudentMark {
  String name;
  String studentId;
  int marks;

  StudentMark({required this.name, required this.studentId, required this.marks});
}

final List<StudentMark> dummyStudentMarks = [
  StudentMark(name: "Amina Farouk", studentId: "STU1023", marks: 84),
  StudentMark(name: "Yusuf Khaled", studentId: "STU1059", marks: 77),
  StudentMark(name: "Layla Omar", studentId: "STU1091", marks: 95),
  StudentMark(name: "Ahmed Saleh", studentId: "STU0998", marks: 62),
];

class MarksPage extends StatefulWidget {
  final String? examName;
  final String? subject;
  final String? classGrade;
  final int? totalMarks;

  const MarksPage({
    Key? key,
    this.examName,
    this.subject,
    this.classGrade,
    this.totalMarks,
  }) : super(key: key);

  @override
  State<MarksPage> createState() => _MarksPageState();
}

class _MarksPageState extends State<MarksPage> {
  late List<StudentMark> studentMarks;

  @override
  void initState() {
    super.initState();
    studentMarks = dummyStudentMarks.map((s) => StudentMark(name: s.name, studentId: s.studentId, marks: s.marks)).toList();
  }

  void _saveMarks() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Marks saved successfully!'), backgroundColor: kPrimaryGreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    String examName = widget.examName ?? "Mid Term Examination";
    String subject = widget.subject ?? "Mathematics";
    String grade = widget.classGrade ?? "Grade 8";
    int total = widget.totalMarks ?? 100;

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
                      child: Text(
                        "Student Marks",
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kPrimaryBlue),
                      ),
                    ),
                    GestureDetector(
                      onTap: _saveMarks,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [kPrimaryGreen, kPrimaryGreen.withOpacity(0.85)]),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [BoxShadow(color: kPrimaryGreen.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
                        ),
                        child: const Text("Save", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [kPrimaryBlue, kPrimaryBlue.withOpacity(0.9)]),
                    borderRadius: BorderRadius.circular(kCardRadius),
                    boxShadow: [
                      BoxShadow(color: kPrimaryBlue.withOpacity(0.25), blurRadius: 16, offset: const Offset(0, 6)),
                      BoxShadow(color: kPrimaryBlue.withOpacity(0.12), blurRadius: 32, offset: const Offset(0, 12)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        examName,
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _InfoBadge(icon: Icons.book_rounded, text: subject),
                          _InfoBadge(icon: Icons.class_rounded, text: grade),
                          _InfoBadge(icon: Icons.grade_rounded, text: "$total Marks"),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  itemCount: studentMarks.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final student = studentMarks[index];
                    return Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(kCardRadius),
                        boxShadow: [
                          BoxShadow(color: kPrimaryBlue.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 6)),
                          BoxShadow(color: kPrimaryBlue.withOpacity(0.03), blurRadius: 32, offset: const Offset(0, 12)),
                        ],
                      ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: kPrimaryBlue.withOpacity(0.05),
                        child: Text(
                          student.name[0],
                          style: const TextStyle(color: kPrimaryBlue, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              student.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: kPrimaryBlue,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "#${student.studentId}",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Marks Input
                      Container(
                        width: 80,
                        height: 45,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: kBgColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: TextField(
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: kPrimaryBlue),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.only(bottom: 2), // vertically center
                          ),
                          controller: TextEditingController(text: student.marks.toString())
                            ..selection = TextSelection.collapsed(offset: student.marks.toString().length),
                          onChanged: (val) {
                            if (val.isNotEmpty) {
                              student.marks = int.tryParse(val) ?? 0;
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoBadge({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
