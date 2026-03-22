part of 'market_create_view.dart';

extension _MarketCreateViewMediaPart on _MarketCreateViewState {
  Widget _buildImagePicker() {
    _syncImagePreviewIndex();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 50,
          width: double.infinity,
          child: OutlinedButton(
            onPressed:
                controller.isSubmitting.value ? null : controller.pickImages,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0x22000000)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              'pasaj.market.create.select_image'.trParams({
                'current': '${controller.totalImageCount}',
                'max': '${MarketCreateController.maxImages}',
              }),
              style: const TextStyle(
                color: Colors.black,
                fontSize: 13,
                fontFamily: 'MontserratBold',
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (controller.totalImageCount == 0)
          _buildImageFallbackCard()
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 186,
                child: PageView.builder(
                  controller: _imagePreviewController,
                  itemCount: controller.totalImageCount,
                  onPageChanged: (index) {
                    _updateMarketCreateState(() {
                      _imagePreviewIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final isExisting =
                        index < controller.existingImageUrls.length;
                    return Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: SizedBox(
                              width: double.infinity,
                              child: isExisting
                                  ? Image.network(
                                      controller.existingImageUrls[index],
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          _buildImageFallback(),
                                    )
                                  : Image.file(
                                      controller.selectedImages[index -
                                          controller.existingImageUrls.length],
                                      fit: BoxFit.cover,
                                    ),
                            ),
                          ),
                          Positioned(
                            top: 10,
                            right: 10,
                            child: GestureDetector(
                              onTap: () => controller.removeImageAt(index),
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.72),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 10,
                            bottom: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.72),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                index == 0
                                    ? 'pasaj.market.create.cover'.tr
                                    : '${index + 1}/${controller.totalImageCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
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
              if (controller.totalImageCount > 1) ...[
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    controller.totalImageCount,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: _imagePreviewIndex == index ? 18 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _imagePreviewIndex == index
                            ? Colors.black
                            : const Color(0x22000000),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              SizedBox(
                height: 60,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: controller.totalImageCount,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final isExisting =
                        index < controller.existingImageUrls.length;
                    final selected = _imagePreviewIndex == index;
                    return GestureDetector(
                      onTap: () {
                        _imagePreviewController.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOut,
                        );
                      },
                      child: Container(
                        width: 86,
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected
                                ? Colors.black
                                : const Color(0x22000000),
                            width: selected ? 1.4 : 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: isExisting
                              ? Image.network(
                                  controller.existingImageUrls[index],
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _buildImageFallback(),
                                )
                              : Image.file(
                                  controller.selectedImages[index -
                                      controller.existingImageUrls.length],
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildImageFallbackCard() {
    return Container(
      height: 186,
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7FB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x11000000)),
      ),
      alignment: Alignment.center,
      child: const Icon(
        CupertinoIcons.photo_on_rectangle,
        color: Colors.black38,
        size: 36,
      ),
    );
  }

  void _syncImagePreviewIndex() {
    final total = controller.totalImageCount;
    if (total <= 0) {
      _imagePreviewIndex = 0;
      return;
    }
    if (_imagePreviewIndex < total) return;
    final targetIndex = total - 1;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _imagePreviewController.jumpToPage(targetIndex);
      _updateMarketCreateState(() {
        _imagePreviewIndex = targetIndex;
      });
    });
  }

  Widget _buildImageFallback() {
    return Container(
      color: const Color(0xFFF3F4F6),
      alignment: Alignment.center,
      child: const Icon(Icons.image_not_supported, color: Colors.black38),
    );
  }
}
