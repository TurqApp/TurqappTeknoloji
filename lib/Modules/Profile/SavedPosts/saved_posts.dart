import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Repositories/market_repository.dart';
import 'package:turqappv2/Core/Services/market_saved_store.dart';
import 'package:turqappv2/Core/Services/share_link_service.dart';
import 'package:turqappv2/Core/Services/short_link_service.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/empty_row.dart';
import 'package:turqappv2/Core/page_line_bar.dart';
import 'package:turqappv2/Models/Education/individual_scholarships_model.dart';
import 'package:turqappv2/Models/market_item_model.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Modules/Education/Scholarships/SavedItems/saved_items_controller.dart';
import 'package:turqappv2/Modules/Education/Scholarships/scholarship_constants.dart';
import 'package:turqappv2/Modules/Education/Scholarships/scholarship_listing_card.dart';
import 'package:turqappv2/Modules/Education/Scholarships/scholarship_navigation_service.dart';
import 'package:turqappv2/Modules/Market/market_listing_card.dart';
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
    final existingController = maybeFindSavedPostsController();
    if (existingController != null) {
      controller = existingController;
    } else {
      controller = ensureSavedPostsController();
      _ownsController = true;
    }
  }

  @override
  void dispose() {
    if (_ownsController &&
        identical(maybeFindSavedPostsController(), controller)) {
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
  final MarketRepository _repository = ensureMarketRepository();
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
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return MarketListingCard(
                      item: item,
                      isSaved: true,
                      onOpen: () async {
                        await Get.to(() => MarketDetailView(item: item));
                        if (!mounted) return;
                        setState(() => _reload(force: true));
                      },
                      onToggleSaved: () => _unsave(item),
                    );
                  },
                ),
        );
      },
    );
  }

  Future<void> _unsave(MarketItemModel item) async {
    try {
      await MarketSavedStore.unsave(_uid, item.id);
      if (!mounted) return;
      setState(() => _reload(force: true));
    } catch (_) {
      AppSnackbar('common.error'.tr, 'pasaj.market.unsave_failed'.tr);
    }
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
    _ownsController = maybeFindSavedJobsController(tag: _controllerTag) == null;
    _controller = ensureSavedJobsController(tag: _controllerTag);
  }

  @override
  void dispose() {
    if (_ownsController &&
        identical(
          maybeFindSavedJobsController(tag: _controllerTag),
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
  final ShortLinkService _shortLinkService = ShortLinkService();

  @override
  void initState() {
    super.initState();
    _controllerTag = 'saved_scholarships_embedded_${identityHashCode(this)}';
    final existing = maybeFindSavedItemsController(tag: _controllerTag);
    _ownsController = existing == null;
    _controller = existing ?? ensureSavedItemsController(tag: _controllerTag);
  }

  @override
  void dispose() {
    if (_ownsController &&
        identical(
          maybeFindSavedItemsController(tag: _controllerTag),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final scholarshipData = items[index];
                  final docId = (scholarshipData['docId'] ?? '').toString();
                  return ScholarshipListingCard(
                    scholarshipData: scholarshipData,
                    isSaved: true,
                    onOpen: () => _openScholarship(scholarshipData),
                    onToggleSaved: () => _toggleSavedScholarship(docId),
                    onShare: () => _shareScholarship(scholarshipData),
                  );
                },
              ),
      );
    });
  }

  Future<void> _openScholarship(Map<String, dynamic> scholarshipData) async {
    await ScholarshipNavigationService.openDetail(scholarshipData);
    await _controller.fetchSavedItems(silent: true, forceRefresh: true);
  }

  Future<void> _toggleSavedScholarship(String docId) async {
    await _controller.toggleBookmark(docId, kIndividualScholarshipType);
  }

  Future<void> _shareScholarship(Map<String, dynamic> scholarshipData) async {
    final burs = scholarshipData['model'] as IndividualScholarshipsModel?;
    if (burs == null) {
      AppSnackbar('common.error'.tr, 'scholarship.share_failed'.tr);
      return;
    }

    final docId =
        (scholarshipData['docId'] ?? scholarshipData['scholarshipId'] ?? '')
            .toString();
    if (docId.isEmpty) {
      AppSnackbar('common.error'.tr, 'scholarship.share_missing_id'.tr);
      return;
    }

    final shareId = 'scholarship:$docId';
    final shortTail = docId.length >= 8 ? docId.substring(0, 8) : docId;
    final fallbackUrl = 'https://turqapp.com/e/scholarship-$shortTail';
    final title = burs.baslik.trim().isNotEmpty
        ? burs.baslik.trim()
        : 'scholarship.share_detail_title'.tr;

    final shortUrl = await _shortLinkService.getEducationPublicUrl(
      shareId: shareId,
      title: title,
      desc: _pickScholarshipShareDesc(burs),
      imageUrl: _pickScholarshipShareImage(burs),
    );
    final resolvedUrl =
        shortUrl.trim().isNotEmpty && shortUrl.trim() != 'https://turqapp.com'
            ? shortUrl
            : fallbackUrl;

    try {
      await ShareLinkService.shareUrl(
        url: resolvedUrl,
        title: title,
        subject: title,
      );
    } catch (_) {
      AppSnackbar('common.error'.tr, 'scholarship.share_failed'.tr);
    }
  }

  String _pickScholarshipShareDesc(IndividualScholarshipsModel model) {
    final normalizedTitle = normalizeSearchText(model.baslik);
    final shortDesc = model.shortDescription.trim();
    if (shortDesc.isNotEmpty &&
        normalizeSearchText(shortDesc) != normalizedTitle) {
      return shortDesc;
    }
    final provider = model.bursVeren.trim();
    if (provider.isNotEmpty &&
        normalizeSearchText(provider) != normalizedTitle) {
      return provider;
    }
    return 'scholarship.share_fallback_desc'.tr;
  }

  String? _pickScholarshipShareImage(IndividualScholarshipsModel model) {
    final img = model.img.trim();
    if (img.isNotEmpty) return img;
    final img2 = model.img2.trim();
    if (img2.isNotEmpty) return img2;
    final logo = model.logo.trim();
    if (logo.isNotEmpty) return logo;
    return null;
  }
}
