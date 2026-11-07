import 'brief.dart';

abstract interface class WorkspaceRepository {
  Future<List<Brief>> list();
  Future<Brief> create(String title, String area);
  Future<Brief> save(Brief brief, RecordData changes);
  Future<Brief> invite(Brief brief, String action);
  Future<List<RecordData>> files(String id, int stage);
  Future<Brief> visualizations(Brief brief, String action);
  Future<void> toPortfolio(String id);
  Future<void> annotate(RecordData file, String notes);
}
