import 'package:flutter/material.dart';

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

class ParentResultsScreen extends StatefulWidget {
  const ParentResultsScreen({Key? key}) : super(key: key);

  @override
  State<ParentResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ParentResultsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String selectedChild = 'All Children';

  final List<Map<String, dynamic>> children = [
    {'id': '1', 'name': 'Ava Carter', 'className': 'Grade 6 - A'},
    {'id': '2', 'name': 'Liam Carter', 'className': 'Grade 8 - B'},
    {'id': '3', 'name': 'Emma Carter', 'className': 'Grade 4 - C'},
  ];

  final List<Map<String, dynamic>> results = [
    {
      'id': '1',
      'childId': '1',
      'childName': 'Ava Carter',
      'term': 'Term 1',
      'year': '2024',
      'subjects': [
        {
          'name': 'Mathematics',
          'marks': 92,
          'grade': 'A',
          'remarks': 'Excellent',
        },
        {'name': 'Science', 'marks': 88, 'grade': 'A-', 'remarks': 'Very Good'},
        {
          'name': 'English',
          'marks': 95,
          'grade': 'A+',
          'remarks': 'Outstanding',
        },
        {'name': 'History', 'marks': 85, 'grade': 'B+', 'remarks': 'Good'},
      ],
      'totalMarks': 360,
      'percentage': 90,
      'rank': '1st',
    },
    {
      'id': '2',
      'childId': '2',
      'childName': 'Liam Carter',
      'term': 'Term 1',
      'year': '2024',
      'subjects': [
        {'name': 'Mathematics', 'marks': 85, 'grade': 'B+', 'remarks': 'Good'},
        {'name': 'Physics', 'marks': 82, 'grade': 'B', 'remarks': 'Good'},
        {
          'name': 'Chemistry',
          'marks': 88,
          'grade': 'A-',
          'remarks': 'Very Good',
        },
        {'name': 'English', 'marks': 90, 'grade': 'A', 'remarks': 'Excellent'},
      ],
      'totalMarks': 345,
      'percentage': 86.25,
      'rank': '3rd',
    },
    {
      'id': '3',
      'childId': '3',
      'childName': 'Emma Carter',
      'term': 'Term 1',
      'year': '2024',
      'subjects': [
        {
          'name': 'English',
          'marks': 94,
          'grade': 'A+',
          'remarks': 'Outstanding',
        },
        {'name': 'Math', 'marks': 91, 'grade': 'A', 'remarks': 'Excellent'},
        {'name': 'Science', 'marks': 89, 'grade': 'A-', 'remarks': 'Very Good'},
        {'name': 'Art', 'marks': 96, 'grade': 'A+', 'remarks': 'Outstanding'},
      ],
      'totalMarks': 370,
      'percentage': 92.5,
      'rank': '1st',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
              colors: [kPrimaryBlue, kSecondaryColor, kAccentColor],
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
                      Icons.assignment_rounded,
                      color: kPrimaryBlue,
                      size: 12,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'ACADEMIC RESULTS',
                    style: TextStyle(
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
              'Exam Results',
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
                Icons.filter_list_rounded,
                color: Colors.white,
                size: 22,
              ),
              onPressed: () {
                _showFilterDialog();
              },
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(30),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color: Colors.white,
              ),
              labelColor: kPrimaryBlue,
              unselectedLabelColor: Colors.white,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: const [
                Tab(text: 'Latest'),
                Tab(text: 'All Results'),
                Tab(text: 'Reports'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildLatestResults(), _buildAllResults(), _buildReports()],
      ),
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Filter Results',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: kTextPrimary,
                ),
              ),
              const SizedBox(height: 20),
              _buildFilterOption(
                'All Terms',
                Icons.calendar_month_rounded,
                true,
              ),
              _buildFilterOption('Term 1', Icons.looks_one_rounded, false),
              _buildFilterOption('Term 2', Icons.looks_two_rounded, false),
              _buildFilterOption('Term 3', Icons.looks_3_rounded, false),
              const SizedBox(height: 10),
              _buildFilterOption(
                '2023-2024',
                Icons.calendar_today_rounded,
                true,
              ),
              _buildFilterOption(
                '2022-2023',
                Icons.calendar_today_rounded,
                false,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterOption(String label, IconData icon, bool isSelected) {
    return ListTile(
      leading: Icon(icon, color: isSelected ? kPrimaryBlue : kTextSecondary),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? kPrimaryBlue : kTextPrimary,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_rounded, color: kPrimaryBlue)
          : null,
      onTap: () => Navigator.pop(context),
    );
  }

  Widget _buildLatestResults() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedChild,
                isExpanded: true,
                icon: Icon(Icons.arrow_drop_down_rounded, color: kPrimaryBlue),
                items: [
                  const DropdownMenuItem(
                    value: 'All Children',
                    child: Text('All Children'),
                  ),
                  ...children.map(
                    (child) => DropdownMenuItem(
                      value: child['name'],
                      child: Text(child['name']),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedChild = value!;
                  });
                },
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final result = results[index];
              if (selectedChild != 'All Children' &&
                  result['childName'] != selectedChild) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _ResultCard(result: result),
              );
            }, childCount: results.length),
          ),
        ),
      ],
    );
  }

  Widget _buildAllResults() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Term',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: kTextPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildTermChip('Term 1', true),
                  const SizedBox(width: 8),
                  _buildTermChip('Term 2', false),
                  const SizedBox(width: 8),
                  _buildTermChip('Term 3', false),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildTermChip('Mid Term', false),
                  const SizedBox(width: 8),
                  _buildTermChip('Final', false),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Academic Year',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: kSoftBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '2023-2024',
                  style: TextStyle(
                    color: kPrimaryBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Previous Results',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: kTextPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(
          3,
          (index) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: kSoftPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.history_edu_rounded, color: kSoftPurple),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Term ${index + 1} - 2024',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ava Carter • Grade 6-A',
                        style: TextStyle(color: kTextSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: kSuccessColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${85 + index * 2}%',
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
      ],
    );
  }

  Widget _buildReports() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [kPrimaryBlue, kSecondaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.analytics_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Performance Report',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Generate comprehensive report',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: kPrimaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Generate Report'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Available Reports',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: kTextPrimary,
          ),
        ),
        const SizedBox(height: 12),
        _buildReportTile(
          icon: Icons.assessment_rounded,
          title: 'Progress Report',
          subtitle: 'Term 1, 2024',
          color: kSoftPurple,
        ),
        _buildReportTile(
          icon: Icons.bar_chart_rounded,
          title: 'Subject Analysis',
          subtitle: 'Performance breakdown',
          color: kSoftBlue,
        ),
        _buildReportTile(
          icon: Icons.trending_up_rounded,
          title: 'Growth Report',
          subtitle: 'Year over year comparison',
          color: kSoftOrange,
        ),
      ],
    );
  }

  Widget _buildTermChip(String label, bool isSelected) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? kAccentColor : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : kTextSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReportTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  subtitle,
                  style: TextStyle(color: kTextSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          Icon(Icons.download_rounded, color: color),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final Map<String, dynamic> result;

  const _ResultCard({Key? key, required this.result}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color performanceColor = result['percentage'] >= 90
        ? kSuccessColor
        : result['percentage'] >= 75
        ? kSoftBlue
        : kSoftOrange;

    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [kSoftPurple, kSoftBlue],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      result['childName'].split(' ').map((e) => e[0]).join(''),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result['childName'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${result['term']} ${result['year']}',
                        style: TextStyle(color: kTextSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: performanceColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${result['percentage']}%',
                    style: TextStyle(
                      color: performanceColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            ...List.generate(
              result['subjects'].length,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        result['subjects'][index]['name'],
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${result['subjects'][index]['marks']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Container(
                      width: 40,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color:
                            result['subjects'][index]['grade']
                                .toString()
                                .startsWith('A')
                            ? kSuccessColor.withOpacity(0.1)
                            : kSoftOrange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        result['subjects'][index]['grade'],
                        style: TextStyle(
                          color:
                              result['subjects'][index]['grade']
                                  .toString()
                                  .startsWith('A')
                              ? kSuccessColor
                              : kSoftOrange,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total: ${result['totalMarks']}/400',
                  style: TextStyle(color: kTextSecondary, fontSize: 12),
                ),
                Text(
                  'Rank: ${result['rank']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: kPrimaryBlue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
