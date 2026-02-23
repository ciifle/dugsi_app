import 'package:flutter/material.dart';
import 'exam_details_page.dart';

// --- Premium 3D Design Constants ---
const Color kPrimaryBlue = Color(0xFF023471);
const Color kPrimaryGreen = Color(0xFF5AB04B);
const Color kBgColor = Color(0xFFF0F3F7);
const double kCardRadius = 28.0;

// Dummy exam data model
class Exam {
  final String name;
  final String subject;
  final String grade;
  final DateTime date;
  final bool isCompleted;

  Exam({
    required this.name,
    required this.subject,
    required this.grade,
    required this.date,
    required this.isCompleted,
  });
}

final List<Exam> _exams = [
  Exam(name: "Midterm Exam", subject: "Mathematics", grade: "Class 7A", date: DateTime(2024, 6, 21), isCompleted: false),
  Exam(name: "Final Exam", subject: "History", grade: "Class 8B", date: DateTime(2024, 3, 15), isCompleted: true),
  Exam(name: "Quarterly Test", subject: "Physics", grade: "Grade 10", date: DateTime(2024, 7, 13), isCompleted: false),
  Exam(name: "Unit Test I", subject: "English", grade: "Grade 9", date: DateTime(2024, 2, 7), isCompleted: true),
];

class ExamsPage extends StatelessWidget {
  const ExamsPage({Key? key}) : super(key: key);

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
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
                        "Exams",
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
                  itemCount: _exams.length,
                  itemBuilder: (context, index) {
                    final exam = _exams[index];
                    return _ExamCard(exam: exam, formatDate: _formatDate);
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

class _ExamCard extends StatelessWidget {
  final Exam exam;
  final String Function(DateTime) formatDate;

  const _ExamCard({required this.exam, required this.formatDate});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ExamDetailsPage())),
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
                  color: kPrimaryBlue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  Icons.assignment_rounded,
                  color: exam.isCompleted ? Colors.grey : kPrimaryBlue,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exam.name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kPrimaryBlue),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.book_rounded, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          "${exam.subject} • ${exam.grade}",
                          style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_rounded, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          formatDate(exam.date),
                          style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: exam.isCompleted ? Colors.grey.withOpacity(0.1) : kPrimaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  exam.isCompleted ? "Completed" : "Active",
                  style: TextStyle(
                    color: exam.isCompleted ? Colors.grey : kPrimaryGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
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
