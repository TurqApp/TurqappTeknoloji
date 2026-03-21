part of 'scholarship_detail_view.dart';

extension ScholarshipDetailViewHelpersPart on ScholarshipDetailView {
  Widget _buildDetail(String title, dynamic value) {
    final baseStyle = TextStyles.rBlack16;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyles.bold18Black),
        4.ph,
        value is String
            ? Text.rich(
                ScholarshipRichText.build(
                  value,
                  baseStyle: baseStyle,
                ),
                style: baseStyle,
              )
            : value,
      ],
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
