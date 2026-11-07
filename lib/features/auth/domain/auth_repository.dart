abstract interface class AuthRepository {
  Future<bool> restore();
  Future<void> login(String email, String password);
  Future<void> register(String studio, String email, String password);
  Future<void> recover(String email);
  Future<void> logout();
}
