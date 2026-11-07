import '../../../core/widgets/async_controller.dart';
import '../domain/studio_repository.dart';

class StudioController extends AsyncController {
  final StudioRepository repository;
  StudioData studio = {}, usage = {}, user = {};
  List<StudioData> templates = [];
  StudioController(this.repository);
  Future<bool> load() => run(() async {
    final values = await Future.wait([
      repository.load(),
      repository.storage(),
      repository.user(),
    ]);
    studio = values[0];
    usage = values[1];
    user = values[2];
    templates = await repository.templates();
  });
  Future<bool> save(StudioData data) => run(() async {
    studio = await repository.save(data);
  });

  Future<bool> saveUser(StudioData data) => run(() async {
    await repository.saveUser(data);
    user = {...user, ...data};
  });
}
