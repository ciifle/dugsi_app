import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

// ---------- WONDERFUL COLOR PALETTE ----------
const Color kPrimaryColor = Color(0xFF1E3A8A);
const Color kSecondaryColor = Color(0xFF3B82F6);
const Color kAccentColor = Color(0xFF10B981);
const Color kSoftPurple = Color(0xFF8B5CF6);
const Color kSoftPink = Color(0xFFEC4899);
const Color kSoftOrange = Color(0xFFF59E0B);
const Color kSoftBlue = Color(0xFF3B82F6);
const Color kSuccessColor = Color(0xFF059669);
const Color kWarningColor = Color(0xFFF59E0B);
const Color kErrorColor = Color(0xFFEF4444);
const Color kBackgroundColor = Color(0xFFF8FAFC);
const Color kSurfaceColor = Colors.white;
const Color kTextPrimaryColor = Color(0xFF1E293B);
const Color kTextSecondaryColor = Color(0xFF64748B);

// ==================== WONDERFUL SNACKBAR ====================

enum SnackBarType { success, error, warning, info }

class WonderfulSnackBar {
  static void show({
    required BuildContext context,
    required String message,
    required SnackBarType type,
    Duration duration = const Duration(seconds: 3),
  }) {
    final colors = _getSnackBarColors(type);

    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => _WonderfulSnackBarContent(
        message: message,
        colors: colors,
        duration: duration,
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(duration, () {
      overlayEntry.remove();
    });
  }

  static Map<String, Color> _getSnackBarColors(SnackBarType type) {
    switch (type) {
      case SnackBarType.success:
        return {
          'background': const Color(0xFF10B981),
          'icon': Colors.white,
          'text': Colors.white,
        };
      case SnackBarType.error:
        return {
          'background': const Color(0xFFEF4444),
          'icon': Colors.white,
          'text': Colors.white,
        };
      case SnackBarType.warning:
        return {
          'background': const Color(0xFFF59E0B),
          'icon': Colors.white,
          'text': Colors.white,
        };
      case SnackBarType.info:
        return {
          'background': const Color(0xFF3B82F6),
          'icon': Colors.white,
          'text': Colors.white,
        };
    }
  }
}

class _WonderfulSnackBarContent extends StatefulWidget {
  final String message;
  final Map<String, Color> colors;
  final Duration duration;

  const _WonderfulSnackBarContent({
    Key? key,
    required this.message,
    required this.colors,
    required this.duration,
  }) : super(key: key);

  @override
  State<_WonderfulSnackBarContent> createState() =>
      _WonderfulSnackBarContentState();
}

class _WonderfulSnackBarContentState extends State<_WonderfulSnackBarContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  IconData _getIcon() {
    if (widget.colors['background'] == const Color(0xFF10B981)) {
      return Icons.check_circle_rounded;
    } else if (widget.colors['background'] == const Color(0xFFEF4444)) {
      return Icons.error_rounded;
    } else if (widget.colors['background'] == const Color(0xFFF59E0B)) {
      return Icons.warning_rounded;
    } else {
      return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 16,
      right: 16,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    widget.colors['background']!,
                    widget.colors['background']!.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: widget.colors['background']!.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _SnackBarPatternPainter(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.3),
                                  blurRadius: 10,
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: Icon(
                              _getIcon(),
                              color: widget.colors['icon'],
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),

                          Expanded(
                            child: Text(
                              widget.message,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),

                          GestureDetector(
                            onTap: () {
                              _controller.reverse().then((_) {
                                if (mounted) {
                                  Navigator.of(context).maybePop();
                                }
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 1.0, end: 0.0),
                        duration: widget.duration,
                        builder: (context, value, child) {
                          return LinearProgressIndicator(
                            value: value,
                            backgroundColor: Colors.transparent,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white.withOpacity(0.3),
                            ),
                            minHeight: 3,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SnackBarPatternPainter extends CustomPainter {
  final Color color;

  _SnackBarPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const spacing = 20.0;
    for (double i = -size.height; i < size.width + size.height; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i - size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

extension WonderfulSnackBarExtension on BuildContext {
  void showWonderfulSnackBar({
    required String message,
    required SnackBarType type,
    Duration duration = const Duration(seconds: 3),
  }) {
    WonderfulSnackBar.show(
      context: this,
      message: message,
      type: type,
      duration: duration,
    );
  }
}

// ==================== STUDENT RESULTS SCREEN ====================

class StudentResultsScreen extends StatefulWidget {
  const StudentResultsScreen({Key? key}) : super(key: key);

  @override
  State<StudentResultsScreen> createState() => _StudentResultsScreenState();
}

class _StudentResultsScreenState extends State<StudentResultsScreen>
    with SingleTickerProviderStateMixin {
  final List<Map<String, dynamic>> _subjects = [
    {
      'name': 'Mathematics',
      'obtained': 87,
      'total': 100,
      'grade': 'A',
      'status': 'Pass',
      'icon': Icons.calculate_rounded,
    },
    {
      'name': 'Science',
      'obtained': 76,
      'total': 100,
      'grade': 'B+',
      'status': 'Pass',
      'icon': Icons.science_rounded,
    },
    {
      'name': 'English Literature',
      'obtained': 68,
      'total': 100,
      'grade': 'B',
      'status': 'Pass',
      'icon': Icons.menu_book_rounded,
    },
    {
      'name': 'History',
      'obtained': 54,
      'total': 100,
      'grade': 'C+',
      'status': 'Improve',
      'icon': Icons.history_edu_rounded,
    },
    {
      'name': 'Physical Education',
      'obtained': 89,
      'total': 100,
      'grade': 'A',
      'status': 'Pass',
      'icon': Icons.sports_rounded,
    },
  ];

  final List<String> _terms = ["Term 1", "Term 2", "Final"];
  String _selectedTerm = "Term 1";
  final String _remarkText =
      "Great effort this term! Focus on History for improvement next semester. Keep up the excellent work in Mathematics and Science!";

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Map<String, dynamic> get _overallStats {
    int totalSubjects = _subjects.length;
    int totalObtained = _subjects.fold<int>(
      0,
      (a, b) => a + (b['obtained'] as int),
    );
    int totalMarks = _subjects.fold<int>(0, (a, b) => a + (b['total'] as int));

    double overallPercent = totalMarks > 0
        ? (totalObtained / totalMarks) * 100
        : 0.0;

    String grade = overallPercent >= 90
        ? 'A+'
        : overallPercent >= 80
        ? 'A'
        : overallPercent >= 70
        ? 'B+'
        : overallPercent >= 60
        ? 'B'
        : overallPercent >= 50
        ? 'C'
        : 'D';

    String status = overallPercent >= 50 ? 'Pass' : 'Needs Improvement';

    return {
      'totalSubjects': totalSubjects,
      'totalObtained': totalObtained,
      'totalMarks': totalMarks,
      'percent': overallPercent,
      'grade': grade,
      'status': status,
    };
  }

  void _shareResults() async {
    final stats = _overallStats;

    String shareText =
        '''
📊 *MY ACADEMIC RESULTS* 📊

━━━━━━━━━━━━━━━━━━━━━
📚 *Overall Performance*
━━━━━━━━━━━━━━━━━━━━━
• Subjects: ${stats['totalSubjects']}
• Percentage: ${stats['percent'].toStringAsFixed(1)}%
• Grade: ${stats['grade']}
• Status: ${stats['status']}

━━━━━━━━━━━━━━━━━━━━━
📋 *Subject Details*
━━━━━━━━━━━━━━━━━━━━━
${_subjects.map((s) => "• ${s['name']}\n  Grade: ${s['grade']} (${s['obtained']}/${s['total']}) - ${s['status']}").join('\n\n')}

━━━━━━━━━━━━━━━━━━━━━
💬 *Teacher's Remark*
━━━━━━━━━━━━━━━━━━━━━
$_remarkText

━━━━━━━━━━━━━━━━━━━━━
📱 Shared from Student App
━━━━━━━━━━━━━━━━━━━━━
    ''';

    try {
      await Share.share(
        shareText,
        subject: 'My Academic Results - ${stats['grade']} Grade',
      );

      // Show wonderful success snackbar
      if (mounted) {
        context.showWonderfulSnackBar(
          message: '✨ Results shared successfully!',
          type: SnackBarType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        context.showWonderfulSnackBar(
          message: '❌ Failed to share. Please try again.',
          type: SnackBarType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = _overallStats;

    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 100,
            pinned: true,
            backgroundColor: kPrimaryColor,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 12),
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.emoji_events_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Results",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [kPrimaryColor, kSecondaryColor],
                  ),
                ),
              ),
            ),
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 22,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.share, color: Colors.white, size: 20),
                  onPressed: _shareResults,
                  tooltip: 'Share Results',
                ),
              ),
            ],
          ),

          // Main Content
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      _buildOverallStatsCard(stats),
                      const SizedBox(height: 20),
                      _buildTermSelector(),
                      const SizedBox(height: 16),
                      _buildSubjectsHeader(stats['totalSubjects']),
                      const SizedBox(height: 12),
                      ...List.generate(_subjects.length, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _SubjectResultCard(
                            subject: _subjects[index],
                            index: index,
                          ),
                        );
                      }),
                      const SizedBox(height: 20),
                      if (_remarkText.isNotEmpty) ...[
                        _buildRemarksCard(),
                        const SizedBox(height: 16),
                      ],
                      _buildPerformanceIndicator(stats['percent']),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallStatsCard(Map<String, dynamic> stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem(
                icon: Icons.menu_book_rounded,
                label: "Subjects",
                value: "${stats['totalSubjects']}",
                color: kSoftPurple,
              ),
              Container(height: 35, width: 1, color: Colors.grey.shade300),
              _buildStatItem(
                icon: Icons.percent_rounded,
                label: "Average",
                value: "${stats['percent'].toStringAsFixed(1)}%",
                color: kAccentColor,
              ),
              Container(height: 35, width: 1, color: Colors.grey.shade300),
              _buildStatItem(
                icon: Icons.grade_rounded,
                label: "Grade",
                value: stats['grade'],
                color: kSoftOrange,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: stats['status'] == 'Pass'
                    ? [kSuccessColor, kAccentColor]
                    : [kWarningColor, kSoftOrange],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      stats['status'] == 'Pass'
                          ? Icons.check_circle_rounded
                          : Icons.warning_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      stats['status'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      "${stats['totalObtained']}/${stats['totalMarks']}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 14,
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

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: kTextSecondaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: kTextPrimaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildTermSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _terms.map((term) {
          bool isSelected = term == _selectedTerm;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTerm = term;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [kSecondaryColor, kPrimaryColor],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  term,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : kTextSecondaryColor,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSubjectsHeader(int totalSubjects) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: kSoftPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.menu_book_rounded,
                color: kSoftPurple,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Subject Details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: kTextPrimaryColor,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: kSoftPurple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$totalSubjects subjects',
            style: TextStyle(
              color: kSoftPurple,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceIndicator(double percent) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: kAccentColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.trending_up_rounded,
              color: kAccentColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Performance Trend",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: kTextPrimaryColor,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: percent / 100,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    percent >= 75
                        ? kSuccessColor
                        : percent >= 50
                        ? kWarningColor
                        : kErrorColor,
                  ),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemarksCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: kPrimaryColor.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: kSoftPurple.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.format_quote_rounded,
              color: kSoftPurple,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Teacher's Remark",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: kTextPrimaryColor,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _remarkText,
                  style: TextStyle(
                    color: kTextSecondaryColor,
                    fontSize: 13,
                    height: 1.4,
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

class _SubjectResultCard extends StatelessWidget {
  final Map<String, dynamic> subject;
  final int index;

  const _SubjectResultCard({
    Key? key,
    required this.subject,
    required this.index,
  }) : super(key: key);

  Color _getSubjectColor(int index) {
    final colors = [
      kSoftPurple,
      kSoftPink,
      kAccentColor,
      kSoftOrange,
      kSoftBlue,
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final Color subjectColor = _getSubjectColor(index);
    final double percent = (subject['obtained'] / subject['total']) * 100;

    return Container(
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: subjectColor.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: subjectColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(subject['icon'], color: subjectColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subject['name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: kTextPrimaryColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: kTextSecondaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "${subject['obtained']}/${subject['total']}",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: kTextSecondaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: subjectColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "Grade ${subject['grade']}",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: subjectColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: subject['status'] == 'Pass'
                        ? kSuccessColor.withOpacity(0.1)
                        : kWarningColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    subject['status'],
                    style: TextStyle(
                      color: subject['status'] == 'Pass'
                          ? kSuccessColor
                          : kWarningColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
