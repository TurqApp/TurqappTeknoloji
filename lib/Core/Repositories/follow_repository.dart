import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Services/read_budget_registry.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'follow_repository_query_part.dart';
part 'follow_repository_action_part.dart';
part 'follow_repository_models_part.dart';
part 'follow_repository_cache_part.dart';

class FollowRepository extends GetxService {
  static const Duration _ttl = Duration(minutes: 15);
  static const String _prefsKeyPrefix = 'follow_repository_v1';
  static const String _relationPrefsKeyPrefix = 'follow_relation_repository_v1';

  static FollowRepository? maybeFind() {
    final isRegistered = Get.isRegistered<FollowRepository>();
    if (!isRegistered) return null;
    return Get.find<FollowRepository>();
  }

  static FollowRepository ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(FollowRepository(), permanent: true);
  }

  SharedPreferences? _prefs;
  final Map<String, _CachedFollowingSet> _memory = {};
  final Map<String, _CachedFollowingSet> _relationMemory = {};

  @override
  void onInit() {
    super.onInit();
    _handleFollowRepositoryInit();
  }
}

class FollowWriteResult {
  final bool nowFollowing;
  final bool limitReached;

  const FollowWriteResult({
    required this.nowFollowing,
    required this.limitReached,
  });
}
