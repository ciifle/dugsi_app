import 'package:flutter/material.dart';
import 'package:kobac/parent/pages/parent_child_details_screen.dart';

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
const Color kPrimaryColor = Color(0xFF2A2E45);

class ParentChildrenListScreen extends StatelessWidget {
  ParentChildrenListScreen({Key? key}) : super(key: key);

  final List<Map<String, dynamic>> children = [
    {
      'id': '1',
      'name': 'Ava Carter',
      'className': 'Grade 6 - A',
      'rollNo': '101',
      'attendance': 95,
      'progress': 'Excellent',
      'subjects': [
        {'name': 'Mathematics', 'marks': 92, 'grade': 'A', 'total': 100},
        {'name': 'Science', 'marks': 88, 'grade': 'A-', 'total': 100},
        {'name': 'English', 'marks': 95, 'grade': 'A+', 'total': 100},
        {'name': 'History', 'marks': 85, 'grade': 'B+', 'total': 100},
      ],
      'fee': {
        'totalFee': 2500.00,
        'paidAmount': 1800.00,
        'dueAmount': 700.00,
        'dueDate': '2024-06-15',
        'status': 'partial',
      },
      'average': 90.0,
    },
    {
      'id': '2',
      'name': 'Liam Carter',
      'className': 'Grade 8 - B',
      'rollNo': '205',
      'attendance': 88,
      'progress': 'Good',
      'subjects': [
        {'name': 'Mathematics', 'marks': 85, 'grade': 'B+', 'total': 100},
        {'name': 'Physics', 'marks': 82, 'grade': 'B', 'total': 100},
        {'name': 'Chemistry', 'marks': 88, 'grade': 'A-', 'total': 100},
        {'name': 'English', 'marks': 90, 'grade': 'A', 'total': 100},
      ],
      'fee': {
        'totalFee': 2800.00,
        'paidAmount': 2800.00,
        'dueAmount': 0.00,
        'dueDate': '2024-06-10',
        'status': 'paid',
      },
      'average': 86.25,
    },
    {
      'id': '3',
      'name': 'Emma Carter',
      'className': 'Grade 4 - C',
      'rollNo': '302',
      'attendance': 92,
      'progress': 'Excellent',
      'subjects': [
        {'name': 'English', 'marks': 94, 'grade': 'A+', 'total': 100},
        {'name': 'Math', 'marks': 91, 'grade': 'A', 'total': 100},
        {'name': 'Science', 'marks': 89, 'grade': 'A-', 'total': 100},
        {'name': 'Art', 'marks': 96, 'grade': 'A+', 'total': 100},
      ],
      'fee': {
        'totalFee': 2200.00,
        'paidAmount': 1100.00,
        'dueAmount': 1100.00,
        'dueDate': '2024-06-20',
        'status': 'partial',
      },
      'average': 92.5,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundEnd,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [kPrimaryBlue, kSecondaryColor, kPrimaryGreen],
              stops: const [0.2, 0.5, 0.9],
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
            boxShadow: [
              BoxShadow(
                color: kPrimaryBlue.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
        ),
        leading: Container(
          margin: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
              size: 24,
            ),
            onPressed: () => Navigator.pop(context),
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
          ),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.family_restroom_rounded,
                      color: kPrimaryBlue,
                      size: 12,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${children.length} ${children.length == 1 ? 'CHILD' : 'CHILDREN'}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'My Children',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        centerTitle: true,
        toolbarHeight: 80,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.search_rounded,
                color: Colors.white,
                size: 22,
              ),
              onPressed: () {
                _showSearchDialog(context);
              },
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.white.withOpacity(0.2), height: 1),
        ),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Stats Header
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kPrimaryBlue, kSecondaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: kPrimaryBlue.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    icon: Icons.family_restroom_rounded,
                    label: 'Total',
                    value: '${children.length}',
                    color: Colors.white,
                  ),
                  _buildStatItem(
                    icon: Icons.warning_rounded,
                    label: 'Due Fees',
                    value: children
                        .where((c) => (c['fee']['dueAmount'] as double) > 0)
                        .length
                        .toString(),
                    color: kSoftOrange,
                  ),
                  _buildStatItem(
                    icon: Icons.check_circle_rounded,
                    label: 'Paid',
                    value: children
                        .where((c) => (c['fee']['dueAmount'] as double) == 0)
                        .length
                        .toString(),
                    color: kAccentColor,
                  ),
                ],
              ),
            ),
          ),

          // Children List - Redesigned Cards
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final child = children[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _RedesignedChildCard(child: child, index: index),
                );
              }, childCount: children.length),
            ),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Search Children',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: kTextPrimary,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Enter child name...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: kPrimaryBlue, width: 2),
                  ),
                ),
                onSubmitted: (value) {
                  // Implement search logic here
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      // Implement search logic here
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Search'),
                  ),
                ],
              ),
            ],
          ),
        ),
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
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: color.withOpacity(0.9), fontSize: 12),
        ),
      ],
    );
  }
}

// Redesigned Child Card with modern look
class _RedesignedChildCard extends StatelessWidget {
  final Map<String, dynamic> child;
  final int index;

  const _RedesignedChildCard({
    Key? key,
    required this.child,
    required this.index,
  }) : super(key: key);

  String _getInitials(String name) {
    if (name.isEmpty) return '';
    List<String> parts = name.trim().split(' ');
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts.last[0]).toUpperCase();
  }

  Color _getAvatarColor() {
    final colors = [
      kSoftPurple,
      kSoftOrange,
      kAccentColor,
      kSoftBlue,
      kSoftPink,
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final String childName = child['name'] ?? 'Unknown';
    final String className = child['className'] ?? 'Not Assigned';
    final String rollNo = child['rollNo'] ?? 'N/A';
    final int attendance = child['attendance'] ?? 0;
    final String progress = child['progress'] ?? 'Good';

    // Safe conversion to double
    final dynamic dueAmountValue = child['fee']['dueAmount'];
    final double dueAmount = dueAmountValue is int
        ? dueAmountValue.toDouble()
        : (dueAmountValue as double?) ?? 0.0;

    final dynamic averageValue = child['average'];
    final double average = averageValue is int
        ? averageValue.toDouble()
        : (averageValue as double?) ?? 0.0;

    final avatarColor = _getAvatarColor();

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ParentChildDetailsScreen(child: child),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top section with avatar and name
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Avatar with gradient border
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [avatarColor, avatarColor.withOpacity(0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: avatarColor.withOpacity(0.3),
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
                          fontSize: 24,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Name and class
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          childName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: kTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: kSoftBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                className,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: kPrimaryBlue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: kSoftPurple.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Roll: $rollNo',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: kSoftPurple,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Due amount badge if any
                  if (dueAmount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: kErrorColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: kErrorColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.warning_rounded,
                            color: kErrorColor,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '\$${dueAmount.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: kErrorColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Divider
            Divider(
              height: 1,
              thickness: 1,
              color: Colors.grey.shade200,
              indent: 16,
              endIndent: 16,
            ),

            // Bottom section with stats
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Attendance
                  _buildStatChip(
                    icon: Icons.event_available_rounded,
                    value: '$attendance%',
                    label: 'Attendance',
                    color: kPrimaryBlue,
                    iconColor: kSuccessColor,
                  ),

                  // Vertical divider
                  Container(height: 30, width: 1, color: Colors.grey.shade300),

                  // Average
                  _buildStatChip(
                    icon: Icons.analytics_rounded,
                    value: '${average.toStringAsFixed(1)}%',
                    label: 'Average',
                    color: kSuccessColor,
                    iconColor: kSuccessColor,
                  ),

                  // Vertical divider
                  Container(height: 30, width: 1, color: Colors.grey.shade300),

                  // Progress
                  _buildStatChip(
                    icon: Icons.stars_rounded,
                    value: progress,
                    label: 'Progress',
                    color: progress == "Excellent"
                        ? kSuccessColor
                        : kSoftOrange,
                    iconColor: progress == "Excellent"
                        ? kSuccessColor
                        : kSoftOrange,
                  ),
                ],
              ),
            ),

            // View Details Button
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    kSoftPurple.withOpacity(0.05),
                    kSoftBlue.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ParentChildDetailsScreen(child: child),
                      ),
                    );
                  },
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'View Details',
                          style: TextStyle(
                            color: kSoftPurple,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: kSoftPurple,
                          size: 12,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required Color iconColor,
  }) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, color: kTextSecondary)),
        ],
      ),
    );
  }
}
