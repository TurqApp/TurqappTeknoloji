import 'package:firebase_auth/firebase_auth.dart';
import 'package:turqappv2/Core/Repositories/admin_task_assignment_repository.dart';
import 'package:turqappv2/Core/Repositories/config_repository.dart';
import 'package:turqappv2/Core/admin_task_catalog.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class AdminAccessService {
  static bool _adminCached = false;
  static bool _hasRefreshed = false;
  static String _cachedUid = '';
  static DateTime? _lastAllowlistFetchAt;
  static const Duration _allowlistTtl = Duration(minutes: 10);
  static Set<String> _allowlistCache = <String>{};
  static DateTime? _lastTaskFetchAt;
  static const Duration _taskTtl = Duration(minutes: 2);
  static List<String> _taskCache = <String>[];

  static bool isKnownAdminSync() {
    final currentUid = CurrentUserService.instance.effectiveUserId.trim();
    if (_cachedUid != currentUid) {
      _cachedUid = currentUid;
      _adminCached = false;
      _hasRefreshed = false;
      _taskCache = <String>[];
      _lastTaskFetchAt = null;
    }
    if (!_hasRefreshed) {
      _hasRefreshed = true;
      // Fire and forget: populate cache from custom claims.
      canManageSliders().then(
        (v) => _adminCached = v,
        onError: (_) => _adminCached = false,
      );
    }
    return _adminCached;
  }

  static Future<bool> canManageSliders() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final effectiveUid = CurrentUserService.instance.effectiveUserId.trim();
    final resolvedUid = (currentUser?.uid ?? effectiveUid).trim();
    if (resolvedUid.isEmpty) {
      _cachedUid = '';
      _adminCached = false;
      _hasRefreshed = false;
      return false;
    }

    if (_cachedUid != resolvedUid) {
      _cachedUid = resolvedUid;
      _adminCached = false;
    }

    var allowed = false;
    if (currentUser != null) {
      try {
        final token = await currentUser.getIdTokenResult(true);
        allowed = token.claims?["admin"] == true;
      } catch (_) {
        allowed = false;
      }
    }
    if (!allowed) {
      final allowlist = await _loadAllowlist();
      allowed = allowlist.contains(resolvedUid);
    }
    _adminCached = allowed;
    _hasRefreshed = true;
    return allowed;
  }

  static Future<bool> isPrimaryAdmin() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return false;
    final token = await currentUser.getIdTokenResult(true);
    return token.claims?["admin"] == true;
  }

  static Future<List<String>> fetchAssignedTaskIds(
      {bool forceRefresh = false}) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _taskCache = <String>[];
      _lastTaskFetchAt = null;
      return const <String>[];
    }

    if (_cachedUid != currentUser.uid) {
      _cachedUid = currentUser.uid;
      _taskCache = <String>[];
      _lastTaskFetchAt = null;
    }

    final now = DateTime.now();
    if (!forceRefresh &&
        _lastTaskFetchAt != null &&
        now.difference(_lastTaskFetchAt!) < _taskTtl) {
      return List<String>.unmodifiable(_taskCache);
    }

    try {
      final assignment = await AdminTaskAssignmentRepository.ensure()
          .fetchAssignment(currentUser.uid);
      _taskCache = normalizeAdminTaskIds(
        assignment?['taskIds'] is List
            ? assignment!['taskIds'] as List
            : const [],
      );
    } catch (_) {
      _taskCache = <String>[];
    }
    _lastTaskFetchAt = now;
    return List<String>.unmodifiable(_taskCache);
  }

  static Future<bool> canAccessTask(String taskId) async {
    if (await canManageSliders()) {
      return true;
    }
    final tasks = await fetchAssignedTaskIds();
    return tasks.contains(taskId.trim());
  }

  static Future<bool> canAccessAnyTask(Iterable<String> taskIds) async {
    if (await canManageSliders()) {
      return true;
    }
    final tasks = await fetchAssignedTaskIds();
    for (final taskId in taskIds) {
      if (tasks.contains(taskId.trim())) {
        return true;
      }
    }
    return false;
  }

  static Future<Set<String>> _loadAllowlist() async {
    final now = DateTime.now();
    if (_lastAllowlistFetchAt != null &&
        now.difference(_lastAllowlistFetchAt!) < _allowlistTtl) {
      return _allowlistCache;
    }

    try {
      final data = await ensureConfigRepository().getAdminConfigDoc(
            'admin',
            preferCache: true,
            ttl: _allowlistTtl,
          ) ??
          const <String, dynamic>{};
      final raw = data['allowedUserIds'];
      final out = <String>{};
      if (raw is List) {
        for (final v in raw) {
          if (v is String && v.trim().isNotEmpty) {
            out.add(v.trim());
          }
        }
      }
      _allowlistCache = out;
    } catch (_) {
      _allowlistCache = <String>{};
    }

    _lastAllowlistFetchAt = now;
    return _allowlistCache;
  }
}
