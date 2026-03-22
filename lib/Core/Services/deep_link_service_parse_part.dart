part of 'deep_link_service.dart';

extension DeepLinkServiceParsePart on DeepLinkService {
  Future<bool> _performTryDirectFallback(_ParsedDeepLink parsed) async {
    final rawId = parsed.id.trim();
    if (rawId.isEmpty) return false;
    try {
      switch (parsed.type) {
        case 'post':
          await _openPost(rawId);
          return true;
        case 'story':
          await _openStory(rawId);
          return true;
        case 'user':
          await _openUserProfile(rawId);
          return true;
        case 'edu':
          await _openEducationLink(rawId);
          return true;
        case 'market':
          await _openMarket(rawId);
          return true;
      }
    } catch (_) {
      return false;
    }
    return false;
  }

  _ParsedDeepLink? _performParse(Uri uri) {
    final scheme = normalizeLowercase(uri.scheme);
    final host = normalizeLowercase(uri.host);
    final segments = uri.pathSegments.where((e) => e.isNotEmpty).toList();

    if (scheme == 'http' || scheme == 'https') {
      if (!(host == 'turqapp.com' ||
          host == 'www.turqapp.com' ||
          host == 'go.turqapp.com' ||
          host == 'turqqapp.com' ||
          host == 'www.turqqapp.com' ||
          host == 'go.turqqapp.com')) {
        return null;
      }
      if (segments.length < 2) return null;
      final type = normalizeDeepLinkType(segments[0]);
      if (type == null) return null;
      final id = normalizeDeepLinkId(segments[1]);
      if (id.isEmpty) return null;
      return _ParsedDeepLink(type: type, id: id);
    }

    if (scheme == 'turqapp') {
      if (host.isNotEmpty) {
        final mappedHostType = normalizeDeepLinkType(host);
        if (mappedHostType != null && segments.isNotEmpty) {
          final id = normalizeDeepLinkId(segments.first);
          if (id.isEmpty) return null;
          return _ParsedDeepLink(type: mappedHostType, id: id);
        }
      }
      if (segments.length >= 2) {
        final type = normalizeDeepLinkType(segments[0]);
        if (type != null) {
          final id = normalizeDeepLinkId(segments[1]);
          if (id.isEmpty) return null;
          return _ParsedDeepLink(type: type, id: id);
        }
      }
    }

    return null;
  }
}
