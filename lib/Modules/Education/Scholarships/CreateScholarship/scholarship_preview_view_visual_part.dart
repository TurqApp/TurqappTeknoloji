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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final height = constraints.maxHeight;

              return Stack(
                fit: StackFit.expand,
                clipBehavior: Clip.hardEdge,
                children: [
                  Image.asset(
                    'assets/bursSablonlar/${controller.selectedTemplateIndex.value + 1}.webp',
                    fit: BoxFit.cover,
                  ),
                  if (controller.bursVeren.value.isNotEmpty)
                    Positioned(
                      top: height * 0.21,
                      left: width * 0.045,
                      width: width * 0.35,
                      height: height * 0.5,
                      child: _buildTemplateTitle(
                        bursVeren: controller.bursVeren.value,
                        width: width * 0.35,
                        height: height * 0.5,
                      ),
                    ),
                  if (controller.logo.value.isNotEmpty)
                    Positioned(
                      top: height * 0.237,
                      right: math.max(0.0, width * 0.064 - 8),
                      width: math.min(width * 0.35868, height * 0.57624),
                      height: math.min(width * 0.35868, height * 0.57624),
                      child: _buildTemplateLogo(
                        logoPath: controller.logo.value,
                        size: math.min(width * 0.35868, height * 0.57624),
                      ),
                    ),
                  if (controller.website.value.isNotEmpty)
                    Positioned(
                      left: width * 0.045,
                      right: width * 0.12,
                      bottom: math.max(0.0, height * 0.015 - 3),
                      height: height * 0.11,
                      child: _buildTemplateWebsite(
                        website: controller.website.value,
                        width: width * 0.835,
                        height: height * 0.11,
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    ];
  }

  Widget _buildTemplateTitle({
    required String bursVeren,
    required double width,
    required double height,
  }) {
    final words = bursVeren
        .split(RegExp(r'\s+'))
        .where((word) => word.trim().isNotEmpty)
        .toList();
    final titleText = [...words, 'BURS', 'BAŞVURULARI'].join('\n');

    return SizedBox(
      width: width,
      height: height,
      child: FittedBox(
        alignment: Alignment.topLeft,
        fit: BoxFit.scaleDown,
        child: SizedBox(
          width: width,
          child: Text(
            titleText,
            maxLines: 6,
            softWrap: true,
            style: TextStyles.textFieldTitle.copyWith(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              height: 1.08,
            ),
            textHeightBehavior: const TextHeightBehavior(
              applyHeightToFirstAscent: false,
              applyHeightToLastDescent: false,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateLogo({
    required String logoPath,
    required double size,
  }) {
    final imageWidget = logoPath.startsWith('http')
        ? CachedNetworkImage(
            imageUrl: logoPath,
            fit: BoxFit.cover,
            errorWidget: (context, url, error) => const Icon(Icons.error),
          )
        : Image.file(
            File(logoPath),
            fit: BoxFit.cover,
          );

    return ClipRect(
      child: Align(
        alignment: Alignment.center,
        child: SizedBox.square(
          dimension: size,
          child: imageWidget,
        ),
      ),
    );
  }

  Widget _buildTemplateWebsite({
    required String website,
    required double width,
    required double height,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openTemplateWebsite(website),
      child: SizedBox(
        width: width,
        height: height,
        child: FittedBox(
          alignment: Alignment.centerLeft,
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                CupertinoIcons.globe,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                website,
                style: TextStyles.textFieldTitle.copyWith(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openTemplateWebsite(String website) async {
    final trimmed = website.trim();
    if (trimmed.isEmpty) return;

    final uri = Uri.tryParse(ensureUrlHasScheme(trimmed));
    if (uri == null) {
      AppSnackbar('common.error'.tr, 'scholarship.website_open_failed'.tr);
      return;
    }

    await confirmAndLaunchExternalUrl(uri);
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
