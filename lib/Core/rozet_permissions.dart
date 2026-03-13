import 'package:firebase_auth/firebase_auth.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Services/current_user_service.dart';

String normalizeRozetValue(String? raw) {
  final key = (raw ?? '').trim().toLowerCase();
  switch (key) {
    case 'gri':
    case 'gray':
    case 'grey':
      return 'gri';
    case 'turkuaz':
    case 'turquoise':
    case 'cyan':
      return 'turkuaz';
    case 'sari':
    case 'sarı':
    case 'yellow':
      return 'sari';
    case 'mavi':
    case 'blue':
      return 'mavi';
    case 'siyah':
    case 'black':
      return 'siyah';
    case 'kirmizi':
    case 'kırmızı':
    case 'red':
      return 'kirmizi';
    default:
      return '';
  }
}

int rozetPermissionLevel(String? raw) {
  switch (normalizeRozetValue(raw)) {
    case 'gri':
      return 4;
    case 'turkuaz':
      return 3;
    case 'sari':
      return 2;
    case 'mavi':
    case 'siyah':
    case 'kirmizi':
      return 1;
    default:
      return 0;
  }
}

bool hasRozetPermission({
  required String? currentRozet,
  required String minimumRozet,
}) {
  return rozetPermissionLevel(currentRozet) >=
      rozetPermissionLevel(minimumRozet);
}

Future<String> getCurrentUserRozet() async {
  final cached = (CurrentUserService.instance.currentUser?.rozet ?? '').trim();
  if (cached.isNotEmpty) return cached;

  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null || uid.isEmpty) return '';

  try {
    final summary = await UserRepository.ensure().getUser(
      uid,
      preferCache: true,
      cacheOnly: false,
    );
    return summary?.rozet.trim() ?? '';
  } catch (_) {
    return '';
  }
}

Future<bool> currentUserHasRozetPermission(String minimumRozet) async {
  final currentRozet = await getCurrentUserRozet();
  return hasRozetPermission(
    currentRozet: currentRozet,
    minimumRozet: minimumRozet,
  );
}

Future<bool> ensureCurrentUserRozetPermission({
  required String minimumRozet,
  required String featureName,
}) async {
  final allowed = await currentUserHasRozetPermission(minimumRozet);
  if (!allowed) {
    AppSnackbar(
      'Yetki',
      '$featureName için $minimumRozet rozet ve üstü hesap gerekli.',
    );
  }
  return allowed;
}
