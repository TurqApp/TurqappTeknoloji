part of 'app_snackbar.dart';

void AppSnackbar(
  String title,
  String message, {
  Color? backgroundColor,
  Duration? duration,
  SnackPosition? snackPosition,
  EdgeInsets? margin,
  double? borderRadius,
  Widget? icon,
  Color? colorText,
  TextStyle? titleStyle,
  TextStyle? messageStyle,
  int? maxLines,
}) {
  final normalizedTitle = _normalizeSnackbarText(title);
  final normalizedMessage = _normalizeSnackbarText(message);
  final signature = '$normalizedTitle|$normalizedMessage';
  final now = DateTime.now();
  if (_lastSnackbarSignature == signature &&
      _lastSnackbarAt != null &&
      now.difference(_lastSnackbarAt!) < _snackbarDedupWindow) {
    return;
  }
  _lastSnackbarSignature = signature;
  _lastSnackbarAt = now;
  final palette = _resolvePalette(
    title: normalizedTitle,
    message: normalizedMessage,
    backgroundColor: backgroundColor,
  );
  final mergedTitleStyle = (titleStyle ??
          TextStyle(
            color: colorText ?? palette.text,
            fontSize: 13,
            fontFamily: "MontserratBold",
            height: 1.0,
          ))
      .copyWith(
    color: colorText ?? palette.text,
    overflow: TextOverflow.ellipsis,
  );
  final mergedMessageStyle = (messageStyle ??
          TextStyle(
            color: colorText ?? palette.text.withValues(alpha: 0.92),
            fontSize: 13,
            fontFamily: "MontserratMedium",
            height: 1.0,
          ))
      .copyWith(
    color: colorText ?? palette.text.withValues(alpha: 0.92),
    overflow: TextOverflow.ellipsis,
  );

  _queueAppSnackbar(
    _AppSnackbarRequest(
      title: normalizedTitle,
      message: normalizedMessage,
      backgroundColor: backgroundColor,
      duration: duration ?? const Duration(seconds: 3),
      snackPosition: snackPosition ?? SnackPosition.TOP,
      margin: margin ?? const EdgeInsets.fromLTRB(12, 10, 12, 0),
      borderRadius: borderRadius ?? 16,
      icon: icon,
      palette: palette,
      titleStyle: mergedTitleStyle,
      messageStyle: mergedMessageStyle,
      maxLines: maxLines ?? 1,
    ),
  );
}

void _queueAppSnackbar(_AppSnackbarRequest request) {
  _pendingSnackbarRequest = request;
  if (_snackbarPostFrameScheduled) return;
  _snackbarPostFrameScheduled = true;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _snackbarPostFrameScheduled = false;
    final next = _pendingSnackbarRequest;
    _pendingSnackbarRequest = null;
    if (next == null) return;
    _showAppSnackbarOverlay(next);
  });
}

void _showAppSnackbarOverlay(
  _AppSnackbarRequest request, {
  int attempt = 0,
}) {
  final overlay = _resolveSnackbarOverlay();
  if (overlay == null) {
    if (_scheduleSnackbarOverlayRetry(request, attempt)) return;
    debugPrint('[AppSnackbar] skipped: overlay is not available.');
    return;
  }

  _removeActiveAppSnackbar();
  final serial = ++_snackbarSerial;
  final entry = OverlayEntry(
    builder: (context) {
      final mediaPadding =
          MediaQuery.maybeOf(context)?.padding ?? EdgeInsets.zero;
      final isBottom = request.snackPosition == SnackPosition.BOTTOM;
      final verticalOffset = isBottom
          ? mediaPadding.bottom + request.margin.bottom
          : mediaPadding.top + request.margin.top;
      final snackbar = Dismissible(
        key: ValueKey<int>(serial),
        direction: DismissDirection.horizontal,
        onDismissed: (_) => _removeActiveAppSnackbar(serial: serial),
        child: Material(
          color: Colors.transparent,
          child: _buildAppSnackbarContent(request),
        ),
      );
      return Positioned(
        left: request.margin.left,
        right: request.margin.right,
        top: isBottom ? null : verticalOffset,
        bottom: isBottom ? verticalOffset : null,
        child: snackbar,
      );
    },
  );
  _activeSnackbarEntry = entry;
  overlay.insert(entry);
  _activeSnackbarTimer = Timer(
    request.duration,
    () => _removeActiveAppSnackbar(serial: serial),
  );
}

OverlayState? _resolveSnackbarOverlay() {
  final rootOverlay = navigatorKey.currentState?.overlay;
  if (rootOverlay != null) return rootOverlay;

  final getNavigatorOverlay = Get.key.currentState?.overlay;
  if (getNavigatorOverlay != null) return getNavigatorOverlay;

  for (final context in <BuildContext?>[
    Get.overlayContext,
    Get.key.currentContext,
    Get.context,
  ]) {
    if (context == null) continue;
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay != null) return overlay;
  }

  return null;
}

bool _scheduleSnackbarOverlayRetry(
  _AppSnackbarRequest request,
  int attempt,
) {
  if (attempt >= _snackbarOverlayMaxRetry) return false;
  Timer(
    _snackbarOverlayRetryDelay,
    () => _showAppSnackbarOverlay(request, attempt: attempt + 1),
  );
  return true;
}

Widget _buildAppSnackbarContent(_AppSnackbarRequest request) {
  return DecoratedBox(
    decoration: BoxDecoration(
      color: request.backgroundColor ?? request.palette.background,
      borderRadius: BorderRadius.circular(request.borderRadius),
      border: Border.all(color: request.palette.border),
      boxShadow: const [
        BoxShadow(
          color: Color(0x29000000),
          blurRadius: 18,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: request.palette.iconBadge,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: request.icon ??
                Icon(
                  request.palette.icon,
                  color: request.palette.text,
                  size: 16,
                ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  if (request.title.isNotEmpty)
                    TextSpan(text: request.title, style: request.titleStyle),
                  if (request.message.isNotEmpty)
                    TextSpan(
                      text: request.title.isNotEmpty
                          ? '  ${request.message}'
                          : request.message,
                      style: request.messageStyle,
                    ),
                ],
              ),
              maxLines: request.maxLines,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    ),
  );
}

void _removeActiveAppSnackbar({int? serial}) {
  if (serial != null && serial != _snackbarSerial) return;
  _activeSnackbarTimer?.cancel();
  _activeSnackbarTimer = null;
  final entry = _activeSnackbarEntry;
  _activeSnackbarEntry = null;
  try {
    entry?.remove();
  } catch (_) {}
}
