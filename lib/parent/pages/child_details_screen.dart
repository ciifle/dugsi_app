import 'package:flutter/material.dart';

// ---------- COLOR CONSTANTS (Must be defined) ----------
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
const Color kTextSecondary = Color(0xFF636E72); // Medium gray
const Color kSuccessColor = Color(0xFF059669); // Dark green
const Color kWarningColor = Color(0xFFF59E0B); // Amber
const Color kErrorColor = Color(0xFFEF4444); // Red

class ChildDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> child;

  const ChildDetailsScreen({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Safe extraction of data with default values
    final String childName = child['name'] ?? 'Unknown';
    final String className = child['className'] ?? 'Not Assigned';
    final int attendance = child['attendance'] ?? 0;
    final String progress = child['progress'] ?? 'Good';
    final List<dynamic> subjects = child['subjects'] ?? [];

    return Scaffold(
      backgroundColor: kBackgroundEnd,
      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        title: Text(childName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Profile Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [kSoftPurple, kSoftBlue],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: kSoftPurple.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _getInitials(childName),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 32,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        childName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: kTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        className,
                        style: TextStyle(color: kTextSecondary, fontSize: 15),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Quick Stats
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildQuickStat(
                        icon: Icons.event_available_rounded,
                        label: 'Attendance',
                        value: '$attendance%',
                        color: kSuccessColor,
                      ),
                      _buildQuickStat(
                        icon: Icons.stars_rounded,
                        label: 'Progress',
                        value: progress,
                        color: kSoftOrange,
                      ),
                      _buildQuickStat(
                        icon: Icons.assignment_rounded,
                        label: 'Subjects',
                        value: '${subjects.length}',
                        color: kSoftPurple,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Subjects Section
                if (subjects.isNotEmpty) ...[
                  const Text(
                    'Subjects',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: kTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(
                    subjects.length,
                    (index) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: index % 3 == 0
                                  ? kSoftPurple.withOpacity(0.1)
                                  : index % 3 == 1
                                  ? kSoftBlue.withOpacity(0.1)
                                  : kSoftOrange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _getSubjectIcon(subjects[index].toString()),
                              color: index % 3 == 0
                                  ? kSoftPurple
                                  : index % 3 == 1
                                  ? kSoftBlue
                                  : kSoftOrange,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              subjects[index].toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                color: kTextPrimary,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: kSuccessColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'A',
                              style: TextStyle(
                                color: kSuccessColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        'No subjects available',
                        style: TextStyle(color: kTextSecondary, fontSize: 14),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Quick Actions for Parent
                const Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: kTextPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _buildActionCard(
                        icon: Icons.payment_rounded,
                        label: 'Pay Fees',
                        color: kAccentColor,
                        onTap: () {
                          // Navigate to fees screen
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildActionCard(
                        icon: Icons.assignment_rounded,
                        label: 'Results',
                        color: kSoftPurple,
                        onTap: () {
                          // Navigate to results screen
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildActionCard(
                        icon: Icons.event_available_rounded,
                        label: 'Attendance',
                        color: kSoftOrange,
                        onTap: () {
                          // Navigate to attendance screen
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '';
    List<String> parts = name.trim().split(' ');
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts.last[0]).toUpperCase();
  }

  IconData _getSubjectIcon(String subject) {
    final subj = subject.toLowerCase();
    if (subj.contains('math')) {
      return Icons.calculate_rounded;
    } else if (subj.contains('science')) {
      return Icons.science_rounded;
    } else if (subj.contains('english')) {
      return Icons.menu_book_rounded;
    } else if (subj.contains('history')) {
      return Icons.history_edu_rounded;
    } else if (subj.contains('physics')) {
      return Icons.bolt_rounded;
    } else if (subj.contains('chemistry')) {
      return Icons.science_rounded;
    } else if (subj.contains('art')) {
      return Icons.palette_rounded;
    } else {
      return Icons.subject_rounded;
    }
  }

  Widget _buildQuickStat({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
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
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(color: kTextSecondary, fontSize: 11)),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: kTextPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
