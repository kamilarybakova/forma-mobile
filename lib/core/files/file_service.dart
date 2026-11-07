import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import '../network/api_client.dart';
import 'save_file.dart';

class FileService {
  final ApiClient api;
  FileService(this.api);
  Future<PlatformFile?> pick({bool images = false}) async {
    final selection = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: images
          ? ['jpg', 'jpeg', 'png', 'webp']
          : ['pdf', 'jpg', 'jpeg', 'png', 'webp', 'dwg', 'dxf'],
    );
    if (selection.isEmpty) return null;
    final file = selection.single;
    if ((await file.length() ?? 0) > 20 * 1024 * 1024) {
      throw const ApiFailure('Файл больше 20 МБ.');
    }
    return file;
  }

  Future<void> upload(
    String path,
    PlatformFile file, {
    Map<String, dynamic> fields = const {},
    String field = 'file',
    String method = 'POST',
  }) async {
    await api.request(
      path,
      method: method,
      data: FormData.fromMap({
        ...fields,
        field: MultipartFile.fromBytes(
          await file.readAsBytes(),
          filename: file.name,
          contentType: MediaType.parse(
            lookupMimeType(file.name) ?? 'application/octet-stream',
          ),
        ),
      }),
    );
  }

  Future<void> form(
    String path,
    Map<String, dynamic> fields, {
    String method = 'POST',
  }) async {
    await api.request(path, method: method, data: FormData.fromMap(fields));
  }

  Future<Uint8List> image(String path) => api.bytes(path);
  Future<void> open(String path, String name) async =>
      saveAndOpen(await api.bytes(path), name);
}
