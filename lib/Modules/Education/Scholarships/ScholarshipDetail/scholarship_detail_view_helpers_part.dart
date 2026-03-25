part of 'scholarship_detail_view.dart';

extension ScholarshipDetailViewHelpersPart on ScholarshipDetailView {
  Widget _buildInfoCard({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F7FB),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontFamily: 'MontserratBold',
                ),
              ),
              const SizedBox(height: 12),
              ...children,
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    bool rich = false,
  }) {
    final cleanValue = value.trim();
    final shouldStack =
        rich || cleanValue.contains('\n') || cleanValue.length > 80;
    final baseStyle = const TextStyle(
      color: Colors.black87,
      fontSize: 14,
      fontFamily: 'MontserratMedium',
      height: 1.45,
    );

    if (shouldStack) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 14,
                fontFamily: 'MontserratBold',
              ),
            ),
            const SizedBox(height: 6),
            rich
                ? Text.rich(
                    ScholarshipRichText.build(
                      cleanValue.isEmpty ? 'common.unspecified'.tr : cleanValue,
                      baseStyle: baseStyle,
                    ),
                    style: baseStyle,
                  )
                : Text(
                    cleanValue.isEmpty ? 'common.unspecified'.tr : cleanValue,
                    style: baseStyle,
                  ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 128,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 14,
                fontFamily: 'MontserratBold',
              ),
            ),
          ),
          Expanded(
            child: rich
                ? Text.rich(
                    ScholarshipRichText.build(
                      cleanValue.isEmpty ? 'common.unspecified'.tr : cleanValue,
                      baseStyle: baseStyle,
                    ),
                    style: baseStyle,
                  )
                : Text(
                    cleanValue.isEmpty ? 'common.unspecified'.tr : cleanValue,
                    style: baseStyle,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildWidgetInfoRow(String label, Widget child) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 128,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 14,
                fontFamily: 'MontserratBold',
              ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.black,
        fontSize: 16,
        fontFamily: 'MontserratBold',
      ),
    );
  }

  Widget _buildGalleryImage(String imageUrl) {
    return CachedNetworkImage(
      memCacheHeight: 1000,
      imageUrl: imageUrl,
      width: double.infinity,
      fit: BoxFit.cover,
      placeholder: (context, url) => const Center(
        child: CupertinoActivityIndicator(),
      ),
      errorWidget: (context, url, error) => const Icon(
        Icons.error,
        color: Colors.red,
        size: 40,
      ),
    );
  }

  Widget _buildPageIndicator({
    required ScholarshipDetailController controller,
    required int count,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (dotIndex) {
        return Obx(
          () => AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: controller.currentPageIndex.value == dotIndex ? 18 : 7,
            height: 7,
            decoration: BoxDecoration(
              color: controller.currentPageIndex.value == dotIndex
                  ? Colors.black
                  : Colors.black26,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        );
      }),
    );
  }

  Future<void> _handleProviderCardTap({
    required String website,
    required String userId,
  }) async {
    if (website.trim().isNotEmpty) {
      await _openWebsite(website);
      return;
    }
    _openProfile(userId);
  }

  Future<void> _openWebsite(String website) async {
    String urlString = website.trim();
    if (urlString.isEmpty) {
      AppSnackbar(
        "common.warning".tr,
        "scholarship.application_link_missing".tr,
      );
      return;
    }

    urlString = ensureUrlHasScheme(urlString);

    final url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await confirmAndLaunchExternalUrl(url);
      return;
    }

    AppSnackbar(
      "common.error".tr,
      "scholarship.website_open_failed".tr,
    );
  }

  void _openProfile(String userId) {
    final trimmedUserId = userId.trim();
    if (trimmedUserId.isEmpty) {
      AppSnackbar("common.warning".tr, "scholarship.profile_missing".tr);
      return;
    }

    Get.to(SocialProfile(userID: trimmedUserId));
  }

  String _truncateLabel(String value, {required int maxChars}) {
    final trimmed = value.trim();
    if (trimmed.length <= maxChars) {
      return trimmed;
    }
    final cutIndex = trimmed.lastIndexOf(' ', maxChars);
    final safeIndex = cutIndex > 0 ? cutIndex : maxChars;
    return '${trimmed.substring(0, safeIndex).trimRight()}...';
  }
}
