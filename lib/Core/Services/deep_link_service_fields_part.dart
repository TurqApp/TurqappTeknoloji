part of 'deep_link_service.dart';

class _DeepLinkServiceState {
  final shortLinkService = ShortLinkService();
  final userSummaryResolver = UserSummaryResolver.ensure();
  final visibilityPolicy = VisibilityPolicyService.ensure();
  bool started = false;
  bool handling = false;
  final initialLinkResolved = false.obs;
}

extension DeepLinkServiceFieldsPart on DeepLinkService {
  ShortLinkService get _shortLinkService => _state.shortLinkService;
  UserSummaryResolver get _userSummaryResolver => _state.userSummaryResolver;
  VisibilityPolicyService get _visibilityPolicy => _state.visibilityPolicy;
  bool get _started => _state.started;
  set _started(bool value) => _state.started = value;
  bool get _handling => _state.handling;
  set _handling(bool value) => _state.handling = value;
  RxBool get initialLinkResolved => _state.initialLinkResolved;
}
