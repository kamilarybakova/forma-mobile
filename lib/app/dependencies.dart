import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import '../core/network/api_client.dart';
import '../core/storage/token_store.dart';
import '../features/auth/domain/auth_repository.dart';
import '../features/auth/data/api_auth_repository.dart';
import '../features/auth/data/secure_login_credential_store.dart';
import '../features/auth/domain/login_credential_store.dart';
import '../features/auth/presentation/auth_controller.dart';
import '../features/workspace/domain/workspace_repository.dart';
import '../features/workspace/data/api_workspace_repository.dart';
import '../features/workspace/presentation/workspace_controller.dart';
import '../features/portfolio/domain/portfolio_repository.dart';
import '../features/portfolio/data/api_portfolio_repository.dart';
import '../features/portfolio/presentation/portfolio_controller.dart';
import '../features/studio/domain/studio_repository.dart';
import '../features/studio/data/api_studio_repository.dart';
import '../features/studio/presentation/studio_controller.dart';
import '../features/billing/domain/billing_repository.dart';
import '../features/billing/data/api_billing_repository.dart';
import '../features/billing/presentation/billing_controller.dart';
import '../features/specifications/domain/specification_repository.dart';
import '../features/specifications/data/api_specification_repository.dart';
import '../core/files/file_service.dart';

final di = GetIt.instance;
const apiUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://api.planiz.app/api/v1/',
);
const siteUrl = String.fromEnvironment(
  'SITE_BASE_URL',
  defaultValue: 'http://127.0.0.1:5173',
);
void configureDependencies() {
  di.registerSingleton(
    const FlutterSecureStorage(
      mOptions: MacOsOptions(usesDataProtectionKeychain: false),
    ),
  );
  di.registerLazySingleton<TokenStore>(() => SecureTokenStore(di()));
  if (!kIsWeb) {
    di.registerLazySingleton<LoginCredentialStore>(
      () => SecureLoginCredentialStore(di()),
    );
  }
  di.registerLazySingleton<ApiClient>(
    () => ApiClient(
      Dio(
        BaseOptions(
          baseUrl: apiUrl.endsWith('/') ? apiUrl : '$apiUrl/',
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 60),
          sendTimeout: const Duration(seconds: 60),
        ),
      ),
      di(),
    ),
  );
  di.registerLazySingleton<AuthRepository>(() => ApiAuthRepository(di()));
  di.registerLazySingleton<AuthController>(
    () => AuthController(di(), credentialStore: kIsWeb ? null : di()),
  );
  di.registerLazySingleton<WorkspaceRepository>(
    () => ApiWorkspaceRepository(di()),
  );
  di.registerFactory(() => WorkspaceController(di()));
  di.registerLazySingleton<PortfolioRepository>(
    () => ApiPortfolioRepository(di()),
  );
  di.registerFactory(() => PortfolioController(di()));
  di.registerLazySingleton<StudioRepository>(() => ApiStudioRepository(di()));
  di.registerFactory(() => StudioController(di()));
  di.registerLazySingleton<BillingRepository>(() => ApiBillingRepository(di()));
  di.registerFactory(() => BillingController(di()));
  di.registerLazySingleton<SpecificationRepository>(
    () => ApiSpecificationRepository(di()),
  );
  di.registerLazySingleton<FileService>(() => FileService(di()));
  di<ApiClient>().onSessionExpired = di<AuthController>().expire;
}
