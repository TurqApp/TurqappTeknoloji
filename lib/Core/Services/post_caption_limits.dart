import 'package:turqappv2/Services/current_user_service.dart';

class PostCaptionLimits {
  static const int unbadged = 300;
  static const int badged = 1250;

  static const Set<String> _emptyBadgeValues = <String>{
    '',
    'none',
    'no_badge',
    'rozetsiz',
  };

  static bool hasBadge(String? rawRozet) {
    final normalized = (rawRozet ?? '').trim().toLowerCase();
    return normalized.isNotEmpty && !_emptyBadgeValues.contains(normalized);
  }

  static int forRozet(String? rawRozet) =>
      hasBadge(rawRozet) ? badged : unbadged;

  static int forCurrentUser() => forRozet(CurrentUserService.instance.rozet);
}
