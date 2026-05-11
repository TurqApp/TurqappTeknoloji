import 'package:flutter/material.dart';
import 'package:turqappv2/Ads/admob_kare.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class FeedFamilyAdSlot extends StatelessWidget {
  const FeedFamilyAdSlot({
    super.key,
    required this.surfaceId,
    required this.slotNumber,
    this.placementId = 'feed',
    this.trailingClassicDivider = true,
  });

  final String surfaceId;
  final int slotNumber;
  final String placementId;
  final bool trailingClassicDivider;

  static const int interval = 3;

  static bool shouldInsertAfterPostIndex(int postIndex) {
    return postIndex >= 0 && (postIndex + 1) % interval == 0;
  }

  static int slotNumberForPostIndex(int postIndex) {
    return ((postIndex + 1) ~/ interval).clamp(1, 1 << 30);
  }

  @override
  Widget build(BuildContext context) {
    final isModernView =
        CurrentUserService.instance.effectiveViewSelection == 1;
    final edgeInsets = isModernView
        ? const EdgeInsets.fromLTRB(48, 8, 5, 8)
        : const EdgeInsets.fromLTRB(5, 8, 5, 0);

    final normalizedSurface =
        surfaceId.trim().isEmpty ? 'feed-family' : surfaceId.trim();
    final normalizedPlacement =
        placementId.trim().isEmpty ? 'feed' : placementId.trim();
    final normalizedSlot = slotNumber < 1 ? 1 : slotNumber;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: edgeInsets,
          child: AdmobKare(
            key: ValueKey('$normalizedSurface-ad-$normalizedSlot'),
            contentPadding: EdgeInsets.zero,
            liveAdOffsetX: 5,
            promoFallbackOffsetX: 0,
            promoFallbackExtraWidth: 0,
            forceSingleLinePromoChips: true,
            suggestionPlacementId: normalizedPlacement,
            adSlotId: '$normalizedSurface-ad-$normalizedSlot',
            disposeImmediatelyWhenHidden: true,
            preferManagedSuggestionSurface: normalizedPlacement == 'feed',
          ),
        ),
        if (!isModernView && trailingClassicDivider) ...[
          const SizedBox(height: 7),
          Divider(
            color: Colors.grey.withAlpha(20),
            height: 3,
          ),
          const SizedBox(height: 13),
        ],
      ],
    );
  }
}
