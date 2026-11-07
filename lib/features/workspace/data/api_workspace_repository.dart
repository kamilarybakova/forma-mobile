import '../../../core/network/api_client.dart';
import '../domain/brief.dart';
import '../domain/workspace_repository.dart';

class ApiWorkspaceRepository implements WorkspaceRepository {
  final ApiClient api;
  ApiWorkspaceRepository(this.api);
  @override
  Future<List<Brief>> list() async =>
      (await api.list('briefs/')).map(Brief.new).toList();
  @override
  Future<Brief> create(String title, String area) async => Brief(
    Map<String, dynamic>.from(
      await api.request(
            'briefs/',
            method: 'POST',
            data: {
              'title': title,
              'area': area,
              'answers': <String, dynamic>{},
              'status': 'draft',
            },
          )
          as Map,
    ),
  );
  @override
  Future<Brief> save(Brief brief, RecordData changes) async => Brief(
    Map<String, dynamic>.from(
      await api.request(
            'briefs/${brief.id}/',
            method: 'PATCH',
            data: brief.patch(changes),
          )
          as Map,
    ),
  );
  @override
  Future<Brief> invite(Brief brief, String action) async => Brief(
    Map<String, dynamic>.from(
      (await api.request(
            'briefs/${brief.id}/invite/',
            method: 'POST',
            data: {'action': action, 'version': brief.version},
          ))['brief']
          as Map,
    ),
  );
  @override
  Future<List<RecordData>> files(String id, int stage) =>
      api.list('briefs/$id/files/?stage=$stage');
  @override
  Future<Brief> visualizations(Brief brief, String action) async => Brief(
    Map<String, dynamic>.from(
      await api.request(
            'briefs/${brief.id}/visualizations/',
            method: 'POST',
            data: {'action': action, 'version': brief.version},
          )
          as Map,
    ),
  );
  @override
  Future<void> toPortfolio(String id) async {
    await api.request('briefs/$id/portfolio-project/', method: 'POST');
  }

  @override
  Future<void> annotate(RecordData file, String notes) async {
    await api.request(
      'brief-files/${file['id']}/',
      method: 'PATCH',
      data: {'notes': notes, 'version': file['version']},
    );
  }
}
