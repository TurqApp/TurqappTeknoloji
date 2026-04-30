part of 'deep_link_service.dart';

extension _DeepLinkServiceRuntimeX on DeepLinkService {
  static const Duration _pendingDrainDelay = Duration(milliseconds: 500);
  static const int _maxPendingDrainAttempts = 40;

  void start() {
    if (_started) return;
    _started = true;
    initialLinkResolved.value = false;
    _linkSubscription?.cancel();
    _linkSubscription = _eventChannel.receiveBroadcastStream().listen(
      _onNativeDeepLinkEvent,
      onError: (_) {},
    );
    unawaited(_resolveInitialLink());
  }

  Future<void> handle(Uri uri) async {
    if (_handling) return;
    final parsed = _parse(uri);
    if (parsed == null) return;

    _handling = true;
    try {
      if (CurrentUserService.instance.effectiveUserId.isEmpty) {
        return;
      }

      if (shouldOpenEducationDeepLinkDirectly(parsed)) {
        await _openEducationLink(parsed.id);
        return;
      }
      if (parsed.type == 'market') {
        await _openMarket(parsed.id);
        return;
      }

      final resolved = await _shortLinkService.resolve(
        type: parsed.type,
        id: parsed.id,
      );

      final data = Map<String, dynamic>.from(
        _cloneDeepLinkStoryDocMap(
          (resolved['data'] as Map? ?? const {}).map(
            (key, value) => MapEntry(key.toString(), value),
          ),
        ),
      );
      final entityId = (data['entityId'] ?? '').toString().trim();
      if (entityId.isEmpty) {
        final handled = await _tryDirectFallback(parsed);
        if (!handled) {
          AppSnackbar('common.info'.tr, 'deep_link.resolve_failed'.tr);
        }
        return;
      }

      switch (parsed.type) {
        case 'post':
          await _openPost(entityId);
          return;
        case 'story':
          await _openStory(entityId);
          return;
        case 'user':
          await _openUserProfile(entityId);
          return;
        case 'edu':
          await _openEducationLink(entityId);
          return;
        case 'market':
          await _openMarket(entityId);
          return;
      }
    } catch (_) {
      final handled = await _tryDirectFallback(parsed);
      if (!handled) {
        AppSnackbar('common.info'.tr, 'deep_link.open_failed'.tr);
      }
    } finally {
      _handling = false;
    }
  }

  Future<void> _resolveInitialLink() async {
    try {
      final rawLink = await _methodChannel.invokeMethod<String>(
        'getInitialLink',
      );
      final normalizedLink = rawLink?.trim() ?? '';
      if (normalizedLink.isEmpty) return;
      final uri = Uri.tryParse(normalizedLink);
      if (uri == null) return;
      await _handleOrQueue(uri);
    } catch (_) {
      return;
    } finally {
      initialLinkResolved.value = true;
    }
  }

  void _onNativeDeepLinkEvent(Object? event) {
    final rawLink = event?.toString().trim() ?? '';
    if (rawLink.isEmpty) return;
    final uri = Uri.tryParse(rawLink);
    if (uri == null) return;
    unawaited(_handleOrQueue(uri));
  }

  Future<void> _handleOrQueue(Uri uri) async {
    if (!_canHandleNow) {
      _pendingUri = uri;
      _pendingDrainAttempts = 0;
      _schedulePendingDrain();
      return;
    }
    _pendingUri = null;
    _clearPendingDrain();
    await handle(uri);
  }

  bool get _canHandleNow =>
      Get.key.currentContext != null &&
      _currentRouteAllowsDeepLinkHandling &&
      CurrentUserService.instance.effectiveUserId.isNotEmpty &&
      !_handling;

  bool get _currentRouteAllowsDeepLinkHandling {
    final route = Get.currentRoute.trim();
    if (route.isEmpty) return false;
    return route != '/SplashView' && route != 'SplashView';
  }

  void _schedulePendingDrain() {
    _pendingDrainTimer?.cancel();
    _pendingDrainTimer = Timer(_pendingDrainDelay, () {
      unawaited(_drainPendingLink());
    });
  }

  Future<void> _drainPendingLink() async {
    final pendingUri = _pendingUri;
    if (pendingUri == null) {
      _clearPendingDrain();
      return;
    }
    if (_canHandleNow) {
      _pendingUri = null;
      _clearPendingDrain();
      await handle(pendingUri);
      return;
    }
    _pendingDrainAttempts += 1;
    if (_pendingDrainAttempts >= _maxPendingDrainAttempts) {
      _pendingUri = null;
      _clearPendingDrain();
      return;
    }
    _schedulePendingDrain();
  }

  void _clearPendingDrain() {
    _pendingDrainTimer?.cancel();
    _pendingDrainTimer = null;
    _pendingDrainAttempts = 0;
  }

  void disposeRuntime() {
    _pendingUri = null;
    _clearPendingDrain();
    _linkSubscription?.cancel();
    _linkSubscription = null;
    _started = false;
  }
}
