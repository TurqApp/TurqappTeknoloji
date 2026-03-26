part of 'storage_budget_manager.dart';

class StorageBudgetManager extends GetxService {
  static StorageBudgetManager? maybeFind() => maybeFindStorageBudgetManager();

  static StorageBudgetManager ensure() => ensureStorageBudgetManager();

  static const int _mb = 1024 * 1024;
  static const int _maxRecentProtectionWindow = 50;
  final _state = _StorageBudgetManagerState();
}
