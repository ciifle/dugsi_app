import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

class ParentAttendanceScreen extends StatefulWidget {
  const ParentAttendanceScreen({Key? key}) : super(key: key);

  @override
  State<ParentAttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<ParentAttendanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String selectedChild = 'All Children';
  DateTime selectedDate = DateTime.now();

  final List<Map<String, dynamic>> children = [
    {'id': '1', 'name': 'Ava Carter', 'className': 'Grade 6 - A'},
    {'id': '2', 'name': 'Liam Carter', 'className': 'Grade 8 - B'},
    {'id': '3', 'name': 'Emma Carter', 'className': 'Grade 4 - C'},
  ];

  final List<Map<String, dynamic>> attendanceData = [
    {
      'childId': '1',
      'childName': 'Ava Carter',
      'totalDays': 180,
      'presentDays': 171,
      'absentDays': 9,
      'percentage': 95,
      'monthly': [
        {'month': 'Jan', 'present': 22, 'total': 22},
        {'month': 'Feb', 'present': 20, 'total': 21},
        {'month': 'Mar', 'present': 19, 'total': 20},
        {'month': 'Apr', 'present': 22, 'total': 22},
        {'month': 'May', 'present': 21, 'total': 21},
        {'month': 'Jun', 'present': 18, 'total': 20},
      ],
      'recent': [
        {'date': '2024-06-10', 'status': 'present', 'subject': 'All Day'},
        {'date': '2024-06-09', 'status': 'present', 'subject': 'All Day'},
        {'date': '2024-06-08', 'status': 'absent', 'subject': 'All Day'},
        {'date': '2024-06-07', 'status': 'present', 'subject': 'All Day'},
        {'date': '2024-06-06', 'status': 'late', 'subject': 'Morning'},
      ],
    },
    {
      'childId': '2',
      'childName': 'Liam Carter',
      'totalDays': 180,
      'presentDays': 158,
      'absentDays': 22,
      'percentage': 88,
      'monthly': [
        {'month': 'Jan', 'present': 20, 'total': 22},
        {'month': 'Feb', 'present': 18, 'total': 21},
        {'month': 'Mar', 'present': 17, 'total': 20},
        {'month': 'Apr', 'present': 19, 'total': 22},
        {'month': 'May', 'present': 18, 'total': 21},
        {'month': 'Jun', 'present': 16, 'total': 20},
      ],
      'recent': [
        {'date': '2024-06-10', 'status': 'present', 'subject': 'All Day'},
        {'date': '2024-06-09', 'status': 'absent', 'subject': 'All Day'},
        {'date': '2024-06-08', 'status': 'present', 'subject': 'All Day'},
        {'date': '2024-06-07', 'status': 'present', 'subject': 'All Day'},
        {'date': '2024-06-06', 'status': 'absent', 'subject': 'All Day'},
      ],
    },
    {
      'childId': '3',
      'childName': 'Emma Carter',
      'totalDays': 180,
      'presentDays': 166,
      'absentDays': 14,
      'percentage': 92,
      'monthly': [
        {'month': 'Jan', 'present': 21, 'total': 22},
        {'month': 'Feb', 'present': 19, 'total': 21},
        {'month': 'Mar', 'present': 18, 'total': 20},
        {'month': 'Apr', 'present': 20, 'total': 22},
        {'month': 'May', 'present': 19, 'total': 21},
        {'month': 'Jun', 'present': 19, 'total': 20},
      ],
      'recent': [
        {'date': '2024-06-10', 'status': 'present', 'subject': 'All Day'},
        {'date': '2024-06-09', 'status': 'present', 'subject': 'All Day'},
        {'date': '2024-06-08', 'status': 'present', 'subject': 'All Day'},
        {'date': '2024-06-07', 'status': 'late', 'subject': 'Morning'},
        {'date': '2024-06-06', 'status': 'present', 'subject': 'All Day'},
      ],
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
                      Icons.event_available_rounded,
                      color: kPrimaryBlue,
                      size: 12,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'ATTENDANCE TRACKER',
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
              'Student Attendance',
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
                Icons.calendar_month_rounded,
                color: Colors.white,
                size: 22,
              ),
              onPressed: () {
                _showCalendarDialog();
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
                Tab(text: 'Overview'),
                Tab(text: 'Monthly'),
                Tab(text: 'History'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildOverview(), _buildMonthly(), _buildHistory()],
      ),
    );
  }

  void _showCalendarDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Date'),
        content: SizedBox(
          height: 300,
          child: Column(
            children: [
              Expanded(
                child: CalendarDatePicker(
                  initialDate: selectedDate,
                  firstDate: DateTime(2024, 1, 1),
                  lastDate: DateTime.now(),
                  onDateChanged: (date) {
                    setState(() {
                      selectedDate = date;
                    });
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildOverview() {
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
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final data = attendanceData[index];
              if (selectedChild != 'All Children' &&
                  data['childName'] != selectedChild) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _AttendanceSummaryCard(data: data),
              );
            }, childCount: attendanceData.length),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthly() {
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
                'Select Child',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: kTextPrimary,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 45,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: children.length,
                  itemBuilder: (context, index) {
                    final child = children[index];
                    final isSelected = selectedChild == child['name'];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedChild = child['name'];
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(
                                  colors: [kPrimaryBlue, kSecondaryColor],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          color: isSelected ? null : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text(
                            child['name'].split(' ').first,
                            style: TextStyle(
                              color: isSelected ? Colors.white : kTextSecondary,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
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
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Monthly Attendance',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 200,
                child: Row(
                  children: List.generate(6, (index) {
                    final data = attendanceData.firstWhere(
                      (d) =>
                          selectedChild == 'All Children' ||
                          d['childName'] == selectedChild,
                      orElse: () => attendanceData[0],
                    );
                    final monthData = data['monthly'][index];
                    return Expanded(
                      child: Column(
                        children: [
                          Expanded(
                            child: Container(
                              width: 20,
                              decoration: BoxDecoration(
                                color: kSoftBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Container(
                                    height:
                                        (monthData['present'] /
                                            monthData['total']) *
                                        150,
                                    width: 20,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [kPrimaryBlue, kSecondaryColor],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            monthData['month'],
                            style: const TextStyle(fontSize: 11),
                          ),
                          Text(
                            '${monthData['present']}/${monthData['total']}',
                            style: TextStyle(
                              fontSize: 10,
                              color: kTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
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
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLegendItem('Present', kSuccessColor),
              _buildLegendItem('Absent', kErrorColor),
              _buildLegendItem('Late', kSoftOrange),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHistory() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selected Date',
                      style: TextStyle(color: kTextSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMMM d, yyyy').format(selectedDate),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: kSoftBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.calendar_month_rounded,
                    color: kPrimaryBlue,
                  ),
                  onPressed: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2024, 1, 1),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() {
                        selectedDate = picked;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: kSoftPurple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.history_rounded, color: kSoftPurple),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Attendance History',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...List.generate(
                attendanceData.length,
                (index) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [kSoftPurple, kSoftBlue],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            attendanceData[index]['childName']
                                .split(' ')
                                .map((e) => e[0])
                                .join(''),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
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
                              attendanceData[index]['childName'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Class: ${children[index]['className']}',
                              style: TextStyle(
                                color: kTextSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildStatusChip(
                        attendanceData[index]['recent'][0]['status'],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: kTextSecondary, fontSize: 12)),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    IconData icon;

    switch (status) {
      case 'present':
        color = kSuccessColor;
        icon = Icons.check_circle_rounded;
        break;
      case 'absent':
        color = kErrorColor;
        icon = Icons.cancel_rounded;
        break;
      case 'late':
        color = kSoftOrange;
        icon = Icons.access_time_rounded;
        break;
      default:
        color = kSoftPurple;
        icon = Icons.help_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceSummaryCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _AttendanceSummaryCard({Key? key, required this.data})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color performanceColor = data['percentage'] >= 90
        ? kSuccessColor
        : data['percentage'] >= 75
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
                      data['childName'].split(' ').map((e) => e[0]).join(''),
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
                        data['childName'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 12,
                            color: kTextSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Total Days: ${data['totalDays']}',
                            style: TextStyle(
                              color: kTextSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: performanceColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${data['percentage']}%',
                    style: TextStyle(
                      color: performanceColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  label: 'Present',
                  value: '${data['presentDays']}',
                  color: kSuccessColor,
                ),
                _buildStatItem(
                  label: 'Absent',
                  value: '${data['absentDays']}',
                  color: kErrorColor,
                ),
                _buildStatItem(
                  label: 'Attendance',
                  value: '${data['percentage']}%',
                  color: kSoftBlue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(color: kTextSecondary, fontSize: 11)),
      ],
    );
  }
}
