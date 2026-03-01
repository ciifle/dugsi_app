import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kobac/services/auth_provider.dart';
import 'package:kobac/services/student_service.dart';
import 'package:kobac/shared/pages/login_screen.dart';

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

// ---------- NOTICE MODEL ----------
class _NoticeData {
  final String title;
  final String description;
  final String time;
  final String date;

  const _NoticeData({
    required this.title,
    required this.description,
    required this.time,
    required this.date,
  });
}

// ---------------- ALL NOTICES SCREEN (API-driven) ----------------
class AllNoticesScreen extends StatefulWidget {
  const AllNoticesScreen({Key? key}) : super(key: key);

  @override
  State<AllNoticesScreen> createState() => _AllNoticesScreenState();
}

class _AllNoticesScreenState extends State<AllNoticesScreen> {
  late Future<StudentResult<List<StudentNoticeModel>>> _noticesFuture;

  @override
  void initState() {
    super.initState();
    _noticesFuture = StudentService().listNotices();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSoftBlue,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [kSoftBlue, kSoftGreen],
            stops: [0.0, 1.0],
          ),
        ),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ---------------- HEADER ----------------
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 50, 24, 30),
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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      "Stay Updated",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      "All Notices",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildNoticeStats(),
                  ],
                ),
              ),
            ),

            // ---------------- NOTICES LIST (API) - Full width ----------------
            SliverToBoxAdapter(
              child: FutureBuilder<StudentResult<List<StudentNoticeModel>>>(
                future: _noticesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return SizedBox(
                      width: double.infinity,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 48),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            CircularProgressIndicator(color: kPrimaryBlue),
                            SizedBox(height: 16),
                            Text('Loading notices…', style: TextStyle(color: kTextSecondary)),
                          ],
                        ),
                      ),
                    );
                  }
                  if (snapshot.data is StudentError) {
                    return SizedBox(
                      width: double.infinity,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: kPrimaryBlue.withOpacity(0.08),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.error_outline_rounded, size: 48, color: kErrorColor.withOpacity(0.8)),
                              const SizedBox(height: 12),
                              Text(
                                (snapshot.data as StudentError).message,
                                style: const TextStyle(color: kTextPrimary, fontSize: 15),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                  final list = snapshot.data is StudentSuccess<List<StudentNoticeModel>>
                      ? (snapshot.data as StudentSuccess<List<StudentNoticeModel>>).data
                      : <StudentNoticeModel>[];
                  if (list.isEmpty) {
                    return SizedBox(
                      width: double.infinity,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: kPrimaryBlue.withOpacity(0.06),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.campaign_rounded, size: 56, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'No notices yet',
                                style: TextStyle(fontSize: 16, color: kTextSecondary),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: list
                          .map((n) => Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: _buildApiNoticeCard(context, n),
                              ))
                          .toList(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApiNoticeCard(BuildContext context, StudentNoticeModel notice) {
    final content = notice.content ?? '';
    final preview = content.length > 120 ? '${content.substring(0, 120).trim()}…' : content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _showNoticeDetailApi(context, notice),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: kPrimaryBlue.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(
                color: kPrimaryBlue.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left accent bar
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [kPrimaryBlue, kPrimaryGreen],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              notice.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: kTextPrimary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (notice.createdAt != null && notice.createdAt!.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: kSoftBlue,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                notice.createdAt!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: kDarkBlue,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (preview.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          preview,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: kTextSecondary,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  color: kTextSecondary.withOpacity(0.6),
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showNoticeDetailApi(BuildContext context, StudentNoticeModel notice) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(notice.title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (notice.createdAt != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(notice.createdAt!, style: TextStyle(fontSize: 12, color: kTextSecondary)),
                ),
              Text(notice.content ?? ''),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // ---------------- HELPER METHOD TO NAVIGATE TO DASHBOARD ----------------
  void _navigateToDashboard(BuildContext context) {
    final user = context.read<AuthProvider>().user;
    final dashboard = roleToHome(user);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => dashboard),
    );
  }

  // ---------------- NOTICE STATS (full width in header) ----------------
  Widget _buildNoticeStats() {
    return FutureBuilder<StudentResult<List<StudentNoticeModel>>>(
      future: _noticesFuture,
      builder: (context, snapshot) {
        final count = snapshot.data is StudentSuccess<List<StudentNoticeModel>>
            ? (snapshot.data as StudentSuccess<List<StudentNoticeModel>>).data.length
            : 0;
        return SizedBox(
          width: double.infinity,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.25)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatChip(
                  Icons.notifications_rounded,
                  "Total",
                  "$count",
                ),
                Container(height: 24, width: 1, color: Colors.white38),
                _buildStatChip(Icons.new_releases_rounded, "New", "$count"),
                Container(height: 24, width: 1, color: Colors.white38),
                _buildStatChip(Icons.priority_high_rounded, "Important", "—"),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatChip(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 14),
        const SizedBox(width: 4),
        Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 8),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------- NOTICE CARD ----------------
  Widget _buildEnhancedNoticeCard(BuildContext context, _NoticeData notice) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () => _showNoticeDetails(context, notice),
      child: Container(
        padding: const EdgeInsets.all(16),
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
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notice.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: kTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              notice.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: kTextSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  notice.date,
                  style: const TextStyle(fontSize: 12, color: kTextSecondary),
                ),
                const SizedBox(width: 10),
                Text(
                  notice.time,
                  style: const TextStyle(fontSize: 12, color: kTextSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- DIALOG ----------------
  void _showNoticeDetails(BuildContext context, _NoticeData notice) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(notice.title),
        content: Text(notice.description),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }
}
