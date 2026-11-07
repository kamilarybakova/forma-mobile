import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import '../storage/token_store.dart';

typedef Json = Map<String, dynamic>;

class ApiFailure implements Exception {
  final String message;
  final int? status;
  const ApiFailure(this.message, [this.status]);
  @override
  String toString() => message;
}

class ApiClient {
  final Dio dio;
  final TokenStore store;
  Json? tokens;
  Future<void>? _refreshing;
  void Function()? onSessionExpired;
  ApiClient(this.dio, this.store) {
    if (kDebugMode) {
      dio.interceptors.add(_ApiLogInterceptor());
    }
  }
  Future<bool> restore() async {
    tokens = await store.read();
    return tokens != null;
  }

  Future<void> accept(Json value) async {
    final pair = <String, dynamic>{
      'access': value['access'],
      'refresh': value['refresh'],
    };
    await store.write(pair);
    tokens = pair;
  }

  Future<void> clear() async {
    tokens = null;
    await store.clear();
  }

  Future<void> _refresh() async {
    if (_refreshing != null) return _refreshing!;
    final pending = _rotate();
    _refreshing = pending;
    try {
      await pending;
    } finally {
      _refreshing = null;
    }
  }

  Future<void> _rotate() async {
    try {
      final result = await dio.post<Json>(
        'auth/refresh/',
        data: {'refresh': tokens?['refresh']},
      );
      await accept(result.data!);
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        await clear();
        onSessionExpired?.call();
      }
      rethrow;
    }
  }

  Future<dynamic> request(
    String path, {
    String method = 'GET',
    dynamic data,
    bool authenticated = true,
    bool binary = false,
  }) async {
    final previousAccess = tokens?['access'];
    Future<Response<dynamic>> send() => dio.request<dynamic>(
      path,
      data: data is FormData ? data.clone() : data,
      options: Options(
        method: method,
        responseType: binary ? ResponseType.bytes : ResponseType.json,
        headers: {
          if (authenticated && tokens != null)
            'Authorization': 'Bearer ${tokens!['access']}',
        },
      ),
    );
    try {
      try {
        return (await send()).data;
      } on DioException catch (error) {
        if (!authenticated ||
            error.response?.statusCode != 401 ||
            tokens == null) {
          rethrow;
        }
        // Concurrent failures share one rotation. Late failures reuse its result.
        if (tokens?['access'] == previousAccess) await _refresh();
        try {
          return (await send()).data;
        } on DioException catch (retry) {
          if (retry.response?.statusCode == 401) {
            await clear();
            onSessionExpired?.call();
          }
          rethrow;
        }
      }
    } on DioException catch (error) {
      final detail = error.response?.data;
      throw ApiFailure(
        detail is Map && detail['detail'] is String
            ? detail['detail'] as String
            : error.response?.statusCode == 422
            ? 'Проверьте поля формы. Изменения не сохранены.'
            : error.response?.statusCode == 409
            ? 'Данные изменились на другом устройстве. Обновите страницу.'
            : error.response?.statusCode == 401
            ? 'Сессия закончилась. Войдите снова.'
            : error.response == null
            ? 'Нет связи с сервером. Проверьте интернет и повторите.'
            : 'Не удалось выполнить действие. Попробуйте ещё раз.',
        error.response?.statusCode,
      );
    }
  }

  Future<Json> get(String path) async =>
      Map<String, dynamic>.from(await request(path) as Map);
  Future<List<Json>> list(String path) async =>
      ((await get(path))['results'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
  Future<Uint8List> bytes(String path) async => Uint8List.fromList(
    (await request(path, binary: true) as List).cast<int>(),
  );
}

class _ApiLogInterceptor extends Interceptor {
  static const _requestKey = 'planiz.apiLog';
  static const _previewLimit = 1500;
  static final _privateKey = RegExp(
    r'password|passwd|token|secret|cookie|authorization|api.?key|email|^(access|refresh|input|ctx)$',
    caseSensitive: false,
  );
  int _nextId = 0;

  Object? _redact(Object? value) => switch (value) {
    Map() => {
      for (final entry in value.entries)
        entry.key.toString(): _privateKey.hasMatch(entry.key.toString())
            ? '[redacted]'
            : _redact(entry.value),
    },
    List() => value.map(_redact).toList(),
    String() || num() || bool() || null => value,
    _ => '[${value.runtimeType}]',
  };

  String _clip(String value) => value.length <= _previewLimit
      ? value
      : '${value.substring(0, _previewLimit)}… [truncated]';

  String _body(Object? data) {
    if (data == null) return '(empty)';
    if (data is Uint8List || data is List<int>) {
      return '(binary, ${(data as List<int>).length} bytes)';
    }
    if (data is FormData) {
      return _clip(
        jsonEncode({
          'fields': [
            for (final field in data.fields) _redact({field.key: field.value}),
          ],
          'files': [
            for (final file in data.files)
              {'field': file.key, 'bytes': file.value.length},
          ],
        }),
      );
    }
    if (data is String) {
      try {
        data = jsonDecode(data);
      } on FormatException {
        return '(non-JSON text, ${(data as String).length} characters)';
      }
    }
    return _clip(jsonEncode(_redact(data)));
  }

  String _response(Response<dynamic> response) {
    final contentType =
        response.headers[Headers.contentTypeHeader]?.firstOrNull ?? 'unknown';
    return 'HTTP ${response.statusCode} | content-type: $contentType'
        '\n  response: ${_body(response.data)}';
  }

  String _completed(RequestOptions options) {
    final log =
        options.extra.remove(_requestKey) as ({int id, Stopwatch timer})?;
    return log == null
        ? '${options.method} ${options.uri.path}'
        : '#${log.id} ${options.method} ${options.uri.path} '
              '(${log.timer.elapsedMilliseconds} ms)';
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final id = ++_nextId;
    options.extra[_requestKey] = (id: id, timer: Stopwatch()..start());
    final uri = options.uri;
    // Print query values separately so credential keys can be masked.
    final address =
        uri.host.isNotEmpty && (uri.isScheme('http') || uri.isScheme('https'))
        ? '${uri.origin}${uri.path}'
        : uri.path;
    debugPrint(
      '[API] → #$id ${options.method} $address'
      '\n  content-type: ${options.contentType ?? 'none'}'
      ' | expects: ${options.responseType.name}'
      '\n  query: ${_clip(jsonEncode(_redact(uri.queryParametersAll)))}'
      '\n  request: ${_body(options.data)}',
    );
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    debugPrint(
      '[API] ← ${_completed(response.requestOptions)} ${_response(response)}',
    );
    handler.next(response);
  }

  @override
  void onError(DioException error, ErrorInterceptorHandler handler) {
    final response = error.response;
    final cause = switch (error.type) {
      DioExceptionType.connectionError ||
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => error.error ?? error.message,
      _ => null,
    };
    debugPrint(
      '[API] ! ${_completed(error.requestOptions)} ${error.type.name}'
      '\n  ${response == null ? 'HTTP response: none' : _response(response)}'
      '${cause == null ? '' : '\n  cause: ${_clip(cause.toString())}'}',
    );
    handler.next(error);
  }
}
