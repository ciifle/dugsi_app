import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:kobac/services/students_service.dart';
import 'package:kobac/services/classes_service.dart';

Future<Uint8List> buildStudentLetterPdf({
  required StudentModel student,
  ClassModel? classModel,
  String? schoolName,
}) async {
  final pdf = pw.Document();
  final now = DateTime.now();
  final dateStr = '${now.day.toString().padLeft(2, "0")}/${now.month.toString().padLeft(2, "0")}/${now.year}';
  final className = classModel?.name ?? student.classDisplayName;
  final school = schoolName ?? student.schoolName ?? 'School';

  pw.Widget row(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 130,
            child: pw.Text(label, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
          ),
          pw.Expanded(child: pw.Text(value.isEmpty ? '—' : value, style: const pw.TextStyle(fontSize: 11))),
        ],
      ),
    );
  }

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(school, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text('Date: $dateStr', style: const pw.TextStyle(fontSize: 11)),
          pw.SizedBox(height: 24),
          pw.Text('STUDENT PROFILE LETTER', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.Divider(),
          pw.SizedBox(height: 16),
          row('Student Name', student.studentName),
          row('EMIS Number', student.emisNumber.trim().isEmpty ? '—' : student.emisNumber),
          row('Class', className),
          row("Mother's name", student.motherName ?? '—'),
          row('Guardian', student.guardianName ?? '—'),
          row('Birth date', student.birthDate ?? '—'),
          row('Sex', student.sex ?? '—'),
          row('Telephone', student.telephone ?? '—'),
          row('Birth place', student.birthPlace ?? '—'),
          row('Nationality', student.nationality ?? '—'),
          row('State / Region', student.studentState ?? '—'),
          row('District', student.studentDistrict ?? '—'),
          row('Village', student.studentVillage ?? '—'),
          row('Refugee status', student.refugeeStatus ?? '—'),
          row('Orphan status', student.orphanStatus ?? '—'),
          row('Disability', student.disabilityStatus ?? '—'),
          pw.Spacer(),
          pw.SizedBox(height: 32),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(width: 120, height: 1, color: PdfColors.grey800),
                  pw.SizedBox(height: 4),
                  pw.Text('Signature', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                ],
              ),
              pw.Container(
                width: 80,
                height: 60,
                decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
                child: pw.Center(child: pw.Text('Stamp', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600))),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  return pdf.save();
}
