import '../../../core/widgets/async_controller.dart';
import '../domain/portfolio_repository.dart';

class PortfolioController extends AsyncController {
  final PortfolioRepository repository;
  List<PortfolioData> projects = [];
  PortfolioController(this.repository);
  Future<bool> load() => run(() async {
    projects = await repository.list();
  });
}
