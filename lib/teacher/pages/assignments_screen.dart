import 'package:flutter/material.dart';
import 'package:kobac/services/teacher_service.dart';
import 'package:kobac/teacher/widgets/teacher_web_ui.dart';

// ---------- COLOR PALETTE (Matching Student Dashboard) ----------
const Color kPrimaryBlue = Color(0xFF023471); // Dark blue
const Color kPrimaryGreen = Color(0xFF5AB04B); // Green
const Color kSoftBlue = Color(0xFFE6F0FF); // Light tint of blue
const Color kTextPrimary = Color(0xFF2D3436); // Dark gray
const Color kTextSecondary = Color(0xFF636E72); // Medium gray

// =========================
//   MAIN SCREEN WIDGET
// =========================
class TeacherAssignmentsScreen extends StatefulWidget {
  /// When provided (e.g. from dashboard), assignments show immediately from this data.
  final TeacherDashboardModel? initialDashboard;
  final bool embedBodyOnly;
  final void Function(String, {Object? arguments})? onNavigateToPage;

  /// When false, renders bare content with no Scaffold/AppBar/back arrow —
  /// used when this screen is hosted as a tab inside the Teacher mobile
  /// shell (which owns the single persistent header + bottom nav). The
  /// search field stays inline (always visible) instead of an AppBar toggle.
  final bool showAppBar;

  const TeacherAssignmentsScreen({
    Key? key,
    this.initialDashboard,
    this.embedBodyOnly = false,
    this.onNavigateToPage,
    this.showAppBar = true,
  }) : super(key: key);

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
    final content = FutureBuilder<TeacherResult<TeacherDashboardModel>>(
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
              child: TeacherErrorState(
                message: is403
                    ? 'Teacher profile not found. Contact school admin.'
                    : result.message,
                onRetry: _refresh,
              ),
            ),
          );
        }
        TeacherDashboardModel? dashboard;
        if (result is TeacherSuccess<TeacherDashboardModel>) {
          dashboard = result.data;
        }
        final list = dashboard?.assignments ?? <TeacherAssignmentModel>[];
        final searchFiltered = _searchQuery.isEmpty
            ? list
            : list.where((a) {
                final q = _searchQuery.toLowerCase();
                return a.classDisplayName.toLowerCase().contains(q) ||
                    a.subjectName.toLowerCase().contains(q);
              }).toList();
        if (searchFiltered.isEmpty) {
          return _buildScaffoldWithAppBar(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TeacherEmptyState(
                    icon: Icons.assignment_outlined,
                    title: list.isEmpty
                        ? 'No assignments found'
                        : 'No assignments match your search',
                  ),
                  if (list.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
                      },
                      child: const Text('Clear search'),
                      style: TextButton.styleFrom(
                        foregroundColor: kPrimaryBlue,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }
        return _buildScaffoldWithList(searchFiltered);
      },
    );

    if (widget.embedBodyOnly || !widget.showAppBar) {
      return ColoredBox(color: teacherWebBg, child: content);
    }

    return Scaffold(backgroundColor: teacherWebBg, body: content);
  }

  Widget _buildDesktopAssignmentsList(
    List<TeacherAssignmentModel> searchFiltered,
  ) {
    return TeacherWebSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const TeacherWebSectionTitle(
            title: 'Assignments',
            subtitle: 'Subjects and classes assigned to you.',
          ),
          const SizedBox(height: 16),
          TeacherWebCard(
            child: TextField(
              controller: _searchController,
              onChanged: _updateSearchQuery,
              decoration: InputDecoration(
                hintText: 'Search assignments...',
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: kPrimaryBlue,
                ),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: teacherWebBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: teacherWebBorder),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TeacherWebCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                const TeacherWebTableHeader(columns: ['Subject', 'Class', '']),
                ...List.generate(searchFiltered.length, (index) {
                  final assignment = searchFiltered[index];
                  final subjectLabel = assignment.subjectName.isNotEmpty
                      ? assignment.subjectName
                      : '—';
                  return TeacherWebTableRow(
                    cells: [
                      Text(
                        subjectLabel,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: kPrimaryBlue,
                        ),
                      ),
                      Text(
                        assignment.classDisplayName,
                        style: const TextStyle(color: kTextSecondary),
                      ),
                      const Align(
                        alignment: Alignment.centerRight,
                        child: Icon(
                          Icons.assignment_rounded,
                          color: kPrimaryGreen,
                          size: 20,
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentCard(TeacherAssignmentModel a) {
    final subjectLabel = a.subjectName.isNotEmpty ? a.subjectName : '—';
    final classLabel = a.classDisplayName;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: teacherWebBorder),
        boxShadow: [
          BoxShadow(
            color: kPrimaryBlue.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: kPrimaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.subject_rounded,
              color: kPrimaryGreen,
              size: 21,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              '$subjectLabel — $classLabel',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: kTextPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Always-visible search field used when this screen is hosted inside the
  /// Teacher mobile shell (no AppBar available to host a search toggle).
  Widget _buildInlineSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        controller: _searchController,
        onChanged: _updateSearchQuery,
        decoration: InputDecoration(
          hintText: 'Search assignments...',
          prefixIcon: const Icon(Icons.search_rounded, color: kPrimaryBlue),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: teacherWebBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: teacherWebBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: kPrimaryBlue),
          ),
        ),
      ),
    );
  }

  Widget _wrapShellBody(Widget body) {
    return ColoredBox(
      color: teacherWebBg,
      child: Column(
        children: [
          _buildInlineSearchField(),
          Expanded(child: body),
        ],
      ),
    );
  }

  /// Builds scaffold with list as slivers (avoids SliverFillRemaining + ListView intrinsic error).
  Widget _buildScaffoldWithList(List<TeacherAssignmentModel> searchFiltered) {
    if (widget.embedBodyOnly) {
      return RefreshIndicator(
        onRefresh: () async => _refresh(),
        color: kPrimaryBlue,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: _buildDesktopAssignmentsList(searchFiltered),
        ),
      );
    }

    final list = RefreshIndicator(
      onRefresh: () async => _refresh(),
      color: kPrimaryBlue,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: searchFiltered.length,
        itemBuilder: (context, index) =>
            _buildAssignmentCard(searchFiltered[index]),
      ),
    );

    if (!widget.showAppBar) {
      return _wrapShellBody(list);
    }

    final scroll = RefreshIndicator(
      onRefresh: () async => _refresh(),
      color: kPrimaryBlue,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          _buildSliverAppBar(),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                return _buildAssignmentCard(searchFiltered[index]);
              }, childCount: searchFiltered.length),
            ),
          ),
        ],
      ),
    );

    return Scaffold(backgroundColor: teacherWebBg, body: scroll);
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: _isSearching ? 90 : 96,
      pinned: true,
      backgroundColor: kPrimaryBlue,
      elevation: 0,
      flexibleSpace: const FlexibleSpaceBar(
        titlePadding: EdgeInsets.only(left: 56, bottom: 16),
        centerTitle: false,
        title: Text(
          "Assignments",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      leading: Container(
        margin: const EdgeInsets.only(left: 12, top: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Colors.white,
            size: 24,
          ),
          onPressed: () => Navigator.pop(context),
          padding: const EdgeInsets.all(10),
        ),
      ),
      actions: [
        if (_isSearching)
          Container(
            margin: const EdgeInsets.only(right: 12, top: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
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
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.search_rounded,
                color: Colors.white,
                size: 24,
              ),
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
                        color: Colors.black.withValues(alpha: 0.1),
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
                      hintStyle: const TextStyle(
                        color: kTextSecondary,
                        fontSize: 15,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: kPrimaryBlue,
                        size: 22,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.clear,
                                color: kTextSecondary,
                                size: 20,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                _updateSearchQuery('');
                              },
                              padding: EdgeInsets.zero,
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
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
    if (widget.embedBodyOnly) {
      return TeacherWebSurface(child: body);
    }

    if (!widget.showAppBar) {
      return _wrapShellBody(body);
    }

    return Scaffold(
      backgroundColor: teacherWebBg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(),
          SliverFillRemaining(hasScrollBody: false, child: body),
        ],
      ),
    );
  }
}
