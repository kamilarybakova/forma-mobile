import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_test/flutter_test.dart';
import 'package:forma_mobile/core/network/api_client.dart';
import 'package:forma_mobile/core/storage/token_store.dart';

class MemoryStore implements TokenStore {
  Json? value;
  @override
  Future<Json?> read() async => value;
  @override
  Future<void> write(Json tokens) async {
    value = tokens;
  }

  @override
  Future<void> clear() async {
    value = null;
  }
}

class TestAdapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions) handler;
  TestAdapter(this.handler);
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancelFuture,
  ) => handler(options);
  @override
  void close({bool force = false}) {}
}

ResponseBody response(dynamic data, [int status = 200]) =>
    ResponseBody.fromString(
      jsonEncode(data),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
void main() {
  test(
    'debug logs show request and response details without credentials',
    () async {
      final previousPrint = debugPrint;
      final logs = <String>[];
      debugPrint = (message, {wrapWidth}) {
        if (message != null) logs.add(message);
      };
      addTearDown(() => debugPrint = previousPrint);

      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8001/api/v1/'));
      final api = ApiClient(dio, MemoryStore());
      await api.accept({
        'access': 'private-header',
        'refresh': 'private-refresh',
      });
      dio.httpClientAdapter = TestAdapter((options) async {
        if (options.path == 'offline/') {
          throw DioException.connectionError(
            requestOptions: options,
            reason: 'Connection refused',
          );
        }
        return response({
          'detail': [
            {'msg': 'Invalid credentials', 'input': 'private-password'},
          ],
          'access_token': 'private-token',
        }, 422);
      });
      await expectLater(
        api.request(
          'auth/login/?page=1&token=private-query',
          method: 'POST',
          data: {'email': 'private-email', 'password': 'private-password'},
        ),
        throwsA(isA<ApiFailure>()),
      );
      await expectLater(api.get('offline/'), throwsA(isA<ApiFailure>()));

      final log = logs.join('\n');
      expect(log, contains('POST http://localhost:8001/api/v1/auth/login/'));
      expect(log, contains('"page":["1"]'));
      expect(log, contains('"password":"[redacted]"'));
      expect(log, contains('HTTP 422'));
      expect(log, contains('Invalid credentials'));
      expect(log, contains('HTTP response: none'));
      expect(log, contains('Connection refused'));
      expect(log, isNot(contains('private-')));
    },
  );

  test('parallel 401 responses rotate once and persist the new pair', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/v1/'));
    final store = MemoryStore();
    final api = ApiClient(dio, store);
    await api.accept({'access': 'old', 'refresh': 'refresh-1'});
    var refreshes = 0, requests = 0;
    dio.httpClientAdapter = TestAdapter((o) async {
      if (o.path == 'auth/refresh/') {
        refreshes++;
        expect(o.data, {'refresh': 'refresh-1'});
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return response({'access': 'new', 'refresh': 'refresh-2'});
      }
      requests++;
      if (o.headers['Authorization'] == 'Bearer old') {
        return response({'detail': 'expired'}, 401);
      }
      expect(o.headers['Authorization'], 'Bearer new');
      return response({'ok': true});
    });
    final result = await Future.wait([api.get('studio/'), api.get('briefs/')]);
    expect(refreshes, 1);
    expect(requests, 4);
    expect(result.every((e) => e['ok'] == true), isTrue);
    expect(store.value, {'access': 'new', 'refresh': 'refresh-2'});
  });
  test(
    'revoked refresh clears session; connection failure retains it',
    () async {
      for (final status in [401, 503]) {
        final dio = Dio(BaseOptions(baseUrl: 'https://example.test/'));
        final store = MemoryStore();
        final api = ApiClient(dio, store);
        await api.accept({'access': 'old', 'refresh': 'refresh'});
        var expired = false;
        api.onSessionExpired = () => expired = true;
        dio.httpClientAdapter = TestAdapter(
          (o) async => response({
            'detail': 'unavailable',
          }, o.path == 'auth/refresh/' ? status : 401),
        );
        await expectLater(api.get('studio/'), throwsA(isA<ApiFailure>()));
        expect(expired, status == 401);
        expect(store.value == null, status == 401);
      }
    },
  );
  test('anonymous login failures never attempt refresh', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test/'));
    final api = ApiClient(dio, MemoryStore());
    var calls = 0;
    dio.httpClientAdapter = TestAdapter((o) async {
      calls++;
      return response({'detail': 'Неверный пароль'}, 401);
    });
    await expectLater(
      api.request(
        'auth/login/',
        method: 'POST',
        data: {},
        authenticated: false,
      ),
      throwsA(isA<ApiFailure>()),
    );
    expect(calls, 1);
  });
}
