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

// =======================
//  TEACHER PROFILE SCREEN
// =======================

class TeacherProfileScreen extends StatelessWidget {
  TeacherProfileScreen({Key? key}) : super(key: key);

  // Dummy teacher data (for demo only)
  final Map<String, dynamic> teacher = const {
    'name': 'Imran Yusuf',
    'role': 'Mathematics Teacher',
    'employeeId': 'EMP-14059',
    'email': 'imran.yusuf@example.com',
    'phone': '+92 301 4455127',
    'gender': 'Male',
    'doj': '14 Feb 2018',
    'subjects': ['Mathematics', 'Statistics', 'Physics'],
    'classes': ['9A', '10A', '11B'],
    'experience': '8 Years',
    'qualification': 'M.Sc (Mathematics)',
    'address': 'House #14, H Block, Model Town, Lahore, Pakistan',
    'notes':
        'Professional educator with a passion for student success and constant improvement. Loves integrating technology in mathematics teaching.',
    'emergency': '502-009-8001 (Wife: Sara Yusuf)',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundEnd,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ---------------- APP BAR (SMALLER SIZE) ----------------
          SliverAppBar(
            expandedHeight: 90, // REDUCED from 120
            pinned: true,
            backgroundColor: kPrimaryColor,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(
                left: 16,
                bottom: 10,
              ), // REDUCED padding
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(5), // REDUCED padding
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8), // REDUCED radius
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: 16, // REDUCED icon size
                    ),
                  ),
                  const SizedBox(width: 6), // REDUCED spacing
                  const Text(
                    "My Profile",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16, // REDUCED font size
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
              ), // REDUCED size
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 12), // REDUCED margin
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.edit_rounded,
                    color: Colors.white,
                    size: 18,
                  ), // REDUCED size
                  onPressed: () {},
                  padding: const EdgeInsets.all(6), // REDUCED padding
                  constraints: const BoxConstraints(),
                ),
              ),
            ],
          ),

          // ---------------- MAIN CONTENT ----------------
          SliverPadding(
            padding: const EdgeInsets.all(16), // REDUCED from 20
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ---------------- PROFILE HEADER ----------------
                _ProfileHeader(teacher: teacher),

                const SizedBox(height: 20), // REDUCED from 24
                // ---------------- BASIC INFORMATION ----------------
                _InfoSectionCard(
                  title: "Basic Information",
                  icon: Icons.person_outline_rounded,
                  gradientColor: kSoftPurple,
                  children: [
                    _ProfileInfoRow(
                      icon: Icons.email_outlined,
                      label: "Email",
                      value: teacher['email'] ?? '',
                      color: kSoftPurple,
                    ),
                    _ProfileInfoRow(
                      icon: Icons.phone_outlined,
                      label: "Phone",
                      value: teacher['phone'] ?? '',
                      color: kSoftBlue,
                    ),
                    _ProfileInfoRow(
                      icon: Icons.person_outline,
                      label: "Gender",
                      value: teacher['gender'] ?? '',
                      color: kAccentColor,
                    ),
                    _ProfileInfoRow(
                      icon: Icons.calendar_month_outlined,
                      label: "Joined",
                      value: teacher['doj'] ?? '',
                      color: kSoftOrange,
                    ),
                  ],
                ),

                const SizedBox(height: 16), // REDUCED from 20
                // ---------------- PROFESSIONAL DETAILS ----------------
                _InfoSectionCard(
                  title: "Professional Details",
                  icon: Icons.work_outline_rounded,
                  gradientColor: kSoftBlue,
                  children: [
                    _ProfileInfoWrapRow(
                      icon: Icons.book_outlined,
                      label: "Subjects",
                      items:
                          (teacher['subjects'] as List<dynamic>?)
                              ?.map((e) => e.toString())
                              .toList() ??
                          [],
                      color: kSoftPurple,
                    ),
                    _ProfileInfoWrapRow(
                      icon: Icons.class_outlined,
                      label: "Classes",
                      items:
                          (teacher['classes'] as List<dynamic>?)
                              ?.map((e) => e.toString())
                              .toList() ??
                          [],
                      color: kSoftBlue,
                    ),
                    _ProfileInfoRow(
                      icon: Icons.timelapse_outlined,
                      label: "Experience",
                      value: teacher['experience'] ?? '',
                      color: kAccentColor,
                    ),
                    _ProfileInfoRow(
                      icon: Icons.school_outlined,
                      label: "Qualification",
                      value: teacher['qualification'] ?? '',
                      color: kSoftOrange,
                    ),
                  ],
                ),

                const SizedBox(height: 16), // REDUCED from 20
                // ---------------- ACCOUNT ACTIONS ----------------
                _AccountActionsSection(),

                const SizedBox(height: 16), // REDUCED from 20
                // ---------------- EXPANDABLE DETAILS ----------------
                _ExpandableDetailsSection(
                  address: teacher['address'] ?? '',
                  notes: teacher['notes'] ?? '',
                  emergency: teacher['emergency'] ?? '',
                ),

                const SizedBox(height: 16), // REDUCED from 20
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

//==============================
// PROFILE HEADER
//==============================
class _ProfileHeader extends StatelessWidget {
  final Map<String, dynamic> teacher;
  const _ProfileHeader({required this.teacher});

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    String first = parts.isNotEmpty ? parts.first[0] : '';
    String last = parts.length > 1 ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16), // REDUCED from 24
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kCardColor, kBackgroundEnd],
        ),
        borderRadius: BorderRadius.circular(24), // REDUCED from 30
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15, // REDUCED from 20
            offset: const Offset(0, 5), // REDUCED from 8
          ),
        ],
        border: Border.all(
          color: Colors.white,
          width: 1.5,
        ), // REDUCED border width
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Profile Image with Gradient Border
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [kSoftPurple, kSoftBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: kSoftPurple.withOpacity(0.3),
                  blurRadius: 10, // REDUCED from 15
                  spreadRadius: 1, // REDUCED from 2
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(2), // REDUCED from 3
              child: Container(
                width: 70, // REDUCED from 90
                height: 70, // REDUCED from 90
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _getInitials(teacher['name'] ?? ''),
                    style: const TextStyle(
                      color: kPrimaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 28, // REDUCED from 36
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12), // REDUCED from 16
          // Name
          Text(
            teacher['name'] ?? '',
            style: const TextStyle(
              color: kTextPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 20, // REDUCED from 24
            ),
          ),
          const SizedBox(height: 3), // REDUCED from 4
          // Role Badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 3,
            ), // REDUCED padding
            decoration: BoxDecoration(
              color: kSoftPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20), // REDUCED from 30
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.school_rounded,
                  size: 12,
                  color: kSoftPurple,
                ), // REDUCED from 14
                const SizedBox(width: 4), // REDUCED from 6
                Text(
                  teacher['role'] ?? '',
                  style: TextStyle(
                    color: kSoftPurple,
                    fontWeight: FontWeight.w600,
                    fontSize: 11, // REDUCED from 13
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6), // REDUCED from 8
          // Employee ID
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.badge_rounded,
                size: 12,
                color: kTextSecondary,
              ), // REDUCED from 14
              const SizedBox(width: 3), // REDUCED from 4
              Text(
                teacher['employeeId'] ?? '',
                style: TextStyle(
                  color: kTextSecondary,
                  fontSize: 11, // REDUCED from 13
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =========================
// INFO SECTION CARD
// =========================
class _InfoSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color gradientColor;
  final List<Widget> children;

  const _InfoSectionCard({
    required this.title,
    required this.icon,
    required this.gradientColor,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16), // REDUCED from 20
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20), // REDUCED from 24
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10, // REDUCED from 15
            offset: const Offset(0, 3), // REDUCED from 5
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6), // REDUCED from 8
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [gradientColor, gradientColor.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10), // REDUCED from 12
                  boxShadow: [
                    BoxShadow(
                      color: gradientColor.withOpacity(0.2),
                      blurRadius: 5, // REDUCED from 8
                      offset: const Offset(0, 2), // REDUCED from 4
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 16,
                ), // REDUCED from 18
              ),
              const SizedBox(width: 8), // REDUCED from 12
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14, // REDUCED from 16
                  fontWeight: FontWeight.bold,
                  color: kTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12), // REDUCED from 16
          ...children,
        ],
      ),
    );
  }
}

// =============
// INFO ROW
// =============
class _ProfileInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _ProfileInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4), // REDUCED from 6
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4), // REDUCED from 6
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 14), // REDUCED from 16
          ),
          const SizedBox(width: 8), // REDUCED from 12
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: kTextSecondary,
                    fontSize: 12, // REDUCED from 13
                  ),
                ),
                const SizedBox(width: 6), // REDUCED from 8
                Flexible(
                  child: Text(
                    value,
                    style: TextStyle(
                      color: kTextPrimary,
                      fontSize: 13, // REDUCED from 14
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ================
// WRAP ROW
// ================
class _ProfileInfoWrapRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final List<String> items;
  final Color color;

  const _ProfileInfoWrapRow({
    required this.icon,
    required this.label,
    required this.items,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4), // REDUCED from 6
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(4), // REDUCED from 6
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 14), // REDUCED from 16
          ),
          const SizedBox(width: 8), // REDUCED from 12
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: kTextSecondary,
                    fontSize: 12, // REDUCED from 13
                  ),
                ),
                const SizedBox(height: 4), // REDUCED from 6
                Wrap(
                  spacing: 6, // REDUCED from 8
                  runSpacing: 6, // REDUCED from 8
                  children: items
                      .map(
                        (item) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8, // REDUCED from 10
                            vertical: 3, // REDUCED from 4
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(
                              10,
                            ), // REDUCED from 12
                          ),
                          child: Text(
                            item,
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w600,
                              fontSize: 11, // REDUCED from 12
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =====================
// ACCOUNT ACTIONS
// =====================
class _AccountActionsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16), // REDUCED from 20
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20), // REDUCED from 24
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10, // REDUCED from 15
            offset: const Offset(0, 3), // REDUCED from 5
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6), // REDUCED from 8
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kSoftOrange, kSoftPink],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10), // REDUCED from 12
                  boxShadow: [
                    BoxShadow(
                      color: kSoftOrange.withOpacity(0.2),
                      blurRadius: 5, // REDUCED from 8
                      offset: const Offset(0, 2), // REDUCED from 4
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.settings_rounded,
                  color: Colors.white,
                  size: 16,
                ), // REDUCED from 18
              ),
              const SizedBox(width: 8), // REDUCED from 12
              const Text(
                "Account Actions",
                style: TextStyle(
                  fontSize: 14, // REDUCED from 16
                  fontWeight: FontWeight.bold,
                  color: kTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12), // REDUCED from 16
          _buildActionTile(
            icon: Icons.edit_rounded,
            label: "Edit Profile",
            color: kSoftPurple,
          ),
          _buildActionTile(
            icon: Icons.lock_rounded,
            label: "Change Password",
            color: kSoftBlue,
          ),
          _buildActionTile(
            icon: Icons.settings_rounded,
            label: "Settings",
            color: kSoftOrange,
          ),
          _buildActionTile(
            icon: Icons.logout_rounded,
            label: "Logout",
            color: kSoftPink,
            isLogout: true,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    required Color color,
    bool isLogout = false,
  }) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(10), // REDUCED from 12
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8), // REDUCED from 12
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6), // REDUCED from 8
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8), // REDUCED from 10
              ),
              child: Icon(
                icon,
                color: isLogout ? color : color,
                size: 16,
              ), // REDUCED from 18
            ),
            const SizedBox(width: 10), // REDUCED from 12
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isLogout ? color : kTextPrimary,
                  fontWeight: FontWeight.w500,
                  fontSize: 14, // REDUCED from 15
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: kTextSecondary.withOpacity(0.3),
              size: 14, // REDUCED from 16
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================
// EXPANDABLE DETAILS SECTION
// ===========================
class _ExpandableDetailsSection extends StatelessWidget {
  final String address;
  final String notes;
  final String emergency;

  const _ExpandableDetailsSection({
    required this.address,
    required this.notes,
    required this.emergency,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16), // REDUCED from 20
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20), // REDUCED from 24
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10, // REDUCED from 15
            offset: const Offset(0, 3), // REDUCED from 5
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6), // REDUCED from 8
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kSoftBlue, kSoftPurple],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10), // REDUCED from 12
                  boxShadow: [
                    BoxShadow(
                      color: kSoftBlue.withOpacity(0.2),
                      blurRadius: 5, // REDUCED from 8
                      offset: const Offset(0, 2), // REDUCED from 4
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.info_rounded,
                  color: Colors.white,
                  size: 16,
                ), // REDUCED from 18
              ),
              const SizedBox(width: 8), // REDUCED from 12
              const Text(
                "Additional Details",
                style: TextStyle(
                  fontSize: 14, // REDUCED from 16
                  fontWeight: FontWeight.bold,
                  color: kTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12), // REDUCED from 16
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(4), // REDUCED from 6
                decoration: BoxDecoration(
                  color: kSoftPurple.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: kSoftPurple,
                  size: 14,
                ), // REDUCED from 16
              ),
              title: const Text(
                "Address",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: kTextPrimary,
                  fontSize: 14, // REDUCED from 15
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    left: 40,
                    bottom: 8,
                  ), // REDUCED from 44,12
                  child: Text(
                    address,
                    style: TextStyle(
                      color: kTextSecondary,
                      fontSize: 13, // REDUCED from 14
                      height: 1.3, // REDUCED from 1.4
                    ),
                  ),
                ),
              ],
            ),
          ),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(4), // REDUCED from 6
                decoration: BoxDecoration(
                  color: kSoftBlue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.note_alt_rounded,
                  color: kSoftBlue,
                  size: 14,
                ), // REDUCED from 16
              ),
              title: const Text(
                "Notes",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: kTextPrimary,
                  fontSize: 14, // REDUCED from 15
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    left: 40,
                    bottom: 8,
                  ), // REDUCED from 44,12
                  child: Text(
                    notes,
                    style: TextStyle(
                      color: kTextSecondary,
                      fontSize: 13, // REDUCED from 14
                      height: 1.3, // REDUCED from 1.4
                    ),
                  ),
                ),
              ],
            ),
          ),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(4), // REDUCED from 6
                decoration: BoxDecoration(
                  color: kSoftOrange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.contact_emergency_rounded,
                  color: kSoftOrange,
                  size: 14,
                ), // REDUCED from 16
              ),
              title: const Text(
                "Emergency Contact",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: kTextPrimary,
                  fontSize: 14, // REDUCED from 15
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    left: 40,
                    bottom: 8,
                  ), // REDUCED from 44,12
                  child: Text(
                    emergency,
                    style: TextStyle(
                      color: kTextSecondary,
                      fontSize: 13, // REDUCED from 14
                      height: 1.3, // REDUCED from 1.4
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
