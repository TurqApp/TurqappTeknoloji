import 'dart:async';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/local_preference_repository.dart';
import 'package:turqappv2/Core/Services/feed_playback_selection_policy.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Core/Services/integration_test_mode.dart';
import 'package:turqappv2/Core/Services/read_budget_registry.dart';
import 'package:turqappv2/Core/Widgets/app_state_view.dart';
import 'package:turqappv2/Core/Widgets/search_reset_on_page_return_scope.dart';
import 'package:turqappv2/Core/Widgets/turq_search_bar.dart';
import 'package:turqappv2/Core/Widgets/Ads/ad_placement_hooks.dart';
import 'package:turqappv2/Core/functions.dart';
import 'package:turqappv2/Core/page_line_bar.dart';
import 'package:turqappv2/Core/texts.dart';
import 'package:turqappv2/Modules/Short/single_short_view.dart';
import 'package:turqappv2/Models/posts_model.dart';
import '../../Core/Helpers/RoadToTop/road_to_top.dart';
import '../Agenda/TagPosts/tag_media_widgets.dart';
import '../Agenda/TagPosts/tag_posts.dart';
import '../Agenda/FloodListing/flood_listing.dart';
import '../Agenda/AgendaContent/agenda_content.dart';
import 'SearchedUser/search_user_content.dart';
import 'explore_controller.dart';

part 'explore_view_content_part.dart';
part 'explore_view_tabs_part.dart';

class StaggeredTile {
  final int crossAxisCellCount;
  final num mainAxisCellCount;

  const StaggeredTile.count(this.crossAxisCellCount, this.mainAxisCellCount);
}

class SliverStaggeredGrid {
  static Widget countBuilder({
    required int crossAxisCount,
    required int itemCount,
    required IndexedWidgetBuilder itemBuilder,
    required StaggeredTile Function(int) staggeredTileBuilder,
    double mainAxisSpacing = 0,
    double crossAxisSpacing = 0,
  }) {
    return SliverMasonryGrid.count(
      crossAxisCount: crossAxisCount,
      childCount: itemCount,
      mainAxisSpacing: mainAxisSpacing,
      crossAxisSpacing: crossAxisSpacing,
      itemBuilder: (context, index) {
        final tile = staggeredTileBuilder(index);
        final aspectRatio = tile.mainAxisCellCount == 0
            ? 1.0
            : tile.crossAxisCellCount / tile.mainAxisCellCount;
        return AspectRatio(
          aspectRatio: aspectRatio.toDouble(),
          child: itemBuilder(context, index),
        );
      },
    );
  }
}

class ExploreView extends StatefulWidget {
  const ExploreView({super.key});

  @override
  State<ExploreView> createState() => _ExploreViewState();
}

class _ExploreViewState extends State<ExploreView> {
  static const String _floodRotationPrefsKey = 'explore_flood_rotation_v1';
  static const int _floodRotationMemoryCount = 8;

  late final ExploreController controller;
  bool _ownsController = false;
  final int _floodSessionShuffleSeed = Random().nextInt(1 << 30);
  bool _didApplyFloodSessionOrder = false;

  bool _isExploreSurfaceActive() {
    final route = Get.currentRoute.trim();
    if (route == '/NavBarView' || route == 'NavBarView') {
      return false;
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    if (IntegrationTestMode.enabled) {
      debugPrint('[integration-smoke] ExploreView.initState');
    }
    final existingController = maybeFindExploreController();
    if (existingController != null) {
      controller = existingController;
    } else {
      controller = ensureExploreController();
      _ownsController = true;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isExploreSurfaceActive()) {
        unawaited(controller.onPrimarySurfaceVisible());
      }
    });
  }

  @override
  void dispose() {
    if (IntegrationTestMode.enabled) {
      debugPrint(
          '[integration-smoke] ExploreView.dispose owns=$_ownsController');
    }
    if (_ownsController &&
        identical(maybeFindExploreController(), controller)) {
      Get.delete<ExploreController>();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final body = Scaffold(
      key: const ValueKey(IntegrationTestKeys.screenExplore),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                _buildSearchHeader(context),
                _buildExploreOrSearchBody(context),
              ],
            ),
            _buildScrollToTopButton(),
            IgnorePointer(
              ignoring: true,
              child: Align(
                alignment: Alignment.topCenter,
                child: ExploreAdPlacementHook(index: 0),
              ),
            ),
          ],
        ),
      ),
    );

    if (IntegrationTestMode.enabled) {
      return body;
    }

    return SearchResetOnPageReturnScope(
      onReset: controller.resetSearchToDefault,
      child: body,
    );
  }
}
