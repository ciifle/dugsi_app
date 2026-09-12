if (process.argv.includes('--cleanup')) {
  const fs = require('fs');
  for (const file of ["build/desktop_ui_check_test.dart","build/desktop_ui_check/exam_hall_management_pages.dart","build/desktop_ui_check/teacher_day_off_page.dart","build/desktop_ui_check/admin_timetable_screen.dart"]) { if (fs.existsSync(file)) fs.unlinkSync(file); }
  process.exit(0);
}
// Generates test-only copies with the web platform guard enabled on the native
// renderer. Production platform guards are never modified by this check.
const fs=require('fs');
const dir='build/desktop_ui_check';fs.mkdirSync(dir,{recursive:true});
for(const name of ['exam_hall_management_pages','teacher_day_off_page','admin_timetable_screen']) {
 let source=fs.readFileSync(`lib/school_admin/pages/${name}.dart`,'utf8');
 source=source.replaceAll('isDesktopWebAdminLayout(context)','(MediaQuery.sizeOf(context).width >= 1024)');
 source=source.replaceAll('isEmbeddedDesktopAdminBody(context, widget.embedBodyOnly)','(widget.embedBodyOnly && MediaQuery.sizeOf(context).width >= 1024)');
 fs.writeFileSync(`${dir}/${name}.dart`,source);
}
let test=fs.readFileSync('test/web_admin_desktop_test.dart','utf8');
for(const name of ['exam_hall_management_pages','teacher_day_off_page','admin_timetable_screen']) {
 test=test.replace(`package:kobac/school_admin/pages/${name}.dart`,`desktop_ui_check/${name}.dart`);
}
test=test.replaceAll("'support/font_", "'../test/support/font_").replaceAll('kIsWeb','true');
test=test.replace('          await tester.pumpWidget(const SizedBox());',`          if (width == 1366 || width == 1024) {
            await expectLater(find.byType(MaterialApp), matchesGoldenFile('desktop_ui_check/' + entry.key + '_' + width.toString() + '.png'));
          }
          await tester.pumpWidget(const SizedBox());`);
fs.writeFileSync('build/desktop_ui_check_test.dart',test);
