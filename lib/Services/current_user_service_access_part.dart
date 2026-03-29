part of 'current_user_service.dart';

extension CurrentUserServiceAccessPart on CurrentUserService {
  List<String> _normalizeBlockedUserIds(List<String>? source) {
    if (source == null || source.isEmpty) return const <String>[];
    return source
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
  }

  String get preferredLocationCityOrEmpty {
    final candidates = [
      _currentUser?.locationSehir,
      _currentUser?.city,
      _currentUser?.ikametSehir,
      _currentUser?.il,
      _currentUser?.ulke,
    ];
    for (final raw in candidates) {
      final value = (raw ?? '').trim();
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  String get preferredLocationCity {
    final value = preferredLocationCityOrEmpty;
    return value.isNotEmpty ? value : 'common.country_turkey'.tr;
  }

  List<String> get blockedUserIds =>
      _normalizeBlockedUserIds(_currentUser?.blockedUsers);

  bool get isPrivate => _currentUser?.isPrivate ?? false;

  bool get isBanned => _currentUser?.isBanned ?? false;

  Map<String, dynamic> getDebugInfo() {
    return {
      'isInitialized': _isInitialized,
      'isLoggedIn': isLoggedIn,
      'isSyncing': _isSyncing,
      'userId': userId,
      'nickname': nickname,
      'cacheExists': userId.isNotEmpty
          ? (_prefs?.containsKey(_cacheKey(userId)) ?? false)
          : false,
    };
  }

  void printDebugInfo() {
    if (!kDebugMode) return;
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('CurrentUserService Debug Info:');
    getDebugInfo().forEach((key, value) {
      debugPrint('  $key: $value');
    });
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }
}
