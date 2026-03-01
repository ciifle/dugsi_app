import 'package:flutter/material.dart';
import 'package:kobac/parent/Widget/parent_drawer.dart';
import 'package:kobac/parent/pages/parent_attendance_screen.dart';
import 'package:kobac/parent/pages/parent_child_details_screen.dart';
import 'package:kobac/parent/pages/parent_children_list_screen.dart';
import 'package:kobac/parent/pages/parent_fee_payment_screen.dart';
import 'package:kobac/parent/pages/parent_notifications.dart';
import 'package:kobac/parent/pages/parent_profile_screen.dart';
import 'package:kobac/parent/pages/parent_result_screen.dart';
import 'package:provider/provider.dart';
import 'package:kobac/services/auth_provider.dart';

// ---------- COLOR PALETTE ----------
const Color kPrimaryBlue = Color(0xFF023471);
const Color kPrimaryGreen = Color(0xFF5AB04B);
const Color kSoftBlue = Color(0xFFE6F0FF);
const Color kSoftGreen = Color(0xFFEDF7EB);
const Color kDarkGreen = Color(0xFF3A7A30);
const Color kDarkBlue = Color(0xFF01255C);
const Color kTextPrimary = Color(0xFF2D3436);
const Color kTextSecondary = Color(0xFF636E72);
const Color kErrorColor = Color(0xFFEF4444);
const Color kSoftOrange = Color(0xFFF59E0B);
const Color kSuccessColor = Color(0xFF5AB04B);
const Color kCardColor = Colors.white;

// Additional color constants
const Color kSoftPurple = Color(0xFFA29BFE);
const Color kSecondaryColor = Color(0xFF6C5CE7);
const Color kAccentColor = Color(0xFF00B894);
const Color kSoftPink = Color(0xFFFF7675);
const Color kBackgroundEnd = Color(0xFFF5F0FF);
const Color kPrimaryColor = Color(0xFF2A2E45);

class ParentDashboardScreen extends StatefulWidget {
  const ParentDashboardScreen({Key? key}) : super(key: key);

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Map<String, String> _parentFromAuth(AuthProvider auth) {
    final user = auth.user;
    final prof = auth.parentProfile;
    final name = prof?.name ?? user?.name ?? '—';
    final email = prof?.email ?? user?.email ?? user?.emisNumber ?? '—';
    final initials = name.isEmpty ? 'P' : name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase();
    return {
      'name': name,
      'email': email,
      'initials': initials,
      'phone': prof?.phone ?? '—',
      'address': '—',
      'occupation': '—',
      'childrenCount': prof?.linkedStudents.isNotEmpty == true ? '${prof!.linkedStudents.length}' : '0',
    };
  }

  final List<Map<String, dynamic>> children = [
    {
      'id': '1',
      'name': 'Ava Carter',
      'className': 'Grade 6 - A',
      'rollNo': '101',
      'attendance': 95,
      'progress': 'Excellent',
      'fee': {
        'totalFee': 2500.00,
        'paidAmount': 1800.00,
        'dueAmount': 700.00,
        'dueDate': '2024-06-15',
        'status': 'partial',
        'feeType': 'Tuition Fee',
        'lateFee': 50.00,
      },
      'subjects': [
        {'name': 'Mathematics', 'marks': 92, 'grade': 'A', 'total': 100},
        {'name': 'Science', 'marks': 88, 'grade': 'A-', 'total': 100},
        {'name': 'English', 'marks': 95, 'grade': 'A+', 'total': 100},
        {'name': 'History', 'marks': 85, 'grade': 'B+', 'total': 100},
      ],
      'average': 90.0,
    },
    {
      'id': '2',
      'name': 'Liam Carter',
      'className': 'Grade 8 - B',
      'rollNo': '205',
      'attendance': 88,
      'progress': 'Good',
      'fee': {
        'totalFee': 2800.00,
        'paidAmount': 2800.00,
        'dueAmount': 0.00,
        'dueDate': '2024-06-10',
        'status': 'paid',
        'feeType': 'Tuition Fee',
        'lateFee': 0.00,
      },
      'subjects': [
        {'name': 'Mathematics', 'marks': 85, 'grade': 'B+', 'total': 100},
        {'name': 'Physics', 'marks': 82, 'grade': 'B', 'total': 100},
        {'name': 'Chemistry', 'marks': 88, 'grade': 'A-', 'total': 100},
        {'name': 'English', 'marks': 90, 'grade': 'A', 'total': 100},
      ],
      'average': 86.25,
    },
    {
      'id': '3',
      'name': 'Emma Carter',
      'className': 'Grade 4 - C',
      'rollNo': '302',
      'attendance': 92,
      'progress': 'Excellent',
      'fee': {
        'totalFee': 2200.00,
        'paidAmount': 1100.00,
        'dueAmount': 1100.00,
        'dueDate': '2024-06-20',
        'status': 'partial',
        'feeType': 'Tuition Fee + Activities',
        'lateFee': 25.00,
      },
      'subjects': [
        {'name': 'English', 'marks': 94, 'grade': 'A+', 'total': 100},
        {'name': 'Math', 'marks': 91, 'grade': 'A', 'total': 100},
        {'name': 'Science', 'marks': 89, 'grade': 'A-', 'total': 100},
        {'name': 'Art', 'marks': 96, 'grade': 'A+', 'total': 100},
      ],
      'average': 92.5,
    },
  ];

  final int notificationCount = 3;

  @override
  void initState() {
    super.initState();
  }

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
                Navigator.of(dialogContext).pop();

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
                  await context.read<AuthProvider>().logout();
                } catch (e) {
                  if (context.mounted) {
                    Navigator.of(context).pop();
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

  String _getInitials(String name) {
    if (name.isEmpty) return '';
    List<String> parts = name.trim().split(' ');
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts.last[0]).toUpperCase();
  }

  void _navigateTo(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  void _navigateToChildDetails(Map<String, dynamic> child) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ParentChildDetailsScreen(child: child),
      ),
    );
  }

  void _navigateToFeePayment() {
    if (children.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No children found'),
          backgroundColor: kErrorColor,
        ),
      );
      return;
    }

    if (children.length > 1) {
      _showChildSelectionDialog();
    } else {
      final child = children.first;
      final feeData = {
        'childName': child['name'],
        'className': child['className'],
        'totalFee': child['fee']['totalFee'],
        'paidAmount': child['fee']['paidAmount'],
        'dueAmount': child['fee']['dueAmount'],
        'dueDate': child['fee']['dueDate'],
        'status': child['fee']['status'],
        'feeType': child['fee']['feeType'],
        'lateFee': child['fee']['lateFee'],
      };

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ParentFeePaymentScreen(fee: feeData),
        ),
      );
    }
  }

  void _navigateToResults() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ParentResultsScreen()),
    );
  }

  void _navigateToAttendance() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ParentAttendanceScreen()),
    );
  }

  void _navigateToNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ParentNotificationsScreen(),
      ),
    );
  }

  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ParentProfileScreen(),
      ),
    );
  }

  void _showChildSelectionDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (BuildContext dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white, kSoftBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: kPrimaryBlue.withOpacity(0.2),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: kPrimaryGreen.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(-5, 5),
                ),
              ],
              border: Border.all(
                color: Colors.white.withOpacity(0.8),
                width: 2,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [kPrimaryBlue, kPrimaryGreen],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.family_restroom_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Select Child',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(dialogContext),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: kSoftBlue,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: kPrimaryBlue.withOpacity(0.2),
                          ),
                        ),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search child...',
                            hintStyle: TextStyle(color: kTextSecondary),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color: kPrimaryBlue,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: children.length,
                        itemBuilder: (context, index) {
                          final child = children[index];
                          final initials = _getInitials(child['name']);
                          final fee = child['fee'] as Map<String, dynamic>;
                          final dueAmount = fee['dueAmount'] as double;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                              border: Border.all(
                                color: dueAmount > 0
                                    ? kErrorColor.withOpacity(0.3)
                                    : kSuccessColor.withOpacity(0.3),
                                width: 1.5,
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  Navigator.pop(dialogContext);
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
                                borderRadius: BorderRadius.circular(20),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: dueAmount > 0
                                                ? [kErrorColor, kSoftOrange]
                                                : [
                                                    kSuccessColor,
                                                    kPrimaryGreen,
                                                  ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: dueAmount > 0
                                                  ? kErrorColor.withOpacity(0.3)
                                                  : kSuccessColor.withOpacity(
                                                      0.3,
                                                    ),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Text(
                                            initials,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    child['name'],
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                      color: kTextPrimary,
                                                    ),
                                                  ),
                                                ),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: dueAmount > 0
                                                        ? kErrorColor
                                                              .withOpacity(0.1)
                                                        : kSuccessColor
                                                              .withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          20,
                                                        ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        dueAmount > 0
                                                            ? Icons
                                                                  .warning_rounded
                                                            : Icons
                                                                  .check_circle_rounded,
                                                        color: dueAmount > 0
                                                            ? kErrorColor
                                                            : kSuccessColor,
                                                        size: 12,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        '\$${dueAmount.toStringAsFixed(0)}',
                                                        style: TextStyle(
                                                          color: dueAmount > 0
                                                              ? kErrorColor
                                                              : kSuccessColor,
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              child['className'],
                                              style: TextStyle(
                                                color: kTextSecondary,
                                                fontSize: 13,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.event_available_rounded,
                                                  size: 12,
                                                  color: dueAmount > 0
                                                      ? kErrorColor
                                                      : kSuccessColor,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Due: ${fee['dueDate']}',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: dueAmount > 0
                                                        ? kErrorColor
                                                        : kSuccessColor,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: dueAmount > 0
                                              ? kErrorColor.withOpacity(0.1)
                                              : kSuccessColor.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.arrow_forward_ios_rounded,
                                          color: dueAmount > 0
                                              ? kErrorColor
                                              : kSuccessColor,
                                          size: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: kErrorColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.warning_rounded,
                              color: kErrorColor,
                              size: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${children.where((c) => c['fee']['dueAmount'] > 0).length} unpaid',
                            style: const TextStyle(
                              fontSize: 12,
                              color: kTextSecondary,
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: TextButton.styleFrom(
                          foregroundColor: kPrimaryBlue,
                        ),
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final parent = _parentFromAuth(auth);
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: kSoftBlue,
      drawer: ParentDrawer(
        parent: parent,
        onNavigate: _navigateTo,
        onLogout: () => _logout(context),
        children: children,
        getInitials: _getInitials,
        onResultsTap: _navigateToResults,
        onAttendanceTap: _navigateToAttendance,
        onNotificationsTap: _navigateToNotifications,
        onProfileTap: _navigateToProfile,
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Fixed AppBar - No overflow issue
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: Colors.transparent,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [kPrimaryBlue, kSecondaryColor, kPrimaryGreen],
                  stops: const [0.2, 0.6, 1.0],
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
              child: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(bottom: 20),
                centerTitle: true,
                title: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Parent Portal Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
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
                              size: 10,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'PARENT PORTAL',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Parent Dashboard",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            leading: Container(
              margin: const EdgeInsets.only(left: 12, top: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1.2,
                ),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.menu_rounded,
                  color: Colors.white,
                  size: 24,
                ),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 12, top: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1.2,
                  ),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.notifications_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      onPressed: _navigateToNotifications,
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                    ),
                    if (notificationCount > 0)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: kErrorColor,
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
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 8),
                _WelcomeCard(parent: parent),
                const SizedBox(height: 16),
                _QuickStats(childrenCount: children.length),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [kPrimaryBlue, kPrimaryGreen],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.family_restroom_rounded,
                            color: Colors.white,
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
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ParentChildrenListScreen(),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: kPrimaryGreen,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        "View All",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...List.generate(
                  children.length,
                  (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ChildCard(
                      child: children[index],
                      getInitials: _getInitials,
                      onTap: () => _navigateToChildDetails(children[index]),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _QuickActions(
                  context: context,
                  onPayFees: _navigateToFeePayment,
                  onResults: _navigateToResults,
                  onAttendance: _navigateToAttendance,
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

// Welcome Card Widget
class _WelcomeCard extends StatelessWidget {
  final Map<String, String> parent;

  const _WelcomeCard({required this.parent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kPrimaryBlue, kPrimaryGreen],
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
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 35,
              backgroundColor: Colors.white,
              child: Text(
                parent['initials'] ?? 'FC',
                style: TextStyle(
                  color: kPrimaryBlue,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
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
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  parent['name'] ?? 'Family',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    parent['email'] ?? '',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
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

// Quick Stats Widget
class _QuickStats extends StatelessWidget {
  final int childrenCount;

  const _QuickStats({required this.childrenCount});

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
      child: Row(
        children: [
          _buildStatItem(
            icon: Icons.family_restroom_rounded,
            label: "Children",
            value: "$childrenCount",
            color: kPrimaryBlue,
          ),
          Container(height: 30, width: 1, color: Colors.grey.shade300),
          _buildStatItem(
            icon: Icons.attach_money_rounded,
            label: "Due Fees",
            value: "\$2,450",
            color: kSoftOrange,
          ),
          Container(height: 30, width: 1, color: Colors.grey.shade300),
          _buildStatItem(
            icon: Icons.event_available_rounded,
            label: "Attendance",
            value: "92%",
            color: kPrimaryGreen,
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
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(label, style: TextStyle(fontSize: 11, color: kTextSecondary)),
        ],
      ),
    );
  }
}

// Child Card Widget
class _ChildCard extends StatelessWidget {
  final Map<String, dynamic> child;
  final String Function(String) getInitials;
  final VoidCallback onTap;

  const _ChildCard({
    required this.child,
    required this.getInitials,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final String childName = child['name'] ?? 'Unknown';
    final String className = child['className'] ?? 'Not Assigned';
    final int attendance = child['attendance'] ?? 0;
    final String progress = child['progress'] ?? 'Good';

    // Safe conversion to double
    final dynamic averageValue = child['average'];
    final double average = averageValue is int
        ? averageValue.toDouble()
        : (averageValue as double?) ?? 0.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
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
          border: Border.all(color: Colors.grey.shade100, width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kPrimaryBlue, kPrimaryGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
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

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      childName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      className,
                      style: TextStyle(fontSize: 11, color: kTextSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      children: [
                        // Attendance
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: kSoftBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.event_available_rounded,
                                size: 10,
                                color: kPrimaryBlue,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '$attendance%',
                                style: const TextStyle(fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                        // Average
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: kSuccessColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.analytics_rounded,
                                size: 10,
                                color: kSuccessColor,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${average.toStringAsFixed(1)}%',
                                style: const TextStyle(fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Progress Badge and Arrow
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: progress == "Excellent"
                          ? kPrimaryGreen.withOpacity(0.1)
                          : kSoftOrange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      progress,
                      style: TextStyle(
                        fontSize: 9,
                        color: progress == "Excellent"
                            ? kPrimaryGreen
                            : kSoftOrange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: kPrimaryBlue,
                    size: 12,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Quick Actions Widget
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
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.bolt_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              "Quick Actions",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: kTextPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                icon: Icons.payment_rounded,
                label: "Pay Fees",
                color: kPrimaryBlue,
                onTap: onPayFees,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionCard(
                icon: Icons.assignment_rounded,
                label: "Results",
                color: kPrimaryGreen,
                onTap: onResults,
              ),
            ),
            const SizedBox(width: 10),
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

// Action Card Widget
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
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey.shade100, width: 1.5),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
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
