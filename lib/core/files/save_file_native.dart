import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

Future<void> saveAndOpen(Uint8List bytes, String name) async {
  final directory = await getTemporaryDirectory();
  final safe = name.replaceAll(RegExp(r'[^a-zA-Zа-яА-ЯёЁ0-9._-]'), '_');
  final file = File('${directory.path}/$safe');
  await file.writeAsBytes(bytes);
  final result = await OpenFilex.open(file.path);
  if (result.type != ResultType.done) {
    throw Exception('Не удалось открыть файл: ${result.message}');
  }
}
