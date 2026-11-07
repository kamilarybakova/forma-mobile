import '../../../core/network/api_client.dart';
import '../domain/billing_repository.dart';

class ApiBillingRepository implements BillingRepository {
  final ApiClient api;
  ApiBillingRepository(this.api);
  @override
  Future<List<BillingData>> plans() => api.list('plans/');
  @override
  Future<List<BillingData>> orders() => api.list('orders/');
  @override
  Future<BillingData> trial() => api.get('trial/');
  @override
  Future<BillingData> checkout(
    int plan,
    String period, {
    bool quote = false,
  }) async => Map<String, dynamic>.from(
    await api.request(
          'orders/',
          method: 'POST',
          data: {
            'plan': plan,
            'period': period,
            'publish_consent': true,
            'quote_only': quote,
          },
        )
        as Map,
  );
  @override
  Future<void> startTrial(int plan) async {
    await api.request(
      'trial/',
      method: 'POST',
      data: {'plan': plan, 'publish_consent': true},
    );
  }

  @override
  Future<void> cancel(String id) async {
    await api.request('orders/$id/cancel/', method: 'POST');
  }
}
