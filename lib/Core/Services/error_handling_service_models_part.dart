part of 'error_handling_service_library.dart';

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
    Map<String, dynamic> metadata = const {},
    this.stackTrace,
    this.isRetryable = false,
    this.retryCount = 0,
  }) : metadata = _cloneAppErrorMetadataMap(metadata);

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'message': message,
        'userFriendlyMessage': userFriendlyMessage,
        'category': category.name,
        'severity': severity.name,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'metadata': _cloneAppErrorMetadataMap(metadata),
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
        metadata: _cloneAppErrorMetadataMap(
          Map<String, dynamic>.from(json['metadata'] ?? {}),
        ),
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
        metadata:
            metadata != null ? _cloneAppErrorMetadataMap(metadata) : this.metadata,
        stackTrace: stackTrace,
        isRetryable: isRetryable,
        retryCount: retryCount ?? this.retryCount,
      );

  static Map<String, dynamic> _cloneAppErrorMetadataMap(
    Map<String, dynamic> source,
  ) {
    return source.map(
      (key, value) => MapEntry(key, _cloneAppErrorMetadataValue(value)),
    );
  }

  static dynamic _cloneAppErrorMetadataValue(dynamic value) {
    if (value is Map) {
      return value.map(
        (key, nestedValue) => MapEntry(
          key.toString(),
          _cloneAppErrorMetadataValue(nestedValue),
        ),
      );
    }
    if (value is List) {
      return value.map(_cloneAppErrorMetadataValue).toList(growable: false);
    }
    return value;
  }
}
