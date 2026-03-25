import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Repositories/follow_repository.dart';

part 'profile_stats_repository_metrics_part.dart';
part 'profile_stats_repository_cache_part.dart';

class ProfileStatsRepository extends GetxService {
  static const Duration _ttl = Duration(minutes: 20);
  static const String _prefsPrefix = 'profile_stats_repository_v1';

  SharedPreferences? _prefs;
  final Map<String, _CachedProfileStats> _memory = {};
  final FollowRepository _followRepository = FollowRepository.ensure();

  static ProfileStatsRepository? maybeFind() {
    final isRegistered = Get.isRegistered<ProfileStatsRepository>();
    if (!isRegistered) return null;
    return Get.find<ProfileStatsRepository>();
  }

  static ProfileStatsRepository ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(ProfileStatsRepository(), permanent: true);
  }

  @override
  void onInit() {
    super.onInit();
    SharedPreferences.getInstance().then((prefs) {
      _prefs = prefs;
    });
  }
}
