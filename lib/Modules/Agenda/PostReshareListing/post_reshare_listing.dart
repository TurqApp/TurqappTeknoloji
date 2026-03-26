import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Modules/Agenda/PostReshareListing/PostReshareContent/post_reshare_content.dart';
import 'package:turqappv2/Modules/Agenda/PostReshareListing/post_reshare_listing_controller.dart';
import 'package:turqappv2/Utils/empty_padding.dart';

class PostReshareListing extends StatefulWidget {
  const PostReshareListing({
    super.key,
    required this.postID,
  });

  final String postID;

  @override
  State<PostReshareListing> createState() => _PostReshareListingState();
}

class _PostReshareListingState extends State<PostReshareListing> {
  late final PostReshareListingController controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    final existing = maybeFindPostReshareListingController(tag: widget.postID);
    controller = ensurePostReshareListingController(tag: widget.postID);
    _ownsController = existing == null;
  }

  @override
  void dispose() {
    if (_ownsController &&
        identical(
          maybeFindPostReshareListingController(tag: widget.postID),
          controller,
        )) {
      Get.delete<PostReshareListingController>(
        tag: widget.postID,
        force: true,
      );
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final safeTop = MediaQuery.of(context).padding.top;
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final maxSheetHeight = screenHeight - safeTop - 20;
    final desiredHeight = (screenHeight * 0.56).clamp(340.0, maxSheetHeight);

    return DefaultTabController(
      length: 2,
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
                    _header(),
                    const SizedBox(height: 12),
                    TabBar(
                      onTap: (index) {
                        if (index == 1) controller.ensureQuotesLoaded();
                      },
                      labelColor: Colors.black,
                      unselectedLabelColor: Colors.black54,
                      indicatorColor: Colors.black,
                      dividerColor: Colors.transparent,
                      labelStyle: const TextStyle(
                        fontSize: 13,
                        fontFamily: 'MontserratBold',
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontSize: 13,
                        fontFamily: 'MontserratMedium',
                      ),
                      tabs: [
                        Tab(text: 'profile.reshare_users_tab'.tr),
                        Tab(text: 'profile.quote_users_tab'.tr),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildList(
                            users: controller.reshareUsers,
                            isLoading: controller.isLoadingReshares,
                            isLoadingMore: controller.isLoadingMoreReshares,
                            emptyText: 'profile.no_reshares'.tr,
                            scrollController:
                                controller.reshareScrollController,
                          ),
                          _buildList(
                            users: controller.quoteUsers,
                            isLoading: controller.isLoadingQuotes,
                            isLoadingMore: controller.isLoadingMoreQuotes,
                            emptyText: 'profile.no_quotes'.tr,
                            scrollController: controller.quoteScrollController,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: Colors.black.withValues(alpha: 0.08),
          ),
        ),
        12.pw,
        Text(
          'short.shared_as_post_by'.tr,
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontFamily: 'MontserratBold',
          ),
        ),
        12.pw,
        Expanded(
          child: Divider(
            color: Colors.black.withValues(alpha: 0.08),
          ),
        ),
      ],
    );
  }

  Widget _buildList({
    required RxList<ReshareUserItem> users,
    required RxBool isLoading,
    required RxBool isLoadingMore,
    required String emptyText,
    required ScrollController scrollController,
  }) {
    return Obx(() {
      if (isLoading.value && users.isEmpty) {
        return const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
            ),
          ),
        );
      }

      if (users.isEmpty) {
        return Center(
          child: Text(
            emptyText,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 14,
              fontFamily: 'MontserratMedium',
            ),
          ),
        );
      }

      return ListView.builder(
        controller: scrollController,
        padding: const EdgeInsets.only(bottom: 18),
        itemCount: users.length + (isLoadingMore.value ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= users.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                  ),
                ),
              ),
            );
          }
          return PostReshareContent(item: users[index]);
        },
      );
    });
  }
}
