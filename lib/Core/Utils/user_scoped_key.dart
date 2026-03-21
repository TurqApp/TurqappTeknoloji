import 'package:turqappv2/Services/current_user_service.dart';

String activeUserScope({String guestFallback = 'guest'}) {
  final uid = CurrentUserService.instance.userId.trim();
  return uid.isEmpty ? guestFallback : uid;
}

String userScopedKey(
  String prefix, {
  String? uid,
  String guestFallback = 'guest',
}) {
  final normalizedPrefix = prefix.trim();
  final normalizedUid = (uid ?? CurrentUserService.instance.userId).trim();
  final scope = normalizedUid.isEmpty ? guestFallback.trim() : normalizedUid;
  if (scope.isEmpty) {
    return normalizedPrefix;
  }
  return '$normalizedPrefix:$scope';
}
