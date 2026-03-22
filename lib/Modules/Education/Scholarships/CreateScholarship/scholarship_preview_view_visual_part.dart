part of 'scholarship_preview_view.dart';

extension ScholarshipPreviewViewVisualPart on ScholarshipPreviewView {
  Widget _buildVisualSection({
    required BuildContext context,
    required CreateScholarshipController controller,
    required CarouselSliderController carouselController,
    required RxInt currentIndex,
    required double logoSize,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('scholarship.visual_info'.tr),
          12.ph,
          Obx(() {
            final imageWidgets = <Widget>[
              ..._buildTemplateImages(controller, logoSize),
              ..._buildCustomImages(controller),
            ];

            if (imageWidgets.isEmpty) {
              return AspectRatio(
                aspectRatio: 4 / 3,
                child: Center(
                  child: Text(
                    'scholarship.image_missing'.tr,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              );
            }

            return Stack(
              alignment: Alignment.center,
              children: [
                CarouselSlider(
                  carouselController: carouselController,
                  options: CarouselOptions(
                    aspectRatio: 4 / 3,
                    autoPlay: false,
                    enlargeCenterPage: true,
                    enableInfiniteScroll: imageWidgets.length > 1,
                    viewportFraction: 1.0,
                    padEnds: false,
                    onPageChanged: (index, reason) {
                      currentIndex.value = index;
                    },
                  ),
                  items: imageWidgets,
                ),
                if (imageWidgets.length > 1)
                  _buildCarouselArrow(
                    isLeft: true,
                    onTap: () {
                      carouselController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                  ),
                if (imageWidgets.length > 1)
                  _buildCarouselArrow(
                    isLeft: false,
                    onTap: () {
                      carouselController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                  ),
                if (imageWidgets.length > 1)
                  Positioned(
                    bottom: 10,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: imageWidgets.asMap().entries.map((entry) {
                        return GestureDetector(
                          onTap: () =>
                              carouselController.animateToPage(entry.key),
                          child: Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: currentIndex.value == entry.key
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.4),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  List<Widget> _buildTemplateImages(
    CreateScholarshipController controller,
    double logoSize,
  ) {
    if (controller.selectedTemplateIndex.value == -1) {
      return const <Widget>[];
    }
    return <Widget>[
      RepaintBoundary(
        key: controller.templateKey,
        child: AspectRatio(
          aspectRatio: 4 / 3,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                'assets/bursSablonlar/${controller.selectedTemplateIndex.value + 1}.webp',
                fit: BoxFit.cover,
              ),
              if (controller.bursVeren.value.isNotEmpty)
                Positioned(
                  top: 65,
                  left: 15,
                  child: Obx(() {
                    final words = controller.bursVeren.value.split(' ');
                    final allWords = [...words, 'BURS', 'BAŞVURULARI'];
                    return Text(
                      allWords.join('\n'),
                      style: TextStyles.textFieldTitle.copyWith(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                      textHeightBehavior: const TextHeightBehavior(
                        applyHeightToFirstAscent: false,
                        applyHeightToLastDescent: false,
                      ),
                    );
                  }),
                ),
              if (controller.logo.value.isNotEmpty)
                Positioned(
                  top: 70,
                  right: 12,
                  child: controller.logo.value.startsWith('http')
                      ? CachedNetworkImage(
                          imageUrl: controller.logo.value,
                          width: logoSize,
                          height: logoSize,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.error),
                        )
                      : Image.file(
                          File(controller.logo.value),
                          width: logoSize,
                          height: logoSize,
                          fit: BoxFit.cover,
                        ),
                ),
              if (controller.website.value.isNotEmpty)
                Positioned(
                  bottom: 6,
                  left: 20,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        CupertinoIcons.globe,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        controller.website.value,
                        style: TextStyles.textFieldTitle.copyWith(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildCustomImages(CreateScholarshipController controller) {
    if (controller.customImagePath.value.isEmpty) {
      return const <Widget>[];
    }
    return <Widget>[
      AspectRatio(
        aspectRatio: 4 / 3,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: controller.customImagePath.value.startsWith('http')
              ? CachedNetworkImage(
                  imageUrl: controller.customImagePath.value,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                )
              : Image.file(
                  File(controller.customImagePath.value),
                  fit: BoxFit.cover,
                ),
        ),
      ),
    ];
  }

  Widget _buildCarouselArrow({
    required bool isLeft,
    required VoidCallback onTap,
  }) {
    return Positioned(
      left: isLeft ? 10 : null,
      right: isLeft ? null : 10,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isLeft ? CupertinoIcons.chevron_left : CupertinoIcons.chevron_right,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }
}
