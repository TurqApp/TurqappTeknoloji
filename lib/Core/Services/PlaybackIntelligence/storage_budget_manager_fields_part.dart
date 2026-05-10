part of 'storage_budget_manager.dart';

class _StorageBudgetManagerState {
  final selectedPlanGb = defaultStorageBudgetPlanGb.obs;
}

extension StorageBudgetManagerFieldsPart on StorageBudgetManager {
  RxInt get _selectedPlanGb => _state.selectedPlanGb;
}
