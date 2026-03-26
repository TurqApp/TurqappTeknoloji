part of 'personalized_controller.dart';

class PersonalizedController extends GetxController {
  static String? _activeTag;

  static PersonalizedController ensure({
    required String tag,
    bool permanent = false,
  }) =>
      _ensurePersonalizedController(tag: tag, permanent: permanent);

  static PersonalizedController? maybeFind({String? tag}) =>
      _maybeFindPersonalizedController(tag: tag);

  final UserRepository _userRepository = UserRepository.ensure();
  final ScholarshipRepository _scholarshipRepository =
      ScholarshipRepository.ensure();
  final _state = _PersonalizedControllerState();

  static const String _cacheKeyPrefix = 'personalized_scholarships_cache_v1';
  static const int _cacheLimit = 30;

  @override
  void onInit() {
    super.onInit();
    _handlePersonalizedControllerInit(this);
  }

  @override
  void onClose() {
    _handlePersonalizedControllerClose(this);
    super.onClose();
  }
}
