part of 'short_link_service.dart';

extension ShortLinkServiceUpsertPart on ShortLinkService {
  Future<Map<String, dynamic>> upsertPost({
    required String postId,
    String? title,
    String? desc,
    String? imageUrl,
    String? shortId,
  }) async {
    return _upsert(
      type: 'post',
      entityId: postId,
      title: title,
      desc: desc,
      imageUrl: imageUrl,
      shortId: shortId,
    );
  }

  Future<Map<String, dynamic>> upsertStory({
    required String storyId,
    String? title,
    String? desc,
    String? imageUrl,
    int? expiresAt,
    String? shortId,
  }) async {
    return _upsert(
      type: 'story',
      entityId: storyId,
      title: title,
      desc: desc,
      imageUrl: imageUrl,
      expiresAt: expiresAt,
      shortId: shortId,
    );
  }

  Future<Map<String, dynamic>> upsertUser({
    required String userId,
    required String slug,
    String? title,
    String? desc,
    String? imageUrl,
  }) async {
    return _upsert(
      type: 'user',
      entityId: userId,
      slug: slug,
      title: title,
      desc: desc,
      imageUrl: imageUrl,
    );
  }

  Future<Map<String, dynamic>> upsertEducation({
    required String shareId,
    String? title,
    String? desc,
    String? imageUrl,
    String? shortId,
  }) async {
    return _upsert(
      type: 'edu',
      entityId: shareId,
      title: title,
      desc: desc,
      imageUrl: imageUrl,
      shortId: shortId,
    );
  }

  Future<Map<String, dynamic>> upsertJob({
    required String jobId,
    String? title,
    String? desc,
    String? imageUrl,
    String? shortId,
  }) async {
    return _upsert(
      type: 'job',
      entityId: 'job:$jobId',
      title: title,
      desc: desc,
      imageUrl: imageUrl,
      shortId: shortId,
    );
  }

  Future<Map<String, dynamic>> upsertMarket({
    required String itemId,
    String? title,
    String? desc,
    String? imageUrl,
    String? shortId,
  }) async {
    return _upsert(
      type: 'market',
      entityId: itemId,
      title: title,
      desc: desc,
      imageUrl: imageUrl,
      shortId: shortId,
    );
  }

  Future<Map<String, dynamic>> resolve({
    required String type,
    required String id,
  }) async {
    final data = await _callCallable(
      'resolveShortLink',
      {
        'type': type,
        'id': id,
      },
    );
    return Map<String, dynamic>.from(data);
  }

  Future<Map<String, dynamic>> _upsert({
    required String type,
    required String entityId,
    String? shortId,
    String? slug,
    String? title,
    String? desc,
    String? imageUrl,
    int? expiresAt,
  }) async {
    final payload = <String, dynamic>{
      'type': type,
      'entityId': entityId,
      if (shortId != null && shortId.trim().isNotEmpty) 'shortId': shortId,
      if (slug != null && slug.trim().isNotEmpty) 'slug': slug,
      if (title != null && title.trim().isNotEmpty) 'title': title.trim(),
      if (desc != null && desc.trim().isNotEmpty) 'desc': desc.trim(),
      if (imageUrl != null && imageUrl.trim().isNotEmpty)
        'imageUrl': imageUrl.trim(),
      if (expiresAt != null && expiresAt > 0) 'expiresAt': expiresAt,
    };

    final data = await _callCallable('upsertShortLink', payload);
    return Map<String, dynamic>.from(data);
  }

  Future<dynamic> _callCallable(
    String callableName,
    Map<String, dynamic> payload,
  ) async {
    Object? lastError;
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final fn = FirebaseFunctions.instanceFor(region: 'us-central1');
        final callable = fn.httpsCallable(
          callableName,
          options: HttpsCallableOptions(
            timeout: ShortLinkService._callTimeout,
          ),
        );
        final result = await callable.call(payload);
        return result.data;
      } catch (e) {
        lastError = e;
        if (attempt == 0) {
          await Future<void>.delayed(const Duration(milliseconds: 250));
          continue;
        }
      }
    }
    throw lastError ?? Exception('Callable failed');
  }
}
