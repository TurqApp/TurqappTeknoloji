part of 'qa_lab_recorder.dart';

extension QALabRecorderRuntimeNavigationPart on QALabRecorder {
  String _inferPrimaryNavSurface(Map<String, dynamic> snapshot) {
    final navBar = snapshot['navBar'] as Map<String, dynamic>? ??
        const <String, dynamic>{};
    if (navBar['registered'] != true) {
      return '';
    }
    final selectedIndex = _asInt(navBar['selectedIndex']);
    final hasEducation = (snapshot['education'] as Map<String, dynamic>? ??
            const <String, dynamic>{})['registered'] ==
        true;
    switch (selectedIndex) {
      case 0:
        return 'feed';
      case 1:
        return 'explore';
      case 2:
        return 'short';
      case 3:
        return hasEducation ? 'pasaj' : 'profile';
      case 4:
        return hasEducation ? 'profile' : '';
      default:
        return '';
    }
  }

  bool _isPrimaryFeedSelected(
    Map<String, dynamic> snapshot, {
    String route = '',
  }) {
    final normalizedRoute = route.trim().toLowerCase();
    final usesPrimaryNavRoute = normalizedRoute.isEmpty ||
        normalizedRoute == '/' ||
        normalizedRoute == '/navbar' ||
        normalizedRoute == 'navbar' ||
        normalizedRoute == '/navbarview' ||
        normalizedRoute == 'navbarview';
    if (!usesPrimaryNavRoute) {
      return false;
    }
    final primaryNavSurface = _inferPrimaryNavSurface(snapshot);
    if (primaryNavSurface.isNotEmpty) {
      return primaryNavSurface == 'feed';
    }

    bool registered(String key) =>
        (snapshot[key] as Map<String, dynamic>? ??
            const <String, dynamic>{})['registered'] ==
        true;

    return registered('feed') &&
        !registered('explore') &&
        !registered('short') &&
        !registered('education') &&
        !registered('profile');
  }

  String _inferSurfaceFromSnapshot(Map<String, dynamic> snapshot) {
    final route = (snapshot['currentRoute'] ?? '').toString();
    final routeSurface = _inferSurfaceFromRoute(route);
    final primaryNavSurface = _inferPrimaryNavSurface(snapshot);

    bool registered(String key) =>
        (snapshot[key] as Map<String, dynamic>? ??
            const <String, dynamic>{})['registered'] ==
        true;

    if (routeSurface.isNotEmpty &&
        routeSurface != 'feed' &&
        routeSurface != 'explore' &&
        routeSurface != 'pasaj' &&
        routeSurface != 'profile') {
      return routeSurface;
    }
    if (routeSurface.isEmpty && primaryNavSurface.isNotEmpty) {
      return primaryNavSurface;
    }
    if (registered('storyComments')) return 'story_comments';
    if (registered('comments')) return 'comments';
    if (registered('chatConversation')) return 'chat_conversation';
    if (registered('chat')) return 'chat';
    if (registered('notifications')) return 'notifications';
    if (registered('socialProfile')) return 'social_profile';
    if (registered('profile')) {
      final route = (snapshot['currentRoute'] ?? '').toString();
      if (route.contains('FollowingFollowers')) return 'following_followers';
      if (route.contains('Permissions')) return 'permissions';
      if (route.contains('Settings')) return 'settings';
      return 'profile';
    }
    if (registered('short')) return 'short';
    if (registered('education')) return 'pasaj';
    if (registered('explore')) return 'explore';
    if (registered('feed')) return 'feed';
    if (routeSurface.isNotEmpty) return routeSurface;
    if (route.isNotEmpty) return _sanitizeRouteSurface(route);
    return 'app';
  }

  List<String> _observedSurfaces() {
    final ordered = <String>[];
    final seen = <String>{};

    void addSurface(String value) {
      final normalized = value.trim();
      if (normalized.isEmpty || normalized == 'app') return;
      if (seen.add(normalized)) {
        ordered.add(normalized);
      }
    }

    for (final surface in QALabCatalog.focusSurfaces) {
      addSurface(surface);
    }
    addSurface(lastSurface.value);
    for (final route in routes) {
      addSurface(route.surface);
    }
    for (final checkpoint in checkpoints) {
      addSurface(checkpoint.surface);
    }
    for (final event in timelineEvents) {
      addSurface(event.surface);
    }
    for (final issue in issues) {
      addSurface(issue.surface);
    }
    return ordered;
  }

  String _inferSurfaceFromRoute(String route) {
    final normalized = route.trim().toLowerCase();
    if (normalized.isEmpty ||
        normalized == '/' ||
        normalized == '/navbarview' ||
        normalized == 'navbarview') {
      return '';
    }
    if (normalized.contains('qalab')) return 'qa_lab';
    if (normalized.contains('support')) return 'support';
    if (normalized.contains('notification')) return 'notifications';
    if (normalized.contains('permission')) return 'permissions';
    if (normalized.contains('setting')) return 'settings';
    if (normalized.contains('saved')) return 'saved_posts';
    if (normalized.contains('liked')) return 'liked_posts';
    if (normalized.contains('scholarship') || normalized.contains('burs')) {
      return 'scholarship';
    }
    if (normalized.contains('answerkey') ||
        normalized.contains('booklet') ||
        normalized.contains('optical') ||
        normalized.contains('optic')) {
      return 'answer_key';
    }
    if (normalized.contains('deneme') ||
        normalized.contains('onlineexam') ||
        normalized.contains('practice')) {
      return 'online_exam';
    }
    if (normalized.contains('tutoring')) return 'tutoring';
    if (normalized.contains('market')) return 'market';
    if (normalized.contains('job')) return 'job_finder';
    if (normalized.contains('questionbank') ||
        normalized.contains('question_bank') ||
        normalized.contains('sorubank')) {
      return 'question_bank';
    }
    if (normalized.contains('story')) {
      return normalized.contains('comment') ? 'story_comments' : 'story';
    }
    if (normalized.contains('comment')) return 'comments';
    if (normalized.contains('chat')) {
      return normalized.contains('conversation') ? 'chat_conversation' : 'chat';
    }
    if (normalized.contains('socialprofile')) return 'social_profile';
    if (normalized.contains('followingfollowers')) return 'following_followers';
    if (normalized.contains('profile')) return 'profile';
    if (normalized.contains('explore')) return 'explore';
    if (normalized.contains('short')) return 'short';
    if (normalized.contains('creator') ||
        normalized.contains('upload') ||
        normalized.contains('composer')) {
      return 'upload';
    }
    if (normalized.contains('login') ||
        normalized.contains('signin') ||
        normalized.contains('signup') ||
        normalized.contains('splash')) {
      return 'auth';
    }
    if (normalized.contains('education') || normalized.contains('pasaj')) {
      return 'pasaj';
    }
    return _sanitizeRouteSurface(route);
  }

  String _sanitizeRouteSurface(String route) {
    final trimmed = route.trim();
    if (trimmed.isEmpty || trimmed == '/') {
      return '';
    }
    final lastSegment = trimmed
        .split('/')
        .where((segment) => segment.trim().isNotEmpty)
        .lastOrNull;
    final candidate = (lastSegment ?? trimmed).trim();
    final withUnderscores = candidate.replaceAllMapped(
      RegExp(r'([a-z0-9])([A-Z])'),
      (match) => '${match.group(1)}_${match.group(2)}',
    );
    return withUnderscores
        .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '')
        .toLowerCase();
  }
}
