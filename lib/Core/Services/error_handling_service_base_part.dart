part of 'error_handling_service_library.dart';

abstract class _ErrorHandlingServiceBase extends GetxService {
  final _state = _ErrorHandlingServiceState();
  @override
  void onInit() {
    super.onInit();
    (this as ErrorHandlingService)._loadErrorHistory();
    (this as ErrorHandlingService)._monitorConnectivity();
  }
}

class ErrorHandlingService extends _ErrorHandlingServiceBase {}
