import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class ReshareHelper {
  // Nickname cache - bellekte tutulan kullanıcı adları
  static final Map<String, String> _nicknameCache = {};
  static final Map<String, String> _displayNameCache = {};

  // Cache temizleme için zaman damgası
  static DateTime? _lastCacheCleanup;

  /// Kullanıcının nickname'ini userID'den alır (cache ile)
  static Future<String> getUserNickname(String userID) async {
    try {
      final safeUserID = userID.trim();
      if (safeUserID.isEmpty) return 'Bilinmeyen Kullanıcı';

      final me = FirebaseAuth.instance.currentUser?.uid;
      if (me != null &&
          safeUserID == me &&
          Get.isRegistered<CurrentUserService>()) {
        final current = Get.find<CurrentUserService>();
        final myNickname = current.nickname.trim();
        if (myNickname.isNotEmpty) {
          _nicknameCache[safeUserID] = myNickname;
          return myNickname;
        }
      }

      // Cache'te var mı kontrol et
      if (_nicknameCache.containsKey(safeUserID)) {
        return _nicknameCache[safeUserID]!;
      }

      String nickname = 'Bilinmeyen Kullanıcı';
      final summary = await UserRepository.ensure().getUser(
        safeUserID,
        preferCache: true,
        cacheOnly: false,
      );
      if (summary != null) {
        final resolved = summary.nickname.trim().isNotEmpty
            ? summary.nickname.trim()
            : (summary.username.trim().isNotEmpty
                ? summary.username.trim()
                : summary.preferredName.trim());
        if (resolved.isNotEmpty) {
          nickname = resolved;
        }
      }

      // Cache'e ekle
      _nicknameCache[safeUserID] = nickname;

      // Periodik cache temizleme (her 30 dakikada bir)
      _cleanupCacheIfNeeded();

      return nickname;
    } catch (e) {
      print('ReshareHelper: getUserNickname error: $e');
      return 'Bilinmeyen Kullanıcı';
    }
  }

  /// Kullanıcının görüntülenecek adını alır (displayName/fullName fallback nickname)
  static Future<String> getUserDisplayName(String userID) async {
    try {
      final safeUserID = userID.trim();
      if (safeUserID.isEmpty) return 'Bilinmeyen Kullanıcı';

      final me = FirebaseAuth.instance.currentUser?.uid;
      if (me != null &&
          safeUserID == me &&
          Get.isRegistered<CurrentUserService>()) {
        final current = Get.find<CurrentUserService>();
        final myFullName = current.fullName.trim();
        final myNickname = current.nickname.trim();
        final resolved = myFullName.isNotEmpty
            ? myFullName
            : (myNickname.isNotEmpty ? myNickname : '');
        if (resolved.isNotEmpty) {
          _displayNameCache[safeUserID] = resolved;
          return resolved;
        }
      }

      if (_displayNameCache.containsKey(safeUserID)) {
        return _displayNameCache[safeUserID]!;
      }

      String displayName = 'Bilinmeyen Kullanıcı';
      final summary = await UserRepository.ensure().getUser(
        safeUserID,
        preferCache: true,
        cacheOnly: false,
      );
      if (summary != null) {
        final resolved = summary.preferredName.trim();
        if (resolved.isNotEmpty) {
          displayName = resolved;
        }
      }

      _displayNameCache[safeUserID] = displayName;
      _cleanupCacheIfNeeded();
      return displayName;
    } catch (e) {
      print('ReshareHelper: getUserDisplayName error: $e');
      return 'Bilinmeyen Kullanıcı';
    }
  }

  static String? getCachedDisplayName(String userID) {
    return _displayNameCache[userID];
  }

  /// Senkron olarak cache'ten nickname al (cache'te yoksa null döner)
  static String? getCachedNickname(String userID) {
    return _nicknameCache[userID];
  }

  /// Cache'i manuel olarak temizle
  static void clearNicknameCache() {
    _nicknameCache.clear();
    _displayNameCache.clear();
    _lastCacheCleanup = DateTime.now();
  }

  /// Belirli bir kullanıcıyı cache'e ekle
  static void cacheNickname(String userID, String nickname) {
    _nicknameCache[userID] = nickname;
  }

  /// Cache temizleme (30 dakikada bir otomatik)
  static void _cleanupCacheIfNeeded() {
    final now = DateTime.now();
    if (_lastCacheCleanup == null ||
        now.difference(_lastCacheCleanup!).inMinutes > 30) {
      // Cache boyutu 1000'den fazlaysa yarısını temizle
      if (_nicknameCache.length > 1000) {
        final keysToRemove = _nicknameCache.keys.take(500).toList();
        for (final key in keysToRemove) {
          _nicknameCache.remove(key);
        }
      }

      _lastCacheCleanup = now;
    }
  }

  /// Post'un orijinal sahibini ve ana post ID'sini belirler
  /// Eğer post zaten reshare edilmişse orijinal bilgileri döner
  /// Değilse post'un kendi sahibini ve ID'sini döner
  static Future<Map<String, String>> getOriginalUserInfo(
    String postUserID,
    String? existingOriginalUserID,
    String? existingOriginalPostID,
  ) async {
    print('ReshareHelper.getOriginalUserInfo called:');
    print('  postUserID: $postUserID');
    print('  existingOriginalUserID: $existingOriginalUserID');
    print('  existingOriginalPostID: $existingOriginalPostID');

    // Eğer post zaten bir reshare ise, orijinal bilgileri koru
    if (existingOriginalUserID != null && existingOriginalUserID.isNotEmpty) {
      print('  -> Returning existing original user info');
      return {
        'userID': existingOriginalUserID,
        'originalPostID': existingOriginalPostID ?? '',
      };
    }

    // İlk kez reshare ediliyorsa, post sahibinin bilgilerini al
    print('  -> First time reshare, setting original user and post info');
    return {
      'userID': postUserID,
      'originalPostID':
          '', // İlk paylaşımda boş kalacak çünkü kendisi ana paylaşım
    };
  }

  /// Dinamik paylaşım zinciri için original bilgileri belirler
  /// A -> B -> C zincirinde C paylaştığında A'nın bilgileri ve A'nın post ID'si döner
  static Future<Map<String, String>> getDynamicOriginalInfo(
    String currentPostID,
    String currentUserID,
    String? existingOriginalUserID,
    String? existingOriginalPostID,
  ) async {
    print('ReshareHelper.getDynamicOriginalInfo called:');
    print('  currentPostID: $currentPostID');
    print('  currentUserID: $currentUserID');
    print('  existingOriginalUserID: $existingOriginalUserID');
    print('  existingOriginalPostID: $existingOriginalPostID');

    // Eğer mevcut post zaten bir paylaşım ise (originalUserID dolu)
    if (existingOriginalUserID != null && existingOriginalUserID.isNotEmpty) {
      print('  -> Post is already a reshare, keeping original chain');
      return {
        'userID': existingOriginalUserID,
        'originalPostID': existingOriginalPostID ?? '',
      };
    }

    // Eğer ilk kez paylaşılıyorsa, mevcut post'un sahibi ve ID'si ana referans olur
    print('  -> First time reshare, setting current post as original source');
    return {
      'userID': currentUserID,
      'originalPostID': currentPostID,
    };
  }
}
