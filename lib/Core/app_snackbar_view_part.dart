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

  if (Get.isSnackbarOpen) {
    Get.closeCurrentSnackbar();
  }
  Get.snackbar(
    '',
    '',
    snackStyle: SnackStyle.FLOATING,
    titleText: const SizedBox.shrink(),
    messageText: DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor ?? palette.background,
        borderRadius: BorderRadius.circular(borderRadius ?? 16),
        border: Border.all(color: palette.border),
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
                color: palette.iconBadge,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: icon ??
                  Icon(
                    palette.icon,
                    color: palette.text,
                    size: 16,
                  ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: normalizedTitle, style: mergedTitleStyle),
                    if (normalizedMessage.isNotEmpty)
                      TextSpan(
                        text: '  $normalizedMessage',
                        style: mergedMessageStyle,
                      ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    ),
    backgroundColor: Colors.transparent,
    snackPosition: snackPosition ?? SnackPosition.TOP,
    duration: duration ?? const Duration(seconds: 3),
    margin: margin ?? const EdgeInsets.fromLTRB(12, 10, 12, 0),
    borderRadius: borderRadius ?? 16,
    padding: EdgeInsets.zero,
    isDismissible: true,
    dismissDirection: DismissDirection.horizontal,
  );
}
