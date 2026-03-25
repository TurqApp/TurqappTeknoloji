part of 'deep_link_service.dart';

extension _DeepLinkServiceRuntimeX on DeepLinkService {
  void start() {
    if (_started) return;
    _started = true;
    initialLinkResolved.value = false;
    initialLinkResolved.value = true;
  }

  Future<void> handle(Uri uri) async {
    if (_handling) return;
    final parsed = _parse(uri);
    if (parsed == null) return;

    _handling = true;
    try {
      if (CurrentUserService.instance.effectiveUserId.isEmpty) {
        return;
      }

      if (parsed.type == 'edu' &&
          (parsed.id.startsWith('question-') ||
              parsed.id.startsWith('scholarship-') ||
              parsed.id.startsWith('practiceexam-') ||
              parsed.id.startsWith('pastquestion-') ||
              parsed.id.startsWith('answerkey-') ||
              parsed.id.startsWith('tutoring-') ||
              parsed.id.startsWith('job-'))) {
        await _openEducationLink(parsed.id);
        return;
      }
      if (parsed.type == 'market') {
        await _openMarket(parsed.id);
        return;
      }

      final resolved = await _shortLinkService.resolve(
        type: parsed.type,
        id: parsed.id,
      );

      final data = Map<String, dynamic>.from(
        resolved['data'] as Map? ?? const {},
      );
      final entityId = (data['entityId'] ?? '').toString().trim();
      if (entityId.isEmpty) {
        final handled = await _tryDirectFallback(parsed);
        if (!handled) {
          AppSnackbar('common.info'.tr, 'deep_link.resolve_failed'.tr);
        }
        return;
      }

      switch (parsed.type) {
        case 'post':
          await _openPost(entityId);
          return;
        case 'story':
          await _openStory(entityId);
          return;
        case 'user':
          await _openUserProfile(entityId);
          return;
        case 'edu':
          await _openEducationLink(entityId);
          return;
        case 'market':
          await _openMarket(entityId);
          return;
      }
    } catch (_) {
      final handled = await _tryDirectFallback(parsed);
      if (!handled) {
        AppSnackbar('common.info'.tr, 'deep_link.open_failed'.tr);
      }
    } finally {
      _handling = false;
    }
  }

  void disposeRuntime() {
    _started = false;
  }
}
