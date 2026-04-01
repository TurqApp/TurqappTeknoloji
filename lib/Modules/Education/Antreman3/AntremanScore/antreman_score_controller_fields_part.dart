part of 'antreman_score_controller_library.dart';

class _AntremanScoreControllerState {
  final leaderboard = <Map<String, dynamic>>[].obs;
  final isLoading = true.obs;
  final userPoint = 0.obs;
  final userRank = 0.obs;
  final now = DateTime.now();
  final antremanRepository = AntremanRepository.ensure();
  final userRepository = UserRepository.ensure();
  final userSummaryResolver = UserSummaryResolver.ensure();
}

extension AntremanScoreControllerFieldsPart on AntremanScoreController {
  RxList<Map<String, dynamic>> get leaderboard => _state.leaderboard;
  RxBool get isLoading => _state.isLoading;
  RxInt get userPoint => _state.userPoint;
  RxInt get userRank => _state.userRank;
  DateTime get now => _state.now;
  AntremanRepository get _antremanRepository => _state.antremanRepository;
  UserRepository get _userRepository => _state.userRepository;
  UserSummaryResolver get _userSummaryResolver => _state.userSummaryResolver;

  String get monthName => _monthKeyFor(DateTime.now().month).tr;

  String get _monthKey {
    final current = DateTime.now();
    final month = current.month.toString().padLeft(2, '0');
    return '${current.year}-$month';
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
}
