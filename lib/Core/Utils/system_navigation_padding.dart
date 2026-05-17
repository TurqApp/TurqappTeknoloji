import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

double systemNavigationBottomInset(BuildContext context) {
  final media = MediaQuery.maybeOf(context);
  if (media == null) return 0;
  final view = View.maybeOf(context);
  final viewBottom = view == null
      ? 0.0
      : math.max(view.viewPadding.bottom, view.padding.bottom) /
          view.devicePixelRatio;

  // Gesture insets describe swipe-sensitive space, not a visible navigation bar.
  // Only reserve bottom space when Android reports an actual visible inset.
  return math.max(
    viewBottom,
    math.max(
      media.viewPadding.bottom,
      media.padding.bottom,
    ),
  );
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
