import 'package:turqappv2/Modules/Story/StoryMaker/story_model.dart';
import 'package:turqappv2/Core/Utils/avatar_url.dart';
import 'package:turqappv2/Core/Utils/cdn_url_builder.dart';

class StoryUserModel {
  String nickname;
  String avatarUrl;
  String fullName;
  String userID;
  List<StoryModel> stories;

  static List<StoryModel> _cloneStories(List<StoryModel> stories) {
    return stories
        .map((story) => StoryModel.fromCacheMap(story.toCacheMap()))
        .toList(growable: false);
  }

  StoryUserModel({
    required this.nickname,
    required this.avatarUrl,
    required this.fullName,
    required this.userID,
    required List<StoryModel> stories,
  }) : stories = _cloneStories(stories);

  Map<String, dynamic> toCacheMap() => {
        'nickname': nickname,
        'avatarUrl': avatarUrl,
        'fullName': fullName,
        'userID': userID,
        'stories': stories.map((e) => e.toCacheMap()).toList(),
      };

  factory StoryUserModel.fromCacheMap(Map<String, dynamic> map) {
    final rawStories = (map['stories'] as List?) ?? const [];
    final rawAvatar = (map['avatarUrl'] ?? '').toString().trim();
    final stories = <StoryModel>[];
    for (final rawStory in rawStories) {
      if (rawStory is! Map) continue;
      try {
        stories.add(
          StoryModel.fromCacheMap(
            Map<String, dynamic>.from(rawStory.cast<dynamic, dynamic>()),
          ),
        );
      } catch (_) {}
    }
    return StoryUserModel(
      nickname: (map['nickname'] ?? '').toString(),
      avatarUrl: rawAvatar.isEmpty
          ? kDefaultAvatarUrl
          : CdnUrlBuilder.toCdnUrl(rawAvatar),
      fullName: (map['fullName'] ?? '').toString(),
      userID: (map['userID'] ?? '').toString(),
      stories: stories,
    );
  }
}
