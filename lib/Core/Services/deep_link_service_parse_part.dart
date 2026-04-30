part of 'deep_link_service.dart';

extension DeepLinkServiceParsePart on DeepLinkService {
  Future<bool> _performTryDirectFallback(ParsedDeepLinkRoute parsed) async {
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

  ParsedDeepLinkRoute? _performParse(Uri uri) => parseDeepLinkUri(uri);
}
