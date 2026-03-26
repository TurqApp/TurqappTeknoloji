part of 'deep_link_service.dart';

const Duration _deepLinkLookupTtl = Duration(seconds: 30);
final Map<String, _PostLookupCache> _deepLinkPostLookupCache =
    <String, _PostLookupCache>{};
final Map<String, _JobLookupCache> _deepLinkJobLookupCache =
    <String, _JobLookupCache>{};
final Map<String, _MarketLookupCache> _deepLinkMarketLookupCache =
    <String, _MarketLookupCache>{};
final Map<String, _UserLookupCache> _deepLinkUserLookupCache =
    <String, _UserLookupCache>{};
final Map<String, _StoryListLookupCache> _deepLinkStoryListLookupCache =
    <String, _StoryListLookupCache>{};
final Map<String, _StoryDocLookupCache> _deepLinkStoryDocLookupCache =
    <String, _StoryDocLookupCache>{};
const Duration _deepLinkStaleRetention = Duration(minutes: 3);
const int _deepLinkMaxLookupEntries = 400;
