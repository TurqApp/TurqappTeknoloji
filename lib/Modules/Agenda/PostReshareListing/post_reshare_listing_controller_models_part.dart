part of 'post_reshare_listing_controller.dart';

class ReshareUserItem {
  const ReshareUserItem({
    required this.userID,
    required this.nickname,
    required this.fullName,
    required this.avatarUrl,
  });
  final String userID, nickname, fullName, avatarUrl;
}
