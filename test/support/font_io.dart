import 'dart:io';
import 'dart:typed_data';

Future<ByteData> fontData() async => ByteData.sublistView(
  await File('test/support/roboto-regular.ttf').readAsBytes(),
);
