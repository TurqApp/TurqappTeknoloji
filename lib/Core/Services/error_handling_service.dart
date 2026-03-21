import 'dart:async';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';

enum ErrorSeverity {
  low('error_handling.severity_low'),
  medium('error_handling.severity_medium'),
  high('error_handling.severity_high'),
  critical('error_handling.severity_critical');

  const ErrorSeverity(this._labelKey);
  final String _labelKey;
  String get label => _labelKey.tr;
}

enum ErrorCategory {
  network('error_handling.category_network'),
  upload('error_handling.category_upload'),
  storage('error_handling.category_storage'),
  authentication('error_handling.category_authentication'),
  validation('error_handling.category_validation'),
  permission('error_handling.category_permission'),
  system('error_handling.category_system'),
  unknown('error_handling.category_unknown');

  const ErrorCategory(this._labelKey);
  final String _labelKey;
  String get label => _labelKey.tr;
}

class AppError {
  final String id;
  final String code;
  final String message;
  final String userFriendlyMessage;
  final ErrorCategory category;
  final ErrorSeverity severity;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;
  final String? stackTrace;
  final bool isRetryable;
  final int retryCount;

  AppError({
    required this.id,
    required this.code,
    required this.message,
    required this.userFriendlyMessage,
    required this.category,
    this.severity = ErrorSeverity.medium,
    required this.timestamp,
    this.metadata = const {},
    this.stackTrace,
    this.isRetryable = false,
    this.retryCount = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'message': message,
        'userFriendlyMessage': userFriendlyMessage,
        'category': category.name,
        'severity': severity.name,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'metadata': metadata,
        'stackTrace': stackTrace,
        'isRetryable': isRetryable,
        'retryCount': retryCount,
      };

  factory AppError.fromJson(Map<String, dynamic> json) => AppError(
        id: json['id'],
        code: json['code'],
        message: json['message'],
        userFriendlyMessage: json['userFriendlyMessage'],
        category:
            ErrorCategory.values.firstWhere((e) => e.name == json['category']),
        severity:
            ErrorSeverity.values.firstWhere((e) => e.name == json['severity']),
        timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
        metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
        stackTrace: json['stackTrace'],
        isRetryable: json['isRetryable'] ?? false,
        retryCount: json['retryCount'] ?? 0,
      );

  AppError copyWith({
    int? retryCount,
    Map<String, dynamic>? metadata,
    ErrorSeverity? severity,
  }) =>
      AppError(
        id: id,
        code: code,
        message: message,
        userFriendlyMessage: userFriendlyMessage,
        category: category,
        severity: severity ?? this.severity,
        timestamp: timestamp,
        metadata: metadata ?? this.metadata,
        stackTrace: stackTrace,
        isRetryable: isRetryable,
        retryCount: retryCount ?? this.retryCount,
      );
}

class ErrorHandlingService extends GetxController {
  static ErrorHandlingService ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(ErrorHandlingService());
  }

  static ErrorHandlingService? maybeFind() {
    if (!Get.isRegistered<ErrorHandlingService>()) return null;
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

  /// Handle and process error
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

    // Suppress passive network errors by default; only show if user initiated
    bool shouldShow = showToUser;
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

  /// Create AppError from various error types
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
    String code = 'UNKNOWN_ERROR';
    String message = error.toString();
    String userFriendlyMessage = userMessage ?? 'Beklenmeyen bir hata oluştu';
    final hasExplicitCategory = category != null;
    ErrorCategory errorCategory = category ?? ErrorCategory.unknown;

    // Analyze error type and categorize
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

  /// Log error to console and debug tools
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

      // In production, you could send this to your logging service
      // await YourLoggingService.log(appError);
    } catch (e) {
      print('Failed to log error: $e');
    }
  }

  /// Show error to user with appropriate UI
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
          seconds: appError.severity == ErrorSeverity.critical ? 10 : 5),
      snackPosition: SnackPosition.TOP,
    );

    // Show retry option for retryable errors
    if (appError.isRetryable && appError.retryCount < 3) {
      _showRetryOption(appError);
    }
  }

  /// Show retry option for retryable errors
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

  /// Retry failed operation
  Future<void> _retryFailedOperation(AppError appError) async {
    final updatedError = appError.copyWith(
      retryCount: appError.retryCount + 1,
    );

    // Here you would implement specific retry logic based on error category
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

  /// Retry network operations
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

    // Implement specific network retry logic
    AppSnackbar(
      'error_handling.retrying_title'.tr,
      'error_handling.retrying_body'.tr,
      backgroundColor: Colors.blue,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
    );
  }

  /// Retry upload operations
  Future<void> _retryUploadOperation(AppError error) async {
    // This would integrate with UploadQueueService
    AppSnackbar(
      'error_handling.upload_retry_title'.tr,
      'error_handling.upload_retry_body'.tr,
      backgroundColor: Colors.blue,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
    );
  }

  /// Monitor connectivity changes
  void _monitorConnectivity() {
    Connectivity().onConnectivityChanged.listen((results) {
      final wasOnline = _isOnline.value;
      _isOnline.value =
          results.any((result) => result != ConnectivityResult.none);

      if (!wasOnline && _isOnline.value) {
        _retryPendingOperations();
      }
      // No user-facing snackbars for connectivity changes
    });
  }

  /// Retry pending operations when connectivity is restored
  void _retryPendingOperations() {
    final retryableErrors = _errorHistory
        .where((error) => error.isRetryable && error.retryCount < 3)
        .toList();

    for (final error in retryableErrors) {
      _retryFailedOperation(error);
    }
  }

  /// Update error statistics
  void _updateErrorStats(AppError error) {
    _totalErrors.value++;
    if (error.severity == ErrorSeverity.critical) {
      _criticalErrors.value++;
    }
  }

  /// Save error to history
  Future<void> _saveErrorToHistory(AppError error) async {
    _errorHistory.add(error);

    // Keep only latest errors
    if (_errorHistory.length > _maxErrorHistory) {
      _errorHistory.removeRange(0, _errorHistory.length - _maxErrorHistory);
    }

    await _saveErrorHistory();
  }

  /// Load error history from storage
  Future<void> _loadErrorHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyString = prefs.getString(_errorHistoryKey);

      if (historyString != null) {
        final historyJson = jsonDecode(historyString) as List;
        _errorHistory.assignAll(
          historyJson.map((item) => AppError.fromJson(item)).toList(),
        );

        _updateStatsFromHistory();
      }
    } catch (e) {
      print('Failed to load error history: $e');
    }
  }

  /// Save error history to storage
  Future<void> _saveErrorHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = _errorHistory.map((error) => error.toJson()).toList();
      await prefs.setString(_errorHistoryKey, jsonEncode(historyJson));
    } catch (e) {
      print('Failed to save error history: $e');
    }
  }

  /// Update statistics from loaded history
  void _updateStatsFromHistory() {
    _totalErrors.value = _errorHistory.length;
    _criticalErrors.value = _errorHistory
        .where((error) => error.severity == ErrorSeverity.critical)
        .length;
  }

  /// Clear error history
  Future<void> clearErrorHistory() async {
    _errorHistory.clear();
    _totalErrors.value = 0;
    _criticalErrors.value = 0;
    await _saveErrorHistory();
  }

  /// Get error statistics
  Map<String, dynamic> getErrorStats() {
    final now = DateTime.now();
    final last24Hours = _errorHistory
        .where((error) => now.difference(error.timestamp).inHours < 24)
        .length;
    final lastWeek = _errorHistory
        .where((error) => now.difference(error.timestamp).inDays < 7)
        .length;

    final categoryCounts = <String, int>{};
    for (final category in ErrorCategory.values) {
      categoryCounts[category.name] =
          _errorHistory.where((error) => error.category == category).length;
    }

    return {
      'total': _totalErrors.value,
      'critical': _criticalErrors.value,
      'last24Hours': last24Hours,
      'lastWeek': lastWeek,
      'byCategory': categoryCounts,
      'retryableErrors': _errorHistory.where((e) => e.isRetryable).length,
    };
  }

  /// Son hatanın kısa özetini döndürür.
  Map<String, dynamic>? getLastErrorSummary() {
    if (_errorHistory.isEmpty) return null;
    final last = _errorHistory.last;
    return {
      'id': last.id,
      'code': last.code,
      'message': last.message,
      'userFriendlyMessage': last.userFriendlyMessage,
      'category': last.category.label,
      'severity': last.severity.label,
      'timestamp': last.timestamp.toIso8601String(),
      'retryable': last.isRetryable,
      'retryCount': last.retryCount,
    };
  }

  /// Check system health
  Map<String, dynamic> getSystemHealth() {
    final recentErrors = _errorHistory
        .where((error) =>
            DateTime.now().difference(error.timestamp).inMinutes < 30)
        .length;

    String healthStatus;
    if (_criticalErrors.value > 0 || recentErrors > 10) {
      healthStatus = 'poor';
    } else if (recentErrors > 5) {
      healthStatus = 'fair';
    } else {
      healthStatus = 'good';
    }

    return {
      'status': healthStatus,
      'recentErrors': recentErrors,
      'criticalErrors': _criticalErrors.value,
      'isOnline': _isOnline.value,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}
