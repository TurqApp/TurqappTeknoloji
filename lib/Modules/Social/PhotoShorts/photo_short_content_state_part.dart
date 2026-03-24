part of 'photo_short_content.dart';

extension PhotoShortContentStatePart on _PhotoShortContentState {
  Widget gonderiGizlendi(BuildContext context) {
    return _buildPostStateOverlay(
      title: 'post_state.hidden_title'.tr,
      body: 'post_state.hidden_body'.tr,
      onUndo: controller.gizlemeyiGeriAl,
    );
  }

  Widget gonderiArsivlendi(BuildContext context) {
    return _buildPostStateOverlay(
      title: 'post_state.archived_title'.tr,
      body: 'post_state.archived_body'.tr,
      onUndo: controller.arsivdenCikart,
    );
  }

  Widget gonderiSilindi(BuildContext context) {
    return _buildPostStateOverlay(
      title: 'post_state.deleted_title'.tr,
      body: 'post_state.deleted_body'.tr,
    );
  }

  Widget _buildPostStateOverlay({
    required String title,
    required String body,
    VoidCallback? onUndo,
  }) {
    return Container(
      color: Colors.black,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.checkmark_seal,
                      color: Colors.green,
                      size: 30,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontFamily: "MontserratMedium",
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 50),
                  child: Divider(color: Colors.white),
                ),
                const SizedBox(height: 7),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontFamily: "Montserrat",
                  ),
                ),
                const SizedBox(height: 15),
                if (onUndo != null)
                  GestureDetector(
                    onTap: onUndo,
                    child: Text(
                      'common.undo'.tr,
                      style: const TextStyle(
                        color: Colors.blueAccent,
                        fontSize: 15,
                        fontFamily: "MontserratMedium",
                      ),
                    ),
                  ),
              ],
            ),
            SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'short.next_post'.tr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontFamily: "MontserratMedium",
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Icon(CupertinoIcons.arrow_down, color: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
