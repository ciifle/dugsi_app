import 'package:flutter/material.dart';
import 'package:kobac/school_admin/pages/teacher_screen.dart';

// --- Premium 3D Design Constants ---
const Color kPrimaryBlue = Color(0xFF023471);
const Color kPrimaryGreen = Color(0xFF5AB04B);
const Color kBgColor = Color(0xFFF0F3F7);
const double kTeacherCardRadius = 28.0;

// Dummy teacher model
class Teacher {
  final String name;
  final String subject;
  final String contact;
  final bool isActive;
  final String? imageUrl;

  const Teacher({
    required this.name,
    required this.subject,
    required this.contact,
    required this.isActive,
    this.imageUrl,
  });
}

final List<Teacher> _dummyTeachers = [
  Teacher(
    name: "Amina Hassan",
    subject: "Mathematics",
    contact: "amina.hassan@school.edu",
    isActive: true,
    imageUrl: "https://randomuser.me/api/portraits/women/68.jpg",
  ),
  Teacher(
    name: "Mohamed Ali",
    subject: "English Literature",
    contact: "mohamed.ali@school.edu",
    isActive: false,
    imageUrl: "https://randomuser.me/api/portraits/men/74.jpg",
  ),
  Teacher(
    name: "Fatima Nur",
    subject: "Physics",
    contact: "fatima.nur@school.edu",
    isActive: true,
    imageUrl: "https://randomuser.me/api/portraits/women/75.jpg",
  ),
  Teacher(
    name: "Liban Warsame",
    subject: "History",
    contact: "liban.warsame@school.edu",
    isActive: true,
    imageUrl: "https://randomuser.me/api/portraits/men/69.jpg",
  ),
  Teacher(
    name: "Sarah Ahmed",
    subject: "Chemistry",
    contact: "sarah.ahmed@school.edu",
    isActive: false,
    imageUrl: "https://randomuser.me/api/portraits/women/80.jpg",
  ),
];

class TeacherListScreen extends StatelessWidget {
  const TeacherListScreen({super.key});

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
                    _BackButton(onPressed: () => Navigator.of(context).pop()),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        "Teachers",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: kPrimaryBlue,
                        ),
                      ),
                    ),
                    _AddButton(onPressed: () {}),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  itemCount: _dummyTeachers.length,
                  itemBuilder: (context, index) {
                    final teacher = _dummyTeachers[index];
                    return _TeacherCard(teacher: teacher);
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

class _TeacherCard extends StatelessWidget {
  final Teacher teacher;

  const _TeacherCard({required this.teacher});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TeacherDetailsPage())),
        borderRadius: BorderRadius.circular(kTeacherCardRadius),
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(kTeacherCardRadius),
            boxShadow: [
              BoxShadow(color: kPrimaryBlue.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 6)),
              BoxShadow(color: kPrimaryBlue.withOpacity(0.03), blurRadius: 32, offset: const Offset(0, 12)),
            ],
          ),
          child: Row(
            children: [
              Hero(
                tag: teacher.name,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kPrimaryBlue.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: kPrimaryBlue.withOpacity(0.08), width: 1),
                  ),
                  child: CircleAvatar(
                    radius: 30,
                    backgroundImage: NetworkImage(teacher.imageUrl ?? ''),
                    backgroundColor: kPrimaryBlue.withOpacity(0.05),
                    onBackgroundImageError: (_, __) {},
                    child: teacher.imageUrl == null
                        ? const Icon(Icons.person, color: kPrimaryBlue)
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        teacher.name,
                        style: const TextStyle(
                          fontSize: 18, 
                          fontWeight: FontWeight.bold,
                          color: kPrimaryBlue,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: kPrimaryBlue.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          teacher.subject,
                          style: TextStyle(
                            fontSize: 13,
                            color: kPrimaryBlue.withOpacity(0.7),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        teacher.contact,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: teacher.isActive ? kPrimaryGreen.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      teacher.isActive ? "Active" : "Inactive",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: teacher.isActive ? kPrimaryGreen : Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
