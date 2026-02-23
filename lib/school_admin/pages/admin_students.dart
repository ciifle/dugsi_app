import 'package:flutter/material.dart';
import 'admin_student_screen.dart';
import 'package:kobac/services/dummy_school_service.dart';
import 'package:kobac/models/dummy_user.dart';

// --- Premium 3D Design Constants ---
const Color kPrimaryBlue = Color(0xFF023471);
const Color kPrimaryGreen = Color(0xFF5AB04B);
const Color kBgColor = Color(0xFFF0F3F7);
const double kCardRadius = 28.0;

class AdminStudentsScreen extends StatefulWidget {
  const AdminStudentsScreen({Key? key}) : super(key: key);

  @override
  State<AdminStudentsScreen> createState() => _AdminStudentsScreenState();
}

class _AdminStudentsScreenState extends State<AdminStudentsScreen> {
  late Future<List<DummyUser>> _studentsFuture;
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _studentsFuture = _loadStudents();
  }

  Future<List<DummyUser>> _loadStudents() async {
    final users = await DummySchoolService().getAllUsersForAdmin();
    return users.where((user) => user.role == UserRole.student).toList();
  }

  List<DummyUser> _filterStudents(List<DummyUser> students) {
    if (searchQuery.isEmpty) return students;
    return students
        .where((student) =>
            student.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
            student.email.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFF2F5F9), Color(0xFFE8ECF2)]),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  children: [
                    _BackButton(onPressed: () => Navigator.pop(context)),
                    const SizedBox(width: 16),
                    const Expanded(child: Text("Students", style: TextStyle(color: kPrimaryBlue, fontWeight: FontWeight.bold, fontSize: 20), textAlign: TextAlign.center)),
                    _AddButton(onPressed: () {}),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
                controller: _searchController,
                onChanged: (val) {
                  setState(() {
                    searchQuery = val;
                  });
                },
                decoration: InputDecoration(
                  hintText: "Search students...",
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: const Icon(Icons.search_rounded, color: kPrimaryBlue),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
              ),
              Expanded(
            child: FutureBuilder<List<DummyUser>>(
              future: _studentsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: kPrimaryGreen));
                }
                if (snapshot.hasError) {
                  return const Center(child: Text("Error loading students"));
                }
                
                final students = _filterStudents(snapshot.data ?? []);

                if (students.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded, size: 60, color: Colors.grey[300]),
                        const SizedBox(height: 10),
                        Text(
                          "No students found",
                          style: TextStyle(color: Colors.grey[500], fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final student = students[index];
                    return Padding(padding: const EdgeInsets.only(bottom: 14), child: _StudentCard(student: student));
                  },
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
          color: kPrimaryGreen,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: kPrimaryGreen.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 24),
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  final DummyUser student;

  const _StudentCard({required this.student});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(kCardRadius),
        child: Container(
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
                child: Text(
                  student.name.isNotEmpty ? student.name.substring(0, 1).toUpperCase() : "?",
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kPrimaryBlue),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(student.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kPrimaryBlue)),
                    const SizedBox(height: 4),
                    Text(student.email, style: TextStyle(fontSize: 13, color: kPrimaryBlue.withOpacity(0.6)), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: kPrimaryGreen.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text("Active", style: TextStyle(color: kPrimaryGreen, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
