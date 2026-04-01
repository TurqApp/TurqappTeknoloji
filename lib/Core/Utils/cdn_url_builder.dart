/// CDN URL dönüştürücü.
/// Firebase Storage URL'lerini cdn.turqapp.com üzerinden serve eder.
/// CNAME: cdn.turqapp.com → firebasestorage.googleapis.com (Cloudflare proxied)
class CdnUrlBuilder {
  static const String cdnDomain = 'cdn.turqapp.com';
  static const String storageBucket = 'turqappteknoloji.firebasestorage.app';
  static const String _firebaseHost = 'firebasestorage.googleapis.com';

  /// Firebase Storage download URL'sini CDN URL'sine dönüştürür.
  /// Token parametresi korunur (auth gerektiğinde).
  static String toCdnUrl(String url) {
    if (url.isEmpty) return url;
    if (url.contains(cdnDomain)) return url;

    // Firebase Storage URL → CDN URL (host değiştir, path aynen kalsın)
    if (url.contains(_firebaseHost)) {
      return url.replaceFirst(_firebaseHost, cdnDomain);
    }

    // firebasestorage.app format (yeni SDK)
    // https://turqappteknoloji.firebasestorage.app/v0/b/...
    if (url.contains('$storageBucket/v0/b/')) {
      return url.replaceFirst(storageBucket, cdnDomain);
    }

    return url;
  }

  /// Storage path'ten temiz CDN URL oluşturur.
  /// Worker otomatik olarak Firebase Storage formatına dönüştürür.
  static String _buildStorageUrl(String storagePath) {
    return 'https://$cdnDomain/$storagePath';
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

  /// Post thumbnail için olası dosya uzantılarını döndürür.
  static List<String> buildThumbnailUrlCandidates(String docID) => <String>[
        _buildStorageUrl('Posts/$docID/thumbnail.webp'),
        _buildStorageUrl('Posts/$docID/thumbnail.jpg'),
        _buildStorageUrl('Posts/$docID/thumbnail.jpeg'),
        _buildStorageUrl('Posts/$docID/thumbnail.png'),
      ];

  /// Genel storage path'i CDN URL'sine çevirir.
  static String buildFromPath(String storagePath) =>
      _buildStorageUrl(storagePath);
}
