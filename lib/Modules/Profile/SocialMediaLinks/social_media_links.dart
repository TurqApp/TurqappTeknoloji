import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reorderable_grid_view/widgets/reorderable_builder.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/BottomSheets/no_yes_alert.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Modules/Profile/SocialMediaLinks/social_media_links_controller.dart';

import '../../../Models/social_media_model.dart';

class SocialMediaLinks extends StatefulWidget {
  const SocialMediaLinks({super.key});

  @override
  State<SocialMediaLinks> createState() => _SocialMediaLinksState();
}

class _SocialMediaLinksState extends State<SocialMediaLinks> {
  late final SocialMediaController controller;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    final existingController = SocialMediaController.maybeFind();
    if (existingController != null) {
      controller = existingController;
    } else {
      controller = SocialMediaController.ensure();
      _ownsController = true;
    }
  }

  @override
  void dispose() {
    if (_ownsController &&
        identical(SocialMediaController.maybeFind(), controller)) {
      Get.delete<SocialMediaController>();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Obx(() => BackButtons(
                  text: 'social_links.title'
                      .trParams({'count': '${controller.list.length}'}),
                )),
            const SizedBox(height: 15),
            Expanded(
              child: RefreshIndicator(
                backgroundColor: Colors.black,
                color: Colors.white,
                onRefresh: () async {
                  await controller.getData(
                    silent: true,
                    forceRefresh: true,
                  );
                },
                child: Obx(() => ReorderableBuilder(
                      // Loading'de boş grid yerine spinner göster.
                      children: controller.list.asMap().entries.map(
                        (entry) {
                          final index = entry.key;
                          final model = entry.value;

                          return KeyedSubtree(
                            key: ValueKey(model.docID),
                            child: Container(
                              decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(20)),
                              child: Column(
                                children: [
                                  Flexible(
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        AspectRatio(
                                          aspectRatio: 1,
                                          child: ClipOval(
                                            child: model.logo
                                                    .startsWith('assets/')
                                                ? Image.asset(
                                                    model.logo,
                                                    fit: BoxFit.cover,
                                                  )
                                                : model.logo.trim().isNotEmpty
                                                    ? CachedNetworkImage(
                                                        imageUrl: model.logo,
                                                        fit: BoxFit.cover,
                                                      )
                                                    : Container(
                                                        color: Colors.grey
                                                            .withValues(
                                                          alpha: 0.15,
                                                        ),
                                                        child: const Icon(
                                                          CupertinoIcons.link,
                                                          color: Colors.black54,
                                                        ),
                                                      ),
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 0,
                                          right: 0,
                                          child: GestureDetector(
                                            onTap: () =>
                                                showRemoveConfirmation(index),
                                            child: Container(
                                              width: 25,
                                              height: 25,
                                              alignment: Alignment.center,
                                              decoration: const BoxDecoration(
                                                color: Colors.white,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                CupertinoIcons
                                                    .minus_circle_fill,
                                                color: Colors.red,
                                                size: 25,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 7),
                                  Text(
                                    model.title,
                                    maxLines: 1,
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 12,
                                      fontFamily: "MontserratBold",
                                    ),
                                  ),
                                  const SizedBox(height: 7),
                                ],
                              ),
                            ),
                          );
                        },
                      ).toList(),
                      onReorder: (ReorderedListFunction reorderFn) async {
                        final oldList = controller.list.toList();
                        final newList =
                            reorderFn(oldList).cast<SocialMediaModel>();

                        controller.list.value = newList;
                        await controller.updateAllSira();
                      },
                      builder: (children) {
                        if (controller.isLoading.value &&
                            controller.list.isEmpty) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Colors.black,
                            ),
                          );
                        }
                        return GridView(
                          padding: EdgeInsets.zero,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            childAspectRatio: 1,
                            mainAxisSpacing: 4,
                            crossAxisSpacing: 4,
                          ),
                          children: [
                            ...children,
                            _buildAddButton(),
                          ],
                        );
                      },
                    )),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> showRemoveConfirmation(int index) async {
    final model = controller.list[index];
    await noYesAlert(
      title: 'social_links.remove_title'.tr,
      message: 'social_links.remove_message'.tr,
      cancelText: 'common.cancel'.tr,
      yesText: 'common.remove'.tr,
      yesButtonColor: CupertinoColors.destructiveRed,
      onYesPressed: () async {
        await controller.deleteLink(model.docID);
        await controller.getData(silent: true);
      },
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: controller.showAddBottomSheet,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(20),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Flexible(
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey),
                  ),
                  child: const Center(
                    child: Icon(CupertinoIcons.add, color: Colors.black),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'social_links.add'.tr,
              maxLines: 1,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 12,
                fontFamily: "MontserratBold",
              ),
            ),
            const SizedBox(height: 7),
          ],
        ),
      ),
    );
  }
}
