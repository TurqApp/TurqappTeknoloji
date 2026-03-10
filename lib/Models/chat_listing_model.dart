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

  factory ChatListingModel.fromJson(Map<String, dynamic> json) {
    return ChatListingModel(
      chatID: json['chatID'] ?? '',
      userID: json['userID'] ?? '',
      timeStamp: json['timeStamp'] ?? '0',
      deleted: List<String>.from(json['deleted'] ?? []),
      nickname: json['nickname'] ?? '',
      fullName: json['fullName'] ?? '',
      avatarUrl: json['avatarUrl'] ?? '',
      lastMessage: json['lastMessage'] ?? '',
      unreadCount: json['unreadCount'] ?? 0,
      isConversation: json['isConversation'] ?? false,
      isPinned: json['isPinned'] ?? false,
      isMuted: json['isMuted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chatID': chatID,
      'userID': userID,
      'timeStamp': timeStamp,
      'deleted': deleted,
      'nickname': nickname,
      'fullName': fullName,
      'avatarUrl': avatarUrl,
      'lastMessage': lastMessage,
      'unreadCount': unreadCount,
      'isConversation': isConversation,
      'isPinned': isPinned,
      'isMuted': isMuted,
    };
  }
}
