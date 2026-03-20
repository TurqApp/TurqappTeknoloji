import 'package:firebase_auth/firebase_auth.dart';

bool isCurrentUserId(String userId) {
  return userId == FirebaseAuth.instance.currentUser?.uid;
}
