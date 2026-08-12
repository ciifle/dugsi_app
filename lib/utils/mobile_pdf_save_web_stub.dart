import 'dart:typed_data';

import 'package:kobac/utils/mobile_pdf_save_result.dart';

Future<MobileSaveResult> saveMobilePdf({
  required Uint8List bytes,
  required String suggestedFilename,
}) async => const MobileSaveResult(status: MobileSaveStatus.failed);
