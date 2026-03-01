import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:kobac/services/students_service.dart';
import 'package:kobac/services/classes_service.dart';

/// Builds a PDF class list letter (class name + table of students).
/// [students] must be the exact list displayed on ClassDetails (passed from screen state).
Future<Uint8List> buildClassLetterPdf({
  required ClassModel classModel,
  required List<StudentModel> students,
  String? schoolName,
}) async {
  if (kDebugMode) {
    debugPrint('[PDF] received students=${students.length}');
  }
  final pdf = pw.Document();
  final now = DateTime.now();
  final dateStr = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
  final school = schoolName ?? 'School';

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(school, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text('Date: $dateStr', style: const pw.TextStyle(fontSize: 11)),
          pw.SizedBox(height: 24),
          pw.Text('CLASS LIST: ${classModel.name}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 16),
          pw.Table(
    border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
    columnWidths: {
      0: const pw.FlexColumnWidth(1.2),
      1: const pw.FlexColumnWidth(3),
      2: const pw.FlexColumnWidth(2.5),
    },
    children: [
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey300),
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text('No', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text('Student Name', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text('EMIS Number', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
          ),
        ],
      ),
      ...students.asMap().entries.map((e) {
        final i = e.key + 1;
        final s = e.value;
        return pw.TableRow(
          children: [
            pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('$i', style: const pw.TextStyle(fontSize: 10))),
            pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(s.studentName, style: const pw.TextStyle(fontSize: 10))),
            pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(s.emisNumber, style: const pw.TextStyle(fontSize: 10))),
          ],
        );
      }),
    ],
          ),
          pw.SizedBox(height: 12),
          pw.Text('Total: ${students.length} student${students.length == 1 ? '' : 's'}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.Spacer(),
          pw.SizedBox(height: 40),
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
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
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
        ],
      ),
    ),
  );

  return pdf.save();
}
