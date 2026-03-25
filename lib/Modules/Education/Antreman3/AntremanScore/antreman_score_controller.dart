import 'dart:developer';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/antreman_repository.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/rozet_permissions.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'antreman_score_controller_data_part.dart';
part 'antreman_score_controller_fields_part.dart';
part 'antreman_score_controller_rank_part.dart';

class AntremanScoreController extends GetxController {
  static AntremanScoreController ensure({
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      AntremanScoreController(),
      tag: tag,
      permanent: permanent,
    );
  }

  static AntremanScoreController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<AntremanScoreController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<AntremanScoreController>(tag: tag);
  }

  static List<Map<String, dynamic>>? _cachedLeaderboard;
  static DateTime? _cachedAt;
  static String? _cachedMonthKey;
  static const Duration _cacheTtl = Duration(minutes: 2);
  static const _excludedRozet = {'turkuaz'};

  final _state = _AntremanScoreControllerState();

  @override
  void onInit() {
    super.onInit();
    final hasWarmCache = _applyWarmCache();
    if (hasWarmCache) {
      unawaited(fetchLeaderboard(showLoader: false));
    } else {
      fetchLeaderboard();
    }
    getUserAntPoint();
  }
}
