part of 'my_q_r_code.dart';

extension _MyQrCodeContentPart on _MyQRCodeState {
  Widget _buildMyQrCodeContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const SizedBox(),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Obx(() {
                  final qrData = controller.profileLink.value.isNotEmpty
                      ? controller.profileLink.value
                      : userService.effectiveUserId;
                  return ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(12)),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        QrImageView(
                          data: qrData,
                          version: QrVersions.auto,
                          size: 250.0,
                          backgroundColor: Colors.white,
                        ),
                        Container(
                          width: 42,
                          height: 42,
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: SvgPicture.asset("assets/icons/logo.svg"),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.all(25),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.all(Radius.circular(18)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  spreadRadius: 2,
                  blurRadius: 2,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(25),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildQrAction(
                    onTap: controller.shareProfile,
                    icon: const Icon(AppIcons.share, color: Colors.black),
                    label: 'common.share'.tr,
                  ),
                  const SizedBox(width: 20),
                  _buildQrAction(
                    onTap: controller.copyLink,
                    icon: const Icon(CupertinoIcons.link, color: Colors.black),
                    label: 'common.copy_link'.tr,
                  ),
                  const SizedBox(width: 20),
                  _buildQrAction(
                    onTap: controller.downloadQRCode,
                    icon: const Icon(
                      CupertinoIcons.arrow_down_to_line,
                      color: Colors.black,
                    ),
                    label: 'common.download'.tr,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQrAction({
    required VoidCallback onTap,
    required Widget icon,
    required String label,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: Colors.grey.withAlpha(50)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: icon,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 12,
              fontFamily: "MontserratMedium",
            ),
          ),
        ],
      ),
    );
  }
}
