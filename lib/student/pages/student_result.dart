import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:kobac/services/student_service.dart';
import 'package:kobac/student/pages/student_result_report_screen.dart';

// ---------- COLOR PALETTE (Updated to match Dashboard) ----------
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
          'background': kPrimaryGreen,
          'icon': Colors.white,
          'text': Colors.white,
        };
      case SnackBarType.error:
        return {
          'background': kErrorColor,
          'icon': Colors.white,
          'text': Colors.white,
        };
      case SnackBarType.warning:
        return {
          'background': kWarningColor,
          'icon': Colors.white,
          'text': Colors.white,
        };
      case SnackBarType.info:
        return {
          'background': kPrimaryBlue,
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
    if (widget.colors['background'] == kPrimaryGreen) {
      return Icons.check_circle_rounded;
    } else if (widget.colors['background'] == kErrorColor) {
      return Icons.error_rounded;
    } else if (widget.colors['background'] == kWarningColor) {
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

// ==================== WONDERFUL SHARE DIALOG ====================

class WonderfulShareDialog extends StatefulWidget {
  final Map<String, dynamic> stats;
  final List<Map<String, dynamic>> subjects;
  final String remarkText;

  const WonderfulShareDialog({
    Key? key,
    required this.stats,
    required this.subjects,
    required this.remarkText,
  }) : super(key: key);

  @override
  State<WonderfulShareDialog> createState() => _WonderfulShareDialogState();
}

class _WonderfulShareDialogState extends State<WonderfulShareDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

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

  String _generateShareText() {
    return '''
📊 *MY ACADEMIC RESULTS* 📊

━━━━━━━━━━━━━━━━━━━━━
📚 *Overall Performance*
━━━━━━━━━━━━━━━━━━━━━
• Subjects: ${widget.stats['totalSubjects']}
• Percentage: ${widget.stats['percent'].toStringAsFixed(1)}%
• Grade: ${widget.stats['grade']}
• Status: ${widget.stats['status']}

━━━━━━━━━━━━━━━━━━━━━
📋 *Subject Details*
━━━━━━━━━━━━━━━━━━━━━
${widget.subjects.map((s) => "• ${s['name']}\n  Grade: ${s['grade']} (${s['obtained']}/${s['total']}) - ${s['status']}").join('\n\n')}

━━━━━━━━━━━━━━━━━━━━━
💬 *Teacher's Remark*
━━━━━━━━━━━━━━━━━━━━━
${widget.remarkText}

━━━━━━━━━━━━━━━━━━━━━
📱 Shared from Student App
━━━━━━━━━━━━━━━━━━━━━
    ''';
  }

  Future<void> _shareToPlatform(String platform) async {
    Navigator.pop(context); // Close dialog

    final shareText = _generateShareText();
    String subject = 'My Academic Results - ${widget.stats['grade']} Grade';

    try {
      if (platform == 'whatsapp') {
        // For WhatsApp, we can use share_plus with specific options
        await Share.share(shareText, subject: subject);
      } else {
        await Share.share(shareText, subject: subject);
      }

      if (mounted) {
        // Show success snackbar after a short delay
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            context.showWonderfulSnackBar(
              message: '✨ Results shared successfully!',
              type: SnackBarType.success,
            );
          }
        });
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
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, kSoftGreen],
              ),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: kPrimaryBlue.withOpacity(0.2),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: kPrimaryGreen.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(-5, 5),
                ),
              ],
              border: Border.all(
                color: Colors.white.withOpacity(0.5),
                width: 2,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with gradient
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [kPrimaryBlue, kPrimaryGreen],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.share_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Share Results',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Choose how you want to share',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Summary Preview
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: kBackgroundColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: kPrimaryBlue.withOpacity(0.1),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: kPrimaryBlue.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.grade_rounded,
                                          color: kPrimaryBlue,
                                          size: 14,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Overall Grade: ${widget.stats['grade']}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: kPrimaryBlue,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: kPrimaryGreen.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.percent_rounded,
                                          color: kPrimaryGreen,
                                          size: 14,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${widget.stats['percent'].toStringAsFixed(1)}%',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: kPrimaryGreen,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: widget.stats['status'] == 'Pass'
                                      ? [kPrimaryGreen, kDarkGreen]
                                      : [kWarningColor, kSoftOrange],
                                ),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Text(
                                widget.stats['status'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Share Options
                      const Text(
                        'Share via',
                        style: TextStyle(
                          color: kTextSecondaryColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Platform Grid
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildShareOption(
                            icon: Icons.share_rounded,
                            label: 'Share',
                            color: kPrimaryBlue,
                            onTap: () => _shareToPlatform('share'),
                          ),
                          _buildShareOption(
                            icon: Icons.message_rounded,
                            label: 'WhatsApp',
                            color: const Color(0xFF25D366),
                            onTap: () => _shareToPlatform('whatsapp'),
                          ),
                          _buildShareOption(
                            icon: Icons.send_rounded,
                            label: 'Telegram',
                            color: const Color(0xFF0088cc),
                            onTap: () => _shareToPlatform('telegram'),
                          ),
                          _buildShareOption(
                            icon: Icons.email_rounded,
                            label: 'Email',
                            color: const Color(0xFFEA4335),
                            onTap: () => _shareToPlatform('email'),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // More Options Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildShareOption(
                            icon: Icons.copy_rounded,
                            label: 'Copy',
                            color: kSoftPurple,
                            onTap: () {
                              // Copy to clipboard
                              Navigator.pop(context);
                              context.showWonderfulSnackBar(
                                message: '📋 Results copied to clipboard!',
                                type: SnackBarType.success,
                              );
                            },
                          ),
                          _buildShareOption(
                            icon: Icons.download_rounded,
                            label: 'Save',
                            color: kSoftOrange,
                            onTap: () {
                              Navigator.pop(context);
                              context.showWonderfulSnackBar(
                                message: '💾 Results saved successfully!',
                                type: SnackBarType.success,
                              );
                            },
                          ),
                          _buildShareOption(
                            icon: Icons.print_rounded,
                            label: 'Print',
                            color: kTextSecondaryColor,
                            onTap: () {
                              Navigator.pop(context);
                              context.showWonderfulSnackBar(
                                message: '🖨️ Print feature coming soon!',
                                type: SnackBarType.info,
                              );
                            },
                          ),
                          _buildShareOption(
                            icon: Icons.more_horiz_rounded,
                            label: 'More',
                            color: kTextSecondaryColor,
                            onTap: () => _shareToPlatform('more'),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Cancel Button
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () {
                            _controller.reverse().then((_) {
                              Navigator.pop(context);
                            });
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: Colors.grey.shade100,
                            foregroundColor: kTextSecondaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShareOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(color: color.withOpacity(0.2), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== REDESIGNED STUDENT RESULTS SCREEN ====================

class StudentResultsScreen extends StatefulWidget {
  const StudentResultsScreen({Key? key}) : super(key: key);

  @override
  State<StudentResultsScreen> createState() => _StudentResultsScreenState();
}

class _StudentResultsScreenState extends State<StudentResultsScreen>
    with SingleTickerProviderStateMixin {
  // FIXED: Added term-specific subject data
  final Map<String, List<Map<String, dynamic>>> _termSubjects = {
    "Term 1": [
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
    ],
    "Term 2": [
      {
        'name': 'Mathematics',
        'obtained': 82,
        'total': 100,
        'grade': 'A-',
        'status': 'Pass',
        'icon': Icons.calculate_rounded,
      },
      {
        'name': 'Physics',
        'obtained': 71,
        'total': 100,
        'grade': 'B+',
        'status': 'Pass',
        'icon': Icons.science_rounded,
      },
      {
        'name': 'Chemistry',
        'obtained': 65,
        'total': 100,
        'grade': 'B',
        'status': 'Pass',
        'icon': Icons.science_rounded,
      },
      {
        'name': 'English Literature',
        'obtained': 74,
        'total': 100,
        'grade': 'B+',
        'status': 'Pass',
        'icon': Icons.menu_book_rounded,
      },
    ],
    "Final": [
      {
        'name': 'Mathematics',
        'obtained': 91,
        'total': 100,
        'grade': 'A+',
        'status': 'Pass',
        'icon': Icons.calculate_rounded,
      },
      {
        'name': 'Physics',
        'obtained': 85,
        'total': 100,
        'grade': 'A',
        'status': 'Pass',
        'icon': Icons.science_rounded,
      },
      {
        'name': 'Chemistry',
        'obtained': 78,
        'total': 100,
        'grade': 'B+',
        'status': 'Pass',
        'icon': Icons.science_rounded,
      },
      {
        'name': 'English Literature',
        'obtained': 88,
        'total': 100,
        'grade': 'A',
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
    ],
  };

  final List<String> _terms = ["Term 1", "Term 2", "Final"];
  String _selectedTerm = "Term 1";
  final String _remarkText =
      "Great effort this term! Focus on History for improvement next semester. Keep up the excellent work in Mathematics and Science!";

  late Future<StudentResult<List<StudentExamModel>>> _examsFuture;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _examsFuture = StudentService().listExams();
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

  // FIXED: Get subjects for selected term
  List<Map<String, dynamic>> get _currentSubjects {
    return _termSubjects[_selectedTerm] ?? _termSubjects["Term 1"]!;
  }

  // FIXED: Calculate stats based on current term subjects
  Map<String, dynamic> get _overallStats {
    List<Map<String, dynamic>> currentSubjects = _currentSubjects;

    int totalSubjects = currentSubjects.length;
    int totalObtained = currentSubjects.fold<int>(
      0,
      (a, b) => a + (b['obtained'] as int),
    );
    int totalMarks = currentSubjects.fold<int>(
      0,
      (a, b) => a + (b['total'] as int),
    );

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

  void _showShareDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => WonderfulShareDialog(
        stats: _overallStats,
        subjects: _currentSubjects, // FIXED: Use current term subjects
        remarkText: _remarkText,
      ),
    );
  }

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
        body: FutureBuilder<StudentResult<List<StudentExamModel>>>(
          future: _examsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: kPrimaryBlue));
            }
            if (snapshot.data is StudentError) {
              final err = snapshot.data as StudentError;
              if (err.statusCode == 403) {
                return CustomScrollView(
                  slivers: [
                    _buildResultsAppBar(),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline_rounded, color: Colors.orange.shade800, size: 28),
                              const SizedBox(width: 12),
                              Expanded(child: Text(err.message, style: TextStyle(fontSize: 14, color: Colors.orange.shade900))),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }
              return CustomScrollView(
                slivers: [
                  _buildResultsAppBar(),
                  SliverFillRemaining(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.error_outline, size: 48, color: kErrorColor),
                            const SizedBox(height: 12),
                            Text((snapshot.data as StudentError).message, textAlign: TextAlign.center, style: const TextStyle(color: kTextPrimaryColor)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }
            final exams = snapshot.data is StudentSuccess<List<StudentExamModel>>
                ? (snapshot.data as StudentSuccess<List<StudentExamModel>>).data
                : <StudentExamModel>[];
            if (exams.isEmpty) {
              return CustomScrollView(
                slivers: [
                  _buildResultsAppBar(),
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.quiz_rounded, size: 56, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          Text('No exams yet', style: TextStyle(fontSize: 16, color: kTextSecondaryColor)),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }
            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildResultsAppBar(),
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final e = exams[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => StudentResultReportScreen(examId: e.id)),
                              ),
                              borderRadius: BorderRadius.circular(24),
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [BoxShadow(color: kPrimaryBlue.withOpacity(0.1), blurRadius: 14, offset: const Offset(0, 6))],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: kPrimaryBlue.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Icon(Icons.assignment_rounded, color: kPrimaryBlue, size: 28),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                        e.name,
                                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: kPrimaryBlue),
                                      ),
                                    ),
                                    const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: kTextSecondaryColor),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: exams.length,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildResultsAppBar() {
    return SliverToBoxAdapter(
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
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(Icons.arrow_back_rounded, color: Colors.white, size: 28),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "Academic Results",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        "Exam Results",
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
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(
                      Icons.stars_rounded,
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
    );
  }

  // REDESIGNED OVERALL STATS CARD
  Widget _buildOverallStatsCard(Map<String, dynamic> stats) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, kSoftGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
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
          // Header with circular progress
          Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 70,
                    height: 70,
                    child: CircularProgressIndicator(
                      value: stats['percent'] / 100,
                      strokeWidth: 6,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        stats['percent'] >= 75
                            ? kPrimaryGreen
                            : stats['percent'] >= 50
                            ? kWarningColor
                            : kErrorColor,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "${stats['percent'].toStringAsFixed(0)}%",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: kPrimaryBlue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Overall Performance",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: kTextPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: stats['status'] == 'Pass'
                                ? kPrimaryGreen.withOpacity(0.1)
                                : kWarningColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                stats['status'] == 'Pass'
                                    ? Icons.check_circle_rounded
                                    : Icons.warning_rounded,
                                color: stats['status'] == 'Pass'
                                    ? kPrimaryGreen
                                    : kWarningColor,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                stats['status'],
                                style: TextStyle(
                                  color: stats['status'] == 'Pass'
                                      ? kPrimaryGreen
                                      : kWarningColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Grade ${stats['grade']}",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: kPrimaryBlue,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Stats Row
          Row(
            children: [
              _buildEnhancedStatItem(
                icon: Icons.menu_book_rounded,
                label: "Subjects",
                value: "${stats['totalSubjects']}",
                color: kSoftPurple,
                bgColor: kSoftBlue,
              ),
              const SizedBox(width: 12),
              _buildEnhancedStatItem(
                icon: Icons.emoji_events_rounded,
                label: "Obtained",
                value: "${stats['totalObtained']}",
                color: kPrimaryGreen,
                bgColor: kSoftGreen,
              ),
              const SizedBox(width: 12),
              _buildEnhancedStatItem(
                icon: Icons.analytics_rounded,
                label: "Total",
                value: "${stats['totalMarks']}",
                color: kPrimaryBlue,
                bgColor: kSoftBlue,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Enhanced Stat Item
  Widget _buildEnhancedStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Color bgColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: kTextSecondaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // FIXED: REDESIGNED TERM SELECTOR with working functionality
  Widget _buildTermSelector() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
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
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [kPrimaryBlue, kPrimaryGreen],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
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
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // REDESIGNED SUBJECTS HEADER
  Widget _buildSubjectsHeader(int totalSubjects) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
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
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$_selectedTerm Subjects',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: kPrimaryBlue,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: kPrimaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$totalSubjects subjects',
              style: TextStyle(
                color: kPrimaryGreen,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // REDESIGNED PERFORMANCE INDICATOR
  Widget _buildPerformanceIndicator(double percent) {
    Color progressColor = percent >= 75
        ? kPrimaryGreen
        : percent >= 50
        ? kWarningColor
        : kErrorColor;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, kSoftBlue.withOpacity(0.3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: kPrimaryBlue.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: progressColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.trending_up_rounded,
                  color: progressColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                "Performance Trend",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: kTextPrimaryColor,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: percent / 100,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "0%",
                style: TextStyle(fontSize: 11, color: kTextSecondaryColor),
              ),
              Text(
                "50%",
                style: TextStyle(fontSize: 11, color: kTextSecondaryColor),
              ),
              Text(
                "100%",
                style: TextStyle(fontSize: 11, color: kTextSecondaryColor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // REDESIGNED REMARKS CARD
  Widget _buildRemarksCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, kSoftGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: kPrimaryBlue.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kPrimaryBlue, kPrimaryGreen],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.format_quote_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Teacher's Remark",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: kTextPrimaryColor,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: kBackgroundColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(
                    _remarkText,
                    style: TextStyle(
                      color: kTextSecondaryColor,
                      fontSize: 14,
                      height: 1.5,
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

// REDESIGNED SUBJECT RESULT CARD
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
      kPrimaryBlue,
      kPrimaryGreen,
      kSoftPurple,
      kSoftPink,
      kSoftOrange,
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final Color subjectColor = _getSubjectColor(index);
    final double percent = (subject['obtained'] / subject['total']) * 100;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: subjectColor.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: subjectColor.withOpacity(0.2), width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [subjectColor, subjectColor.withOpacity(0.7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        subject['icon'],
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subject['name'],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: kTextPrimaryColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: subjectColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
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
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: subject['status'] == 'Pass'
                                      ? kPrimaryGreen.withOpacity(0.1)
                                      : kWarningColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  subject['status'],
                                  style: TextStyle(
                                    color: subject['status'] == 'Pass'
                                        ? kPrimaryGreen
                                        : kWarningColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Score",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: kTextSecondaryColor,
                                ),
                              ),
                              Text(
                                "${subject['obtained']}/${subject['total']}",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: subjectColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: percent / 100,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              subjectColor,
                            ),
                            minHeight: 4,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
