typedef LoginCredentials = ({String email, String password});

abstract interface class LoginCredentialStore {
  Future<LoginCredentials?> read();
  Future<void> save(LoginCredentials credentials);
  Future<void> clear();
}
