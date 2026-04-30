import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Services/read_budget_registry.dart';
import 'package:turqappv2/Core/Widgets/app_state_view.dart';
import 'package:turqappv2/Core/text_styles.dart';
import 'package:turqappv2/Models/Education/individual_scholarships_model.dart';
import 'package:turqappv2/Modules/Education/Scholarships/Personalized/personalized_controller.dart';
import 'package:turqappv2/Modules/Education/Scholarships/scholarship_constants.dart';
import 'package:turqappv2/Modules/Education/Scholarships/scholarship_navigation_service.dart';
import 'package:turqappv2/Themes/app_icons.dart';
import 'package:turqappv2/Utils/empty_padding.dart';

class PersonalizedView extends StatefulWidget {
  const PersonalizedView({super.key});

  @override
  State<PersonalizedView> createState() => _PersonalizedViewState();
}

class _PersonalizedViewState extends State<PersonalizedView> {
  late final String _controllerTag;
  late final bool _ownsController;
  late final PersonalizedController controller;

  @override
  void initState() {
    super.initState();
    _controllerTag = 'scholarship_personalized_${identityHashCode(this)}';
    final existing = maybeFindPersonalizedController(tag: _controllerTag);
    _ownsController = existing == null;
    controller = existing ?? ensurePersonalizedController(tag: _controllerTag);
  }

  @override
  void dispose() {
    if (_ownsController &&
        identical(
          maybeFindPersonalizedController(tag: _controllerTag),
          controller,
        )) {
      Get.delete<PersonalizedController>(tag: _controllerTag, force: true);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [_buildHeader(controller), _buildBody(controller)],
        ),
      ),
    );
  }

  Widget _buildHeader(PersonalizedController controller) {
    return Row(
      children: [
        Expanded(child: BackButtons(text: 'explore.tab.for_you'.tr)),
        Obx(
          () => Text(
            controller.locationSehir.value,
            style: TextStyles.medium15Black,
          ),
        ),
        4.pw,
        GestureDetector(
          onTap: controller.getUserLocation,
          child: const Icon(AppIcons.locationSolid, color: Colors.red),
        ),
        15.pw,
      ],
    );
  }

  Widget _buildBody(PersonalizedController controller) {
    return Expanded(
      child: RefreshIndicator(
        backgroundColor: Colors.white,
        color: Colors.black,
        onRefresh: controller.refreshList,
        child: Obx(() {
          if (controller.isInitialLoading.value) {
            return _buildInitialLoader();
          }
          return _buildContent(controller);
        }),
      ),
    );
  }

  Widget _buildInitialLoader() {
    return const AppStateView.loading();
  }

  Widget _buildContent(PersonalizedController controller) {
    return ListView(
      controller: controller.scrollController,
      children: [
        _buildCarousel(controller),
        _buildGrid(controller),
        // _buildBottomLoader(controller),
      ],
    );
  }

  Widget _buildCarousel(PersonalizedController controller) {
    if (controller.vitrin.isEmpty) {
      return SizedBox.shrink();
    }

    // Vitrin listesini karıştır
    final randomVitrin = controller.vitrin.toList()..shuffle();

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        CarouselSlider(
          options: CarouselOptions(
            autoPlay: true,
            enlargeCenterPage: false,
            autoPlayInterval: Duration(seconds: 2),
            viewportFraction: 1,
            aspectRatio: 4 / 3,
            onPageChanged: (index, reason) {
              controller.currentIndex.value = index;
            },
          ),
          items: randomVitrin.map((item) => _buildCarouselItem(item)).toList(),
        ),
        _buildCarouselIndicators(controller),
      ],
    );
  }

  Widget _buildCarouselItem(IndividualScholarshipsModel item) {
    if (item.img.trim().isEmpty) {
      return AspectRatio(
        aspectRatio: 4 / 3,
        child: Container(
          color: Colors.grey.shade200,
          alignment: Alignment.center,
          child: const Icon(Icons.image_not_supported,
              size: 40, color: Colors.grey),
        ),
      );
    }
    return GestureDetector(
      onTap: () => _navigateToIndividualDetail(item),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: CachedNetworkImage(
          imageUrl: item.img,
          fit: BoxFit.cover,
          width: double.infinity,
          placeholder: (context, url) => _buildImagePlaceholder(),
          errorWidget: (context, url, error) => _buildImageError(),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: Colors.grey[300],
      child: const Center(child: CupertinoActivityIndicator()),
    );
  }

  Widget _buildImageError() {
    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: Icon(Icons.error, color: Colors.red, size: 30),
      ),
    );
  }

  Widget _buildCarouselIndicators(PersonalizedController controller) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: controller.vitrin
          .take(ReadBudgetRegistry.scholarshipPersonalizedShowcaseLimit)
          .map((item) {
        int index = controller.vitrin.indexOf(item);
        return Obx(
          () => Container(
            width: 5.0,
            height: 5.0,
            margin: const EdgeInsets.symmetric(
              vertical: 10.0,
              horizontal: 2.0,
            ),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: controller.currentIndex.value == index
                  ? Colors.white
                  : Colors.grey.withValues(alpha: 0.8),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGrid(PersonalizedController controller) {
    if (controller.list.isEmpty) {
      return const SizedBox.shrink();
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 4 / 3,
        crossAxisSpacing: 1,
        mainAxisSpacing: 1,
      ),
      itemCount: controller.list.length,
      itemBuilder: (context, index) {
        final IndividualScholarshipsModel item = controller.list[index];
        return GestureDetector(
          onTap: () => _navigateToIndividualDetail(item),
          child: item.img.trim().isEmpty
              ? Container(
                  color: Colors.grey.shade200,
                  alignment: Alignment.center,
                  child: const Icon(Icons.image_not_supported,
                      size: 24, color: Colors.grey),
                )
              : CachedNetworkImage(
                  imageUrl: item.img,
                  fit: BoxFit.cover,
                  placeholder: (c, u) =>
                      const Center(child: CupertinoActivityIndicator()),
                  errorWidget: (c, u, e) => const Icon(Icons.error),
                ),
        );
      },
    );
  }

  Future<void> _navigateToIndividualDetail(
      IndividualScholarshipsModel item) async {
    final docId = controller.docIdByTimestamp[item.timeStamp] ?? '';
    final scholarshipData = {
      'model': item,
      'type': kIndividualScholarshipType,
      'userData': null,
      'docId': docId,
      'scholarshipId': docId,
    };
    await ScholarshipNavigationService.openDetailRoute(scholarshipData);
  }
}
