import '../../../core/network/api_client.dart';
import '../domain/auth_repository.dart';

class ApiAuthRepository implements AuthRepository {
  final ApiClient api;
  ApiAuthRepository(this.api);
  @override
  Future<bool> restore() => api.restore();
  @override
  Future<void> login(String email, String password) async => api.accept(
    Map<String, dynamic>.from(
      await api.request(
            'auth/login/',
            method: 'POST',
            data: {'email': email, 'password': password},
            authenticated: false,
          )
          as Map,
    ),
  );
  @override
  Future<void> register(String studio, String email, String password) async =>
      api.accept(
        Map<String, dynamic>.from(
          await api.request(
                'auth/register/',
                method: 'POST',
                data: {
                  'studio_name': studio,
                  'email': email,
                  'password': password,
                },
                authenticated: false,
              )
              as Map,
        ),
      );
  @override
  Future<void> recover(String email) async {
    await api.request(
      'auth/forgot-password/',
      method: 'POST',
      data: {'email': email},
      authenticated: false,
    );
  }

  @override
  Future<void> logout() async {
    try {
      if (api.tokens != null) {
        await api.request(
          'auth/logout/',
          method: 'POST',
          data: {'refresh': api.tokens!['refresh']},
          authenticated: false,
        );
      }
    } finally {
      await api.clear();
    }
  }
}
