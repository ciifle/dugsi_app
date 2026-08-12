import 'dart:typed_data';
import 'package:printing/printing.dart';

Future<bool> previewStudentPdf(Uint8List bytes, String filename) async {
  return Printing.layoutPdf(name: filename, onLayout: (_) async => bytes);
}

Future<void> downloadStudentPdf(Uint8List bytes, String filename) async {
  throw UnsupportedError('Mobile downloads must use the save-document picker.');
}
