import 'dart:typed_data';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

Future<void> saveAndOpen(Uint8List bytes, String name) async {
  final blob = web.Blob([bytes.toJS].toJS);
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = name;
  anchor.click();
  Future.delayed(
    const Duration(seconds: 30),
    () => web.URL.revokeObjectURL(url),
  );
}
