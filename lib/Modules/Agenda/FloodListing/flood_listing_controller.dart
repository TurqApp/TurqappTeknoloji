import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/explore_repository.dart';
import 'package:turqappv2/Core/Services/feed_playback_selection_policy.dart';
import 'package:turqappv2/Core/Services/SegmentCache/cache_manager.dart';
import 'package:turqappv2/Core/Services/SegmentCache/prefetch_scheduler.dart';
import 'package:turqappv2/Core/Repositories/post_repository.dart';
import 'package:turqappv2/Models/posts_model.dart';
import '../AgendaContent/agenda_content_controller.dart';

part 'flood_listing_controller_fields_part.dart';
part 'flood_listing_controller_runtime_part.dart';
part 'flood_listing_controller_data_part.dart';

class FloodListingController extends GetxController {
  final _state = _FloodListingControllerState();

  @override
  void onInit() {
    super.onInit();
    _handleOnInit();
  }

  @override
  void onClose() {
    _handleOnClose();
    super.onClose();
  }
}

FloodListingController ensureFloodListingController() =>
    maybeFindFloodListingController() ?? Get.put(FloodListingController());

FloodListingController? maybeFindFloodListingController() =>
    Get.isRegistered<FloodListingController>()
        ? Get.find<FloodListingController>()
        : null;
