import 'package:flutter/material.dart';
import 'subject_details_page.dart';

// --- Premium 3D Design Constants ---
const Color kPrimaryBlue = Color(0xFF023471);
const Color kPrimaryGreen = Color(0xFF5AB04B);
const Color kBgColor = Color(0xFFF0F3F7);
const double kCardRadius = 28.0;

class Subject {
  final String name;
  final String code;
  final String assignedClass;
  final String teacher;
  final bool isActive;

  Subject({
    required this.name,
    required this.code,
    required this.assignedClass,
    required this.teacher,
    required this.isActive,
  });
}

class SubjectsScreen extends StatelessWidget {
  const SubjectsScreen({Key? key}) : super(key: key);

  static final List<Subject> _subjects = [
    Subject(name: "Mathematics", code: "MATH101", assignedClass: "Grade 10", teacher: "Mr. Alan Turing", isActive: true),
    Subject(name: "Physics", code: "PHY102", assignedClass: "Grade 11", teacher: "Ms. Marie Curie", isActive: true),
    Subject(name: "History", code: "HIS103", assignedClass: "Grade 9", teacher: "Mr. Nelson Mandela", isActive: false),
    Subject(name: "Chemistry", code: "CHEM104", assignedClass: "Grade 10", teacher: "Dr. Rosalind Franklin", isActive: true),
  ];

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
                        "Subjects",
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kPrimaryBlue),
                      ),
                    ),
                    _AddButton(onPressed: () {}),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  itemCount: _subjects.length,
                  itemBuilder: (context, index) {
                    final subject = _subjects[index];
                    return _SubjectCard(subject: subject);
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

class _SubjectCard extends StatelessWidget {
  final Subject subject;

  const _SubjectCard({required this.subject});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => SubjectDetailsPage())),
        borderRadius: BorderRadius.circular(kCardRadius),
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
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kPrimaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  subject.code.substring(0, 1),
                  style: const TextStyle(color: kPrimaryGreen, fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject.name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kPrimaryBlue),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${subject.assignedClass} • ${subject.code}",
                      style: TextStyle(fontSize: 13, color: kPrimaryBlue.withOpacity(0.6)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Teacher: ${subject.teacher}",
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: subject.isActive ? kPrimaryGreen.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  subject.isActive ? "Active" : "Inactive",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: subject.isActive ? kPrimaryGreen : Colors.grey,
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
