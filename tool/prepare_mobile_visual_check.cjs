if (process.argv.includes('--cleanup')) {
  const fs = require('fs');
  for (const file of ["build/mobile_visual_comparison_test.dart","build/mobile_ui_baseline/teacher_day_off_page.dart","build/mobile_ui_baseline/admin_timetable_screen.dart","build/mobile_ui_baseline/management.dart"]) { if (fs.existsSync(file)) fs.unlinkSync(file); }
  process.exit(0);
}
const fs = require('fs');
const cp = require('child_process');
const out = 'build/mobile_ui_baseline';
fs.mkdirSync(out, {recursive: true});
for (const name of ['teacher_day_off_page', 'admin_timetable_screen']) {
  fs.writeFileSync(`${out}/${name}.dart`, cp.execFileSync('git', ['show', `HEAD:lib/school_admin/pages/${name}.dart`], {encoding:'utf8'}));
}
let management = fs.readFileSync('lib/school_admin/pages/exam_hall_management_pages.dart','utf8');
management = management.replace("    if (isDesktopWebAdminLayout(context)) return _webLevels();", '').replace("    if (isDesktopWebAdminLayout(context)) return _webShifts();", '');
fs.writeFileSync(`${out}/management.dart`, management);
const check = `import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import '../test/web_admin_desktop_test.dart' as harness;
import '../test/support/font_io.dart';
import '../lib/school_admin/pages/teacher_day_off_page.dart' as current_days;
import '../lib/school_admin/pages/admin_timetable_screen.dart' as current_time;
import '../lib/school_admin/pages/exam_hall_management_pages.dart' as current_management;
import 'mobile_ui_baseline/teacher_day_off_page.dart' as old_days;
import 'mobile_ui_baseline/admin_timetable_screen.dart' as old_time;
import 'mobile_ui_baseline/management.dart' as old_management;
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async { await (FontLoader('Roboto')..addFont(fontData())).load(); await (FontLoader('MaterialIcons')..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load(); });
  for(final entry in <String,List<Widget>>{
    'teacher_days': [const old_days.TeacherDayOffPage(embedBodyOnly:true), const current_days.TeacherDayOffPage(embedBodyOnly:true)],
    'timetable': [const old_time.AdminTimetableScreen(embedBodyOnly:true), const current_time.AdminTimetableScreen(embedBodyOnly:true)],
    'levels': [const old_management.LevelsPage(),const current_management.LevelsPage()],
    'shifts': [const old_management.ShiftsPage(),const current_management.ShiftsPage()],
  }.entries) {
    testWidgets(entry.key + ' mobile pixels remain unchanged', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390,844);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.binding.setSurfaceSize(const Size(390,844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final captures = <List<int>>[];
      await http.runWithClient(() async {
        for (var i=0;i<2;i++) {
          await tester.pumpWidget(RepaintBoundary(key:const ValueKey('capture'), child:harness.host(entry.value[i],390)));
          await tester.pumpAndSettle();
          expect(tester.takeException(),isNull);
          await tester.runAsync(() async {
          final image = await captureImage(tester.element(find.byKey(const ValueKey('capture'))));
          final data = await image.toByteData(format:ImageByteFormat.png);
          image.dispose();
          captures.add(data!.buffer.asUint8List());
          final file = File('build/mobile_ui_baseline/' + entry.key + (i==0 ? '_before.png' : '_after.png'));
          await file.writeAsBytes(captures.last);
          });
          await tester.pumpWidget(const SizedBox());
        }
      }, () => MockClient(harness.fixture));
      expect(captures.last, orderedEquals(captures.first));
    });
  }
}
`;
fs.writeFileSync('build/mobile_visual_comparison_test.dart', "import 'dart:ui' show ImageByteFormat;\n" + check);
