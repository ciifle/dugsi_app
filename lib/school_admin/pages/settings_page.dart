import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:kobac/services/auth_provider.dart';

const Color kDarkBlue = Color(0xFF023471);
const Color kOrange = Color(0xFF5AB04B);
const Color kBgLight = Color(0xFFF7F8FA);

class SettingsPage extends StatelessWidget {
  SettingsPage({Key? key}) : super(key: key);

  // Dummy Profile Data
  final String adminName = "Nourhan El-Masry";
  final String adminAvatar =
      "https://i.pravatar.cc/150?img=47"; // Placeholder image

  // Dummy Settings Data
  final String schoolName = "International School of Cairo";
  final String academicYear = "2023-2024";
  final String termSettings = "Term 2";

  final String language = "English";
  final String appVersion = "v2.1.4";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgLight,
      appBar: AppBar(
        backgroundColor: kDarkBlue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Colors.white,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 1.2,
        centerTitle: true,
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 22,
            letterSpacing: 0.2,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          children: [
            // --- Profile Section ---
            _ProfileSection(
              name: adminName,
              avatarUrl: adminAvatar,
            ),
            const SizedBox(height: 28),

            // --- SCHOOL SETTINGS ---
            _SectionTitle(title: "School Settings"),
            SettingTile(
              icon: Icons.school_outlined,
              iconColor: kOrange,
              title: "School name",
              subtitle: schoolName,
              onTap: () {
                // Dummy, no edit in this sample
              },
            ),
            SettingTile(
              icon: Icons.calendar_month_outlined,
              iconColor: kOrange,
              title: "Academic year",
              subtitle: academicYear,
              onTap: () {},
            ),
            SettingTile(
              icon: Icons.timelapse_outlined,
              iconColor: kOrange,
              title: "Term settings",
              subtitle: termSettings,
              onTap: () {},
            ),
            const SizedBox(height: 26),

            // --- ACCOUNT SETTINGS ---
            _SectionTitle(title: "Account Settings"),
            SettingTile(
              icon: Icons.lock_outline,
              iconColor: kOrange,
              title: "Change password",
              onTap: () {},
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            ),
            SettingTile(
              icon: Icons.notifications_active_outlined,
              iconColor: kOrange,
              title: "Notification preferences",
              onTap: () {},
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            ),
            SettingTile(
              icon: Icons.translate_outlined,
              iconColor: kOrange,
              title: "Language",
              subtitle: language,
              onTap: () {},
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            ),
            const SizedBox(height: 26),

            // --- SYSTEM SETTINGS ---
            _SectionTitle(title: "System Settings"),
            _DarkModeSettingTile(),
            SettingTile(
              icon: Icons.cloud_upload_outlined,
              iconColor: kOrange,
              title: "Data backup",
              onTap: () {},
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            ),
            SettingTile(
              icon: Icons.info_outline,
              iconColor: kOrange,
              title: "App version",
              subtitle: appVersion,
              enabled: false,
            ),
            const SizedBox(height: 32),

            // --- Logout Section ---
            Divider(
              thickness: 1.3,
              color: kOrange.withOpacity(0.19),
              height: 38,
            ),
            _LogoutButton(),
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }
}

/// Profile Section Widget (Admin avatar, name, role, edit icon)
class _ProfileSection extends StatelessWidget {
  final String name;
  final String avatarUrl;
  const _ProfileSection({
    required this.name,
    required this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white, // Section bg (not card, just flat)
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 14),
      child: Row(
        children: [
          CircleAvatar(
            radius: 33,
            backgroundColor: kOrange.withOpacity(0.16),
            backgroundImage: NetworkImage(avatarUrl),
          ),
          const SizedBox(width: 22),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: kDarkBlue,
                    fontWeight: FontWeight.w700,
                    fontSize: 19,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  "School Administrator",
                  style: TextStyle(
                    color: kDarkBlue.withOpacity(0.65),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.02,
                  ),
                ),
              ],
            ),
          ),
          // Edit Profile Icon
          InkWell(
            borderRadius: BorderRadius.circular(100),
            onTap: () {},
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: Icon(Icons.edit, color: kOrange, size: 24),
            ),
          ),
        ],
      ),
    );
  }
}

/// Section Title Heading
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 5, top: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: kDarkBlue,
          fontWeight: FontWeight.w600,
          fontSize: 15.7,
          letterSpacing: 0.02,
        ),
      ),
    );
  }
}

/// Generic Setting Tile
class SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool enabled;
  final Color? iconColor;
  final VoidCallback? onTap;

  const SettingTile({
    Key? key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.iconColor,
    this.onTap,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textColor = enabled ? kDarkBlue : kDarkBlue.withOpacity(0.39);
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 9),
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? kOrange, size: 23),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2.7),
                      child: Text(
                        subtitle!,
                        style: TextStyle(
                          color: kDarkBlue.withOpacity(enabled ? 0.46 : 0.26),
                          fontSize: 12.6,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.01,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ]
          ],
        ),
      ),
    );
  }
}

/// Standalone dark mode toggle (UI only, no logic)
class _DarkModeSettingTile extends StatefulWidget {
  @override
  State<_DarkModeSettingTile> createState() => _DarkModeSettingTileState();
}

class _DarkModeSettingTileState extends State<_DarkModeSettingTile> {
  bool _darkMode = false;

  @override
  Widget build(BuildContext context) {
    return SettingTile(
      icon: Icons.dark_mode_outlined,
      iconColor: kOrange,
      title: "Dark mode",
      subtitle: "Change app appearance",
      trailing: Switch(
        value: _darkMode,
        onChanged: (v) {
          setState(() => _darkMode = v);
          // UI-only; no actual theme logic
        },
        activeColor: kOrange,
        inactiveThumbColor: Colors.grey[300],
        inactiveTrackColor: Colors.grey[200],
      ),
      onTap: () {}, // UI only
    );
  }
}

/// Logout button area
class _LogoutButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 180,
        height: 45,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            backgroundColor: kOrange,
            side: BorderSide(color: kOrange, width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(9),
            ),
            elevation: 0,
            textStyle: const TextStyle(
              fontSize: 16.3,
              fontWeight: FontWeight.bold,
            ),
          ),
          onPressed: () async {
            await context.read<AuthProvider>().logout();
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.logout, color: Colors.white, size: 22),
              SizedBox(width: 8),
              Text(
                'Logout',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
