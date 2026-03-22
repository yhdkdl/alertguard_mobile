import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/alert_history_model.dart';
import '../../data/alert_history_repository.dart';

final alertHistoryRepositoryProvider = Provider<AlertHistoryRepository>((ref) {
  return AlertHistoryRepository();
});

class AlertHistoryNotifier extends AsyncNotifier<List<AlertHistoryModel>> {
  late AlertHistoryRepository _repo;

  @override
  Future<List<AlertHistoryModel>> build() async {
    _repo = ref.read(alertHistoryRepositoryProvider);
    return _repo.getAlertHistory();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.getAlertHistory());
  }
}

final alertHistoryProvider =
    AsyncNotifierProvider<AlertHistoryNotifier, List<AlertHistoryModel>>(
      AlertHistoryNotifier.new,
    );
