part of 'booklet_preview.dart';

extension BookletPreviewWidgetsPart on _BookletPreviewState {
  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontFamily: 'MontserratBold',
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 14,
                fontFamily: 'MontserratMedium',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xFFF6F7FB),
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
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _buildAnswerKeysList(BookletPreviewController controller) {
    return Column(
      children: controller.answerKeys.map((item) {
        return GestureDetector(
          onTap: () => controller.navigateToAnswerKey(Get.context!, item),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.14)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.baslik,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontFamily: 'MontserratBold',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'tests.questions_prepared_count'.trParams({
                            'count': item.dogruCevaplar.length.toString(),
                          }),
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 13,
                            fontFamily: 'MontserratMedium',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    CupertinoIcons.chevron_right,
                    color: Colors.black45,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(growable: false),
    );
  }

  Widget _buildAuthorCard(BookletPreviewController controller) {
    final nickname = controller.nickname.value.trim();
    return PasajOwnerCard(
      title: nickname.isEmpty ? 'answer_key.default_user'.tr : nickname,
      subtitle: nickname.isEmpty ? null : '@$nickname',
      userId: controller.model.userID,
      imageUrl: controller.avatarUrl.value.trim(),
      onTap: isCurrentUserId(controller.model.userID)
          ? null
          : () => Get.to(() => SocialProfile(userID: controller.model.userID)),
    );
  }

  Widget _pullDownMenu(BookletPreviewController controller) {
    return PullDownButton(
      itemBuilder: (context) => [
        PullDownMenuItem(
          onTap: () {
            Get.to(
              () => ReportUser(
                userID: controller.model.userID,
                postID: controller.model.docID,
                commentID: '',
              ),
            );
          },
          title: 'answer_key.report_book'.tr,
          icon: CupertinoIcons.exclamationmark_circle,
        ),
      ],
      buttonBuilder: (context, showMenu) => AppHeaderActionButton(
        onTap: showMenu,
        child: Icon(
          AppIcons.ellipsisVertical,
          color: Colors.black,
          size: 20,
        ),
      ),
    );
  }
}
