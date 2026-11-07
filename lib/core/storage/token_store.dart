import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class TokenStore {
  Future<Map<String, dynamic>?> read();
  Future<void> write(Map<String, dynamic> tokens);
  Future<void> clear();
}

class SecureTokenStore implements TokenStore {
  final FlutterSecureStorage storage;
  SecureTokenStore(this.storage);
  static const key = 'planiz.session.v1';
  @override
  Future<Map<String, dynamic>?> read() async {
    final value = await storage.read(key: key);
    return value == null ? null : jsonDecode(value) as Map<String, dynamic>;
  }

  @override
  Future<void> write(Map<String, dynamic> tokens) =>
      storage.write(key: key, value: jsonEncode(tokens));
  @override
  Future<void> clear() => storage.delete(key: key);
}
