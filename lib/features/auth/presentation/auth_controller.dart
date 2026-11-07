import '../../../core/widgets/async_controller.dart';
import '../domain/auth_repository.dart';
import '../domain/login_credential_store.dart';

class AuthController extends AsyncController {
  final AuthRepository repository;
  final LoginCredentialStore? credentialStore;
  LoginCredentials? rememberedLogin;
  bool credentialSaveFailed = false;
  bool authenticated = false;
  bool ready = false;
  AuthController(this.repository, {this.credentialStore});

  Future<void> restore() async {
    await run(() async {
      authenticated = await repository.restore();
    });
    if (error != null) {
      error =
          'Не удалось прочитать сохранённую сессию. Попробуйте войти снова.';
    }
    try {
      rememberedLogin = await credentialStore?.read();
    } catch (_) {
      // A storage error must not prevent restoring a session or signing in.
      rememberedLogin = null;
    }
    ready = true;
    notifyListeners();
  }

  Future<bool> submit(
    String email,
    String password, {
    String? studio,
    bool remember = false,
  }) => run(() async {
    credentialSaveFailed = false;
    if (studio == null) {
      await repository.login(email, password);
      final store = credentialStore;
      if (remember && store != null) {
        try {
          final credentials = (email: email, password: password);
          await store.save(credentials);
          rememberedLogin = credentials;
        } catch (_) {
          credentialSaveFailed = true;
        }
      }
    } else {
      await repository.register(studio, email, password);
    }
    authenticated = true;
  });

  Future<bool> forgetLogin() => run(() async {
    try {
      await credentialStore?.clear();
      rememberedLogin = null;
    } catch (_) {
      throw StateError('Не удалось удалить сохранённый логин и пароль.');
    }
  });

  void expire() {
    authenticated = false;
    notifyListeners();
  }

  Future<void> logout() async {
    await run(repository.logout);
    authenticated = false;
    notifyListeners();
  }
}
