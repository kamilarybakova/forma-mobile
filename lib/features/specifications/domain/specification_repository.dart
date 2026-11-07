typedef SpecificationData = Map<String, dynamic>;

abstract interface class SpecificationRepository {
  Future<List<SpecificationData>> list(String briefId);
  Future<SpecificationData> save(
    String briefId,
    SpecificationData data, {
    String? id,
  });
  Future<void> delete(String id, int version);
  Future<void> deleteItem(String id, String itemId, int version);
}
