typedef BillingData = Map<String, dynamic>;

abstract interface class BillingRepository {
  Future<List<BillingData>> plans();
  Future<List<BillingData>> orders();
  Future<BillingData> trial();
  Future<BillingData> checkout(int plan, String period, {bool quote = false});
  Future<void> startTrial(int plan);
  Future<void> cancel(String id);
}
