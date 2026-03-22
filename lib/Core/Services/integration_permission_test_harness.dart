import 'dart:collection';

import 'package:permission_handler/permission_handler.dart';

class IntegrationPermissionTestHarness {
  IntegrationPermissionTestHarness._();

  static final Map<String, PermissionStatus> _statuses =
      <String, PermissionStatus>{};
  static final Map<String, Queue<PermissionStatus>> _queuedRequests =
      <String, Queue<PermissionStatus>>{};

  static bool get isActive => _statuses.isNotEmpty || _queuedRequests.isNotEmpty;

  static void reset() {
    _statuses.clear();
    _queuedRequests.clear();
  }

  static void setStatus(String permissionId, PermissionStatus status) {
    _statuses[_normalize(permissionId)] = status;
  }

  static void queueRequestSequence(
    String permissionId,
    Iterable<PermissionStatus> results,
  ) {
    _queuedRequests[_normalize(permissionId)] = Queue<PermissionStatus>.from(
      results,
    );
  }

  static Future<PermissionStatus> statusFor(
    Permission permission, {
    required String permissionId,
  }) async {
    final normalized = _normalize(permissionId);
    final overridden = _statuses[normalized];
    if (overridden != null) return overridden;
    return permission.status;
  }

  static Future<PermissionStatus> request(
    Permission permission, {
    required String permissionId,
  }) async {
    final normalized = _normalize(permissionId);
    final queued = _queuedRequests[normalized];
    if (queued != null && queued.isNotEmpty) {
      final next = queued.removeFirst();
      _statuses[normalized] = next;
      if (queued.isEmpty) {
        _queuedRequests.remove(normalized);
      }
      return next;
    }
    final result = await permission.request();
    _statuses[normalized] = result;
    return result;
  }

  static Map<String, dynamic> snapshot() {
    final statuses = <String, String>{};
    for (final entry in _statuses.entries) {
      statuses[entry.key] = entry.value.name;
    }
    final queued = <String, List<String>>{};
    for (final entry in _queuedRequests.entries) {
      queued[entry.key] = entry.value.map((value) => value.name).toList();
    }
    return <String, dynamic>{
      'active': isActive,
      'statuses': statuses,
      'queuedRequests': queued,
    };
  }

  static String _normalize(String value) => value.trim().toLowerCase();
}
