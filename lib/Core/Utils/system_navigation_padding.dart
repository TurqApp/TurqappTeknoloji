import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

const double _androidNavigationFallback = 48;

double systemNavigationAwareBottom(
  BuildContext context, {
  double spacing = 20,
}) {
  final media = MediaQuery.maybeOf(context);
  if (media == null) return spacing;

  final systemBottom = math.max(
    media.viewPadding.bottom,
    math.max(media.padding.bottom, media.viewInsets.bottom),
  );
  final navigationBottom = defaultTargetPlatform == TargetPlatform.android
      ? math.max(systemBottom, _androidNavigationFallback)
      : systemBottom;

  return navigationBottom + spacing;
}
