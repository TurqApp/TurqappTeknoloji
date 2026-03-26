part of 'deneme_sinavi_preview_controller.dart';

class _DenemeSinaviPreviewControllerState {
  final userSummaryResolver = UserSummaryResolver.ensure();
  final practiceExamRepository = PracticeExamRepository.ensure();
  final displayName = ''.obs;
  final nickname = ''.obs;
  final avatarUrl = ''.obs;
  final dahaOnceBasvurdu = false.obs;
  final basvuranSayisi = 0.obs;
  final currentTime = DateTime.now().millisecondsSinceEpoch.obs;
  final showSucces = false.obs;
  final sinavaGirebilir = false.obs;
  final examTime = 0.obs;
  final isLoading = true.obs;
  final isInitialized = false.obs;
  final isSaved = false.obs;
}

extension DenemeSinaviPreviewControllerFieldsPart
    on DenemeSinaviPreviewController {
  UserSummaryResolver get _userSummaryResolver => _state.userSummaryResolver;
  PracticeExamRepository get _practiceExamRepository =>
      _state.practiceExamRepository;
  RxString get displayName => _state.displayName;
  RxString get nickname => _state.nickname;
  RxString get avatarUrl => _state.avatarUrl;
  RxBool get dahaOnceBasvurdu => _state.dahaOnceBasvurdu;
  RxInt get basvuranSayisi => _state.basvuranSayisi;
  RxInt get currentTime => _state.currentTime;
  RxBool get showSucces => _state.showSucces;
  RxBool get sinavaGirebilir => _state.sinavaGirebilir;
  RxInt get examTime => _state.examTime;
  RxBool get isLoading => _state.isLoading;
  RxBool get isInitialized => _state.isInitialized;
  RxBool get isSaved => _state.isSaved;
  String get _currentUserId => _currentPracticeExamPreviewUserId();
}
