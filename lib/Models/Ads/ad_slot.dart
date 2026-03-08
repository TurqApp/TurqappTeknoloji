import 'package:turqappv2/Models/Ads/ad_enums.dart';

class AdSlot {
  final String slotId;
  final AdPlacementType placement;
  final int indexHint;
  final bool enabled;

  const AdSlot({
    required this.slotId,
    required this.placement,
    required this.indexHint,
    required this.enabled,
  });
}
