part of 'social_media_links.dart';

extension SocialMediaLinksActionsPart on _SocialMediaLinksState {
  Future<void> showRemoveConfirmation(int index) async {
    final model = controller.list[index];
    await noYesAlert(
      title: 'social_links.remove_title'.tr,
      message: 'social_links.remove_message'.tr,
      cancelText: 'common.cancel'.tr,
      yesText: 'common.remove'.tr,
      yesButtonColor: CupertinoColors.destructiveRed,
      onYesPressed: () async {
        await controller.deleteLink(model.docID);
        await controller.getData(silent: true);
      },
    );
  }

  Widget _buildGridCard(
    SocialMediaModel model, {
    required int index,
  }) {
    return Container(
      decoration: BoxDecoration(color: Colors.white.withAlpha(20)),
      child: Column(
        children: [
          Flexible(
            child: Stack(
              alignment: Alignment.center,
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: ClipOval(
                    child: _buildLogo(model),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () => showRemoveConfirmation(index),
                    child: Container(
                      width: 25,
                      height: 25,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        CupertinoIcons.minus_circle_fill,
                        color: Colors.red,
                        size: 25,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 7),
          Text(
            model.title,
            maxLines: 1,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 12,
              fontFamily: 'MontserratBold',
            ),
          ),
          const SizedBox(height: 7),
        ],
      ),
    );
  }

  Widget _buildLogo(SocialMediaModel model) {
    if (model.logo.startsWith('assets/')) {
      return Image.asset(
        model.logo,
        fit: BoxFit.cover,
      );
    }
    if (model.logo.trim().isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: model.logo,
        fit: BoxFit.cover,
      );
    }
    return Container(
      color: Colors.grey.withValues(alpha: 0.15),
      child: const Icon(
        CupertinoIcons.link,
        color: Colors.black54,
      ),
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: controller.showAddBottomSheet,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(20),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Flexible(
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey),
                  ),
                  child: const Center(
                    child: Icon(CupertinoIcons.add, color: Colors.black),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'social_links.add'.tr,
              maxLines: 1,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 12,
                fontFamily: 'MontserratBold',
              ),
            ),
            const SizedBox(height: 7),
          ],
        ),
      ),
    );
  }
}
