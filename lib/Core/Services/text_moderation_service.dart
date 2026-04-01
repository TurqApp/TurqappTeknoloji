import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/blocked_texts.dart';

class TextModerationService {
  TextModerationService._();

  static Future<BlockedTextMatch?> findFirstBlockedMatch(
    Iterable<String?> values,
  ) async {
    for (final value in values) {
      final text = value?.trim() ?? '';
      if (text.isEmpty) continue;
      final blockedMatch = await kufurEslesmesiniBul(text);
      if (blockedMatch != null) return blockedMatch;
    }
    return null;
  }

  static Future<bool> ensureAllowed(Iterable<String?> values) async {
    final blockedMatch = await findFirstBlockedMatch(values);
    if (blockedMatch == null) return true;
    final blockedWord = blockedMatch.displayValue.replaceAll('"', "'");
    AppSnackbar(
      'comments.community_violation_title'.tr,
      'comments.community_violation_body_with_word'.trParams({
        'word': blockedWord,
      }),
    );
    return false;
  }
}
