import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

const double _androidNavigationFallback = 48;

double systemNavigationBottomInset(BuildContext context) {
  final media = MediaQuery.maybeOf(context);
  if (media == null) return 0;
  final view = View.maybeOf(context);
  final viewBottom = view == null
      ? 0.0
      : math.max(view.viewPadding.bottom, view.padding.bottom) /
          view.devicePixelRatio;

  final systemBottom = math.max(
    viewBottom,
    math.max(
      media.viewPadding.bottom,
      math.max(
        media.padding.bottom,
        media.systemGestureInsets.bottom,
      ),
    ),
  );

  return defaultTargetPlatform == TargetPlatform.android
      ? math.max(systemBottom, _androidNavigationFallback)
      : systemBottom;
}

double systemNavigationAwareBottom(
  BuildContext context, {
  double spacing = 20,
}) {
  return systemNavigationBottomInset(context) + spacing;
}

double androidNavigationAwareBottom(
  BuildContext context, {
  double spacing = 20,
}) {
  if (defaultTargetPlatform != TargetPlatform.android) return spacing;
  return systemNavigationAwareBottom(context, spacing: spacing);
}
