part of 'error_handling_service_library.dart';

extension ErrorHandlingServiceHistoryPart on ErrorHandlingService {
  void _updateErrorStats(AppError error) {
    _totalErrors.value++;
    if (error.severity == ErrorSeverity.critical) {
      _criticalErrors.value++;
    }
  }

  Future<void> _saveErrorToHistory(AppError error) async {
    _errorHistory.add(error);

    if (_errorHistory.length > _errorHandlingMaxHistory) {
      _errorHistory.removeRange(
        0,
        _errorHistory.length - _errorHandlingMaxHistory,
      );
    }

    await _saveErrorHistory();
  }

  Future<void> _loadErrorHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyString = prefs.getString(_errorHandlingHistoryKey);

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

  Future<void> _saveErrorHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = _errorHistory.map((error) => error.toJson()).toList();
      await prefs.setString(
        _errorHandlingHistoryKey,
        jsonEncode(historyJson),
      );
    } catch (e) {
      print('Failed to save error history: $e');
    }
  }

  void _updateStatsFromHistory() {
    _totalErrors.value = _errorHistory.length;
    _criticalErrors.value = _errorHistory
        .where((error) => error.severity == ErrorSeverity.critical)
        .length;
  }

  Future<void> clearErrorHistory() async {
    _errorHistory.clear();
    _totalErrors.value = 0;
    _criticalErrors.value = 0;
    await _saveErrorHistory();
  }

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
