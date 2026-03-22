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

  final RxList<Map<String, dynamic>> leaderboard = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = true.obs;
  final userPoint = 0.obs;
  final userRank = 0.obs;
  final now = DateTime.now();
  static const _excludedRozet = {'turkuaz'};
  final AntremanRepository _antremanRepository = AntremanRepository.ensure();
  final UserRepository _userRepository = UserRepository.ensure();
  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();
  String get monthName => _monthKeyFor(DateTime.now().month).tr;

  String get _monthKey {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    return '${now.year}-$month';
  }

  String _monthKeyFor(int month) {
    switch (month) {
      case 1:
        return 'common.month.january';
      case 2:
        return 'common.month.february';
      case 3:
        return 'common.month.march';
      case 4:
        return 'common.month.april';
      case 5:
        return 'common.month.may';
      case 6:
        return 'common.month.june';
      case 7:
        return 'common.month.july';
      case 8:
        return 'common.month.august';
      case 9:
        return 'common.month.september';
      case 10:
        return 'common.month.october';
      case 11:
        return 'common.month.november';
      case 12:
        return 'common.month.december';
      default:
        return 'common.month.january';
    }
  }

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
