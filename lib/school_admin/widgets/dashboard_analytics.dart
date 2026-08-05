import 'dart:math' as math;

import 'package:flutter/material.dart';

const _blue = Color(0xFF023471);
const _green = Color(0xFF5AB04B);
const _muted = Color(0xFF6B7280);

class DashboardAnalyticsSection extends StatelessWidget {
  const DashboardAnalyticsSection({super.key});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 980
              ? 4
              : constraints.maxWidth >= 680
                  ? 2
                  : 1;
          final cards = const [
            _AttendanceChart(),
            _DistributionChart(),
            _AttendanceRadialChart(),
            _AdmissionsChart(),
          ];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionTitle(
                title: 'Analytics Overview',
                subtitle: 'Visual placeholders ready for dashboard data APIs',
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: cards.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  mainAxisExtent: 280,
                ),
                itemBuilder: (_, index) => cards[index],
              ),
            ],
          );
        },
      );
}

class DashboardUpdatesSection extends StatelessWidget {
  const DashboardUpdatesSection({super.key});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final activity = _Panel(
            title: 'Recent Activity',
            subtitle: 'Ready for future activity data',
            child: Column(
              children: const [
                _TimelineItem(Icons.person_add_alt_1_rounded,
                    'Student registrations', 'Recent records will appear here'),
                _TimelineItem(Icons.school_rounded, 'Teacher updates',
                    'Staff changes will appear here'),
                _TimelineItem(Icons.fact_check_rounded, 'Attendance updates',
                    'Recent attendance changes will appear here'),
              ],
            ),
          );
          final events = _Panel(
            title: 'Upcoming Events',
            subtitle: 'Ready for future calendar data',
            child: Column(
              children: const [
                _EventItem(Icons.quiz_rounded, 'Upcoming exams'),
                _EventItem(Icons.groups_rounded, 'School meetings'),
                _EventItem(Icons.event_rounded, 'School events'),
              ],
            ),
          );
          if (constraints.maxWidth < 760) {
            return Column(children: [activity, const SizedBox(height: 16), events]);
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: activity),
              const SizedBox(width: 16),
              Expanded(child: events),
            ],
          );
        },
      );
}

class _AttendanceChart extends StatelessWidget {
  const _AttendanceChart();
  @override
  Widget build(BuildContext context) => _Panel(
        title: 'Attendance Trend',
        subtitle: 'Weekly overview',
        trailing: const _Pill('This week'),
        child: const Expanded(
          child: CustomPaint(
            painter: _LineChartPainter(),
            child: SizedBox.expand(),
          ),
        ),
      );
}

class _DistributionChart extends StatelessWidget {
  const _DistributionChart();
  @override
  Widget build(BuildContext context) => _Panel(
        title: 'Students Distribution',
        subtitle: 'By grade level',
        child: const Expanded(
          child: Row(children: [
            Expanded(child: _Donut(colors: [Color(0xFF023471), Color(0xFF2E7CC9), Color(0xFF5AB04B), Color(0xFF8AC981)])),
            SizedBox(width: 14),
            Expanded(child: _Legend(labels: ['Grade 1', 'Grade 2', 'Grade 3', 'Other'])),
          ]),
        ),
      );
}

class _AttendanceRadialChart extends StatelessWidget {
  const _AttendanceRadialChart();
  @override
  Widget build(BuildContext context) => _Panel(
        title: 'Attendance Percentage',
        subtitle: 'Current month placeholder',
        child: const Expanded(
          child: Row(children: [
            Expanded(child: _Donut(colors: [_green, Color(0xFFDAEED7), Color(0xFF2E7CC9)])),
            SizedBox(width: 14),
            Expanded(child: _Legend(labels: ['Present', 'Late', 'Absent'])),
          ]),
        ),
      );
}

class _AdmissionsChart extends StatelessWidget {
  const _AdmissionsChart();
  @override
  Widget build(BuildContext context) => _Panel(
        title: 'Monthly Admissions',
        subtitle: 'Enrollment trend placeholder',
        child: const Expanded(child: _BarChart()),
      );
}

class _Panel extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;
  const _Panel({required this.title, required this.subtitle, required this.child, this.trailing});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE8ECF2)),
          boxShadow: [BoxShadow(color: _blue.withValues(alpha: .07), blurRadius: 22, offset: const Offset(0, 8))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(color: _blue, fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text(subtitle, style: const TextStyle(color: _muted, fontSize: 12)),
            ])),
            if (trailing != null) trailing!,
          ]),
          const SizedBox(height: 18),
          child,
        ]),
      );
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionTitle({required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: _blue, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 3),
        Text(subtitle, style: const TextStyle(color: _muted, fontSize: 12)),
      ]);
}

class _Pill extends StatelessWidget {
  final String text;
  const _Pill(this.text);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: const Color(0xFFF4F7FB), borderRadius: BorderRadius.circular(9)),
        child: Text(text, style: const TextStyle(color: _blue, fontSize: 11, fontWeight: FontWeight.w600)),
      );
}

class _Donut extends StatelessWidget {
  final List<Color> colors;
  const _Donut({required this.colors});
  @override
  Widget build(BuildContext context) => CustomPaint(painter: _DonutPainter(colors), child: const Center(child: Text('Overview', style: TextStyle(color: _blue, fontWeight: FontWeight.w700))));
}

class _Legend extends StatelessWidget {
  final List<String> labels;
  const _Legend({required this.labels});
  @override
  Widget build(BuildContext context) => Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        for (var index = 0; index < labels.length; index++)
          Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(children: [
            Container(width: 9, height: 9, decoration: BoxDecoration(color: [const Color(0xFF023471), const Color(0xFF2E7CC9), _green, const Color(0xFF8AC981)][index % 4], shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Expanded(child: Text(labels[index], style: const TextStyle(color: _muted, fontSize: 12))),
          ])),
      ]);
}

class _BarChart extends StatelessWidget {
  const _BarChart();
  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        for (final height in [55.0, 90.0, 72.0, 125.0, 105.0, 145.0])
          Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 7), child: Container(height: height, decoration: BoxDecoration(color: _blue.withValues(alpha: .12 + height / 700), borderRadius: const BorderRadius.vertical(top: Radius.circular(8)))))),
      ]);
}

class _TimelineItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _TimelineItem(this.icon, this.title, this.subtitle);
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 14), child: Row(children: [
        CircleAvatar(backgroundColor: _blue.withValues(alpha: .08), foregroundColor: _blue, child: Icon(icon, size: 18)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: _blue, fontWeight: FontWeight.w600)), Text(subtitle, style: const TextStyle(color: _muted, fontSize: 12))])),
      ]));
}

class _EventItem extends StatelessWidget {
  final IconData icon;
  final String title;
  const _EventItem(this.icon, this.title);
  @override
  Widget build(BuildContext context) => Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFF7F9FC), borderRadius: BorderRadius.circular(12)), child: Row(children: [Icon(icon, color: _green, size: 19), const SizedBox(width: 10), Expanded(child: Text(title, style: const TextStyle(color: _blue, fontWeight: FontWeight.w600)))]));
}

class _DonutPainter extends CustomPainter {
  final List<Color> colors;
  const _DonutPainter(this.colors);
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) * .34;
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = 24..strokeCap = StrokeCap.butt;
    const gap = .04;
    final sweep = (math.pi * 2 / colors.length) - gap;
    for (var i = 0; i < colors.length; i++) {
      paint.color = colors[i];
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -math.pi / 2 + i * (sweep + gap), sweep, false, paint);
    }
  }
  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) => oldDelegate.colors != colors;
}

class _LineChartPainter extends CustomPainter {
  const _LineChartPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()..color = const Color(0xFFE9EEF5)..strokeWidth = 1;
    for (var i = 1; i < 5; i++) canvas.drawLine(Offset(0, size.height * i / 5), Offset(size.width, size.height * i / 5), grid);
    final points = [Offset(0, size.height * .65), Offset(size.width * .18, size.height * .72), Offset(size.width * .38, size.height * .28), Offset(size.width * .58, size.height * .58), Offset(size.width * .78, size.height * .38), Offset(size.width, size.height * .62)];
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) path.lineTo(point.dx, point.dy);
    canvas.drawPath(path, Paint()..color = const Color(0xFF1267D8)..style = PaintingStyle.stroke..strokeWidth = 3..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round);
    for (final point in points) {
      canvas.drawCircle(point, 4, Paint()..color = Colors.white);
      canvas.drawCircle(
        point,
        3,
        Paint()..color = const Color(0xFF1267D8),
      );
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
