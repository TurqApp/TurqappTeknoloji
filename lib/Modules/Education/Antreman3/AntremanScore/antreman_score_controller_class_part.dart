part of 'antreman_score_controller.dart';

class AntremanScoreController extends _AntremanScoreControllerBase {
  static List<Map<String, dynamic>>? _cachedLeaderboard;
  static DateTime? _cachedAt;
  static String? _cachedMonthKey;
  static const Duration _cacheTtl = Duration(minutes: 2);
  static const _excludedRozet = {'turkuaz'};

  final _state = _AntremanScoreControllerState();
}
