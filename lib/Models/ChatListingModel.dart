class ChatListingModel {
  String chatID;
  String userID;
  String timeStamp;
  List<String> deleted;
  String fullName;
  String nickname;
  String pfImage;

  ChatListingModel({
    required this.chatID,
    required this.userID,
    required this.timeStamp,
    required this.deleted,
    required this.nickname,
    required this.fullName,
    required this.pfImage,
});
}