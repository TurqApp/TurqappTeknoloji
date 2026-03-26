part of 'deneme_sinavi_yap_controller.dart';

class _DenemeSinaviYapControllerConfig {
  _DenemeSinaviYapControllerConfig({
    required this.model,
    required this.sinaviBitir,
    required this.showGecersizAlert,
    required this.uyariAtla,
  })  : userSummaryResolver = UserSummaryResolver.ensure(),
        practiceExamRepository = PracticeExamRepository.ensure();

  final SinavModel model;
  final Function sinaviBitir;
  final Function showGecersizAlert;
  final bool uyariAtla;
  final UserSummaryResolver userSummaryResolver;
  final PracticeExamRepository practiceExamRepository;
}

extension DenemeSinaviYapControllerConfigX on DenemeSinaviYapController {
  SinavModel get model => _config.model;
  Function get sinaviBitir => _config.sinaviBitir;
  Function get showGecersizAlert => _config.showGecersizAlert;
  bool get uyariAtla => _config.uyariAtla;
  UserSummaryResolver get _userSummaryResolver => _config.userSummaryResolver;
  PracticeExamRepository get _practiceExamRepository =>
      _config.practiceExamRepository;
  String get _currentUserId => CurrentUserService.instance.effectiveUserId;
}
