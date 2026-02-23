import 'package:flutter/material.dart';
import 'package:kobac/services/local_auth_service.dart';
import 'package:kobac/shared/pages/login_screen.dart';

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

// =======================
//  TEACHER PROFILE SCREEN
// =======================

class TeacherProfileScreen extends StatefulWidget {
  const TeacherProfileScreen({Key? key}) : super(key: key);

  @override
  State<TeacherProfileScreen> createState() => _TeacherProfileScreenState();
}

class _TeacherProfileScreenState extends State<TeacherProfileScreen> {
  // Dummy teacher data (for demo only) - NOW MUTABLE
  Map<String, dynamic> teacher = {
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

  // Navigation methods for account actions
  void _editProfile(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditProfileSheet(
        teacher: teacher,
        onSave: (updatedTeacher) {
          setState(() {
            teacher = updatedTeacher; // This updates the UI!
          });
        },
      ),
    );
  }

  void _changePassword(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _ChangePasswordSheet(),
    );
  }

  void _openSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SettingsSheet(
        onNotificationsTap: () => _showNotificationsSettings(context),
        onLanguageTap: () => _showLanguageSettings(context),
        onThemeTap: () => _showThemeSettings(context),
        onPrivacyTap: () => _showPrivacySettings(context),
      ),
    );
  }

  // Settings navigation methods
  void _showNotificationsSettings(BuildContext context) {
    Navigator.pop(context); // Close settings sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _NotificationsSettingsSheet(),
    );
  }

  void _showLanguageSettings(BuildContext context) {
    Navigator.pop(context); // Close settings sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _LanguageSettingsSheet(),
    );
  }

  void _showThemeSettings(BuildContext context) {
    Navigator.pop(context); // Close settings sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _ThemeSettingsSheet(),
    );
  }

  void _showPrivacySettings(BuildContext context) {
    Navigator.pop(context); // Close settings sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _PrivacySettingsSheet(),
    );
  }

  // FIXED LOGOUT FUNCTION - Direct to Login Page
  void _logout(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text(
            'Logout',
            style: TextStyle(fontWeight: FontWeight.bold, color: kPrimaryBlue),
          ),
          content: const Text(
            'Are you sure you want to logout?',
            style: TextStyle(color: kTextSecondary),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: Text('Cancel', style: TextStyle(color: kTextSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                // Close the dialog
                Navigator.of(dialogContext).pop();

                // Show loading indicator
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (loadingContext) {
                    return const Center(
                      child: CircularProgressIndicator(color: kPrimaryBlue),
                    );
                  },
                );

                try {
                  // Perform logout
                  await LocalAuthService().logout();

                  // Close loading dialog
                  if (context.mounted) {
                    Navigator.of(context).pop(); // Close loading

                    // Navigate to login screen and clear all routes
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const LoginPage(),
                      ),
                      (route) => false,
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.of(context).pop(); // Close loading
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Logout failed: $e'),
                        backgroundColor: kErrorColor,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kErrorColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSoftBlue,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ---------------- APP BAR WITH GRADIENT ----------------
          SliverAppBar(
            expandedHeight: 120,
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
                titlePadding: const EdgeInsets.only(bottom: 20),
                centerTitle: true,
                title: const Text(
                  "My Profile",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
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
                  size: 28,
                ),
                onPressed: () => Navigator.pop(context),
                padding: const EdgeInsets.all(10),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 12, top: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.edit_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  onPressed: () => _editProfile(context),
                  padding: const EdgeInsets.all(10),
                ),
              ),
            ],
          ),

          // ---------------- MAIN CONTENT ----------------
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ---------------- PROFILE HEADER ----------------
                _ProfileHeader(teacher: teacher),

                const SizedBox(height: 20),

                // ---------------- BASIC INFORMATION ----------------
                _InfoSectionCard(
                  title: "Basic Information",
                  icon: Icons.person_outline_rounded,
                  gradientColors: [kPrimaryBlue, kPrimaryGreen],
                  children: [
                    _ProfileInfoRow(
                      icon: Icons.email_outlined,
                      label: "Email",
                      value: teacher['email'] ?? '',
                      color: kPrimaryBlue,
                    ),
                    _ProfileInfoRow(
                      icon: Icons.phone_outlined,
                      label: "Phone",
                      value: teacher['phone'] ?? '',
                      color: kPrimaryGreen,
                    ),
                    _ProfileInfoRow(
                      icon: Icons.person_outline,
                      label: "Gender",
                      value: teacher['gender'] ?? '',
                      color: kSoftOrange,
                    ),
                    _ProfileInfoRow(
                      icon: Icons.calendar_month_outlined,
                      label: "Joined",
                      value: teacher['doj'] ?? '',
                      color: kDarkBlue,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ---------------- PROFESSIONAL DETAILS ----------------
                _InfoSectionCard(
                  title: "Professional Details",
                  icon: Icons.work_outline_rounded,
                  gradientColors: [kPrimaryGreen, kPrimaryBlue],
                  children: [
                    _ProfileInfoWrapRow(
                      icon: Icons.book_outlined,
                      label: "Subjects",
                      items:
                          (teacher['subjects'] as List<dynamic>?)
                              ?.map((e) => e.toString())
                              .toList() ??
                          [],
                      color: kPrimaryBlue,
                    ),
                    _ProfileInfoWrapRow(
                      icon: Icons.class_outlined,
                      label: "Classes",
                      items:
                          (teacher['classes'] as List<dynamic>?)
                              ?.map((e) => e.toString())
                              .toList() ??
                          [],
                      color: kPrimaryGreen,
                    ),
                    _ProfileInfoRow(
                      icon: Icons.timelapse_outlined,
                      label: "Experience",
                      value: teacher['experience'] ?? '',
                      color: kSoftOrange,
                    ),
                    _ProfileInfoRow(
                      icon: Icons.school_outlined,
                      label: "Qualification",
                      value: teacher['qualification'] ?? '',
                      color: kDarkBlue,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ---------------- ACCOUNT ACTIONS ----------------
                _AccountActionsSection(
                  onEditProfile: () => _editProfile(context),
                  onChangePassword: () => _changePassword(context),
                  onSettings: () => _openSettings(context),
                  onLogout: () => _logout(context),
                ),

                const SizedBox(height: 16),

                // ---------------- EXPANDABLE DETAILS ----------------
                _ExpandableDetailsSection(
                  address: teacher['address'] ?? '',
                  notes: teacher['notes'] ?? '',
                  emergency: teacher['emergency'] ?? '',
                ),

                const SizedBox(height: 16),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
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
        mainAxisSize: MainAxisSize.min,
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
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _getInitials(teacher['name'] ?? ''),
                    style: const TextStyle(
                      color: kPrimaryBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 36,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Name
          Text(
            teacher['name'] ?? '',
            style: const TextStyle(
              color: kTextPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 4),

          // Role Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kPrimaryBlue, kPrimaryGreen],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: kPrimaryBlue.withOpacity(0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.school_rounded, size: 14, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  teacher['role'] ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Employee ID
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: kSoftBlue,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.badge_rounded, size: 12, color: kPrimaryBlue),
                const SizedBox(width: 4),
                Text(
                  teacher['employeeId'] ?? '',
                  style: TextStyle(
                    color: kPrimaryBlue,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
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

// =========================
// INFO SECTION CARD
// =========================
class _InfoSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Color> gradientColors;
  final List<Widget> children;

  const _InfoSectionCard({
    required this.title,
    required this.icon,
    required this.gradientColors,
    required this.children,
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
            color: kPrimaryBlue.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: gradientColors.first.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: kTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: TextStyle(color: kTextSecondary, fontSize: 13),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    value,
                    style: TextStyle(
                      color: kTextPrimary,
                      fontSize: 14,
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
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(color: kTextSecondary, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: items
                      .map(
                        (item) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            item,
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
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
  final VoidCallback onEditProfile;
  final VoidCallback onChangePassword;
  final VoidCallback onSettings;
  final VoidCallback onLogout;

  const _AccountActionsSection({
    required this.onEditProfile,
    required this.onChangePassword,
    required this.onSettings,
    required this.onLogout,
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
            color: kPrimaryBlue.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
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
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: kPrimaryBlue.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.settings_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                "Account Actions",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: kTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildActionTile(
            icon: Icons.edit_rounded,
            label: "Edit Profile",
            color: kPrimaryBlue,
            onTap: onEditProfile,
          ),
          _buildActionTile(
            icon: Icons.lock_rounded,
            label: "Change Password",
            color: kPrimaryGreen,
            onTap: onChangePassword,
          ),
          _buildActionTile(
            icon: Icons.settings_rounded,
            label: "Settings",
            color: kSoftOrange,
            onTap: onSettings,
          ),
          _buildActionTile(
            icon: Icons.logout_rounded,
            label: "Logout",
            color: kErrorColor,
            onTap: onLogout,
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
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: isLogout ? color : color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isLogout ? color : kTextPrimary,
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: kTextSecondary.withOpacity(0.3),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================
// SETTINGS SHEET
// ===========================
class _SettingsSheet extends StatelessWidget {
  final VoidCallback onNotificationsTap;
  final VoidCallback onLanguageTap;
  final VoidCallback onThemeTap;
  final VoidCallback onPrivacyTap;

  const _SettingsSheet({
    required this.onNotificationsTap,
    required this.onLanguageTap,
    required this.onThemeTap,
    required this.onPrivacyTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: kPrimaryBlue.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(3),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [kPrimaryBlue, kPrimaryGreen],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: kPrimaryBlue.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.settings_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  "Settings",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: kTextPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.close, color: kTextSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: Colors.grey.shade200),

          // Settings options
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSettingTile(
                  icon: Icons.notifications_outlined,
                  title: "Notifications",
                  subtitle: "Manage notification preferences",
                  color: kPrimaryBlue,
                  onTap: onNotificationsTap,
                ),
                _buildSettingTile(
                  icon: Icons.language_outlined,
                  title: "Language",
                  subtitle: "English (United States)",
                  color: kPrimaryGreen,
                  onTap: onLanguageTap,
                ),
                _buildSettingTile(
                  icon: Icons.dark_mode_outlined,
                  title: "Theme",
                  subtitle: "Light Mode",
                  color: kSoftOrange,
                  onTap: onThemeTap,
                ),
                _buildSettingTile(
                  icon: Icons.privacy_tip_outlined,
                  title: "Privacy",
                  subtitle: "Manage privacy settings",
                  color: kDarkBlue,
                  onTap: onPrivacyTap,
                ),
                _buildSettingTile(
                  icon: Icons.help_outline,
                  title: "Help & Support",
                  subtitle: "Get help and contact support",
                  color: kPrimaryBlue,
                  onTap: () {
                    Navigator.pop(context);
                    _showComingSoon(context, "Help & Support");
                  },
                ),
                _buildSettingTile(
                  icon: Icons.info_outline,
                  title: "About",
                  subtitle: "Version 1.0.0",
                  color: kPrimaryGreen,
                  onTap: () {
                    Navigator.pop(context);
                    _showComingSoon(context, "About");
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: kTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: kTextSecondary),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: kTextSecondary.withOpacity(0.3),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================
// NOTIFICATIONS SETTINGS SHEET
// ===========================
class _NotificationsSettingsSheet extends StatefulWidget {
  const _NotificationsSettingsSheet({Key? key}) : super(key: key);

  @override
  State<_NotificationsSettingsSheet> createState() =>
      _NotificationsSettingsSheetState();
}

class _NotificationsSettingsSheetState
    extends State<_NotificationsSettingsSheet> {
  bool pushNotifications = true;
  bool emailNotifications = true;
  bool smsNotifications = false;
  bool assignmentAlerts = true;
  bool gradeAlerts = true;
  bool attendanceAlerts = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: kPrimaryBlue.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(3),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [kPrimaryBlue, kPrimaryGreen],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: kPrimaryBlue.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.notifications_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  "Notifications",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: kTextPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.close, color: kTextSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: Colors.grey.shade200),

          // Settings options
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSwitchTile(
                  title: "Push Notifications",
                  subtitle: "Receive notifications on your device",
                  value: pushNotifications,
                  color: kPrimaryBlue,
                  onChanged: (val) => setState(() => pushNotifications = val),
                ),
                _buildSwitchTile(
                  title: "Email Notifications",
                  subtitle: "Receive notifications via email",
                  value: emailNotifications,
                  color: kPrimaryGreen,
                  onChanged: (val) => setState(() => emailNotifications = val),
                ),
                _buildSwitchTile(
                  title: "SMS Notifications",
                  subtitle: "Receive notifications via text message",
                  value: smsNotifications,
                  color: kSoftOrange,
                  onChanged: (val) => setState(() => smsNotifications = val),
                ),
                const Divider(height: 24),
                const Text(
                  "Alert Types",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: kTextPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                _buildSwitchTile(
                  title: "Assignment Alerts",
                  subtitle: "Get notified about new assignments",
                  value: assignmentAlerts,
                  color: kPrimaryBlue,
                  onChanged: (val) => setState(() => assignmentAlerts = val),
                ),
                _buildSwitchTile(
                  title: "Grade Alerts",
                  subtitle: "Get notified when grades are posted",
                  value: gradeAlerts,
                  color: kPrimaryGreen,
                  onChanged: (val) => setState(() => gradeAlerts = val),
                ),
                _buildSwitchTile(
                  title: "Attendance Alerts",
                  subtitle: "Get notified about attendance",
                  value: attendanceAlerts,
                  color: kSoftOrange,
                  onChanged: (val) => setState(() => attendanceAlerts = val),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Color color,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              value ? Icons.notifications_active : Icons.notifications_off,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: kTextPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: kTextSecondary),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: color,
            activeTrackColor: color.withOpacity(0.5),
          ),
        ],
      ),
    );
  }
}

// ===========================
// LANGUAGE SETTINGS SHEET
// ===========================
class _LanguageSettingsSheet extends StatefulWidget {
  const _LanguageSettingsSheet({Key? key}) : super(key: key);

  @override
  State<_LanguageSettingsSheet> createState() => _LanguageSettingsSheetState();
}

class _LanguageSettingsSheetState extends State<_LanguageSettingsSheet> {
  String _selectedLanguage = "English";
  final List<Map<String, dynamic>> languages = const [
    {"name": "English", "code": "en", "flag": "🇺🇸"},
    {"name": "Somali", "code": "so", "flag": "🇸🇴"},
    {"name": "Arabic", "code": "ar", "flag": "🇸🇦"},
    {"name": "French", "code": "fr", "flag": "🇫🇷"},
    {"name": "Spanish", "code": "es", "flag": "🇪🇸"},
    {"name": "Urdu", "code": "ur", "flag": "🇵🇰"},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: kPrimaryBlue.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(3),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [kPrimaryBlue, kPrimaryGreen],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: kPrimaryBlue.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.language_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  "Language",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: kTextPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.close, color: kTextSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: Colors.grey.shade200),

          // Language list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: languages.length,
              itemBuilder: (context, index) {
                final lang = languages[index];
                final isSelected = _selectedLanguage == lang["name"];

                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedLanguage = lang["name"];
                    });
                    // Apply language change
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Language changed to ${lang["name"]}'),
                        backgroundColor: kPrimaryGreen,
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? kPrimaryBlue.withOpacity(0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Text(
                              lang["flag"],
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            lang["name"],
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected ? kPrimaryBlue : kTextPrimary,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle_rounded,
                            color: kPrimaryBlue,
                            size: 24,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================
// THEME SETTINGS SHEET
// ===========================
class _ThemeSettingsSheet extends StatefulWidget {
  const _ThemeSettingsSheet({Key? key}) : super(key: key);

  @override
  State<_ThemeSettingsSheet> createState() => _ThemeSettingsSheetState();
}

class _ThemeSettingsSheetState extends State<_ThemeSettingsSheet> {
  String _selectedTheme = "Light";
  final List<Map<String, dynamic>> themes = const [
    {"name": "Light", "icon": Icons.light_mode_rounded, "color": Colors.amber},
    {"name": "Dark", "icon": Icons.dark_mode_rounded, "color": Colors.indigo},
    {
      "name": "System Default",
      "icon": Icons.settings_rounded,
      "color": Colors.grey,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: kPrimaryBlue.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(3),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [kPrimaryBlue, kPrimaryGreen],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: kPrimaryBlue.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.palette_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  "Theme",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: kTextPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.close, color: kTextSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: Colors.grey.shade200),

          // Theme options
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: themes.length,
              itemBuilder: (context, index) {
                final theme = themes[index];
                final isSelected = _selectedTheme == theme["name"];

                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedTheme = theme["name"];
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Theme changed to ${theme["name"]}'),
                        backgroundColor: kPrimaryGreen,
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme["color"].withOpacity(0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Icon(
                            theme["icon"],
                            color: theme["color"],
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            theme["name"],
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected ? kPrimaryBlue : kTextPrimary,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle_rounded,
                            color: kPrimaryBlue,
                            size: 24,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================
// PRIVACY SETTINGS SHEET
// ===========================
class _PrivacySettingsSheet extends StatefulWidget {
  const _PrivacySettingsSheet({Key? key}) : super(key: key);

  @override
  State<_PrivacySettingsSheet> createState() => _PrivacySettingsSheetState();
}

class _PrivacySettingsSheetState extends State<_PrivacySettingsSheet> {
  bool shareProfile = true;
  bool showEmail = true;
  bool showPhone = false;
  bool allowDataCollection = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: kPrimaryBlue.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(3),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [kPrimaryBlue, kPrimaryGreen],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: kPrimaryBlue.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.privacy_tip_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  "Privacy",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: kTextPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.close, color: kTextSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: Colors.grey.shade200),

          // Privacy options
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildPrivacyTile(
                  title: "Share Profile",
                  subtitle: "Allow others to see your profile",
                  value: shareProfile,
                  color: kPrimaryBlue,
                  onChanged: (val) => setState(() => shareProfile = val),
                ),
                _buildPrivacyTile(
                  title: "Show Email",
                  subtitle: "Display your email address",
                  value: showEmail,
                  color: kPrimaryGreen,
                  onChanged: (val) => setState(() => showEmail = val),
                ),
                _buildPrivacyTile(
                  title: "Show Phone",
                  subtitle: "Display your phone number",
                  value: showPhone,
                  color: kSoftOrange,
                  onChanged: (val) => setState(() => showPhone = val),
                ),
                _buildPrivacyTile(
                  title: "Data Collection",
                  subtitle: "Allow anonymous data collection",
                  value: allowDataCollection,
                  color: kDarkBlue,
                  onChanged: (val) => setState(() => allowDataCollection = val),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: kSoftBlue.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "Privacy Policy",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: kTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Your data is protected and secure. We never share your personal information with third parties without your consent.",
                        style: TextStyle(fontSize: 12, color: kTextSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyTile({
    required String title,
    required String subtitle,
    required bool value,
    required Color color,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              value ? Icons.lock_open : Icons.lock,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: kTextPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: kTextSecondary),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: color,
            activeTrackColor: color.withOpacity(0.5),
          ),
        ],
      ),
    );
  }
}

// ===========================
// EDIT PROFILE SHEET
// ===========================
class _EditProfileSheet extends StatefulWidget {
  final Map<String, dynamic> teacher;
  final Function(Map<String, dynamic>) onSave;

  const _EditProfileSheet({required this.teacher, required this.onSave});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _genderController;
  late TextEditingController _qualificationController;
  late TextEditingController _experienceController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.teacher['name'] ?? '');
    _emailController = TextEditingController(
      text: widget.teacher['email'] ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.teacher['phone'] ?? '',
    );
    _addressController = TextEditingController(
      text: widget.teacher['address'] ?? '',
    );
    _genderController = TextEditingController(
      text: widget.teacher['gender'] ?? 'Male',
    );
    _qualificationController = TextEditingController(
      text: widget.teacher['qualification'] ?? '',
    );
    _experienceController = TextEditingController(
      text: widget.teacher['experience'] ?? '',
    );
    _notesController = TextEditingController(
      text: widget.teacher['notes'] ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _genderController.dispose();
    _qualificationController.dispose();
    _experienceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: kPrimaryBlue.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(3),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [kPrimaryBlue, kPrimaryGreen],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: kPrimaryBlue.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  "Edit Profile",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: kTextPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.close, color: kTextSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: Colors.grey.shade200),

          // Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildTextField(
                    controller: _nameController,
                    label: "Full Name",
                    icon: Icons.person_outline,
                    color: kPrimaryBlue,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _emailController,
                    label: "Email",
                    icon: Icons.email_outlined,
                    color: kPrimaryGreen,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _phoneController,
                    label: "Phone",
                    icon: Icons.phone_outlined,
                    color: kSoftOrange,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _addressController,
                    label: "Address",
                    icon: Icons.location_on_outlined,
                    color: kDarkBlue,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _genderController,
                    label: "Gender",
                    icon: Icons.people_outline,
                    color: kPrimaryBlue,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _qualificationController,
                    label: "Qualification",
                    icon: Icons.school_outlined,
                    color: kPrimaryGreen,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _experienceController,
                    label: "Experience",
                    icon: Icons.timelapse_outlined,
                    color: kSoftOrange,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _notesController,
                    label: "Notes",
                    icon: Icons.note_alt_outlined,
                    color: kDarkBlue,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [kPrimaryBlue, kPrimaryGreen],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: kPrimaryBlue.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          // Create updated teacher data
                          final updatedTeacher = Map<String, dynamic>.from(
                            widget.teacher,
                          );

                          // Update all fields
                          updatedTeacher['name'] = _nameController.text;
                          updatedTeacher['email'] = _emailController.text;
                          updatedTeacher['phone'] = _phoneController.text;
                          updatedTeacher['address'] = _addressController.text;
                          updatedTeacher['gender'] = _genderController.text;
                          updatedTeacher['qualification'] =
                              _qualificationController.text;
                          updatedTeacher['experience'] =
                              _experienceController.text;
                          updatedTeacher['notes'] = _notesController.text;

                          // Call the callback with updated data
                          widget.onSave(updatedTeacher);

                          // Close the sheet
                          Navigator.pop(context);

                          // Show success message
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                'Profile updated successfully',
                              ),
                              backgroundColor: kPrimaryGreen,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: const Center(
                          child: Text(
                            "Save Changes",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color color,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: kSoftBlue.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600),
          prefixIcon: Icon(icon, color: color),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        style: const TextStyle(color: kTextPrimary),
      ),
    );
  }
}

// ===========================
// CHANGE PASSWORD SHEET
// ===========================
class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet({Key? key}) : super(key: key);

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: kPrimaryBlue.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(3),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [kPrimaryBlue, kPrimaryGreen],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: kPrimaryBlue.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.lock_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  "Change Password",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: kTextPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.close, color: kTextSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: Colors.grey.shade200),

          // Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildPasswordField(
                    controller: _currentPasswordController,
                    label: "Current Password",
                    icon: Icons.lock_outline,
                    color: kPrimaryBlue,
                    obscure: _obscureCurrent,
                    onToggle: () =>
                        setState(() => _obscureCurrent = !_obscureCurrent),
                  ),
                  const SizedBox(height: 16),
                  _buildPasswordField(
                    controller: _newPasswordController,
                    label: "New Password",
                    icon: Icons.lock_reset,
                    color: kPrimaryGreen,
                    obscure: _obscureNew,
                    onToggle: () => setState(() => _obscureNew = !_obscureNew),
                  ),
                  const SizedBox(height: 16),
                  _buildPasswordField(
                    controller: _confirmPasswordController,
                    label: "Confirm Password",
                    icon: Icons.check_circle_outline,
                    color: kSoftOrange,
                    obscure: _obscureConfirm,
                    onToggle: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [kPrimaryBlue, kPrimaryGreen],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: kPrimaryBlue.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          // Validate passwords
                          if (_newPasswordController.text !=
                              _confirmPasswordController.text) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Passwords do not match'),
                                backgroundColor: kErrorColor,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            return;
                          }

                          if (_newPasswordController.text.length < 6) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                  'Password must be at least 6 characters',
                                ),
                                backgroundColor: kErrorColor,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            return;
                          }

                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                'Password changed successfully',
                              ),
                              backgroundColor: kPrimaryGreen,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: const Center(
                          child: Text(
                            "Change Password",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color color,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: kSoftBlue.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600),
          prefixIcon: Icon(icon, color: color),
          suffixIcon: IconButton(
            icon: Icon(
              obscure ? Icons.visibility_off : Icons.visibility,
              color: color,
            ),
            onPressed: onToggle,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        style: const TextStyle(color: kTextPrimary),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kPrimaryBlue.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kPrimaryGreen, kPrimaryBlue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: kPrimaryGreen.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.info_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                "Additional Details",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: kTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Address ExpansionTile
          Container(
            decoration: BoxDecoration(
              color: kSoftBlue.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                leading: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: kPrimaryBlue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.location_on_rounded,
                    color: kPrimaryBlue,
                    size: 16,
                  ),
                ),
                title: const Text(
                  "Address",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: kTextPrimary,
                    fontSize: 15,
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 44,
                      bottom: 12,
                      right: 12,
                    ),
                    child: Text(
                      address,
                      style: TextStyle(
                        color: kTextSecondary,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Notes ExpansionTile
          Container(
            decoration: BoxDecoration(
              color: kSoftBlue.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                leading: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: kPrimaryGreen.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.note_alt_rounded,
                    color: kPrimaryGreen,
                    size: 16,
                  ),
                ),
                title: const Text(
                  "Notes",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: kTextPrimary,
                    fontSize: 15,
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 44,
                      bottom: 12,
                      right: 12,
                    ),
                    child: Text(
                      notes,
                      style: TextStyle(
                        color: kTextSecondary,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Emergency Contact ExpansionTile
          Container(
            decoration: BoxDecoration(
              color: kSoftBlue.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                leading: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: kSoftOrange.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.contact_emergency_rounded,
                    color: kSoftOrange,
                    size: 16,
                  ),
                ),
                title: const Text(
                  "Emergency Contact",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: kTextPrimary,
                    fontSize: 15,
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 44,
                      bottom: 12,
                      right: 12,
                    ),
                    child: Text(
                      emergency,
                      style: TextStyle(
                        color: kTextSecondary,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Helper function for coming soon
void _showComingSoon(BuildContext context, String feature) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(feature),
      content: Text('$feature screen is coming soon!'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}
