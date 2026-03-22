import 'package:turqappv2/Services/current_user_service.dart';

String _safeEffectiveUserId() {
  try {
    return CurrentUserService.instance.effectiveUserId.trim();
  } catch (_) {
    return '';
  }
}

String activeUserScope({String guestFallback = 'guest'}) {
  final uid = _safeEffectiveUserId();
  return uid.isEmpty ? guestFallback : uid;
}

String userScopedKey(
  String prefix, {
  String? uid,
  String guestFallback = 'guest',
}) {
  final normalizedPrefix = prefix.trim();
  final normalizedUid = (uid ?? _safeEffectiveUserId()).trim();
  final scope = normalizedUid.isEmpty ? guestFallback.trim() : normalizedUid;
  if (scope.isEmpty) {
    return normalizedPrefix;
  }
  return '$normalizedPrefix:$scope';
}
