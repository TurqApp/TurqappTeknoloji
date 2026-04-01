part of 'visibility_policy_service.dart';

class _VisibilityPolicyServiceState {
  final resolver = UserSummaryResolver.ensure();
  final followRepository = ensureFollowRepository();
}

extension VisibilityPolicyServiceFieldsPart on VisibilityPolicyService {
  UserSummaryResolver get _resolver => _state.resolver;
  FollowRepository get _followRepository => _state.followRepository;
}
