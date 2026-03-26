import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Widgets/search_reset_on_page_return_scope.dart';
import 'package:turqappv2/Core/Widgets/turq_search_bar.dart';
import 'package:turqappv2/Modules/Agenda/PostLikeListing/PostLikeContent/post_like_content.dart';
import 'package:turqappv2/Utils/empty_padding.dart';

import 'post_like_listing_controller.dart';

class PostLikeListing extends StatefulWidget {
  final String postID;
  const PostLikeListing({super.key, required this.postID});

  @override
  State<PostLikeListing> createState() => _PostLikeListingState();
}

class _PostLikeListingState extends State<PostLikeListing> {
  late final PostLikeListingController controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    final existing = PostLikeListingController.maybeFind(tag: widget.postID);
    controller = PostLikeListingController.ensure(tag: widget.postID);
    _ownsController = existing == null;
  }

  @override
  void dispose() {
    if (_ownsController &&
        identical(
          PostLikeListingController.maybeFind(tag: widget.postID),
          controller,
        )) {
      Get.delete<PostLikeListingController>(tag: widget.postID, force: true);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final safeTop = MediaQuery.of(context).padding.top;
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final maxSheetHeight = screenHeight - safeTop - 20;
    final desiredHeight = (screenHeight * 0.52).clamp(320.0, maxSheetHeight);
    return SearchResetOnPageReturnScope(
      onReset: () {
        controller.searchController.clear();
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              height: desiredHeight,
              margin: EdgeInsets.fromLTRB(0, 10, 0, safeBottom),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(26),
                  topRight: Radius.circular(26),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(15, 10, 15, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      height: 4,
                      width: 56,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.15),
                        borderRadius:
                            const BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    header(),
                    const SizedBox(height: 14),
                    TurqSearchBar(
                      controller: controller.searchController,
                      hintText: 'common.search'.tr,
                      onChanged: controller.onSearchChanged,
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Obx(() {
                        final items = controller.filteredUsers;
                        if (controller.users.isEmpty) {
                          return Center(
                            child: Text(
                              'post_likes.empty'.tr,
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 14,
                                fontFamily: 'MontserratMedium',
                              ),
                            ),
                          );
                        }
                        if (items.isEmpty) {
                          return Center(
                            child: Text(
                              'common.no_results'.tr,
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 14,
                                fontFamily: 'MontserratMedium',
                              ),
                            ),
                          );
                        }
                        return ListView.builder(
                          controller: controller.scrollController,
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: const EdgeInsets.only(bottom: 18),
                          itemCount: items.length +
                              (controller.isLoadingMore.value ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index >= items.length) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.black),
                                    ),
                                  ),
                                ),
                              );
                            }
                            return PostLikeContent(item: items[index]);
                          },
                        );
                      }),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget header() {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: Colors.black.withValues(alpha: 0.08),
          ),
        ),
        12.pw,
        Text(
          'post_likes.title'.tr,
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontFamily: "MontserratBold",
          ),
        ),
        12.pw,
        Expanded(
          child: Divider(
            color: Colors.black.withValues(alpha: 0.08),
          ),
        )
      ],
    );
  }
}
