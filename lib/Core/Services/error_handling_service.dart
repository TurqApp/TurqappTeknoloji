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
import 'package:turqappv2/Core/Services/qa_lab_bridge.dart';

part 'error_handling_service_processing_part.dart';
part 'error_handling_service_history_part.dart';

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
