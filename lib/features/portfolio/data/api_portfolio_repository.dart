import '../../../core/network/api_client.dart';
import '../domain/portfolio_repository.dart';

class ApiPortfolioRepository implements PortfolioRepository {
  final ApiClient api;
  ApiPortfolioRepository(this.api);
  @override
  Future<List<PortfolioData>> list() async {
    final result = <PortfolioData>[];
    for (var page = 1; ; page++) {
      final data = await api.get('projects/?page=$page&page_size=50');
      result.addAll(
        (data['results'] as List).map(
          (e) => Map<String, dynamic>.from(e as Map),
        ),
      );
      if (result.length >= (data['count'] as int)) return result;
    }
  }

  @override
  Future<PortfolioData> save(PortfolioData data, {String? id}) async =>
      Map<String, dynamic>.from(
        await api.request(
              id == null ? 'projects/' : 'projects/$id/',
              method: id == null ? 'POST' : 'PATCH',
              data: data,
            )
            as Map,
      );
  @override
  Future<void> delete(String id) async {
    await api.request('projects/$id/', method: 'DELETE');
  }

  @override
  Future<void> deleteAsset(String kind, String id) async {
    await api.request('$kind/$id/', method: 'DELETE');
  }

  @override
  Future<void> updateAsset(String kind, String id, PortfolioData data) async {
    await api.request('$kind/$id/', method: 'PATCH', data: data);
  }
}
