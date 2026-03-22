import 'package:share_plus/share_plus.dart';
import 'package:turqappv2/Core/Services/share_action_guard.dart';
import 'package:turqappv2/Core/Services/user_moderation_guard.dart';

class ShareLinkService {
  static Future<void> shareUrl({
    required String url,
    String? subject,
    String? title,
  }) async {
    if (!UserModerationGuard.ensureAllowed(RestrictedAction.externalShare)) {
      return;
    }
    await ShareActionGuard.run(() async {
      final clean = url.trim();
      if (clean.isEmpty) return;

      Uri? uri;
      try {
        final parsed = Uri.parse(clean);
        if (parsed.hasScheme &&
            (parsed.scheme == 'http' || parsed.scheme == 'https')) {
          uri = parsed;
        }
      } catch (_) {
        uri = null;
      }

      if (uri != null) {
        await SharePlus.instance.share(
          ShareParams(
            uri: uri,
            subject: subject,
            title: title,
          ),
        );
        return;
      }

      await SharePlus.instance.share(
        ShareParams(
          text: clean,
          subject: subject,
          title: title,
        ),
      );
    });
  }
}
