import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';

class ParsedDeepLinkRoute {
  const ParsedDeepLinkRoute({
    required this.type,
    required this.id,
  });

  final String type;
  final String id;
}

String normalizeDeepLinkId(String raw) {
  var id = raw.trim();
  id = id.replaceAll(RegExp(r'^[^A-Za-z0-9_-]+'), '');
  id = id.replaceAll(RegExp(r'[^A-Za-z0-9_-]+$'), '');
  return id;
}

String? normalizeDeepLinkType(String raw) {
  final value = normalizeSearchText(raw);
  if (value == 'p' || value == 'post') return 'post';
  if (value == 's' || value == 'story') return 'story';
  if (value == 'u' || value == 'user' || value == 'profile') return 'user';
  if (value == 'i' || value == 'e' || value == 'edu' || value == 'education') {
    return 'edu';
  }
  if (value == 'm' || value == 'market' || value == 'product') {
    return 'market';
  }
  return null;
}

ParsedDeepLinkRoute? parseDeepLinkUri(Uri uri) {
  final scheme = normalizeLowercase(uri.scheme);
  final host = normalizeLowercase(uri.host);
  final segments = uri.pathSegments.where((e) => e.isNotEmpty).toList();

  if (scheme == 'http' || scheme == 'https') {
    if (!_isAllowedDeepLinkHost(host)) return null;
    if (segments.length < 2) return null;
    return _routeFromTypeAndId(segments[0], segments[1]);
  }

  if (scheme == 'turqapp') {
    if (host.isNotEmpty) {
      final mappedHostType = normalizeDeepLinkType(host);
      if (mappedHostType != null && segments.isNotEmpty) {
        final id = normalizeDeepLinkId(segments.first);
        if (id.isEmpty) return null;
        return ParsedDeepLinkRoute(type: mappedHostType, id: id);
      }
    }
    if (segments.length >= 2) {
      return _routeFromTypeAndId(segments[0], segments[1]);
    }
  }

  return null;
}

int educationDeepLinkTabIndexFor(String entityId) {
  final normalized = normalizeSearchText(entityId);
  if (normalized.startsWith('scholarship:')) {
    return 0;
  }
  if (normalized.startsWith('question:') ||
      normalized.startsWith('question-')) {
    return 1;
  }
  if (normalized.startsWith('practiceexam:')) {
    return 2;
  }
  if (normalized.startsWith('pastquestion:')) {
    return 3;
  }
  if (normalized.startsWith('answerkey:')) {
    return 4;
  }
  if (normalized.startsWith('tutoring:')) {
    return 5;
  }
  if (normalized.startsWith('job:')) {
    return 6;
  }
  return 0;
}

bool shouldOpenEducationDeepLinkDirectly(ParsedDeepLinkRoute route) {
  if (route.type != 'edu') return false;
  return route.id.startsWith('question-') ||
      route.id.startsWith('scholarship-') ||
      route.id.startsWith('practiceexam-') ||
      route.id.startsWith('pastquestion-') ||
      route.id.startsWith('answerkey-') ||
      route.id.startsWith('tutoring-') ||
      route.id.startsWith('job-');
}

bool _isAllowedDeepLinkHost(String host) {
  return host == 'turqapp.com' ||
      host == 'www.turqapp.com' ||
      host == 'go.turqapp.com' ||
      host == 'turqqapp.com' ||
      host == 'www.turqqapp.com' ||
      host == 'go.turqqapp.com';
}

ParsedDeepLinkRoute? _routeFromTypeAndId(String rawType, String rawId) {
  final type = normalizeDeepLinkType(rawType);
  if (type == null) return null;
  final id = normalizeDeepLinkId(rawId);
  if (id.isEmpty) return null;
  return ParsedDeepLinkRoute(type: type, id: id);
}
