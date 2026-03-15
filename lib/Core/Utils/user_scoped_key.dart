import 'package:firebase_auth/firebase_auth.dart';

String activeUserScope({String guestFallback = 'guest'}) {
  final uid = FirebaseAuth.instance.currentUser?.uid.trim() ?? '';
  return uid.isEmpty ? guestFallback : uid;
}

String userScopedKey(
  String prefix, {
  String? uid,
  String guestFallback = 'guest',
}) {
  final normalizedPrefix = prefix.trim();
  final normalizedUid = (uid ?? FirebaseAuth.instance.currentUser?.uid ?? '')
      .trim();
  final scope = normalizedUid.isEmpty ? guestFallback.trim() : normalizedUid;
  if (scope.isEmpty) {
    return normalizedPrefix;
  }
  return '$normalizedPrefix:$scope';
}
