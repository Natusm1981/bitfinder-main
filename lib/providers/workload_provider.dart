import 'package:flutter/foundation.dart';

enum WorkloadActivity { idle, localSearch, poolHost, poolClient }

class WorkloadProvider extends ChangeNotifier {
  WorkloadActivity _activity = WorkloadActivity.idle;

  WorkloadActivity get activity => _activity;
  bool get isIdle => _activity == WorkloadActivity.idle;
  bool get isLocalSearchRunning => _activity == WorkloadActivity.localSearch;
  bool get isPoolHostRunning => _activity == WorkloadActivity.poolHost;
  bool get isPoolClientRunning => _activity == WorkloadActivity.poolClient;

  bool canStart(WorkloadActivity activity) {
    return _activity == WorkloadActivity.idle || _activity == activity;
  }

  bool acquire(WorkloadActivity activity) {
    if (!canStart(activity)) return false;
    if (_activity == activity) return true;
    _activity = activity;
    notifyListeners();
    return true;
  }

  void release(WorkloadActivity activity) {
    if (_activity != activity) return;
    _activity = WorkloadActivity.idle;
    notifyListeners();
  }
}
