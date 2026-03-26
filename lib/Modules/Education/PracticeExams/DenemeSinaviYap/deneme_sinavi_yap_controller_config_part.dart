part of 'deneme_sinavi_yap_controller.dart';

class _DenemeSinaviYapControllerConfig {
  const _DenemeSinaviYapControllerConfig({
    required this.model,
    required this.sinaviBitir,
    required this.showGecersizAlert,
    required this.uyariAtla,
  });

  final SinavModel model;
  final Function sinaviBitir;
  final Function showGecersizAlert;
  final bool uyariAtla;
  final UserSummaryResolver userSummaryResolver =
      const _DenemeUserSummaryHolder().resolver;
  final PracticeExamRepository practiceExamRepository =
      const _DenemePracticeExamHolder().repository;
}

class _DenemeUserSummaryHolder {
  const _DenemeUserSummaryHolder();
  UserSummaryResolver get resolver => UserSummaryResolver.ensure();
}

class _DenemePracticeExamHolder {
  const _DenemePracticeExamHolder();
  PracticeExamRepository get repository => PracticeExamRepository.ensure();
}

extension _DenemeSinaviYapControllerConfigPart on DenemeSinaviYapController {
  SinavModel get model => _config.model;
  Function get sinaviBitir => _config.sinaviBitir;
  Function get showGecersizAlert => _config.showGecersizAlert;
  bool get uyariAtla => _config.uyariAtla;
  UserSummaryResolver get _userSummaryResolver => _config.userSummaryResolver;
  PracticeExamRepository get _practiceExamRepository =>
      _config.practiceExamRepository;
  String get _currentUserId => CurrentUserService.instance.effectiveUserId;
}
