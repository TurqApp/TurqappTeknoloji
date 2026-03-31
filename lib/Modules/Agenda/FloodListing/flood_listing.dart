import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/feed_playback_selection_policy.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Ads/admob_kare.dart';
import 'package:turqappv2/Modules/Agenda/Common/agenda_spacing.dart';
import 'package:turqappv2/Core/Widgets/app_header_action_button.dart';
import '../AgendaContent/agenda_content.dart';
import 'flood_listing_controller.dart';

class FloodListing extends StatefulWidget {
  final PostsModel mainModel;
  const FloodListing({super.key, required this.mainModel});

  @override
  State<FloodListing> createState() => _FloodListingState();
}

class _FloodListingState extends State<FloodListing> {
  late final FloodListingController controller;
  late final bool _ownsController;
  static const double _chainLineWidth = 2.0;
  static const Color _chainLineColor = Color(0xFFD7DCE2);
  static const double _headerHeight = 52;

  double _tailSpaceHeight() {
    final screenHeight = MediaQuery.of(context).size.height;
    return (screenHeight * 0.24).clamp(120.0, 200.0);
  }

  double _chainLeftOffset() =>
      AgendaSpacing.modernContainerPadding.left + AgendaSpacing.avatarRadius;

  @override
  void initState() {
    super.initState();
    final existingController = maybeFindFloodListingController();
    if (existingController != null) {
      controller = existingController;
      _ownsController = false;
    } else {
      controller = ensureFloodListingController();
      _ownsController = true;
    }
    controller.getFloods(widget.mainModel.floodCount.toInt(),
        widget.mainModel.docID); // floodCount: 10 örnek
  }

  @override
  void dispose() {
    if (_ownsController &&
        identical(maybeFindFloodListingController(), controller)) {
      Get.delete<FloodListingController>(force: true);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        toolbarHeight: 0,
        elevation: 0,
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        bottom: false,
        child: Obx(() {
          final centeredIndex = controller.centeredIndex.value;

          return Stack(
            children: [
              ListView.builder(
                controller: controller.scrollController,
                padding: const EdgeInsets.only(top: _headerHeight),
                itemCount: controller.floods.length + 1,
                itemBuilder: (context, index) {
                  final tailSpace = _tailSpaceHeight();
                  if (index == controller.floods.length) {
                    if (controller.floods.length < 4) {
                      return Column(
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: AdmobKare(
                              suggestionPlacementId: 'feed',
                            ),
                          ),
                          SizedBox(height: tailSpace),
                        ],
                      );
                    }
                    return SizedBox(height: tailSpace);
                  }

                  final model = controller.floods[index];
                  final itemKey = controller.getFloodKey(docId: model.docID);
                  final isCentered = centeredIndex == index;
                  final shouldPlay =
                      FeedPlaybackSelectionPolicy.shouldPlayCenteredItem(
                    isCentered: isCentered,
                  );
                  final isLastItem = index == controller.floods.length - 1;

                  final contentWidget = AgendaContent(
                    key: itemKey,
                    model: model,
                    isPreview: true,
                    instanceTag: controller.floodInstanceTag(model.docID),
                    shouldPlay: shouldPlay,
                    suppressFloodBadge: true,
                  );

                  final children = <Widget>[];

                  children.add(
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Stack(
                        children: [
                          Positioned(
                            left: _chainLeftOffset(),
                            top: 0,
                            bottom: isLastItem ? null : 0,
                            height: isLastItem ? 44 : null,
                            child: Container(
                              width: _chainLineWidth,
                              decoration: BoxDecoration(
                                color: _chainLineColor,
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                          contentWidget,
                        ],
                      ),
                    ),
                  );

                  if ((index + 1) % 4 == 0) {
                    final slot = ((index + 1) ~/ 4);
                    children.add(
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: AdmobKare(
                          key: ValueKey('flood-ad-$slot'),
                          suggestionPlacementId: 'feed',
                        ),
                      ),
                    );
                  }

                  return Column(children: children);
                },
              ),
              const Positioned(
                top: 8,
                left: 12,
                child: AppBackButton(
                  icon: Icons.arrow_back_ios_new,
                  iconSize: 18,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
