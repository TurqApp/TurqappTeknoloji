part of 'story_row.dart';

extension StoryRowContentPart on _StoryRowState {
  Widget _buildStoryRow(BuildContext context) {
    return Obx(() {
      // OPTİMİZE EDİLMİŞ REACTİVE: Local cache'den dinle
      _storyOptimizer.localStoryCache.length;
      _storyOptimizer.localTimeCache.length;

      final hasData = controller.users.isNotEmpty;

      return AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        alignment: Alignment.topCenter,
        child: hasData
            ? SizedBox(
                height: StoryRow._storyRowHeight,
                width: double.infinity,
                child: ListView.builder(
                  key: const ValueKey(IntegrationTestKeys.storyRow),
                  scrollDirection: Axis.horizontal,
                  itemCount: controller.users.length,
                  itemBuilder: (context, index) {
                    final user = controller.users[index];
                    return Padding(
                      padding: EdgeInsets.only(
                        left: index == 0 ? StoryRow._storyRowLeadingPadding : 0,
                        right: StoryRow._storyRowItemSpacing,
                      ),
                      child: StoryCircle(
                        key: ValueKey('circle_${user.userID}'),
                        model: user,
                        users: controller.users,
                        isFirst: index == 0,
                      ),
                    );
                  },
                ),
              )
            : SizedBox(
                height: StoryRow._storyRowHeight,
                width: double.infinity,
                child: Builder(
                  builder: (context) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      controller.addMyUserImmediately();
                    });
                    return const StoryRowPlaceholder();
                  },
                ),
              ),
      );
    });
  }
}
