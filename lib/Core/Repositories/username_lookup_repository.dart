import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Utils/nickname_utils.dart';

class UsernameLookupRepository extends GetxService {
  UsernameLookupRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const Duration _ttl = Duration(minutes: 10);
  final Map<String, _UsernameCacheEntry> _cache =
      <String, _UsernameCacheEntry>{};

  static UsernameLookupRepository _ensureService() {
    if (Get.isRegistered<UsernameLookupRepository>()) {
      return Get.find<UsernameLookupRepository>();
    }
    return Get.put(UsernameLookupRepository(), permanent: true);
  }

  static UsernameLookupRepository ensure() {
    return _ensureService();
  }

  Future<String?> findUidForHandle(String handle) async {
    final normalized = normalizeNicknameInput(handle);
    if (normalized.isEmpty) return null;

    final cached = _cache[normalized];
    if (cached != null && DateTime.now().difference(cached.cachedAt) <= _ttl) {
      return cached.uid;
    }

    String? uid;
    try {
      final usernameDoc =
          await _firestore.collection('usernames').doc(normalized).get();
      final mappedUid = (usernameDoc.data()?['uid'] ?? '').toString().trim();
      if (mappedUid.isNotEmpty) {
        uid = mappedUid;
      }
    } catch (_) {}

    if (uid == null) {
      try {
        final byUsername = await _firestore
            .collection('users')
            .where('username', isEqualTo: normalized)
            .limit(1)
            .get();
        if (byUsername.docs.isNotEmpty) {
          uid = byUsername.docs.first.id;
        }
      } catch (_) {}
    }

    if (uid == null) {
      try {
        final byNickname = await _firestore
            .collection('users')
            .where('nickname', isEqualTo: normalizeHandleInput(handle))
            .limit(1)
            .get();
        if (byNickname.docs.isNotEmpty) {
          uid = byNickname.docs.first.id;
        }
      } catch (_) {}
    }

    _cache[normalized] = _UsernameCacheEntry(
      uid: uid,
      cachedAt: DateTime.now(),
    );
    return uid;
  }
}

class _UsernameCacheEntry {
  const _UsernameCacheEntry({
    required this.uid,
    required this.cachedAt,
  });

  final String? uid;
  final DateTime cachedAt;
}
