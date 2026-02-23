import 'package:flutter/material.dart';
import 'package:kobac/school_admin/pages/admin_class_screen.dart';

// --- Premium 3D Design Constants ---
const Color kPrimaryBlue = Color(0xFF023471);
const Color kPrimaryGreen = Color(0xFF5AB04B);
const Color kBgColor = Color(0xFFF0F3F7);
const double kCardRadius = 28.0;

class SchoolClass {
  final String name;
  final int studentCount;
  final String teacher;
  final String performance;
  final String section;
  final String academicYear;

  SchoolClass({
    required this.name,
    required this.studentCount,
    required this.teacher,
    required this.performance,
    required this.section,
    required this.academicYear,
  });
}

final List<SchoolClass> dummyClasses = [
  SchoolClass(name: 'Grade 7 - A', studentCount: 35, teacher: 'Mrs. Alice Johnson', performance: 'Excellent', section: 'A', academicYear: '2023-24'),
  SchoolClass(name: 'Grade 8 - B', studentCount: 32, teacher: 'Mr. Ben Carter', performance: 'Average', section: 'B', academicYear: '2023-24'),
  SchoolClass(name: 'Grade 9 - C', studentCount: 29, teacher: 'Ms. Mariel Wang', performance: 'Needs Attention', section: 'C', academicYear: '2022-23'),
  SchoolClass(name: 'Grade 10 - A', studentCount: 27, teacher: 'Dr. Laura Simon', performance: 'Excellent', section: 'A', academicYear: '2022-23'),
];

class AdminClassesPage extends StatefulWidget {
  const AdminClassesPage({Key? key}) : super(key: key);

  @override
  State<AdminClassesPage> createState() => _AdminClassesPageState();
}

class _AdminClassesPageState extends State<AdminClassesPage> {
  String searchText = '';
  String? selectedSection;
  String? selectedYear;

  List<SchoolClass> get filteredClasses {
    return dummyClasses.where((schoolClass) {
      final searchMatch = schoolClass.name.toLowerCase().contains(searchText.toLowerCase());
      final sectionMatch = selectedSection == null || schoolClass.section == selectedSection;
      final yearMatch = selectedYear == null || schoolClass.academicYear == selectedYear;
      return searchMatch && sectionMatch && yearMatch;
    }).toList();
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
                        "Classes",
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kPrimaryBlue),
                      ),
                    ),
                    _AddButton(onPressed: () {}),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(color: kPrimaryBlue.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 6)),
                            BoxShadow(color: kPrimaryBlue.withOpacity(0.03), blurRadius: 40, offset: const Offset(0, 12)),
                          ],
                        ),
                        child: TextField(
                          onChanged: (val) => setState(() => searchText = val),
                          decoration: InputDecoration(
                            hintText: "Search classes...",
                            prefixIcon: const Icon(Icons.search_rounded, color: kPrimaryBlue),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: kPrimaryBlue.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.filter_list_rounded, color: kPrimaryBlue),
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: filteredClasses.isEmpty
                    ? Center(child: Text("No classes found", style: TextStyle(color: Colors.grey[500])))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        itemCount: filteredClasses.length,
                        itemBuilder: (context, index) => _ClassCard(schoolClass: filteredClasses[index]),
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

class _ClassCard extends StatelessWidget {
  final SchoolClass schoolClass;

  const _ClassCard({required this.schoolClass});

  Color _getStatusColor(String status) {
    if (status == 'Excellent') return kPrimaryGreen;
    if (status == 'Average') return Colors.orange;
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
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
                child: const Icon(Icons.class_rounded, color: kPrimaryBlue, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      schoolClass.name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kPrimaryBlue),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.person_outline_rounded, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            schoolClass.teacher,
                            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.people_outline_rounded, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          "${schoolClass.studentCount} Students",
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
                  color: _getStatusColor(schoolClass.performance).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  schoolClass.performance,
                  style: TextStyle(
                    color: _getStatusColor(schoolClass.performance),
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
