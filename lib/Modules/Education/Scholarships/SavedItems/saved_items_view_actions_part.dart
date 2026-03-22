part of 'saved_items_view.dart';

extension _SavedItemsViewActionsPart on _SavedItemsViewState {
  void _openScholarshipDetail(Map<String, dynamic> scholarshipData) {
    Get.to(
      () => ScholarshipDetailView(),
      arguments: scholarshipData,
    );
  }

  List<PullDownMenuEntry> _buildItemActions({
    required String docId,
    required String type,
    required bool isBookmarked,
  }) {
    return [
      PullDownMenuItem(
        iconColor: Colors.black,
        icon: isBookmarked
            ? CupertinoIcons.bookmark_fill
            : CupertinoIcons.hand_thumbsup_fill,
        title: isBookmarked
            ? 'scholarship.remove_saved'.tr
            : 'scholarship.remove_liked'.tr,
        onTap: () => _confirmRemove(
          docId: docId,
          type: type,
          isBookmarked: isBookmarked,
        ),
      ),
    ];
  }

  void _confirmRemove({
    required String docId,
    required String type,
    required bool isBookmarked,
  }) {
    noYesAlert(
      title: isBookmarked
          ? 'scholarship.remove_saved'.tr
          : 'scholarship.remove_liked'.tr,
      message: isBookmarked
          ? 'scholarship.remove_saved_confirm'.tr
          : 'scholarship.remove_liked_confirm'.tr,
      onYesPressed: () {
        if (isBookmarked) {
          controller.toggleBookmark(docId, type);
        } else {
          controller.toggleLike(docId, type);
        }
        AppSnackbar(
          'common.success'.tr,
          isBookmarked
              ? 'scholarship.removed_saved'.tr
              : 'scholarship.removed_liked'.tr,
        );
      },
      yesText: 'common.remove'.tr,
      cancelText: 'common.cancel'.tr,
    );
  }

  String _subtitleText(
    Map<String, dynamic>? userData,
    dynamic burs,
    String type,
  ) {
    if (isIndividualScholarshipType(type)) {
      final value = (userData?['displayName'] ??
              userData?['username'] ??
              userData?['nickname'])
          ?.toString();
      if (value != null && value.isNotEmpty) {
        return value;
      }
      return 'common.unknown_user'.tr;
    }
    if (burs.kategori?.isNotEmpty ?? false) {
      return burs.kategori;
    }
    return 'common.unknown_category'.tr;
  }
}
