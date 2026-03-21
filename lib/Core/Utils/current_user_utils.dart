import 'package:turqappv2/Services/current_user_service.dart';

bool isCurrentUserId(String userId) {
  return userId == CurrentUserService.instance.userId;
}
