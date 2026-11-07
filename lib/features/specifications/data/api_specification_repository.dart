import '../../../core/network/api_client.dart';
import '../domain/specification_repository.dart';

class ApiSpecificationRepository implements SpecificationRepository {
  final ApiClient api;
  ApiSpecificationRepository(this.api);
  @override
  Future<List<SpecificationData>> list(String briefId) =>
      api.list('briefs/$briefId/specifications/');
  @override
  Future<SpecificationData> save(
    String briefId,
    SpecificationData data, {
    String? id,
  }) async => Map<String, dynamic>.from(
    await api.request(
          id == null
              ? 'briefs/$briefId/specifications/'
              : 'specifications/$id/',
          method: id == null ? 'POST' : 'PATCH',
          data: data,
        )
        as Map,
  );
  @override
  Future<void> delete(String id, int version) async {
    await api.request('specifications/$id/?version=$version', method: 'DELETE');
  }

  @override
  Future<void> deleteItem(String id, String itemId, int version) async {
    await api.request(
      'specifications/$id/items/$itemId/?version=$version',
      method: 'DELETE',
    );
  }
}
