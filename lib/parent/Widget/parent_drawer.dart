import 'package:flutter/material.dart';
import 'package:kobac/parent/pages/parent_children_list_screen.dart';
import 'package:kobac/parent/pages/parent_fee_payment_screen.dart';

// ---------- COMPLETE COLOR PALETTE ----------
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

// Additional color constants for consistent theming
const Color kSoftPurple = Color(0xFFA29BFE);
const Color kSecondaryColor = Color(0xFF6C5CE7);
const Color kAccentColor = Color(0xFF00B894);
const Color kSoftPink = Color(0xFFFF7675);
const Color kBackgroundEnd = Color(0xFFF5F0FF);
const Color kPrimaryColor = Color(0xFF2A2E45);

class ParentDrawer extends StatelessWidget {
  final Map<String, String> parent;
  final Function(Widget) onNavigate;
  final VoidCallback onLogout;
  final List<Map<String, dynamic>> children;
  final String Function(String) getInitials;
  final VoidCallback onResultsTap;
  final VoidCallback onAttendanceTap;
  final VoidCallback onNotificationsTap;
  final VoidCallback onProfileTap; // Add this

  const ParentDrawer({
    Key? key,
    required this.parent,
    required this.onNavigate,
    required this.onLogout,
    required this.children,
    required this.getInitials,
    required this.onResultsTap,
    required this.onAttendanceTap,
    required this.onNotificationsTap,
    required this.onProfileTap, // Add this
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      width: MediaQuery.of(context).size.width * 0.78,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(40),
            bottomRight: Radius.circular(40),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(3, 0),
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          children: [
            _buildDrawerHeader(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    _buildDrawerItem(
                      icon: Icons.dashboard_rounded,
                      label: 'Dashboard',
                      color: kPrimaryBlue,
                      badge: null,
                      onTap: () => Navigator.pop(context),
                    ),
                    _buildDrawerItem(
                      icon: Icons.family_restroom_rounded,
                      label: 'Children',
                      color: kPrimaryGreen,
                      badge: children.length.toString(),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ParentChildrenListScreen(),
                          ),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.account_balance_wallet_rounded,
                      label: 'Fees',
                      color: kSoftOrange,
                      badge: _getUnpaidFeesCount(),
                      onTap: () {
                        Navigator.pop(context);
                        if (children.isNotEmpty) {
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
                              builder: (context) =>
                                  ParentFeePaymentScreen(fee: feeData),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('No children found'),
                              backgroundColor: kErrorColor,
                            ),
                          );
                        }
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.assignment_rounded,
                      label: 'Results',
                      color: kSoftPurple,
                      badge: null,
                      onTap: () {
                        Navigator.pop(context);
                        onResultsTap();
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.event_available_rounded,
                      label: 'Attendance',
                      color: kSuccessColor,
                      badge: null,
                      onTap: () {
                        Navigator.pop(context);
                        onAttendanceTap();
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.notifications_rounded,
                      label: 'Notifications',
                      color: kDarkBlue,
                      badge: '3',
                      onTap: () {
                        Navigator.pop(context);
                        onNotificationsTap();
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.person_rounded,
                      label: 'Profile',
                      color: kPrimaryBlue,
                      badge: null,
                      onTap: () {
                        Navigator.pop(context);
                        onProfileTap(); // Use the callback
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildLogoutButton(context),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  String? _getUnpaidFeesCount() {
    int unpaidCount = 0;
    for (var child in children) {
      if (child['fee'] != null && child['fee']['dueAmount'] > 0) {
        unpaidCount++;
      }
    }
    return unpaidCount > 0 ? unpaidCount.toString() : null;
  }

  Widget _buildDrawerHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kPrimaryBlue, kPrimaryBlue, kPrimaryGreen],
          stops: [0.2, 0.6, 1.0],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(35),
          bottomRight: Radius.circular(35),
        ),
        boxShadow: [
          BoxShadow(
            color: kPrimaryBlue.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
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
                      radius: 38,
                      backgroundColor: Colors.white,
                      child: Text(
                        parent['initials'] ?? 'FC',
                        style: const TextStyle(
                          color: kPrimaryBlue,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  if (children.isNotEmpty)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: kPrimaryGreen,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Text(
                          '${children.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.family_restroom_rounded,
                            color: Colors.white,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Parent • ${children.length} ${children.length == 1 ? 'child' : 'children'}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        parent['email'] ?? '',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String label,
    required Color color,
    String? badge,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: kTextPrimary,
                    ),
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: kTextSecondary.withOpacity(0.4),
                  size: 12,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onLogout,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                colors: [
                  kErrorColor.withOpacity(0.05),
                  kErrorColor.withOpacity(0.02),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: kErrorColor.withOpacity(0.2), width: 1),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [kErrorColor, kErrorColor.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: kErrorColor.withOpacity(0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'Logout',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: kErrorColor,
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

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.shade200, width: 0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [kPrimaryBlue, kPrimaryGreen],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.family_restroom_rounded,
              color: Colors.white,
              size: 10,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Kobac Parent v1.0.0',
            style: TextStyle(
              color: kTextSecondary.withOpacity(0.7),
              fontSize: 10,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
