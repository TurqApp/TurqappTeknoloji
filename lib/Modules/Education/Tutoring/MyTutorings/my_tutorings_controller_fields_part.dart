part of 'my_tutorings_controller.dart';

class _MyTutoringsControllerState {
  final UserSummaryResolver userSummaryResolver = UserSummaryResolver.ensure();
  final TutoringRepository tutoringRepository = TutoringRepository.ensure();
  final RxList<TutoringModel> myTutorings = <TutoringModel>[].obs;
  final RxMap<String, Map<String, dynamic>> users =
      <String, Map<String, dynamic>>{}.obs;
  final RxString errorMessage = ''.obs;
  final RxList<TutoringModel> activeTutorings = <TutoringModel>[].obs;
  final RxList<TutoringModel> expiredTutorings = <TutoringModel>[].obs;
  final PageController pageController = PageController();
  final RxInt selection = 0.obs;
  final RxBool isLoading = true.obs;
}

extension MyTutoringsControllerFieldsPart on MyTutoringsController {
  UserSummaryResolver get _userSummaryResolver => _state.userSummaryResolver;
  TutoringRepository get _tutoringRepository => _state.tutoringRepository;
  RxList<TutoringModel> get myTutorings => _state.myTutorings;
  RxMap<String, Map<String, dynamic>> get users => _state.users;
  RxString get errorMessage => _state.errorMessage;
  RxList<TutoringModel> get activeTutorings => _state.activeTutorings;
  RxList<TutoringModel> get expiredTutorings => _state.expiredTutorings;
  PageController get pageController => _state.pageController;
  RxInt get selection => _state.selection;
  RxBool get isLoading => _state.isLoading;
}
