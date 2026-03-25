part of 'post_like_listing_controller.dart';

class LikeUserItem {
  const LikeUserItem({
    required this.userID,
    required this.nickname,
    required this.fullName,
    required this.avatarUrl,
    required this.searchText,
  });

  final String userID;
  final String nickname;
  final String fullName;
  final String avatarUrl;
  final String searchText;
}
