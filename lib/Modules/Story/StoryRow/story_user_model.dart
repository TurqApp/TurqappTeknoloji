import 'package:turqappv2/Modules/Story/StoryMaker/story_model.dart';

class StoryUserModel {
  String nickname;
  String pfImage;
  String fullName;
  String userID;
  List<StoryModel> stories;

  StoryUserModel({
    required this.nickname,
    required this.pfImage,
    required this.fullName,
    required this.userID,
    required this.stories,
  });

  Map<String, dynamic> toCacheMap() => {
        'nickname': nickname,
        'pfImage': pfImage,
        'fullName': fullName,
        'userID': userID,
        'stories': stories.map((e) => e.toCacheMap()).toList(),
      };

  factory StoryUserModel.fromCacheMap(Map<String, dynamic> map) {
    final rawStories =
        (map['stories'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    return StoryUserModel(
      nickname: (map['nickname'] ?? '').toString(),
      pfImage: (map['pfImage'] ?? '').toString(),
      fullName: (map['fullName'] ?? '').toString(),
      userID: (map['userID'] ?? '').toString(),
      stories: rawStories.map(StoryModel.fromCacheMap).toList(),
    );
  }
}
