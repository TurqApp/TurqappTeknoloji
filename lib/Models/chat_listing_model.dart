class ChatListingModel {
  String chatID;
  String userID;
  String timeStamp;
  List<String> deleted;
  String fullName;
  String nickname;
  String avatarUrl;
  String lastMessage;
  int unreadCount;
  bool isConversation;
  bool isPinned;
  bool isMuted;

  ChatListingModel({
    required this.chatID,
    required this.userID,
    required this.timeStamp,
    required this.deleted,
    required this.nickname,
    required this.fullName,
    required this.avatarUrl,
    this.lastMessage = "",
    this.unreadCount = 0,
    this.isConversation = false,
    this.isPinned = false,
    this.isMuted = false,
  });
}
