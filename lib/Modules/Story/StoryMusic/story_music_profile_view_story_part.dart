part of 'story_music_profile_view.dart';

extension StoryMusicProfileViewStoryPart on _StoryMusicProfileViewState {
  StoryElement? _resolvePreviewElement(StoryModel story) {
    for (final element in story.elements) {
      if (element.type == StoryElementType.image ||
          element.type == StoryElementType.gif ||
          element.type == StoryElementType.video) {
        return element;
      }
    }
    return story.elements.isNotEmpty ? story.elements.first : null;
  }

  Future<void> _openStory(_MusicStoryEntry entry) async {
    final startedUser = StoryUserModel(
      nickname: entry.user.nickname,
      avatarUrl: entry.user.avatarUrl,
      fullName: entry.user.fullName,
      userID: entry.user.userID,
      stories: [entry.story],
    );
    await Get.to(
      () => StoryViewer(
        startedUser: startedUser,
        storyOwnerUsers: [startedUser],
      ),
    );
  }
}
