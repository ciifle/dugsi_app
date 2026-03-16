import 'package:flutter/material.dart';
import 'package:kobac/services/teacher_service.dart';

// ---------- COLOR PALETTE (Matching Student Dashboard) ----------
const Color kPrimaryBlue = Color(0xFF023471); // Dark blue
const Color kPrimaryGreen = Color(0xFF5AB04B); // Green

// Derived colors (shades/tints of the two main colors)
const Color kSoftBlue = Color(0xFFE6F0FF); // Light tint of blue
const Color kSoftGreen = Color(0xFFEDF7EB); // Light tint of green
const Color kDarkGreen = Color(0xFF3A7A30); // Darker shade of green
const Color kDarkBlue = Color(0xFF01255C); // Darker shade of blue
const Color kTextPrimary = Color(0xFF2D3436); // Dark gray
const Color kTextSecondary = Color(0xFF636E72); // Medium gray
const Color kErrorColor = Color(0xFFEF4444); // Red
const Color kSoftOrange = Color(0xFFF59E0B); // Amber
const Color kSuccessColor = Color(0xFF5AB04B); // Green for present
const Color kCardColor = Colors.white;

// =========================
//   MAIN SCREEN WIDGET
// =========================
class TeacherAssignmentsScreen extends StatefulWidget {
  /// When provided (e.g. from dashboard), assignments show immediately from this data.
  final TeacherDashboardModel? initialDashboard;

  const TeacherAssignmentsScreen({Key? key, this.initialDashboard}) : super(key: key);

  @override
  State<TeacherAssignmentsScreen> createState() =>
      _TeacherAssignmentsScreenState();
}

class _TeacherAssignmentsScreenState extends State<TeacherAssignmentsScreen> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  late Future<TeacherResult<TeacherDashboardModel>> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = widget.initialDashboard != null
        ? Future.value(TeacherSuccess(widget.initialDashboard!))
        : TeacherService().getDashboard();
  }

  void _refresh() {
    setState(() {
      _dashboardFuture = TeacherService().getDashboard();
    });
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
    });
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  void _updateSearchQuery(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSoftBlue,
      body: FutureBuilder<TeacherResult<TeacherDashboardModel>>(
        future: _dashboardFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return _buildScaffoldWithAppBar(
              body: const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(color: kPrimaryBlue),
                ),
              ),
            );
          }
          final result = snap.data;
          if (result is TeacherError) {
            final is403 = result.statusCode == 403;
            return _buildScaffoldWithAppBar(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        is403 ? Icons.person_off_rounded : Icons.error_outline_rounded,
                        size: 56,
                        color: kTextSecondary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        is403
                            ? 'Teacher profile not found. Contact school admin.'
                            : result.message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16, color: kTextPrimary),
                      ),
                      const SizedBox(height: 24),
                      TextButton.icon(
                        onPressed: _refresh,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Retry'),
                        style: TextButton.styleFrom(foregroundColor: kPrimaryBlue),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
          TeacherDashboardModel? dashboard;
          if (result is TeacherSuccess<TeacherDashboardModel>) {
            dashboard = result.data;
          }
          final list = dashboard?.assignments ?? <TeacherAssignmentModel>[];
          if (dashboard != null) {
            debugPrint('TeacherAssignmentsScreen: dashboard assignments: ${dashboard.assignments.length}');
          }
          final searchFiltered = _searchQuery.isEmpty
              ? list
              : list.where((a) {
                  final q = _searchQuery.toLowerCase();
                  return a.classDisplayName.toLowerCase().contains(q) || a.subjectName.toLowerCase().contains(q);
                }).toList();
          if (searchFiltered.isEmpty) {
            return _buildScaffoldWithAppBar(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.assignment_rounded, size: 56, color: kTextSecondary),
                      const SizedBox(height: 16),
                      Text(
                        list.isEmpty
                            ? 'No assignments found.'
                            : 'No assignments match your search.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16, color: kTextPrimary),
                      ),
                      if (list.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                            });
                          },
                          child: const Text('Clear search'),
                          style: TextButton.styleFrom(foregroundColor: kPrimaryBlue),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }
          return _buildScaffoldWithList(searchFiltered);
        },
      ),
    );
  }

  /// Builds scaffold with list as slivers (avoids SliverFillRemaining + ListView intrinsic error).
  Widget _buildScaffoldWithList(List<TeacherAssignmentModel> searchFiltered) {
    return Scaffold(
      backgroundColor: kSoftBlue,
      body: RefreshIndicator(
        onRefresh: () async => _refresh(),
        color: kPrimaryBlue,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            _buildSliverAppBar(),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final a = searchFiltered[index];
                    final subjectLabel = a.subjectName.isNotEmpty ? a.subjectName : '—';
                    final classLabel = a.classDisplayName;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: kPrimaryBlue.withOpacity(0.08),
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
                              color: kPrimaryGreen.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.subject_rounded, color: kPrimaryGreen, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              '$subjectLabel — $classLabel',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: kTextPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  childCount: searchFiltered.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: _isSearching ? 100 : 120,
      pinned: true,
      backgroundColor: kPrimaryBlue,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [kPrimaryBlue, kPrimaryBlue, kPrimaryGreen],
            stops: const [0.3, 0.7, 1.0],
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(30),
            bottomRight: Radius.circular(30),
          ),
        ),
        child: FlexibleSpaceBar(
          titlePadding: const EdgeInsets.only(bottom: 20),
          centerTitle: true,
          title: _isSearching
              ? null
              : const Text(
                  "Assignments",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                  ),
                ),
        ),
      ),
      leading: Container(
        margin: const EdgeInsets.only(left: 12, top: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(14),
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 28),
          onPressed: () => Navigator.pop(context),
          padding: const EdgeInsets.all(10),
        ),
      ),
      actions: [
        if (_isSearching)
          Container(
            margin: const EdgeInsets.only(right: 12, top: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 24),
              onPressed: _stopSearch,
              padding: const EdgeInsets.all(10),
            ),
          )
        else
          Container(
            margin: const EdgeInsets.only(right: 12, top: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: IconButton(
              icon: const Icon(Icons.search_rounded, color: Colors.white, size: 24),
              onPressed: _startSearch,
              padding: const EdgeInsets.all(10),
            ),
          ),
      ],
      bottom: _isSearching
          ? PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    onChanged: _updateSearchQuery,
                    decoration: InputDecoration(
                      hintText: 'Search assignments...',
                      hintStyle: TextStyle(color: kTextSecondary, fontSize: 15),
                      prefixIcon: Icon(Icons.search_rounded, color: kPrimaryBlue, size: 22),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, color: kTextSecondary, size: 20),
                              onPressed: () {
                                _searchController.clear();
                                _updateSearchQuery('');
                              },
                              padding: EdgeInsets.zero,
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    style: const TextStyle(color: kTextPrimary, fontSize: 15),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildScaffoldWithAppBar({required Widget body}) {
    return Scaffold(
      backgroundColor: kSoftBlue,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(),
          SliverFillRemaining(
            hasScrollBody: false,
            child: body,
          ),
        ],
      ),
    );
  }

}

