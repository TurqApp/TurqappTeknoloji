import 'package:turqappv2/Modules/Story/StoryMaker/StoryModel.dart';

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
}
