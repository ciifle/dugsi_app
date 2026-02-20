import 'package:flutter/material.dart';

// Comment out these imports if the files don't exist yet
// import 'package:kobac/parent/pages/children_list_screen.dart';
// import 'package:kobac/parent/pages/parent_fees_screen.dart';
// import 'package:kobac/parent/pages/parent_notifications.dart';
// import 'package:kobac/parent/pages/parent_profile.dart';

// ==================== COLOR CONSTANTS (DEFINED HERE) ====================
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

class ParentDashboardScreen extends StatefulWidget {
  const ParentDashboardScreen({Key? key}) : super(key: key);

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final Map<String, String> parent = {
    'name': "Mr. & Mrs. Carter",
    'email': "carter.family@email.com",
    'initials': "FC",
  };

  final List<Map<String, dynamic>> children = [
    {
      'name': 'Ava Carter',
      'className': 'Grade 6 - A',
      'rollNo': '101',
      'attendance': 95,
      'progress': 'Excellent',
    },
    {
      'name': 'Liam Carter',
      'className': 'Grade 8 - B',
      'rollNo': '205',
      'attendance': 88,
      'progress': 'Good',
    },
  ];

  final int notificationCount = 3;

  // Helper method to get initials
  String _getInitials(String name) {
    if (name.isEmpty) return '';
    List<String> parts = name.trim().split(' ');
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts.last[0]).toUpperCase();
  }

  // Safe navigation method
  void _navigateTo(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: kBackgroundEnd,
      drawer: _ParentDrawer(parent: parent, onNavigate: _navigateTo),
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
                      Icons.family_restroom_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Family Dashboard",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [kPrimaryColor, kSecondaryColor, kSoftPurple],
                  ),
                ),
              ),
            ),
            leading: IconButton(
              icon: const Icon(
                Icons.menu_rounded,
                color: Colors.white,
                size: 22,
              ),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            actions: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    onPressed: () {
                      // Show placeholder if screen doesn't exist
                      _showComingSoon(context, 'Notifications');
                    },
                  ),
                  if (notificationCount > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: kSoftPink,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Center(
                          child: Text(
                            '$notificationCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),

          // Main Content
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Welcome Card
                _WelcomeCard(parent: parent),

                const SizedBox(height: 20),

                // Quick Stats
                _QuickStats(childrenCount: children.length),

                const SizedBox(height: 24),

                // Children Section Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: kSoftOrange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.family_restroom_rounded,
                            color: kSoftOrange,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "My Children",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: kTextPrimary,
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        _showComingSoon(context, 'Children List');
                      },
                      child: const Text("View All"),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Children Cards
                ...List.generate(
                  children.length,
                  (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ChildCard(
                      child: children[index],
                      getInitials: _getInitials,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Quick Actions
                _QuickActions(
                  context: context,
                  onPayFees: () => _showComingSoon(context, 'Pay Fees'),
                  onResults: () => _showComingSoon(context, 'Results'),
                  onAttendance: () => _showComingSoon(context, 'Attendance'),
                ),

                const SizedBox(height: 20),

                // Debug info - remove in production
                if (children.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    color: Colors.yellow.shade100,
                    child: const Text(
                      'No children data available',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// Helper function to show "Coming Soon" dialog
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

// Welcome Card
class _WelcomeCard extends StatelessWidget {
  final Map<String, String> parent;

  const _WelcomeCard({required this.parent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kPrimaryColor, kSecondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kSecondaryColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Text(
              parent['initials'] ?? 'FC',
              style: TextStyle(
                color: kPrimaryColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Welcome back! 👋",
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  parent['name'] ?? 'Family',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  parent['email'] ?? '',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Quick Stats
class _QuickStats extends StatelessWidget {
  final int childrenCount;

  const _QuickStats({required this.childrenCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Icons.family_restroom_rounded,
            label: "Children",
            value: "$childrenCount",
            color: kSoftPurple,
          ),
          _buildStatItem(
            icon: Icons.attach_money_rounded,
            label: "Due Fees",
            value: "\$2,450",
            color: kWarningColor,
          ),
          _buildStatItem(
            icon: Icons.event_available_rounded,
            label: "Attendance",
            value: "92%",
            color: kSuccessColor,
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
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
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
          Text(label, style: TextStyle(fontSize: 10, color: kTextSecondary)),
        ],
      ),
    );
  }
}

// Child Card
class _ChildCard extends StatelessWidget {
  final Map<String, dynamic> child;
  final String Function(String) getInitials;

  const _ChildCard({required this.child, required this.getInitials});

  @override
  Widget build(BuildContext context) {
    // Safe extraction with defaults
    final String childName = child['name'] ?? 'Unknown';
    final String className = child['className'] ?? 'Not Assigned';
    final int attendance = child['attendance'] ?? 0;
    final String progress = child['progress'] ?? 'Good';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _showComingSoon(context, 'Child Details - $childName');
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Child Avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [kSoftPurple, kSoftBlue],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: kSoftPurple.withOpacity(0.3),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      getInitials(childName),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Child Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        childName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: kTextPrimary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        className,
                        style: TextStyle(color: kTextSecondary, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.event_available_rounded,
                            size: 12,
                            color: kSuccessColor,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '$attendance%',
                            style: TextStyle(
                              fontSize: 11,
                              color: kSuccessColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: kSoftOrange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              progress,
                              style: TextStyle(
                                fontSize: 9,
                                color: kSoftOrange,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Arrow Icon
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: kSoftPurple,
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Quick Actions
class _QuickActions extends StatelessWidget {
  final BuildContext context;
  final VoidCallback onPayFees;
  final VoidCallback onResults;
  final VoidCallback onAttendance;

  const _QuickActions({
    required this.context,
    required this.onPayFees,
    required this.onResults,
    required this.onAttendance,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Quick Actions",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: kTextPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                icon: Icons.payment_rounded,
                label: "Pay Fees",
                color: kAccentColor,
                onTap: onPayFees,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ActionCard(
                icon: Icons.assignment_rounded,
                label: "Results",
                color: kSoftPurple,
                onTap: onResults,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ActionCard(
                icon: Icons.event_available_rounded,
                label: "Attendance",
                color: kSoftOrange,
                onTap: onAttendance,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
              child: Icon(icon, color: color, size: 20),
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

// Parent Drawer
class _ParentDrawer extends StatelessWidget {
  final Map<String, String> parent;
  final Function(Widget) onNavigate;

  const _ParentDrawer({required this.parent, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kPrimaryColor, kSecondaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.white,
                      child: Text(
                        parent['initials'] ?? 'FC',
                        style: TextStyle(
                          color: kPrimaryColor,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      parent['name'] ?? 'Family',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      parent['email'] ?? '',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _buildDrawerItem(
            icon: Icons.dashboard_rounded,
            label: 'Dashboard',
            color: kSoftPurple,
            onTap: () => Navigator.pop(context),
          ),
          _buildDrawerItem(
            icon: Icons.family_restroom_rounded,
            label: 'Children',
            color: kSoftBlue,
            onTap: () {
              Navigator.pop(context);
              _showComingSoon(context, 'Children List');
            },
          ),
          _buildDrawerItem(
            icon: Icons.account_balance_wallet_rounded,
            label: 'Fees',
            color: kAccentColor,
            onTap: () {
              Navigator.pop(context);
              _showComingSoon(context, 'Fees');
            },
          ),
          _buildDrawerItem(
            icon: Icons.notifications_rounded,
            label: 'Notifications',
            color: kSoftOrange,
            onTap: () {
              Navigator.pop(context);
              _showComingSoon(context, 'Notifications');
            },
          ),
          _buildDrawerItem(
            icon: Icons.person_rounded,
            label: 'Profile',
            color: kSoftPink,
            onTap: () {
              Navigator.pop(context);
              _showComingSoon(context, 'Profile');
            },
          ),
          const Divider(),
          _buildDrawerItem(
            icon: Icons.logout_rounded,
            label: 'Logout',
            color: Colors.red,
            onTap: () {
              _showComingSoon(context, 'Logout');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: kTextPrimary,
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
      ),
      onTap: onTap,
    );
  }
}
