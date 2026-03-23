part of 'error_handling_service.dart';

extension ErrorHandlingServiceProcessingPart on ErrorHandlingService {
  Future<void> handleError(
    dynamic error, {
    String? userMessage,
    ErrorCategory? category,
    ErrorSeverity severity = ErrorSeverity.medium,
    Map<String, dynamic> metadata = const {},
    bool showToUser = true,
    bool isRetryable = false,
    StackTrace? stackTrace,
  }) async {
    final appError = _createAppError(
      error,
      userMessage: userMessage,
      category: category,
      severity: severity,
      metadata: metadata,
      isRetryable: isRetryable,
      stackTrace: stackTrace,
    );

    await _logError(appError);
    recordQALabHandledError(
      code: appError.code,
      message: appError.message,
      severity: appError.severity.name,
      metadata: appError.metadata,
      stackTrace: appError.stackTrace,
    );

    var shouldShow = showToUser;
    if (appError.category == ErrorCategory.network) {
      final userInitiated = (appError.metadata['userInitiated'] == true);
      shouldShow = showToUser && userInitiated;
    }
    if (shouldShow) {
      _showErrorToUser(appError);
    }

    _updateErrorStats(appError);
    await _saveErrorToHistory(appError);
  }

  AppError _createAppError(
    dynamic error, {
    String? userMessage,
    ErrorCategory? category,
    ErrorSeverity severity = ErrorSeverity.medium,
    Map<String, dynamic> metadata = const {},
    bool isRetryable = false,
    StackTrace? stackTrace,
  }) {
    final errorId = DateTime.now().millisecondsSinceEpoch.toString();
    var code = 'UNKNOWN_ERROR';
    final message = error.toString();
    var userFriendlyMessage = userMessage ?? 'Beklenmeyen bir hata oluştu';
    final hasExplicitCategory = category != null;
    var errorCategory = category ?? ErrorCategory.unknown;

    if (!hasExplicitCategory) {
      final lower = normalizeLowercase(error.toString());
      if (error is SocketException || error is TimeoutException) {
        errorCategory = ErrorCategory.network;
        userFriendlyMessage =
            userMessage ?? 'İnternet bağlantısı kontrol edilemiyor';
        code = 'NETWORK_ERROR';
        isRetryable = true;
      } else if (error is FileSystemException) {
        errorCategory = ErrorCategory.storage;
        userFriendlyMessage = userMessage ?? 'Dosya işlemi başarısız oldu';
        code = 'STORAGE_ERROR';
      } else if (lower.contains('permission') ||
          lower.contains('permission-denied') ||
          lower.contains('unauthorized')) {
        errorCategory = ErrorCategory.permission;
        userFriendlyMessage = userMessage ?? 'Gerekli izinler verilmedi';
        code = 'PERMISSION_ERROR';
      } else if (lower.contains('unauthenticated') ||
          lower.contains('auth/') ||
          lower.contains('requires-recent-login')) {
        errorCategory = ErrorCategory.authentication;
        userFriendlyMessage = userMessage ?? 'Kimlik doğrulama hatası';
        code = 'AUTH_ERROR';
      }
    }

    return AppError(
      id: errorId,
      code: code,
      message: message,
      userFriendlyMessage: userFriendlyMessage,
      category: errorCategory,
      severity: severity,
      timestamp: DateTime.now(),
      metadata: {
        ...metadata,
        'isOnline': _isOnline.value,
        'errorType': error.runtimeType.toString(),
      },
      stackTrace: stackTrace?.toString(),
      isRetryable: isRetryable,
    );
  }

  Future<void> _logError(AppError appError) async {
    try {
      final logMessage = '''
===============================
ERROR REPORT
===============================
ID: ${appError.id}
Category: ${appError.category.label}
Severity: ${appError.severity.label}
Message: ${appError.message}
User Message: ${appError.userFriendlyMessage}
Timestamp: ${appError.timestamp}
Metadata: ${appError.metadata}
Stack Trace: ${appError.stackTrace ?? 'Not available'}
Retryable: ${appError.isRetryable}
Retry Count: ${appError.retryCount}
===============================
      ''';

      if (kDebugMode) {
        print(logMessage);
      }
    } catch (e) {
      print('Failed to log error: $e');
    }
  }

  void _showErrorToUser(AppError appError) {
    Color backgroundColor;
    switch (appError.severity) {
      case ErrorSeverity.critical:
        backgroundColor = Colors.red;
        break;
      case ErrorSeverity.high:
        backgroundColor = Colors.orange;
        break;
      case ErrorSeverity.medium:
        backgroundColor = Colors.amber;
        break;
      case ErrorSeverity.low:
        backgroundColor = Colors.blue;
        break;
    }

    AppSnackbar(
      appError.category.label,
      appError.userFriendlyMessage,
      backgroundColor: backgroundColor,
      colorText: Colors.white,
      duration: Duration(
        seconds: appError.severity == ErrorSeverity.critical ? 10 : 5,
      ),
      snackPosition: SnackPosition.TOP,
    );

    if (appError.isRetryable && appError.retryCount < 3) {
      _showRetryOption(appError);
    }
  }

  void _showRetryOption(AppError appError) {
    Get.defaultDialog(
      title: 'common.retry'.tr,
      middleText: 'error_handling.retry_prompt'
          .trParams({'message': appError.userFriendlyMessage}),
      textConfirm: 'common.retry'.tr,
      textCancel: 'common.cancel'.tr,
      onConfirm: () {
        Get.back();
        _retryFailedOperation(appError);
      },
      onCancel: () => Get.back(),
    );
  }

  Future<void> _retryFailedOperation(AppError appError) async {
    final updatedError = appError.copyWith(
      retryCount: appError.retryCount + 1,
    );

    switch (appError.category) {
      case ErrorCategory.network:
        await _retryNetworkOperation(updatedError);
        break;
      case ErrorCategory.upload:
        await _retryUploadOperation(updatedError);
        break;
      default:
        AppSnackbar(
          'common.info'.tr,
          'error_handling.retry_unsupported'.tr,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
    }
  }

  Future<void> _retryNetworkOperation(AppError error) async {
    if (!_isOnline.value) {
      AppSnackbar(
        'error_handling.network_title'.tr,
        'error_handling.network_missing'.tr,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    AppSnackbar(
      'error_handling.retrying_title'.tr,
      'error_handling.retrying_body'.tr,
      backgroundColor: Colors.blue,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
    );
  }

  Future<void> _retryUploadOperation(AppError error) async {
    AppSnackbar(
      'error_handling.upload_retry_title'.tr,
      'error_handling.upload_retry_body'.tr,
      backgroundColor: Colors.blue,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
    );
  }

  void _monitorConnectivity() {
    Connectivity().onConnectivityChanged.listen((results) {
      final wasOnline = _isOnline.value;
      _isOnline.value =
          results.any((result) => result != ConnectivityResult.none);

      if (!wasOnline && _isOnline.value) {
        _retryPendingOperations();
      }
    });
  }

  void _retryPendingOperations() {
    final retryableErrors = _errorHistory
        .where((error) => error.isRetryable && error.retryCount < 3)
        .toList();

    for (final error in retryableErrors) {
      _retryFailedOperation(error);
    }
  }
}
