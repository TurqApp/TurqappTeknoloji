part of 'message_content_controller.dart';

extension MessageContentControllerDataPart on MessageContentController {
  Future<void> _loadMessageUser() async {
    final user = await _userSummaryResolver.resolve(
      model.userID,
      preferCache: true,
    );
    if (user == null) return;
    nickname.value = user.nickname.isNotEmpty
        ? user.nickname
        : (user.username.isNotEmpty ? user.username : user.displayName);
    avatarUrl.value = user.avatarUrl;
  }

  Future<void> getPost() async {
    final lookup = await ensureNotifyLookupRepository().getPostLookup(
      model.postID,
    );
    if (!lookup.exists || lookup.model == null) {
      postModel.value = PostsModel.empty();
      return;
    }
    postModel.value = lookup.model;
    final user = await _userSummaryResolver.resolve(
      lookup.model!.userID,
      preferCache: true,
    );
    if (user == null) return;
    postNickname.value = user.preferredName;
    postPfImage.value = user.avatarUrl;
  }
}
