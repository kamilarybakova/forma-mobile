import '../../../core/widgets/async_controller.dart';
import '../domain/brief.dart';
import '../domain/workspace_repository.dart';

class WorkspaceController extends AsyncController {
  final WorkspaceRepository repository;
  List<Brief> briefs = [];
  WorkspaceController(this.repository);
  Future<bool> load() => run(() async {
    briefs = await repository.list();
  });
  Future<bool> create(String title, String area) => run(() async {
    await repository.create(title, area);
    briefs = await repository.list();
  });
}
