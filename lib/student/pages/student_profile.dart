import 'package:flutter/material.dart';

// ---------- COLOR PALETTE (Matching Dashboard) ----------
const Color kPrimaryBlue = Color(0xFF023471); // Dark blue
const Color kPrimaryGreen = Color(0xFF5AB04B); // Green

// Derived colors (shades/tints of the two main colors)
const Color kSoftBlue = Color(0xFFE0E9F5); // Light tint of blue
const Color kSoftGreen = Color(0xFFE4F1E2); // Light tint of green
const Color kDarkGreen = Color(0xFF3D8C30); // Darker shade of green
const Color kDarkBlue = Color(0xFF011A3D); // Darker shade of blue
const Color kSoftPurple = Color(0xFF4A6FA5); // Soft blue-purple
const Color kSoftPink = Color(0xFF7CB86E); // Soft green-pink
const Color kSoftOrange = Color(0xFFF59E0B); // Amber for warning
const Color kSuccessColor = Color(0xFF3D8C30); // Darker green
const Color kWarningColor = Color(0xFFF59E0B); // Amber
const Color kErrorColor = Color(0xFFEF4444); // Red
const Color kBackgroundColor = Color(0xFFF5F8FC); // Light background
const Color kSurfaceColor = Colors.white;
const Color kTextPrimaryColor = Color(0xFF1A1E1F); // Dark slate
const Color kTextSecondaryColor = Color(0xFF4F5A5E); // Medium slate

// GRADIENT COLORS
const List<Color> kPrimaryGradient = [kPrimaryBlue, kPrimaryGreen];
const List<Color> kSuccessGradient = [kPrimaryGreen, kDarkGreen];
const List<Color> kWarningGradient = [Color(0xFFF59E0B), Color(0xFFFBBF24)];

class StudentProfileScreen extends StatelessWidget {
  const StudentProfileScreen({Key? key}) : super(key: key);

  // Dummy data
  final Map<String, String> student = const {
    'fullName': "Ayesha Khan",
    'studentID': "STU230017",
    'class': "10",
    'section': "B",
    'rollNumber': "21",
    'academicYear': "2023-24",
    'dob': "12 Aug 2008",
    'gender': "Female",
    'phone': "+971 55 667 8821",
    'email': "ayesha.khan@email.com",
    'schoolName': "Sunrise Model School",
    'guardianName': "Mariam Khan",
    'guardianRelation': "Mother",
    'guardianPhone': "+971 55 909 6612",
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [kSoftBlue, kSoftGreen],
          stops: [0.0, 1.0],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // App Bar
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 50, 24, 40),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [kPrimaryBlue, kPrimaryBlue, kPrimaryGreen],
                    stops: const [0.3, 0.7, 1.0],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: kPrimaryBlue.withOpacity(0.3),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Back Button
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Icon(
                                Icons.arrow_back_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Title
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                "My Profile",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                "Personal Info",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Edit Icon
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Icon(
                              Icons.edit_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Main Content
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _ProfileHeaderCard(student: student),
                  const SizedBox(height: 20),
                  _InfoCard(
                    title: "Personal Information",
                    icon: Icons.person_outline_rounded,
                    gradientColor: kPrimaryBlue,
                    data: [
                      _CardRow(label: "Date of Birth", value: student['dob']!),
                      _CardRow(label: "Gender", value: student['gender']!),
                      _CardRow(label: "Phone", value: student['phone']!),
                      _CardRow(label: "Email", value: student['email']!),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _InfoCard(
                    title: "Academic Information",
                    icon: Icons.school_rounded,
                    gradientColor: kPrimaryGreen,
                    data: [
                      _CardRow(label: "School", value: student['schoolName']!),
                      _CardRow(label: "Class", value: student['class']!),
                      _CardRow(label: "Section", value: student['section']!),
                      _CardRow(
                        label: "Roll Number",
                        value: student['rollNumber']!,
                      ),
                      _CardRow(
                        label: "Academic Year",
                        value: student['academicYear']!,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _InfoCard(
                    title: "Guardian Information",
                    icon: Icons.family_restroom_rounded,
                    gradientColor: kSoftOrange,
                    data: [
                      _CardRow(label: "Name", value: student['guardianName']!),
                      _CardRow(
                        label: "Relationship",
                        value: student['guardianRelation']!,
                      ),
                      _CardRow(
                        label: "Phone",
                        value: student['guardianPhone']!,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildEditButton(),
                  const SizedBox(height: 20),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditButton() {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kPrimaryBlue, kPrimaryGreen],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(27),
        boxShadow: [
          BoxShadow(
            color: kPrimaryBlue.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(27),
          child: const Center(
            child: Text(
              "Edit Profile",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Profile Header Card
class _ProfileHeaderCard extends StatelessWidget {
  final Map<String, String> student;
  const _ProfileHeaderCard({required this.student});

  String _getInitials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.isEmpty) return "";
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final name = student['fullName']!;
    final id = student['studentID']!;
    final className = student['class']!;
    final section = student['section']!;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, kSoftGreen],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: kPrimaryBlue.withOpacity(0.15),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Column(
        children: [
          // Profile Image with Gradient Border
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [kPrimaryBlue, kPrimaryGreen],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: kPrimaryBlue.withOpacity(0.3),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _getInitials(name),
                    style: TextStyle(
                      color: kPrimaryBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 40,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: TextStyle(
              color: kTextPrimaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: kPrimaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.badge_rounded, size: 16, color: kPrimaryBlue),
                const SizedBox(width: 6),
                Text(
                  "ID: $id",
                  style: TextStyle(
                    color: kPrimaryBlue,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kPrimaryBlue, kPrimaryBlue.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: kPrimaryBlue.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  "Class $className",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kPrimaryGreen, kDarkGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: kPrimaryGreen.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  "Section $section",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
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

// Info Card
class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color gradientColor;
  final List<_CardRow> data;

  const _InfoCard({
    required this.title,
    required this.icon,
    required this.gradientColor,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: gradientColor.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: gradientColor.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [gradientColor, gradientColor.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: gradientColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 14),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: kTextPrimaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...List.generate(
            data.length,
            (i) => Padding(
              padding: EdgeInsets.only(bottom: i == data.length - 1 ? 0 : 14),
              child: data[i],
            ),
          ),
        ],
      ),
    );
  }
}

// Card Row
class _CardRow extends StatelessWidget {
  final String label;
  final String value;

  const _CardRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 110,
          child: Text(
            label,
            style: TextStyle(
              color: kTextSecondaryColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: kTextPrimaryColor,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
