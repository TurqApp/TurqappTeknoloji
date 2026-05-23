/// CDN URL dönüştürücü.
/// Firebase Storage URL'lerini cdn.turqapp.com üzerinden serve eder.
/// CNAME: cdn.turqapp.com → firebasestorage.googleapis.com (Cloudflare proxied)
class CdnUrlBuilder {
  static const String cdnDomain = 'cdn.turqapp.com';
  static const String storageBucket = 'turqappteknoloji.firebasestorage.app';
  static const Set<String> _legacyBuckets = <String>{
    'burs-city.appspot.com',
  };
  static const String _firebaseHost = 'firebasestorage.googleapis.com';

  static String _buildStorageUrl(String storagePath) {
    return 'https://$cdnDomain/$storagePath';
  }

  static String _decodeFirebaseObjectPath(String url) {
    try {
      final parsed = Uri.parse(url);
      final marker = '/o/';
      final path = parsed.path;
      final index = path.indexOf(marker);
      if (index >= 0) {
        return Uri.decodeComponent(path.substring(index + marker.length));
      }
    } catch (_) {}
    return '';
  }

  static String _remapLegacyBucket(String url) {
    var normalized = url;
    for (final legacyBucket in _legacyBuckets) {
      normalized = normalized.replaceFirst(
        '/v0/b/$legacyBucket/o/',
        '/v0/b/$storageBucket/o/',
      );
      normalized = normalized.replaceFirst(
        '$legacyBucket/v0/b/',
        '$storageBucket/v0/b/',
      );
    }
    return normalized;
  }

  /// Firebase Storage download URL'sini CDN URL'sine dönüştürür.
  /// Token parametresi korunur (auth gerektiğinde).
  static String toCdnUrl(String url) {
    if (url.isEmpty) return url;
    final bucketNormalized = _remapLegacyBucket(url.trim());
    if (bucketNormalized.contains(cdnDomain)) return bucketNormalized;

    final objectPath = _decodeFirebaseObjectPath(bucketNormalized);
    if (objectPath.startsWith('Posts/') || objectPath.startsWith('users/')) {
      return _buildStorageUrl(objectPath);
    }

    // Firebase Storage URL → CDN URL (host değiştir, path aynen kalsın)
    if (bucketNormalized.contains(_firebaseHost)) {
      return bucketNormalized.replaceFirst(_firebaseHost, cdnDomain);
    }

    // firebasestorage.app format (yeni SDK)
    // https://turqappteknoloji.firebasestorage.app/v0/b/...
    if (bucketNormalized.contains('$storageBucket/v0/b/')) {
      return bucketNormalized.replaceFirst(storageBucket, cdnDomain);
    }

    return bucketNormalized;
  }

  /// CDN URL'sini mümkünse Firebase origin URL'sine geri çevirir.
  /// Sadece v0/b tabanlı signed URL'lerde güvenlidir.
  static String toOriginUrl(String url) {
    if (url.isEmpty || !url.contains(cdnDomain)) return url;
    if (url.contains('/v0/b/')) {
      return url.replaceFirst(cdnDomain, storageBucket);
    }
    return url;
  }

  /// Post video HLS URL'si oluşturur.
  static String buildHlsUrl(String docID) =>
      _buildStorageUrl('Posts/$docID/hls/master.m3u8');

  /// Post video mp4 URL'si oluşturur.
  static String buildVideoUrl(String docID) =>
      _buildStorageUrl('Posts/$docID/video.mp4');

  /// Post thumbnail URL'si oluşturur.
  static String buildThumbnailUrl(String docID) =>
      _buildStorageUrl('Posts/$docID/thumbnail.webp');

  /// Storage/CDN video URL'sinden post klasörünü çıkarıp thumbnail adaylarını üretir.
  static List<String> buildThumbnailUrlCandidatesFromMediaUrl(String mediaUrl) {
    final normalized = toCdnUrl(mediaUrl.trim());
    if (normalized.isEmpty) return const <String>[];
    try {
      final parsed = Uri.parse(normalized);
      final segments = parsed.pathSegments;
      final postsIndex = segments.indexOf('Posts');
      if (postsIndex < 0 || postsIndex + 1 >= segments.length) {
        return const <String>[];
      }
      final postId = segments[postsIndex + 1].trim();
      if (postId.isEmpty) return const <String>[];
      return buildThumbnailUrlCandidates(postId);
    } catch (_) {
      return const <String>[];
    }
  }

  /// Post thumbnail adayları. Storage standardı `thumbnail.webp`.
  static List<String> buildThumbnailUrlCandidates(String docID) => <String>[
        _buildStorageUrl('Posts/$docID/thumbnail.webp'),
      ];

  /// Genel storage path'i CDN URL'sine çevirir.
  static String buildFromPath(String storagePath) =>
      _buildStorageUrl(storagePath);
}
