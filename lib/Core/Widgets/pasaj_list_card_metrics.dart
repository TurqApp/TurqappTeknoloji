import 'package:flutter/foundation.dart';

@immutable
class PasajListCardMetrics {
  static const double gridMediaAspectRatio = 0.78;

  const PasajListCardMetrics({
    required this.mediaSize,
    required this.railWidth,
    required this.railHeight,
    required this.actionButtonSize,
    required this.actionIconSize,
    required this.middleSlotHeight,
    required this.detailRowHeight,
    required this.ctaHeight,
    required this.ctaFontSize,
    required this.contentGap,
    required this.railActionGap,
    required this.railSectionGap,
  });

  final double mediaSize;
  final double railWidth;
  final double railHeight;
  final double actionButtonSize;
  final double actionIconSize;
  final double middleSlotHeight;
  final double detailRowHeight;
  final double ctaHeight;
  final double ctaFontSize;
  final double contentGap;
  final double railActionGap;
  final double railSectionGap;

  static const PasajListCardMetrics regular = PasajListCardMetrics(
    mediaSize: 88,
    railWidth: 108,
    railHeight: 88,
    actionButtonSize: 36,
    actionIconSize: 20,
    middleSlotHeight: 20,
    detailRowHeight: 16,
    ctaHeight: 30,
    ctaFontSize: 13,
    contentGap: 4,
    railActionGap: 6,
    railSectionGap: 10,
  );

  static PasajListCardMetrics forWidth(double width) {
    return regular;
  }
}
