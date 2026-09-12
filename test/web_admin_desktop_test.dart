import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'support/font_io.dart'
    if (dart.library.js_interop) 'support/font_web.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:kobac/services/auth_provider.dart';
import 'package:kobac/services/academic_years_service.dart';
import 'package:kobac/services/shifts_service.dart';
import 'package:kobac/school_admin/widgets/web_sidebar.dart';
import 'package:kobac/school_admin/widgets/web_admin_reference_kit.dart';
import 'package:kobac/school_admin/widgets/web_admin_theme.dart';
import 'package:kobac/school_admin/pages/exam_hall_management_pages.dart';
import 'package:kobac/school_admin/pages/teacher_day_off_page.dart';
import 'package:kobac/school_admin/pages/admin_timetable_screen.dart';

const year = {'id': 7, 'name': '2026-2027', 'is_active': true};
Future<http.Response> fixture(http.Request request) async {
  final path = request.url.path;
  Object body = <String, dynamic>{};
  if (path.endsWith('/academic-years/active')) {
    body = {'academic_year': year};
  } else if (path.endsWith('/academic-years')) {
    body = {
      'academic_years': [year],
    };
  } else if (path.endsWith('/levels')) {
    body = {
      'levels': [
        {'id': 1, 'name': 'Primary', 'class_count': 4, 'is_active': true},
      ],
    };
  } else if (path.endsWith('/shifts')) {
    body = {
      'shifts': [
        {'id': 1, 'name': 'Morning', 'class_count': 4, 'is_active': true},
      ],
    };
  } else if (path.endsWith('/classes')) {
    body = {
      'classes': [
        {'id': 1, 'name': 'Form One', 'shift_name': 'Morning'},
      ],
    };
  } else if (path.endsWith('/subjects')) {
    body = {
      'subjects': [
        {'id': 1, 'name': 'Biology'},
      ],
    };
  } else if (path.endsWith('/teachers')) {
    body = {
      'teachers': [
        {'id': 1, 'fullName': 'Teacher Example'},
      ],
    };
  } else if (path.endsWith('/teacher-day-offs')) {
    body = {
      'data': [
        for (final entry in ['MON', 'WED', 'SAT'].asMap().entries)
          {
            'id': entry.key + 1,
            'teacher_id': 1,
            'day': entry.value,
            'is_active': true,
            'teacher': {'id': 1, 'fullName': 'Teacher Example'},
          },
      ],
    };
  } else if (path.endsWith('/timetables')) {
    body = {
      'timetables': [
        {
          'id': 1,
          'class_id': 1,
          'subject_id': 1,
          'teacher_id': 1,
          'day': 'MON',
          'start_time': '07:20',
          'end_time': '08:00',
          'period': {
            'id': 1,
            'name': 'Period 1',
            'period_number': 1,
            'shift': 'morning',
          },
        },
      ],
    };
  }
  return http.Response(jsonEncode(body), 200);
}

Widget host(Widget page, double width, {String selectedPage = 'dashboard'}) =>
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AcademicYearsProvider()),
        ChangeNotifierProvider(create: (_) => ShiftsProvider()),
      ],
      child: MaterialApp(
        theme: kIsWeb && width >= 1024 ? webAdminTheme(ThemeData()) : null,
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Row(
            children: [
              if (kIsWeb && width >= 1024)
                WebSidebar(
                  width: width < 1200 ? 220 : 260,
                  selectedPage: selectedPage,
                  onNavigate: (_) {},
                ),
              Expanded(child: page),
            ],
          ),
        ),
      ),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final loader = FontLoader('Roboto')..addFont(fontData());
    await loader.load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  for (final width in [960, 1024, 1130, 1280, 1366, 1440, 1920]) {
    for (final entry in <String, Widget>{
      'levels': const LevelsPage(),
      'shifts': const ShiftsPage(),
      'days': const TeacherDayOffPage(embedBodyOnly: true),
      'timetable': const AdminTimetableScreen(embedBodyOnly: true),
    }.entries) {
      testWidgets('${entry.key} has usable layout at $width', (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width.toDouble(), 1000);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.binding.setSurfaceSize(Size(width.toDouble(), 1000));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await http.runWithClient(() async {
          await tester.pumpWidget(
            host(
              entry.value,
              width.toDouble(),
              selectedPage: entry.key == 'days' ? 'teacherDayOff' : entry.key,
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final desktop = kIsWeb && width >= 1024;
          expect(
            find.byType(WebAdminPage),
            desktop ? findsOneWidget : findsNothing,
          );
          if (desktop) {
            expect(find.byType(WebAdminTable), findsOneWidget);
            final card = tester.getSize(find.byType(WebAdminCard).last);
            expect(
              card.width,
              greaterThan(width - (width < 1200 ? 220 : 260) - 60),
            );
            if (entry.key == 'days') {
              expect(find.text('Teacher Example'), findsOneWidget);
              expect(find.byType(InputChip), findsNWidgets(3));
              final chips = tester.getRect(find.byType(InputChip).first);
              final next = tester.getRect(find.byType(InputChip).at(1));
              expect(chips.overlaps(next), isFalse);
              if (width >= 1280) expect(chips.top, next.top);
              expect(find.byTooltip('Edit'), findsOneWidget);
              expect(
                find.byWidgetPredicate(
                  (widget) =>
                      widget is IconButton && widget.tooltip == 'Delete',
                ),
                findsOneWidget,
              );
            }
            final action = switch (entry.key) {
              'levels' => 'Add Level',
              'shifts' => 'Add Shift',
              'days' => 'Add Manually',
              _ => 'Delete Year Timetables',
            };
            await tester.ensureVisible(find.text(action));
            await tester.tap(find.text(action));
            await tester.pumpAndSettle();
            expect(find.byType(Dialog), findsOneWidget);
            expect(tester.takeException(), isNull);
            final bounds = tester.getRect(find.byType(Dialog));
            expect(bounds.left, greaterThanOrEqualTo(0));
            expect(bounds.right, lessThanOrEqualTo(width));
            expect(bounds.top, greaterThanOrEqualTo(0));
            expect(bounds.bottom, lessThanOrEqualTo(1000));
            Navigator.of(tester.element(find.byType(Dialog))).pop();
            await tester.pumpAndSettle();
            final pageScroll = find.descendant(
              of: find.byType(WebAdminPage),
              matching: find.byType(Scrollable),
            );
            tester.state<ScrollableState>(pageScroll.first).position.jumpTo(0);
            await tester.pump();
          }
          await tester.pumpWidget(const SizedBox());
        }, () => MockClient(fixture));
      });
    }
  }

  testWidgets('active sidebar groups collapse and reopen on route changes', (
    tester,
  ) async {
    String page = 'levels';
    late StateSetter update;
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(),
        child: MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                update = setState;
                return WebSidebar(
                  selectedPage: page,
                  onNavigate: (value) => setState(() => page = value),
                );
              },
            ),
          ),
        ),
      ),
    );
    expect(find.text('Levels'), findsOneWidget);
    await tester.tap(find.text('Classes'));
    await tester.pumpAndSettle();
    expect(find.text('Levels'), findsNothing);
    await tester.tap(find.text('Classes'));
    await tester.pumpAndSettle();
    expect(find.text('Levels'), findsOneWidget);
    update(() => page = 'teacherDayOff');
    await tester.pumpAndSettle();
    expect(find.text('Levels'), findsNothing);
    expect(find.text('Teacher Day Off'), findsOneWidget);
    await tester.ensureVisible(find.text('Time Table').first);
    await tester.tap(find.text('Time Table').first);
    await tester.pumpAndSettle();
    expect(find.text('Teacher Day Off'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
