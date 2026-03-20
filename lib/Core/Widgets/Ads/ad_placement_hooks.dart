import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/Ads/ad_slot_service.dart';
import 'package:turqappv2/Core/Widgets/Ads/ad_renderer.dart';

class FeedAdPlacementHook extends StatelessWidget {
  FeedAdPlacementHook({super.key, required this.index});

  final int index;
  final AdSlotService _slotService = const AdSlotService();

  @override
  Widget build(BuildContext context) {
    final slot = _slotService.buildFeedSlot(index);
    return AdRenderer(slot: slot, title: 'ads.sponsored'.tr);
  }
}

class ShortsAdPlacementHook extends StatelessWidget {
  ShortsAdPlacementHook({super.key, required this.index});

  final int index;
  final AdSlotService _slotService = const AdSlotService();

  @override
  Widget build(BuildContext context) {
    final slot = _slotService.buildShortsSlot(index);
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: 70),
        child: AdRenderer(slot: slot, title: 'ads.sponsored_shorts'.tr),
      ),
    );
  }
}

class ExploreAdPlacementHook extends StatelessWidget {
  ExploreAdPlacementHook({super.key, required this.index});

  final int index;
  final AdSlotService _slotService = const AdSlotService();

  @override
  Widget build(BuildContext context) {
    final slot = _slotService.buildExploreSlot(index);
    return AdRenderer(slot: slot, title: 'ads.sponsored_explore'.tr);
  }
}
