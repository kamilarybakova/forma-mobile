import '../../../core/network/api_client.dart';
import '../domain/studio_repository.dart';

class ApiStudioRepository implements StudioRepository {
  final ApiClient api;
  ApiStudioRepository(this.api);
  @override
  Future<StudioData> load() => api.get('studio/');
  @override
  Future<StudioData> save(StudioData data) async => Map<String, dynamic>.from(
    await api.request('studio/', method: 'PATCH', data: data) as Map,
  );
  @override
  Future<StudioData> storage() => api.get('studio/storage/');
  @override
  Future<List<StudioData>> templates() => api.list('templates/');
  @override
  Future<StudioData> user() => api.get('auth/me/');
  @override
  Future<void> saveUser(StudioData data) async {
    await api.request('auth/me/', method: 'PATCH', data: data);
  }
}
