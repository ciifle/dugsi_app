import 'dart:typed_data';
import 'package:http/http.dart' as http;

Future<ByteData> fontData() async => ByteData.sublistView(
  (await http.get(Uri.base.resolve('/support/roboto-regular.ttf'))).bodyBytes,
);
