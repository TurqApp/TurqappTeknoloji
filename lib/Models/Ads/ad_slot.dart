import 'package:turqappv2/Models/Ads/ad_enums.dart';

class AdSlot {
  final String slotId;
  final AdPlacementType placement;
  final int indexHint;
  final bool enabled;

  const AdSlot(this.slotId, this.placement, this.indexHint, this.enabled);
}
