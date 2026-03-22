import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';
import 'package:turqappv2/Services/current_user_service.dart';

String normalizeRozetValue(String? raw) {
  final key = normalizeSearchText(raw ?? '');
  switch (key) {
    case 'gri':
    case 'gray':
    case 'grey':
    case 'grau':
    case 'gris':
    case 'grigio':
    case 'серый':
      return 'gri';
    case 'turkuaz':
    case 'turquoise':
    case 'cyan':
    case 'türkis':
    case 'turchese':
    case 'бирюзовый':
      return 'turkuaz';
    case 'sari':
    case 'sarı':
    case 'yellow':
    case 'gelb':
    case 'jaune':
    case 'giallo':
    case 'желтый':
    case 'жёлтый':
      return 'sari';
    case 'mavi':
    case 'blue':
    case 'blau':
    case 'bleu':
    case 'blu':
    case 'синий':
      return 'mavi';
    case 'siyah':
    case 'black':
    case 'schwarz':
    case 'noir':
    case 'nero':
    case 'черный':
    case 'чёрный':
      return 'siyah';
    case 'kirmizi':
    case 'kırmızı':
    case 'red':
    case 'rot':
    case 'rouge':
    case 'rosso':
    case 'красный':
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

  final uid = CurrentUserService.instance.effectiveUserId;
  if (uid.isEmpty) return '';

  try {
    final summary = await UserSummaryResolver.ensure().resolve(
      uid,
      preferCache: true,
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
    final badgeLabel = _localizedRozetLabel(minimumRozet);
    AppSnackbar(
      'permission.required_title'.tr,
      'permission.rozet_required_body'.trParams({
        'feature': featureName,
        'badge': badgeLabel,
      }),
    );
  }
  return allowed;
}

String _localizedRozetLabel(String raw) {
  switch (normalizeRozetValue(raw)) {
    case 'gri':
      return 'become_verified.badge_gray'.tr;
    case 'turkuaz':
      return 'become_verified.badge_turquoise'.tr;
    case 'sari':
      return 'become_verified.badge_yellow'.tr;
    case 'mavi':
      return 'become_verified.badge_blue'.tr;
    case 'siyah':
      return 'become_verified.badge_black'.tr;
    case 'kirmizi':
      return 'become_verified.badge_red'.tr;
    default:
      return raw;
  }
}
