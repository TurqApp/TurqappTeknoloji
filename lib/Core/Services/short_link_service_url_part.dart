part of 'short_link_service.dart';

extension ShortLinkServiceUrlPart on ShortLinkService {
  String getPostDirectUrl(String postId) {
    final normalized = postId.trim();
    if (normalized.isEmpty) {
      return 'https://${ShortLinkService._defaultDomain}';
    }
    return 'https://${ShortLinkService._defaultDomain}/p/$normalized';
  }

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

  String getPostPublicUrlForImmediateShare({
    required String postId,
    String? title,
    String? desc,
    String? imageUrl,
    String? shortId,
  }) {
    final normalized = postId.trim();
    if (normalized.isEmpty) {
      return 'https://${ShortLinkService._defaultDomain}';
    }

    final cached = ShortLinkService._postUrlCache[normalized];
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    final warmupKey = '$normalized|${shortId?.trim() ?? ''}';
    if (!ShortLinkService._postUrlWarmupInFlight.contains(warmupKey)) {
      ShortLinkService._postUrlWarmupInFlight.add(warmupKey);
      unawaited(() async {
        try {
          await getPostPublicUrl(
            postId: normalized,
            title: title,
            desc: desc,
            imageUrl: imageUrl,
            shortId: shortId,
          );
        } finally {
          ShortLinkService._postUrlWarmupInFlight.remove(warmupKey);
        }
      }());
    }

    return getPostDirectUrl(normalized);
  }

  String getStoryDirectUrl(String storyId) {
    final normalized = storyId.trim();
    if (normalized.isEmpty) {
      return 'https://${ShortLinkService._defaultDomain}';
    }
    return 'https://${ShortLinkService._defaultDomain}/s/$normalized';
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

  String getStoryPublicUrlForImmediateShare({
    required String storyId,
    String? title,
    String? desc,
    String? imageUrl,
    int? expiresAt,
  }) {
    final normalized = storyId.trim();
    if (normalized.isEmpty) {
      return 'https://${ShortLinkService._defaultDomain}';
    }

    final cached = ShortLinkService._storyUrlCache[normalized];
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    if (!ShortLinkService._storyUrlWarmupInFlight.contains(normalized)) {
      ShortLinkService._storyUrlWarmupInFlight.add(normalized);
      unawaited(() async {
        try {
          await getStoryPublicUrl(
            storyId: normalized,
            title: title,
            desc: desc,
            imageUrl: imageUrl,
            expiresAt: expiresAt,
          );
        } finally {
          ShortLinkService._storyUrlWarmupInFlight.remove(normalized);
        }
      }());
    }

    return getStoryDirectUrl(normalized);
  }

  String getEducationDirectUrl(String shareId) {
    final normalized = shareId.trim();
    if (normalized.isEmpty) {
      return 'https://${ShortLinkService._defaultDomain}';
    }
    return 'https://${ShortLinkService._defaultDomain}/e/$normalized';
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

  String getEducationPublicUrlForImmediateShare({
    required String shareId,
    String? title,
    String? desc,
    String? imageUrl,
    String? shortId,
  }) {
    final normalized = shareId.trim();
    if (normalized.isEmpty) {
      return 'https://${ShortLinkService._defaultDomain}';
    }

    final cached = ShortLinkService._eduUrlCache[normalized];
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    final warmupKey = '$normalized|${shortId?.trim() ?? ''}';
    if (!ShortLinkService._eduUrlWarmupInFlight.contains(warmupKey)) {
      ShortLinkService._eduUrlWarmupInFlight.add(warmupKey);
      unawaited(() async {
        try {
          await getEducationPublicUrl(
            shareId: normalized,
            title: title,
            desc: desc,
            imageUrl: imageUrl,
            shortId: shortId,
          );
        } finally {
          ShortLinkService._eduUrlWarmupInFlight.remove(warmupKey);
        }
      }());
    }

    return getEducationDirectUrl(normalized);
  }

  String getJobDirectUrl(String jobId) {
    final normalized = jobId.trim();
    if (normalized.isEmpty) {
      return 'https://${ShortLinkService._defaultDomain}';
    }
    return 'https://${ShortLinkService._defaultDomain}/i/job:$normalized';
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

  String getJobPublicUrlForImmediateShare({
    required String jobId,
    String? title,
    String? desc,
    String? imageUrl,
  }) {
    final normalized = jobId.trim();
    if (normalized.isEmpty) {
      return 'https://${ShortLinkService._defaultDomain}';
    }

    final cached = ShortLinkService._jobUrlCache[normalized];
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    if (!ShortLinkService._jobUrlWarmupInFlight.contains(normalized)) {
      ShortLinkService._jobUrlWarmupInFlight.add(normalized);
      unawaited(() async {
        try {
          await getJobPublicUrl(
            jobId: normalized,
            title: title,
            desc: desc,
            imageUrl: imageUrl,
          );
        } finally {
          ShortLinkService._jobUrlWarmupInFlight.remove(normalized);
        }
      }());
    }

    return getJobDirectUrl(normalized);
  }

  String getMarketDirectUrl(String itemId) {
    final normalized = itemId.trim();
    if (normalized.isEmpty) {
      return 'https://${ShortLinkService._defaultDomain}';
    }
    return 'https://${ShortLinkService._defaultDomain}/m/$normalized';
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

  String getMarketPublicUrlForImmediateShare({
    required String itemId,
    String? title,
    String? desc,
    String? imageUrl,
    String? shortId,
  }) {
    final normalized = itemId.trim();
    if (normalized.isEmpty) {
      return 'https://${ShortLinkService._defaultDomain}';
    }

    final cached = ShortLinkService._marketUrlCache[normalized];
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    final warmupKey = '$normalized|${shortId?.trim() ?? ''}';
    if (!ShortLinkService._marketUrlWarmupInFlight.contains(warmupKey)) {
      ShortLinkService._marketUrlWarmupInFlight.add(warmupKey);
      unawaited(() async {
        try {
          await getMarketPublicUrl(
            itemId: normalized,
            title: title,
            desc: desc,
            imageUrl: imageUrl,
            shortId: shortId,
          );
        } finally {
          ShortLinkService._marketUrlWarmupInFlight.remove(warmupKey);
        }
      }());
    }

    return getMarketDirectUrl(normalized);
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
