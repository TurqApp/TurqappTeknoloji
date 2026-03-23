part of 'following_followers.dart';

extension _FollowingFollowersContentPart on _FollowingFollowersState {
  Widget _buildFollowersList({
    required RxList<String> list,
    required bool Function() isLoading,
    required bool Function() hasMore,
    required ScrollController scrollController,
    required Future<void> Function() loadMore,
  }) {
    return Obx(
      () => NotificationListener<ScrollNotification>(
        onNotification: (info) {
          if (info.metrics.pixels >= info.metrics.maxScrollExtent - 300) {
            if (hasMore() && !isLoading()) {
              loadMore();
            }
          }
          return false;
        },
        child: ListView.builder(
          controller: scrollController,
          padding: EdgeInsets.zero,
          itemCount: list.isEmpty ? 1 : list.length + 1,
          itemBuilder: (ctx, i) {
            if (list.isEmpty) {
              return Padding(
                padding: EdgeInsets.only(top: 30),
                child: Center(
                  child: Text(
                    'following.none'.tr,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 15,
                      fontFamily: 'MontserratMedium',
                    ),
                  ),
                ),
              );
            }

            if (i == list.length) {
              if (isLoading()) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CupertinoActivityIndicator()),
                );
              } else {
                return const SizedBox.shrink();
              }
            }

            final id = list[i];
            return Padding(
              padding: EdgeInsets.only(top: i == 0 ? 15 : 0),
              child: FollowerContent(userID: id, key: ValueKey(id)),
            );
          },
        ),
      ),
    );
  }
}
