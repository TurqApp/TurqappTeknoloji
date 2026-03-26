part of 'personalized_controller.dart';

String? _activePersonalizedControllerTag;
const String _personalizedCacheKeyPrefix = 'personalized_scholarships_cache_v1';
const int _personalizedCacheLimit = 30;

extension PersonalizedControllerSupportPart on PersonalizedController {
  UserRepository get _userRepository => UserRepository.ensure();

  ScholarshipRepository get _scholarshipRepository =>
      ensureScholarshipRepository();
}
