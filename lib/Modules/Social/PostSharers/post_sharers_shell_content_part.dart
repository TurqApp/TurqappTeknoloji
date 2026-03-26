part of 'post_sharers.dart';

extension _PostSharersShellContentPart on _PostSharersState {
  Widget _buildPostSharersShellContent(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                BackButtons(text: 'short.shared_as_post_by'.tr),
              ],
            ),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(
                    child: CupertinoActivityIndicator(),
                  );
                }

                if (controller.postSharers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.share_up,
                          size: 64,
                          color: Colors.grey.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'post_sharers.empty'.tr,
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                            fontFamily: "MontserratMedium",
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  controller: controller.scrollController,
                  itemCount: controller.postSharers.length +
                      (controller.isLoadingMore.value ? 1 : 0),
                  separatorBuilder: (context, index) => Divider(
                    indent: 10,
                    endIndent: 10,
                    height: 1,
                    thickness: 1,
                    color: Colors.grey.shade200,
                  ),
                  itemBuilder: (context, index) {
                    if (index >= controller.postSharers.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: CupertinoActivityIndicator(),
                        ),
                      );
                    }

                    final sharer = controller.postSharers[index];
                    final userData = controller.usersData[sharer.userID];

                    return _PostSharerTile(
                      sharer: sharer,
                      userData: userData,
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
