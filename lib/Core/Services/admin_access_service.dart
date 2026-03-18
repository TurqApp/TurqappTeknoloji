import 'package:firebase_auth/firebase_auth.dart';
import 'package:turqappv2/Core/Repositories/config_repository.dart';

class AdminAccessService {
  static bool _adminCached = false;
  static bool _hasRefreshed = false;
  static String _cachedUid = '';
  static DateTime? _lastAllowlistFetchAt;
  static const Duration _allowlistTtl = Duration(minutes: 10);
  static Set<String> _allowlistCache = <String>{};

  static bool isKnownAdminSync() {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (_cachedUid != currentUid) {
      _cachedUid = currentUid;
      _adminCached = false;
      _hasRefreshed = false;
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
    if (currentUser == null) {
      _cachedUid = '';
      _adminCached = false;
      _hasRefreshed = false;
      return false;
    }

    if (_cachedUid != currentUser.uid) {
      _cachedUid = currentUser.uid;
      _adminCached = false;
    }

    final token = await currentUser.getIdTokenResult(true);
    var allowed = token.claims?["admin"] == true;
    if (!allowed) {
      final allowlist = await _loadAllowlist();
      allowed = allowlist.contains(currentUser.uid);
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

  static Future<Set<String>> _loadAllowlist() async {
    final now = DateTime.now();
    if (_lastAllowlistFetchAt != null &&
        now.difference(_lastAllowlistFetchAt!) < _allowlistTtl) {
      return _allowlistCache;
    }

    try {
      final data = await ConfigRepository.ensure().getAdminConfigDoc(
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
