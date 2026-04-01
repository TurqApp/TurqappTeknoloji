part of 'post_creator.dart';

extension PostCreatorBodyPart on PostCreator {
  Widget _buildPostBody() {
    return Expanded(
      child: ListView.builder(
        padding: EdgeInsets.only(top: controller.postList.isNotEmpty ? 15 : 0),
        itemCount: controller.postList.length,
        itemBuilder: (context, index) {
          return Obx(() {
            final isSelected = controller.selectedIndex.value == index;
            final postModel = controller.postList[index];
            final tag = postModel.index.toString();
            ensureCreatorContentController(tag: tag);
            return GestureDetector(
              key: ValueKey('composer-${postModel.index}'),
              behavior: HitTestBehavior.deferToChild,
              onTap: isSelected
                  ? null
                  : () => controller.selectedIndex.value = index,
              child: Padding(
                padding: EdgeInsets.only(top: index == 0 ? 15 : 0),
                child: Stack(
                  children: [
                    CreatorContent(
                      model: postModel,
                      isSelected: isSelected,
                    ),
                    if (!isSelected)
                      Positioned.fill(
                        child: Container(
                          color: Colors.white.withValues(alpha: 0.70),
                        ),
                      ),
                  ],
                ),
              ),
            );
          });
        },
      ),
    );
  }
}
