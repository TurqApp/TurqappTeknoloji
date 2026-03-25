part of 'current_user_service.dart';

class _CurrentUserServiceStoryPart {
  final CurrentUserService _service;

  const _CurrentUserServiceStoryPart(this._service);

  bool hasReadStory(String storyId) {
    return _service._currentUser?.readStories.contains(storyId) ?? false;
  }

  int? getStoryReadTime(String userId) {
    return _service._currentUser?.readStoriesTimes[userId];
  }

  bool get isVerified => _service._currentUser?.isVerified ?? false;
}
