part of 'deneme_sinavi_preview.dart';

extension DenemeSinaviPreviewSectionsPart on _DenemeSinaviPreviewState {
  Widget _buildCover() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: AspectRatio(
        aspectRatio: 1,
        child: CachedNetworkImage(
          imageUrl: controller.model.cover,
          fit: BoxFit.cover,
          errorWidget: (context, url, error) => Center(
            child: Text(
              'practice.cover_load_failed'.tr,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 15,
                fontFamily: 'MontserratMedium',
              ),
            ),
          ),
        ),
      ),
    );
  }

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

  Widget _buildAuthorCard(DenemeSinaviPreviewController controller) {
    final displayName = controller.displayName.value.trim();
    final nickname = controller.nickname.value.trim();
    return PasajOwnerCard(
      title: displayName.isEmpty
          ? (nickname.isEmpty ? 'common.user'.tr : nickname)
          : displayName,
      subtitle: nickname.isEmpty ? null : '@$nickname',
      userId: controller.model.userID,
      imageUrl: controller.avatarUrl.value.trim(),
      onTap: isCurrentUserId(controller.model.userID)
          ? null
          : () => Get.to(() => SocialProfile(userID: controller.model.userID)),
    );
  }

  Widget _buildSuccessSheet(DenemeSinaviPreviewController controller) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        GestureDetector(
          onTap: () => controller.showSucces.value = false,
          child: Container(color: Colors.black.withValues(alpha: 0.2)),
        ),
        Container(
          height: (Get.height * 0.28).clamp(190.0, 220.0),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(18),
              topLeft: Radius.circular(18),
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x33000000),
                spreadRadius: 5,
                blurRadius: 7,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'practice.apply_completed_title'.tr,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontFamily: 'MontserratBold',
                  ),
                ),
                15.ph,
                Text(
                  'practice.apply_completed_body'.tr,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontFamily: 'MontserratMedium',
                  ),
                ),
                15.ph,
                GestureDetector(
                  onTap: Get.back,
                  child: Container(
                    height: 50,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    child: Text(
                      'common.ok'.tr,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontFamily: 'MontserratMedium',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
