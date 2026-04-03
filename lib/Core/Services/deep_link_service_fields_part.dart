part of 'deep_link_service.dart';

class _DeepLinkServiceState {
  final shortLinkService = ShortLinkService();
  final userSummaryResolver = UserSummaryResolver.ensure();
  final visibilityPolicy = VisibilityPolicyService.ensure();
  final methodChannel = const MethodChannel('turqapp.deep_link/method');
  final eventChannel = const EventChannel('turqapp.deep_link/events');
  bool started = false;
  bool handling = false;
  final initialLinkResolved = false.obs;
  StreamSubscription<dynamic>? linkSubscription;
  Timer? pendingDrainTimer;
  Uri? pendingUri;
  int pendingDrainAttempts = 0;
}

extension DeepLinkServiceFieldsPart on DeepLinkService {
  ShortLinkService get _shortLinkService => _state.shortLinkService;
  UserSummaryResolver get _userSummaryResolver => _state.userSummaryResolver;
  VisibilityPolicyService get _visibilityPolicy => _state.visibilityPolicy;
  MethodChannel get _methodChannel => _state.methodChannel;
  EventChannel get _eventChannel => _state.eventChannel;
  bool get _started => _state.started;
  set _started(bool value) => _state.started = value;
  bool get _handling => _state.handling;
  set _handling(bool value) => _state.handling = value;
  RxBool get initialLinkResolved => _state.initialLinkResolved;
  StreamSubscription<dynamic>? get _linkSubscription => _state.linkSubscription;
  set _linkSubscription(StreamSubscription<dynamic>? value) =>
      _state.linkSubscription = value;
  Timer? get _pendingDrainTimer => _state.pendingDrainTimer;
  set _pendingDrainTimer(Timer? value) => _state.pendingDrainTimer = value;
  Uri? get _pendingUri => _state.pendingUri;
  set _pendingUri(Uri? value) => _state.pendingUri = value;
  int get _pendingDrainAttempts => _state.pendingDrainAttempts;
  set _pendingDrainAttempts(int value) => _state.pendingDrainAttempts = value;
}
