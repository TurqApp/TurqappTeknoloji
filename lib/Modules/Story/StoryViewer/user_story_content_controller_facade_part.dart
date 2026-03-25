part of 'user_story_content_controller.dart';

extension UserStoryContentControllerFacadePart on UserStoryContentController {
  Future<void> getLikes(String storyID) =>
      _UserStoryContentControllerRuntimePart(this).getLikes(storyID);

  Future<void> showPostCommentsBottomSheet(
    String docID,
    String nickname,
    bool isMyStory, {
    void Function(bool)? onClosed,
  }) =>
      _UserStoryContentControllerRuntimePart(this).showPostCommentsBottomSheet(
        docID,
        nickname,
        isMyStory,
        onClosed: onClosed,
      );

  Future<void> showLikesBottomSheet(
    String docID, {
    void Function(bool)? onClosed,
  }) =>
      _UserStoryContentControllerRuntimePart(this)
          .showLikesBottomSheet(docID, onClosed: onClosed);

  Future<void> showSeensBottomSheet(
    String docID, {
    void Function(bool)? onClosed,
  }) =>
      _UserStoryContentControllerRuntimePart(this)
          .showSeensBottomSheet(docID, onClosed: onClosed);

  Future<void> getReactions(String storyID) =>
      _UserStoryContentControllerRuntimePart(this).getReactions(storyID);

  Future<void> react(String storyID, String emoji) =>
      _UserStoryContentControllerRuntimePart(this).react(storyID, emoji);

  Future<void> like(String storyID) =>
      _UserStoryContentControllerRuntimePart(this).like(storyID);

  Future<void> setSeen(String storyID) =>
      _UserStoryContentControllerRuntimePart(this).setSeen(storyID);
}
