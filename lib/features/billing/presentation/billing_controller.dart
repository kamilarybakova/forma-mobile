import '../../../core/widgets/async_controller.dart';
import '../domain/billing_repository.dart';

class BillingController extends AsyncController {
  final BillingRepository repository;
  List<BillingData> plans = [], orders = [];
  BillingData trial = {};
  BillingData? get activeOrder =>
      orders.where((order) => order['is_live'] == true).firstOrNull;
  BillingController(this.repository);
  Future<bool> load() => run(() async {
    plans = await repository.plans();
    orders = await repository.orders();
    trial = await repository.trial();
  });
}
