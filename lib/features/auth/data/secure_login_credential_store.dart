import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../domain/login_credential_store.dart';

class SecureLoginCredentialStore implements LoginCredentialStore {
  final FlutterSecureStorage storage;
  static const _key = 'planiz.remembered_login.v1';

  SecureLoginCredentialStore(this.storage);

  @override
  Future<LoginCredentials?> read() async {
    final value = await storage.read(key: _key);
    if (value == null) return null;
    return switch (jsonDecode(value)) {
      {'email': final String email, 'password': final String password} => (
        email: email,
        password: password,
      ),
      _ => null,
    };
  }

  @override
  Future<void> save(LoginCredentials credentials) => storage.write(
    key: _key,
    value: jsonEncode({
      'email': credentials.email,
      'password': credentials.password,
    }),
  );

  @override
  Future<void> clear() => storage.delete(key: _key);
}
