import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Services/typesense_user_card_cache_service.dart';
import 'package:turqappv2/Core/Utils/avatar_url.dart';

part 'user_summary_resolver_data_part.dart';

class UserSummaryResolver extends GetxService {
  static UserSummaryResolver? maybeFind() {
    final isRegistered = Get.isRegistered<UserSummaryResolver>();
    if (!isRegistered) return null;
    return Get.find<UserSummaryResolver>();
  }

  static UserSummaryResolver ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(UserSummaryResolver(), permanent: true);
  }

  UserRepository get _users => UserRepository.ensure();
  TypesenseUserCardCacheService get _typesenseCards =>
      TypesenseUserCardCacheService.ensure();

  Future<UserSummary?> resolve(
    String uid, {
    bool preferCache = true,
    bool cacheOnly = false,
    bool forceServer = false,
  }) async {
    if (uid.trim().isEmpty) return null;
    if (!forceServer) {
      final local = await _users.getUser(
        uid,
        preferCache: preferCache,
        cacheOnly: cacheOnly,
      );
      if (local != null) return local;
      final cards = await _typesenseCards.getUserCardsByIds(
        <String>[uid],
        preferCache: preferCache,
        cacheOnly: cacheOnly,
      );
      final card = cards[uid.trim()];
      if (card != null && card.isNotEmpty) {
        await _users.putUserRaw(uid.trim(), card);
        return UserSummary.fromMap(uid.trim(), card);
      }
      return null;
    }
    final raw = await _users.getUserRaw(
      uid,
      preferCache: false,
      cacheOnly: cacheOnly,
      forceServer: true,
    );
    if (raw == null || raw.isEmpty) return null;
    return UserSummary.fromMap(uid.trim(), raw);
  }

  UserSummary? peek(
    String uid, {
    bool allowStale = true,
  }) {
    return _users.peekUser(uid, allowStale: allowStale);
  }

  Future<void> seedRaw(
    String uid,
    Map<String, dynamic> raw,
  ) async {
    if (uid.trim().isEmpty || raw.isEmpty) return;
    await _users.putUserRaw(uid, raw);
  }
}
