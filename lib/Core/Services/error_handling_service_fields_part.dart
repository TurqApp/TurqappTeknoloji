part of 'error_handling_service.dart';

const String _errorHandlingHistoryKey = 'error_history';
const int _errorHandlingMaxHistory = 100;

class _ErrorHandlingServiceState {
  final errorHistory = <AppError>[].obs;
  final isOnline = true.obs;
  final totalErrors = 0.obs;
  final criticalErrors = 0.obs;
}

extension ErrorHandlingServiceFieldsPart on ErrorHandlingService {
  RxList<AppError> get _errorHistory => _state.errorHistory;
  RxBool get _isOnline => _state.isOnline;
  RxInt get _totalErrors => _state.totalErrors;
  RxInt get _criticalErrors => _state.criticalErrors;

  List<AppError> get errorHistory => _errorHistory;
  bool get isOnline => _isOnline.value;
  int get totalErrors => _totalErrors.value;
  int get criticalErrors => _criticalErrors.value;
}
