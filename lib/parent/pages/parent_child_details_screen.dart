import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kobac/parent/pages/parent_attendance_screen.dart';
import 'package:kobac/parent/pages/parent_fee_payment_screen.dart';
import 'package:kobac/parent/pages/parent_result_screen.dart';
import 'package:kobac/services/auth_provider.dart';

// Color constants
const Color kPrimaryBlue = Color(0xFF023471);
const Color kPrimaryGreen = Color(0xFF5AB04B);
const Color kSoftBlue = Color(0xFFE6F0FF);
const Color kSoftPurple = Color(0xFFA29BFE);
const Color kSoftOrange = Color(0xFFF59E0B);
const Color kBackgroundEnd = Color(0xFFF5F0FF);
const Color kTextPrimary = Color(0xFF2D3436);
const Color kTextSecondary = Color(0xFF636E72);
const Color kSuccessColor = Color(0xFF059669);
const Color kErrorColor = Color(0xFFEF4444);
const Color kSecondaryColor = Color(0xFF6C5CE7);
const Color kAccentColor = Color(0xFF00B894);
const Color kSoftPink = Color(0xFFFF7675);
const Color kDarkBlue = Color(0xFF01255C);

class ParentChildDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> child;

  const ParentChildDetailsScreen({Key? key, required this.child})
    : super(key: key);

  String _getInitials(String name) {
    if (name.isEmpty) return '';
    List<String> parts = name.trim().split(' ');
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts.last[0]).toUpperCase();
  }

  String _getGradeLetter(double percentage) {
    if (percentage >= 90) return 'A';
    if (percentage >= 80) return 'B';
    if (percentage >= 70) return 'C';
    if (percentage >= 60) return 'D';
    return 'F';
  }

  Color _getGradeColor(double percentage) {
    if (percentage >= 90) return kSuccessColor;
    if (percentage >= 80) return kSoftBlue;
    if (percentage >= 70) return kSoftOrange;
    if (percentage >= 60) return kSoftPurple;
    return kErrorColor;
  }

  String _getGradeRemark(double percentage) {
    if (percentage >= 90) return 'Excellent';
    if (percentage >= 80) return 'Very Good';
    if (percentage >= 70) return 'Good';
    if (percentage >= 60) return 'Satisfactory';
    return 'Needs Improvement';
  }

  String _getSubjectDisplayName(String subject) {
    final subj = subject.toLowerCase();
    if (subj.contains('math')) return 'Mathematics';
    if (subj.contains('science')) return 'Science';
    if (subj.contains('history')) return 'History';
    if (subj.contains('english')) return 'English';
    if (subj.contains('physics')) return 'Physics';
    if (subj.contains('chemistry')) return 'Chemistry';
    if (subj.contains('art')) return 'Art';
    return subject;
  }

  IconData _getSubjectIcon(String subject) {
    final subj = subject.toLowerCase();
    if (subj.contains('math')) {
      return Icons.calculate_rounded;
    } else if (subj.contains('science') ||
        subj.contains('chemistry') ||
        subj.contains('physics')) {
      return Icons.science_rounded;
    } else if (subj.contains('english')) {
      return Icons.menu_book_rounded;
    } else if (subj.contains('history')) {
      return Icons.history_edu_rounded;
    } else if (subj.contains('art')) {
      return Icons.palette_rounded;
    } else {
      return Icons.subject_rounded;
    }
  }

  Color _getSubjectColor(String subject) {
    final subj = subject.toLowerCase();
    if (subj.contains('math')) {
      return kSoftPurple;
    } else if (subj.contains('science') ||
        subj.contains('chemistry') ||
        subj.contains('physics')) {
      return kSoftBlue;
    } else if (subj.contains('english')) {
      return kAccentColor;
    } else if (subj.contains('history')) {
      return kSoftOrange;
    } else if (subj.contains('art')) {
      return kSoftPink;
    } else {
      return kSecondaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String childName = child['name'] ?? 'Unknown';
    final String className = child['className'] ?? 'Not Assigned';
    final String rollNo = child['rollNo'] ?? 'N/A';
    final int attendance = child['attendance'] ?? 0;
    final String progress = child['progress'] ?? 'Good';
    final List<dynamic> subjects = child['subjects'] ?? [];
    final Map<String, dynamic> fee = child['fee'] ?? {};
    final double dueAmount = (fee['dueAmount'] as double?) ?? 0.0;
    final double average = child['average'] ?? 0;

    // Calculate total points and overall grade
    int totalPoints = 0;
    int totalPossible = 0;
    for (var subject in subjects) {
      totalPoints += subject['marks'] as int;
      totalPossible += subject['total'] as int;
    }
    final double percentage = totalPossible > 0
        ? (totalPoints / totalPossible) * 100
        : 0;
    final String overallGrade = _getGradeLetter(percentage);
    final String gradeRemark = _getGradeRemark(percentage);
    final Color gradeColor = _getGradeColor(percentage);

    return Scaffold(
      backgroundColor: kBackgroundEnd,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Custom Sliver App Bar
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            stretch: true,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Gradient Background
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [kPrimaryBlue, kSecondaryColor, kPrimaryGreen],
                        stops: const [0.1, 0.5, 0.9],
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(40),
                        bottomRight: Radius.circular(40),
                      ),
                    ),
                  ),

                  // Pattern Overlay
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.1,
                      child: CustomPaint(painter: _CirclesPainter()),
                    ),
                  ),

                  // Content
                  Positioned(
                    bottom: 30,
                    left: 20,
                    right: 20,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Large Avatar
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                            gradient: LinearGradient(
                              colors: [kSoftPurple, kSoftBlue],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              _getInitials(childName),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        // Name and Class
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                childName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black26,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  _buildInfoChip(className),
                                  const SizedBox(width: 8),
                                  _buildInfoChip('Roll: $rollNo'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            leading: _buildActionButton(
              icon: Icons.arrow_back_rounded,
              onPressed: () => Navigator.pop(context),
            ),
            actions: [_buildPopupMenu()],
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 10),

                // Fee Status Card (only when fees enabled for school)
                if (context.watch<AuthProvider>().feesEnabled && dueAmount > 0) _buildFeeCard(dueAmount, fee, context),

                const SizedBox(height: 20),

                // Overall Grade Card
                _buildOverallGradeCard(
                  gradeColor,
                  overallGrade,
                  gradeRemark,
                  average,
                  totalPoints,
                  totalPossible,
                ),

                const SizedBox(height: 20),

                // Stats Cards Grid
                _buildStatsGrid(attendance, average, progress),

                const SizedBox(height: 24),

                // Subjects Section Header
                _buildSectionHeader(
                  Icons.menu_book_rounded,
                  'Subjects & Grades',
                  [kSoftPurple, kSoftBlue],
                ),

                const SizedBox(height: 16),

                // Subjects List - Each subject clearly displayed
                ...subjects
                    .map((subject) => _buildSubjectCard(subject))
                    .toList(),

                const SizedBox(height: 24),

                // Quick Actions Section
                _buildQuickActionsSection(fee, child, context),

                const SizedBox(height: 20),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build info chip
  Widget _buildInfoChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // Helper method to build action button
  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      margin: const EdgeInsets.only(left: 16, top: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 24),
        onPressed: onPressed,
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(),
      ),
    );
  }

  // Helper method to build popup menu
  Widget _buildPopupMenu() {
    return Container(
      margin: const EdgeInsets.only(right: 16, top: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
      ),
      child: PopupMenuButton<String>(
        icon: const Icon(
          Icons.more_vert_rounded,
          color: Colors.white,
          size: 22,
        ),
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        offset: const Offset(0, 40),
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'share',
            child: Row(
              children: [
                Icon(Icons.share_rounded, color: kSoftPurple),
                SizedBox(width: 12),
                Text('Share Profile'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'report',
            child: Row(
              children: [
                Icon(Icons.download_rounded, color: kSuccessColor),
                SizedBox(width: 12),
                Text('Download Report'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build fee card
  Widget _buildFeeCard(
    double dueAmount,
    Map<String, dynamic> fee,
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kErrorColor.withOpacity(0.1), kSoftOrange.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kErrorColor.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: kErrorColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.warning_rounded, color: kErrorColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Fee Payment Required',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${dueAmount.toStringAsFixed(2)} due by ${fee['dueDate']}',
                  style: TextStyle(
                    color: kErrorColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final feeData = {
                'childName': child['name'],
                'className': child['className'],
                'totalFee': fee['totalFee'],
                'paidAmount': fee['paidAmount'],
                'dueAmount': fee['dueAmount'],
                'dueDate': fee['dueDate'],
                'status': fee['status'],
                'feeType': fee['feeType'],
                'lateFee': fee['lateFee'],
              };
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ParentFeePaymentScreen(fee: feeData),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kErrorColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Pay Now'),
          ),
        ],
      ),
    );
  }

  // Helper method to build overall grade card
  Widget _buildOverallGradeCard(
    Color gradeColor,
    String overallGrade,
    String gradeRemark,
    double average,
    int totalPoints,
    int totalPossible,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [gradeColor.withOpacity(0.1), gradeColor.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: gradeColor.withOpacity(0.3), width: 2),
      ),
      child: Row(
        children: [
          // Grade Letter
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: gradeColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: gradeColor.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                overallGrade,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          // Grade Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Overall Grade',
                  style: TextStyle(fontSize: 14, color: kTextSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  gradeRemark,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: gradeColor,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildInfoChipWithIcon(
                      Icons.analytics_rounded,
                      'Avg: ${average.toStringAsFixed(1)}%',
                      gradeColor,
                    ),
                    const SizedBox(width: 8),
                    _buildInfoChipWithIcon(
                      Icons.calculate_rounded,
                      '$totalPoints/$totalPossible',
                      kSoftBlue,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build info chip with icon
  Widget _buildInfoChipWithIcon(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build stats grid
  Widget _buildStatsGrid(int attendance, double average, String progress) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: [
        _buildStatCard(
          Icons.event_available_rounded,
          '$attendance%',
          'Attendance',
          kSuccessColor,
        ),
        _buildStatCard(
          Icons.analytics_rounded,
          '${average.toStringAsFixed(1)}%',
          'Average',
          kSoftPurple,
        ),
        _buildStatCard(
          Icons.emoji_events_rounded,
          progress,
          'Progress',
          progress == "Excellent" ? kSuccessColor : kSoftOrange,
        ),
      ],
    );
  }

  // Helper method to build stat card
  Widget _buildStatCard(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: Icon(icon, size: 60, color: Colors.white),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 24),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  label,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build section header
  Widget _buildSectionHeader(
    IconData icon,
    String title,
    List<Color> gradientColors,
  ) {
    return Row(
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
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: kTextPrimary,
          ),
        ),
      ],
    );
  }

  // Helper method to build subject card - CLEAR AND DETAILED
  Widget _buildSubjectCard(Map<String, dynamic> subject) {
    final subjectName = subject['name'].toString();
    final displaySubjectName = _getSubjectDisplayName(subjectName);
    final subjectMarks = subject['marks'] as int;
    final subjectTotal = subject['total'] as int;
    final subjectPercentage = (subjectMarks / subjectTotal) * 100;
    final subjectGrade = _getGradeLetter(subjectPercentage);
    final subjectGradeColor = _getGradeColor(subjectPercentage);
    final subjectGradeRemark = _getGradeRemark(subjectPercentage);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Row 1: Subject Icon and Name
          Row(
            children: [
              // Subject Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getSubjectColor(subjectName).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _getSubjectIcon(subjectName),
                  color: _getSubjectColor(subjectName),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              // Subject Name
              Expanded(
                child: Text(
                  displaySubjectName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: kTextPrimary,
                  ),
                ),
              ),
              // Grade Letter Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: subjectGradeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: subjectGradeColor.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Grade ',
                      style: TextStyle(fontSize: 14, color: kTextSecondary),
                    ),
                    Text(
                      subjectGrade,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: subjectGradeColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1, color: Colors.grey),
          const SizedBox(height: 16),

          // Row 2: Marks, Percentage, and Remark
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Marks Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: kSoftBlue.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.score_rounded, color: kSoftBlue, size: 20),
                      const SizedBox(height: 4),
                      Text(
                        'Marks',
                        style: TextStyle(fontSize: 11, color: kTextSecondary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$subjectMarks/$subjectTotal',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: kSoftBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Percentage Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: subjectGradeColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.pie_chart_rounded,
                        color: subjectGradeColor,
                        size: 20,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Percentage',
                        style: TextStyle(fontSize: 11, color: kTextSecondary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${subjectPercentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: subjectGradeColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Remark Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: kSoftPurple.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.star_rounded, color: kSoftPurple, size: 20),
                      const SizedBox(height: 4),
                      Text(
                        'Remark',
                        style: TextStyle(fontSize: 11, color: kTextSecondary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subjectGradeRemark,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: kSoftPurple,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper method to build quick actions section
  Widget _buildQuickActionsSection(
    Map<String, dynamic> fee,
    Map<String, dynamic> child,
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(Icons.bolt_rounded, 'Quick Actions', [
            kPrimaryBlue,
            kPrimaryGreen,
          ]),
          const SizedBox(height: 20),
          Row(
            children: [
              if (context.watch<AuthProvider>().feesEnabled) ...[
                Expanded(
                  child: _buildQuickActionButton(
                    Icons.payment_rounded,
                    'Pay Fees',
                    kPrimaryBlue,
                    () {
                      final feeData = {
                        'childName': child['name'],
                        'className': child['className'],
                        'totalFee': fee['totalFee'],
                        'paidAmount': fee['paidAmount'],
                        'dueAmount': fee['dueAmount'],
                        'dueDate': fee['dueDate'],
                        'status': fee['status'],
                        'feeType': fee['feeType'],
                        'lateFee': fee['lateFee'],
                      };
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ParentFeePaymentScreen(fee: feeData),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: _buildQuickActionButton(
                  Icons.assignment_rounded,
                  'Results',
                  kPrimaryGreen,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ParentResultsScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionButton(
                  Icons.event_available_rounded,
                  'Attendance',
                  kSoftOrange,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ParentAttendanceScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper method to build quick action button
  Widget _buildQuickActionButton(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom painter for background circles
class _CirclesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 0; i < 5; i++) {
      final radius = 20.0 + (i * 15);
      canvas.drawCircle(
        Offset(size.width * (0.2 + i * 0.15), size.height * 0.7),
        radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
