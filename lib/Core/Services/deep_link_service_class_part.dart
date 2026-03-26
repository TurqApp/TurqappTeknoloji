part of 'deep_link_service.dart';

class DeepLinkService extends GetxService {
  static DeepLinkService ensure() => _ensureDeepLinkService();

  static DeepLinkService? maybeFind() => _maybeFindDeepLinkService();
  static const Duration _lookupTtl = Duration(seconds: 30);
  static final Map<String, _PostLookupCache> _postLookupCache =
      <String, _PostLookupCache>{};
  static final Map<String, _JobLookupCache> _jobLookupCache =
      <String, _JobLookupCache>{};
  static final Map<String, _MarketLookupCache> _marketLookupCache =
      <String, _MarketLookupCache>{};
  static final Map<String, _UserLookupCache> _userLookupCache =
      <String, _UserLookupCache>{};
  static final Map<String, _StoryListLookupCache> _storyListLookupCache =
      <String, _StoryListLookupCache>{};
  static final Map<String, _StoryDocLookupCache> _storyDocLookupCache =
      <String, _StoryDocLookupCache>{};
  static const Duration _staleRetention = Duration(minutes: 3);
  static const int _maxLookupEntries = 400;
  final _state = _DeepLinkServiceState();

  @override
  void onClose() {
    _handleDeepLinkServiceClose(this);
    super.onClose();
  }
}
