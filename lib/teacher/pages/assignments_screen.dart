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
  const TeacherAssignmentsScreen({Key? key}) : super(key: key);

  @override
  State<TeacherAssignmentsScreen> createState() =>
      _TeacherAssignmentsScreenState();
}

class _TeacherAssignmentsScreenState extends State<TeacherAssignmentsScreen> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  late Future<TeacherResult<List<TeacherAssignmentModel>>> _assignmentsFuture;

  @override
  void initState() {
    super.initState();
    _assignmentsFuture = TeacherService().listAssignments();
  }

  void _refresh() {
    setState(() {
      _assignmentsFuture = TeacherService().listAssignments();
    });
  }

  /// Group API assignments by class display name. Never use "class 0"; use Unassigned.
  Map<String, List<TeacherAssignmentModel>> _groupByClass(List<TeacherAssignmentModel> list) {
    final map = <String, List<TeacherAssignmentModel>>{};
    for (final a in list) {
      final key = a.classDisplayName;
      map.putIfAbsent(key, () => []).add(a);
    }
    return map;
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
      body: FutureBuilder<TeacherResult<List<TeacherAssignmentModel>>>(
        future: _assignmentsFuture,
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
          final list = result is TeacherSuccess<List<TeacherAssignmentModel>> ? result.data : <TeacherAssignmentModel>[];
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
                            ? 'No assignments yet. Contact school admin.'
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
          final grouped = _groupByClass(searchFiltered);
          return _buildScaffoldWithAppBar(
            body: RefreshIndicator(
              onRefresh: () async => _refresh(),
              color: kPrimaryBlue,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  const SizedBox(height: 8),
                  ...grouped.entries.map((e) => _ApiAssignmentClassCard(
                        className: e.key,
                        assignments: e.value,
                      )),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildScaffoldWithAppBar({required Widget body}) {
    return Scaffold(
      backgroundColor: kSoftBlue,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ---------------- APP BAR WITH GRADIENT ----------------
          SliverAppBar(
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
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                  size: 28,
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
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
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
                            hintStyle: TextStyle(
                              color: kTextSecondary,
                              fontSize: 15,
                            ),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color: kPrimaryBlue,
                              size: 22,
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: Icon(
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
                          style: const TextStyle(
                            color: kTextPrimary,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  )
                : null,
          ),

          // ---------------- MAIN CONTENT (injected body) ----------------
          SliverFillRemaining(
            hasScrollBody: false,
            child: body,
          ),
        ],
      ),
    );
  }

}

// ---------------- API ASSIGNMENT CLASS CARD (grouped by class) ----------------
class _ApiAssignmentClassCard extends StatelessWidget {
  final String className;
  final List<TeacherAssignmentModel> assignments;

  const _ApiAssignmentClassCard({
    required this.className,
    required this.assignments,
  });

  @override
  Widget build(BuildContext context) {
    final subjectNames = assignments.map((a) => a.subjectName).where((s) => s.isNotEmpty).toSet().toList();
    if (subjectNames.isEmpty) subjectNames.add('—');
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: kPrimaryBlue.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kPrimaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.class_rounded, color: kPrimaryBlue, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                'Class: $className',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: kTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...subjectNames.map((s) => Padding(
                padding: const EdgeInsets.only(left: 8, top: 4),
                child: Row(
                  children: [
                    Icon(Icons.subject_rounded, size: 18, color: kTextSecondary),
                    const SizedBox(width: 8),
                    Text(s, style: TextStyle(fontSize: 15, color: kTextPrimary)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

