typedef StudioData = Map<String, dynamic>;

abstract interface class StudioRepository {
  Future<StudioData> load();
  Future<StudioData> save(StudioData data);
  Future<StudioData> storage();
  Future<List<StudioData>> templates();
  Future<void> saveUser(StudioData data);
  Future<StudioData> user();
}
