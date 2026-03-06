import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminAccessService {
  static bool _adminCached = false;
  static bool _hasRefreshed = false;
  static DateTime? _lastAllowlistFetchAt;
  static const Duration _allowlistTtl = Duration(minutes: 10);
  static Set<String> _allowlistCache = <String>{};

  static bool isKnownAdminSync() {
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
    if (currentUser == null) return false;

    final token = await currentUser.getIdTokenResult(true);
    var allowed = token.claims?["admin"] == true;
    if (!allowed) {
      final allowlist = await _loadAllowlist();
      allowed = allowlist.contains(currentUser.uid);
    }
    _adminCached = allowed;
    return allowed;
  }

  static Future<Set<String>> _loadAllowlist() async {
    final now = DateTime.now();
    if (_lastAllowlistFetchAt != null &&
        now.difference(_lastAllowlistFetchAt!) < _allowlistTtl) {
      return _allowlistCache;
    }

    try {
      final snap = await FirebaseFirestore.instance
          .collection('adminConfig')
          .doc('admin')
          .get();
      final data = snap.data() ?? const <String, dynamic>{};
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
