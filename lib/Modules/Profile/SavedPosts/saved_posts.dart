import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Repositories/market_repository.dart';
import 'package:turqappv2/Core/empty_row.dart';
import 'package:turqappv2/Core/page_line_bar.dart';
import 'package:turqappv2/Models/market_item_model.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Modules/Education/Scholarships/SavedItems/saved_items_controller.dart';
import 'package:turqappv2/Modules/Education/Scholarships/ScholarshipDetail/scholarship_detail_view.dart';
import 'package:turqappv2/Modules/JobFinder/JobContent/job_content.dart';
import 'package:turqappv2/Modules/JobFinder/SavedJobs/saved_job_controller.dart';
import 'package:turqappv2/Modules/Market/market_detail_view.dart';
import 'package:turqappv2/Modules/Profile/SavedPosts/saved_posts_controller.dart';
import 'package:turqappv2/Modules/Short/single_short_view.dart';
import 'package:turqappv2/Modules/Social/PhotoShorts/photo_shorts.dart';
import 'package:turqappv2/Services/current_user_service.dart';

import '../../Agenda/FloodListing/flood_listing.dart';

class SavedPosts extends StatefulWidget {
  const SavedPosts({super.key});

  @override
  State<SavedPosts> createState() => _SavedPostsState();
}

class _SavedPostsState extends State<SavedPosts> {
  late SavedPostsController controller;
  bool _ownsController = false;
  late final String _pageLineBarTag =
      '${kSavedPostsPageLineBarTag}_${identityHashCode(this)}';

  @override
  void initState() {
    super.initState();
    final existingController = SavedPostsController.maybeFind();
    if (existingController != null) {
      controller = existingController;
    } else {
      controller = SavedPostsController.ensure();
      _ownsController = true;
    }
  }

  @override
  void dispose() {
    if (_ownsController &&
        identical(SavedPostsController.maybeFind(), controller)) {
      Get.delete<SavedPostsController>(force: true);
    }
    super.dispose();
  }

  Widget _buildSavedPostsShell(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: "settings.saved_posts".tr),
            PageLineBar(
              barList: [
                "common.all".tr,
                "saved_posts.posts_tab".tr,
                "saved_posts.series_tab".tr,
                "pasaj.tabs.market".tr,
                "pasaj.tabs.job_finder".tr,
                "pasaj.tabs.scholarships".tr,
              ],
              isScrollable: true,
              scrollablePadding: const EdgeInsets.symmetric(horizontal: 4),
              scrollableTabHorizontalPadding: 18,
              pageName: _pageLineBarTag,
              pageController: controller.pageController,
            ),
            Expanded(
              child: Obx(() {
                return PageView(
                  controller: controller.pageController,
                  onPageChanged: (v) {
                    syncPageLineBarSelection(_pageLineBarTag, v);
                  },
                  children: [
                    _buildAgendaTab(
                      posts: controller.savedAgendas,
                      emptyText: "saved_posts.no_saved_posts".tr,
                    ),
                    _buildAgendaTab(
                      posts: controller.savedPostsOnly,
                      emptyText: "saved_posts.no_saved_posts".tr,
                    ),
                    _buildAgendaTab(
                      posts: controller.savedSeries,
                      emptyText: "saved_posts.no_saved_series".tr,
                    ),
                    const _SavedMarketTab(),
                    const _SavedJobsTab(),
                    const _SavedScholarshipsTab(),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildSavedPostsShell(context);
  }

  Widget _buildAgendaTab({
    required List<PostsModel> posts,
    required String emptyText,
  }) {
    if (controller.isLoading.value && posts.isEmpty) {
      return const Center(
        child: CupertinoActivityIndicator(color: Colors.grey),
      );
    }
    if (posts.isEmpty) {
      return Center(child: EmptyRow(text: emptyText));
    }

    return SizedBox.expand(
      child: Container(
        color: Colors.white,
        child: RefreshIndicator(
          backgroundColor: Colors.black,
          color: Colors.white,
          onRefresh: controller.refresh,
          child: GridView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 50),
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 1,
              crossAxisSpacing: 1,
              childAspectRatio: 0.9,
            ),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final model = posts[index];
              final previewUrl = model.hasPlayableVideo
                  ? model.thumbnail
                  : (model.img.isNotEmpty ? model.img.first : '');
              return GestureDetector(
                onTap: () => _openSavedPost(posts, model),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (previewUrl.isNotEmpty)
                      CachedNetworkImage(
                        imageUrl: previewUrl,
                        fit: BoxFit.cover,
                        fadeOutDuration: Duration.zero,
                        memCacheWidth: 300,
                        memCacheHeight: 500,
                        placeholder: (context, url) =>
                            Container(color: Colors.grey[300]),
                        errorWidget: (context, url, error) =>
                            Container(color: Colors.grey[300]),
                      )
                    else
                      Container(color: Colors.grey[300]),
                    if (model.hasPlayableVideo)
                      const Positioned(
                        right: 6,
                        bottom: 6,
                        child: Icon(
                          CupertinoIcons.play_circle_fill,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    if (model.floodCount > 1)
                      Positioned(
                        left: 6,
                        bottom: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(170),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'saved_posts.series_badge'.tr,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontFamily: 'MontserratBold',
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _openSavedPost(List<PostsModel> posts, PostsModel model) {
    if (model.floodCount > 1) {
      Get.to(() => FloodListing(mainModel: model));
      return;
    }
    if (model.hasPlayableVideo) {
      Get.to(() => SingleShortView(startList: posts, startModel: model));
      return;
    }
    Get.to(() => PhotoShorts(fetchedList: posts, startModel: model));
  }
}

class _SavedMarketTab extends StatefulWidget {
  const _SavedMarketTab();

  @override
  State<_SavedMarketTab> createState() => _SavedMarketTabState();
}

class _SavedMarketTabState extends State<_SavedMarketTab> {
  final MarketRepository _repository = MarketRepository.ensure();
  late final String _uid;
  late Future<List<MarketItemModel>> _future;

  @override
  void initState() {
    super.initState();
    _uid = CurrentUserService.instance.effectiveUserId;
    _reload();
  }

  void _reload({bool force = false}) {
    _future = _repository.fetchSaved(
      _uid,
      preferCache: !force,
      forceRefresh: force,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MarketItemModel>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CupertinoActivityIndicator(color: Colors.grey),
          );
        }
        final items = snapshot.data ?? const <MarketItemModel>[];
        return RefreshIndicator(
          backgroundColor: Colors.black,
          color: Colors.white,
          onRefresh: () async {
            if (!mounted) return;
            setState(() => _reload(force: true));
            await _future;
          },
          child: items.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.45,
                      child: Center(
                        child: EmptyRow(text: 'pasaj.market.saved_empty'.tr),
                      ),
                    ),
                  ],
                )
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(15),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return GestureDetector(
                      onTap: () async {
                        await Get.to(() => MarketDetailView(item: item));
                        if (!mounted) return;
                        setState(() => _reload(force: true));
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0x14000000)),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(
                                width: 65,
                                height: 65,
                                child: item.coverImageUrl.trim().isNotEmpty
                                    ? Image.network(
                                        item.coverImageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          color: const Color(0xFFF3F4F6),
                                        ),
                                      )
                                    : Container(
                                        color: const Color(0xFFF3F4F6),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 14,
                                      fontFamily: 'MontserratBold',
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.locationText.isEmpty
                                        ? 'pasaj.market.location_missing'.tr
                                        : item.locationText,
                                    style: const TextStyle(
                                      color: Colors.black54,
                                      fontSize: 12,
                                      fontFamily: 'MontserratMedium',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}

class _SavedJobsTab extends StatefulWidget {
  const _SavedJobsTab();

  @override
  State<_SavedJobsTab> createState() => _SavedJobsTabState();
}

class _SavedJobsTabState extends State<_SavedJobsTab> {
  late final String _controllerTag;
  late final SavedJobsController _controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _controllerTag = 'saved_jobs_embedded_${identityHashCode(this)}';
    _ownsController =
        SavedJobsController.maybeFind(tag: _controllerTag) == null;
    _controller = SavedJobsController.ensure(tag: _controllerTag);
  }

  @override
  void dispose() {
    if (_ownsController &&
        identical(
          SavedJobsController.maybeFind(tag: _controllerTag),
          _controller,
        )) {
      Get.delete<SavedJobsController>(tag: _controllerTag);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (_controller.isLoading.value && _controller.list.isEmpty) {
        return const Center(
          child: CupertinoActivityIndicator(color: Colors.black),
        );
      }

      return RefreshIndicator(
        backgroundColor: Colors.black,
        color: Colors.white,
        onRefresh: () => _controller.getStartData(forceRefresh: true),
        child: _controller.list.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.45,
                    child: Center(
                      child: EmptyRow(
                        text: 'pasaj.job_finder.no_saved_jobs'.tr,
                      ),
                    ),
                  ),
                ],
              )
            : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 50),
                itemCount: _controller.list.length,
                itemBuilder: (context, index) {
                  return JobContent(
                    model: _controller.list[index],
                    isGrid: false,
                  );
                },
              ),
      );
    });
  }
}

class _SavedScholarshipsTab extends StatefulWidget {
  const _SavedScholarshipsTab();

  @override
  State<_SavedScholarshipsTab> createState() => _SavedScholarshipsTabState();
}

class _SavedScholarshipsTabState extends State<_SavedScholarshipsTab> {
  late final SavedItemsController _controller;
  late final String _controllerTag;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _controllerTag = 'saved_scholarships_embedded_${identityHashCode(this)}';
    final existing = SavedItemsController.maybeFind(tag: _controllerTag);
    _ownsController = existing == null;
    _controller = existing ?? SavedItemsController.ensure(tag: _controllerTag);
  }

  @override
  void dispose() {
    if (_ownsController &&
        identical(
          SavedItemsController.maybeFind(tag: _controllerTag),
          _controller,
        )) {
      Get.delete<SavedItemsController>(tag: _controllerTag);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final items = _controller.bookmarkedScholarships;
      if (_controller.isLoading.value && items.isEmpty) {
        return const Center(child: CupertinoActivityIndicator());
      }

      return RefreshIndicator(
        backgroundColor: Colors.black,
        color: Colors.white,
        onRefresh: () => _controller.fetchSavedItems(forceRefresh: true),
        child: items.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.45,
                    child: Center(
                      child: EmptyRow(text: 'scholarship.saved_empty'.tr),
                    ),
                  ),
                ],
              )
            : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final scholarshipData = items[index];
                  final burs = scholarshipData['model'];
                  final title = (burs.baslik ?? '').toString();
                  final description = (burs.aciklama ?? '').toString();
                  final imageUrl = (burs.img ?? '').toString();
                  final userData =
                      scholarshipData['userData'] as Map<String, dynamic>?;
                  final subtitle = (userData?['displayName'] ??
                          userData?['username'] ??
                          userData?['nickname'] ??
                          '')
                      .toString();
                  return GestureDetector(
                    onTap: () => Get.to(
                      () => ScholarshipDetailView(),
                      arguments: scholarshipData,
                    ),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: SizedBox(
                              width: 104,
                              height: 78,
                              child: imageUrl.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: imageUrl,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) => Container(
                                        color: Colors.grey.shade300,
                                      ),
                                      errorWidget: (_, __, ___) => Container(
                                        color: Colors.grey.shade300,
                                      ),
                                    )
                                  : Container(
                                      color: Colors.grey.shade300,
                                    ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontFamily: 'MontserratBold',
                                    color: Colors.black,
                                  ),
                                ),
                                if (subtitle.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    subtitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontFamily: 'MontserratMedium',
                                      color: Colors.blue.shade900,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 4),
                                Text(
                                  description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontFamily: 'Montserrat',
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      );
    });
  }
}
