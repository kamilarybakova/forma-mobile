typedef PortfolioData = Map<String, dynamic>;

abstract interface class PortfolioRepository {
  Future<List<PortfolioData>> list();
  Future<PortfolioData> save(PortfolioData data, {String? id});
  Future<void> delete(String id);
  Future<void> deleteAsset(String kind, String id);
  Future<void> updateAsset(String kind, String id, PortfolioData data);
}
