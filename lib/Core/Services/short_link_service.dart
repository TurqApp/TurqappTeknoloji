import 'package:cloud_functions/cloud_functions.dart';

class ShortLinkService {
  static const String _defaultDomain = 'turqapp.com';
  static final Map<String, String> _postUrlCache = <String, String>{};
  static final Map<String, String> _storyUrlCache = <String, String>{};
  static final Map<String, String> _eduUrlCache = <String, String>{};
  static final Map<String, String> _jobUrlCache = <String, String>{};
  static final Map<String, String> _internalEduUrlCache = <String, String>{};

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

  Future<String> getPostPublicUrl({
    required String postId,
    String? title,
    String? desc,
    String? imageUrl,
  }) async {
    final cached = _postUrlCache[postId];
    if (cached != null && cached.isNotEmpty) return cached;

    final result = await upsertPost(
      postId: postId,
      title: title,
      desc: desc,
      imageUrl: imageUrl,
    );
    final url = _extractUrl(result, fallbackPath: '/p/');
    if (url.isNotEmpty) _postUrlCache[postId] = url;
    return url;
  }

  Future<String> getStoryPublicUrl({
    required String storyId,
    String? title,
    String? desc,
    String? imageUrl,
    int? expiresAt,
  }) async {
    final cached = _storyUrlCache[storyId];
    if (cached != null && cached.isNotEmpty) return cached;

    final result = await upsertStory(
      storyId: storyId,
      title: title,
      desc: desc,
      imageUrl: imageUrl,
      expiresAt: expiresAt,
    );
    final url = _extractUrl(result, fallbackPath: '/s/');
    if (url.isNotEmpty) _storyUrlCache[storyId] = url;
    return url;
  }

  Future<String> getEducationPublicUrl({
    required String shareId,
    String? title,
    String? desc,
    String? imageUrl,
  }) async {
    final cached = _eduUrlCache[shareId];
    if (cached != null && cached.isNotEmpty) return cached;

    final result = await upsertEducation(
      shareId: shareId,
      title: title,
      desc: desc,
      imageUrl: imageUrl,
    );
    final url = _extractUrl(result, fallbackPath: '/e/');
    if (url.isNotEmpty) _eduUrlCache[shareId] = url;
    return url;
  }

  Future<String> getJobPublicUrl({
    required String jobId,
    String? title,
    String? desc,
    String? imageUrl,
  }) async {
    final cached = _jobUrlCache[jobId];
    if (cached != null && cached.isNotEmpty) return cached;

    final result = await upsertEducation(
      shareId: 'job:$jobId',
      title: title,
      desc: desc,
      imageUrl: imageUrl,
    );
    final url = _extractUrl(result, fallbackPath: '/i/');
    if (url.isNotEmpty) _jobUrlCache[jobId] = url;
    return url;
  }

  Future<String> getInternalEducationPublicUrl({
    required String shareId,
    String? title,
    String? desc,
    String? imageUrl,
  }) async {
    final cached = _internalEduUrlCache[shareId];
    if (cached != null && cached.isNotEmpty) return cached;

    final result = await upsertEducation(
      shareId: shareId,
      title: title,
      desc: desc,
      imageUrl: imageUrl,
    );
    final url = _extractUrl(result, fallbackPath: '/i/');
    if (url.isNotEmpty) _internalEduUrlCache[shareId] = url;
    return url;
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
    final targets = <FirebaseFunctions>[
      FirebaseFunctions.instance,
      FirebaseFunctions.instanceFor(region: 'us-central1'),
      FirebaseFunctions.instanceFor(region: 'europe-west1'),
    ];

    Object? lastError;
    for (final fn in targets) {
      try {
        final result = await fn.httpsCallable(callableName).call(payload);
        return result.data;
      } catch (e) {
        lastError = e;
      }
    }
    throw lastError ?? Exception('short_link_callable_failed');
  }

  String _extractUrl(
    Map<String, dynamic> response, {
    required String fallbackPath,
  }) {
    final url = (response['url'] ?? '').toString().trim();
    if (url.isNotEmpty) return url;
    final id = (response['id'] ?? '').toString().trim();
    if (id.isEmpty) return 'https://$_defaultDomain';
    return 'https://$_defaultDomain$fallbackPath$id';
  }
}
