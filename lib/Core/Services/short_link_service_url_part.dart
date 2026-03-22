part of 'short_link_service.dart';

extension ShortLinkServiceUrlPart on ShortLinkService {
  Future<String> getPostPublicUrl({
    required String postId,
    String? title,
    String? desc,
    String? imageUrl,
    bool forceRefresh = false,
    String? shortId,
  }) async {
    final cached = ShortLinkService._postUrlCache[postId];
    if (!forceRefresh && cached != null && cached.isNotEmpty) return cached;

    final url = await _safeUpsertUrl(
      fallbackPath: '/p/',
      request: () => upsertPost(
        postId: postId,
        title: title,
        desc: desc,
        imageUrl: imageUrl,
        shortId: shortId,
      ),
    );
    if (url.isNotEmpty) ShortLinkService._postUrlCache[postId] = url;
    return url;
  }

  Future<String> getStoryPublicUrl({
    required String storyId,
    String? title,
    String? desc,
    String? imageUrl,
    int? expiresAt,
  }) async {
    final cached = ShortLinkService._storyUrlCache[storyId];
    if (cached != null && cached.isNotEmpty) return cached;

    final url = await _safeUpsertUrl(
      fallbackPath: '/s/',
      request: () => upsertStory(
        storyId: storyId,
        title: title,
        desc: desc,
        imageUrl: imageUrl,
        expiresAt: expiresAt,
      ),
    );
    if (url.isNotEmpty) ShortLinkService._storyUrlCache[storyId] = url;
    return url;
  }

  Future<String> getEducationPublicUrl({
    required String shareId,
    String? title,
    String? desc,
    String? imageUrl,
    bool forceRefresh = false,
    String? shortId,
  }) async {
    final cached = ShortLinkService._eduUrlCache[shareId];
    if (!forceRefresh && cached != null && cached.isNotEmpty) return cached;

    final url = await _safeUpsertUrl(
      fallbackPath: '/e/',
      request: () => upsertEducation(
        shareId: shareId,
        title: title,
        desc: desc,
        imageUrl: imageUrl,
        shortId: shortId,
      ),
    );
    if (url.isNotEmpty) ShortLinkService._eduUrlCache[shareId] = url;
    return url;
  }

  Future<String> getJobPublicUrl({
    required String jobId,
    String? title,
    String? desc,
    String? imageUrl,
  }) async {
    final cached = ShortLinkService._jobUrlCache[jobId];
    if (cached != null && cached.isNotEmpty) return cached;

    final url = await _safeUpsertUrl(
      fallbackPath: '/i/',
      request: () => upsertJob(
        jobId: jobId,
        title: title,
        desc: desc,
        imageUrl: imageUrl,
      ),
    );
    if (url.isNotEmpty) ShortLinkService._jobUrlCache[jobId] = url;
    return url;
  }

  Future<String> getMarketPublicUrl({
    required String itemId,
    String? title,
    String? desc,
    String? imageUrl,
    bool forceRefresh = false,
    String? shortId,
  }) async {
    final cached = ShortLinkService._marketUrlCache[itemId];
    if (!forceRefresh && cached != null && cached.isNotEmpty) return cached;

    final url = await _safeUpsertUrl(
      fallbackPath: '/m/',
      request: () => upsertMarket(
        itemId: itemId,
        title: title,
        desc: desc,
        imageUrl: imageUrl,
        shortId: shortId,
      ),
    );
    if (url.isNotEmpty) ShortLinkService._marketUrlCache[itemId] = url;
    return url;
  }

  Future<String> getInternalEducationPublicUrl({
    required String shareId,
    String? title,
    String? desc,
    String? imageUrl,
  }) async {
    final cached = ShortLinkService._internalEduUrlCache[shareId];
    if (cached != null && cached.isNotEmpty) return cached;

    final url = await _safeUpsertUrl(
      fallbackPath: '/i/',
      request: () => upsertEducation(
        shareId: shareId,
        title: title,
        desc: desc,
        imageUrl: imageUrl,
      ),
    );
    if (url.isNotEmpty) ShortLinkService._internalEduUrlCache[shareId] = url;
    return url;
  }

  String _extractUrl(
    Map<String, dynamic> response, {
    required String fallbackPath,
  }) {
    final url = (response['url'] ?? '').toString().trim();
    if (url.isNotEmpty) return url;
    final id = (response['id'] ?? '').toString().trim();
    if (id.isEmpty) return 'https://${ShortLinkService._defaultDomain}';
    return 'https://${ShortLinkService._defaultDomain}$fallbackPath$id';
  }

  Future<String> _safeUpsertUrl({
    required String fallbackPath,
    required Future<Map<String, dynamic>> Function() request,
  }) async {
    try {
      final result = await request();
      return _extractUrl(result, fallbackPath: fallbackPath);
    } catch (_) {
      return 'https://${ShortLinkService._defaultDomain}';
    }
  }
}
