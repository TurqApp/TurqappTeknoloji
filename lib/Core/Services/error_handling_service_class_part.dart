part of 'error_handling_service.dart';

class ErrorHandlingService extends GetxController {
  static ErrorHandlingService ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(ErrorHandlingService());
  }

  static ErrorHandlingService? maybeFind() {
    final isRegistered = Get.isRegistered<ErrorHandlingService>();
    if (!isRegistered) return null;
    return Get.find<ErrorHandlingService>();
  }

  final RxList<AppError> _errorHistory = <AppError>[].obs;
  final RxBool _isOnline = true.obs;
  final RxInt _totalErrors = 0.obs;
  final RxInt _criticalErrors = 0.obs;

  static const String _errorHistoryKey = 'error_history';
  static const int _maxErrorHistory = 100;

  List<AppError> get errorHistory => _errorHistory;
  bool get isOnline => _isOnline.value;
  int get totalErrors => _totalErrors.value;
  int get criticalErrors => _criticalErrors.value;

  @override
  void onInit() {
    super.onInit();
    _loadErrorHistory();
    _monitorConnectivity();
  }
}
