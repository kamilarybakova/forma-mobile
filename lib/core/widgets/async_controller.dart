import 'package:flutter/foundation.dart';

class AsyncController extends ChangeNotifier {
  bool busy = false;
  String? error;
  bool _disposed = false;
  Future<bool> run(Future<void> Function() action) async {
    if (busy) return false;
    busy = true;
    error = null;
    notifyListeners();
    try {
      await action();
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      busy = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
