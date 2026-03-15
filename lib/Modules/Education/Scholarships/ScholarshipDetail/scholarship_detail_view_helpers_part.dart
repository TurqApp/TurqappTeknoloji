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
        "Uyarı!",
        "Bu burs için bir başvuru bağlantısı bulunmamaktadır.",
      );
      return;
    }

    if (!urlString.startsWith('http://') && !urlString.startsWith('https://')) {
      urlString = 'https://$urlString';
    }

    final url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
      return;
    }

    AppSnackbar(
      "Hata!",
      "Web sitesi açılamadı. Lütfen geçerli bir URL girin.",
    );
  }

  void _openProfile(String userId) {
    final trimmedUserId = userId.trim();
    if (trimmedUserId.isEmpty) {
      AppSnackbar("Uyarı!", "Bu burs için profil bilgisi bulunmamaktadır.");
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
