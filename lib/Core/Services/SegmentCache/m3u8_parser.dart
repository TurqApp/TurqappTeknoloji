/// Basit M3U8 (HLS) playlist parser.
/// Master playlist'ten variant'ları, variant playlist'ten segment URI'lerini çıkarır.
/// Harici paket gerekmez — satır bazlı parse.
library;

class M3U8Variant {
  final String uri;
  final int bandwidth;
  final String? resolution;

  M3U8Variant({
    required this.uri,
    required this.bandwidth,
    this.resolution,
  });

  @override
  String toString() =>
      'M3U8Variant(uri: $uri, bandwidth: $bandwidth, resolution: $resolution)';
}

class M3U8Segment {
  final String uri;
  final double duration; // saniye

  M3U8Segment({required this.uri, required this.duration});

  @override
  String toString() => 'M3U8Segment(uri: $uri, duration: ${duration}s)';
}

class M3U8Parser {
  /// Master playlist metninden variant listesi çıkar.
  /// Eğer hiç #EXT-X-STREAM-INF yoksa boş liste döner (bu bir variant playlist'tir).
  static List<M3U8Variant> parseVariants(String content) {
    final lines = content.split('\n');
    final variants = <M3U8Variant>[];

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (!line.startsWith('#EXT-X-STREAM-INF:')) continue;

      // Attributes parse
      final attrs = line.substring('#EXT-X-STREAM-INF:'.length);
      final bandwidth = _extractInt(attrs, 'BANDWIDTH') ?? 0;
      final resolution = _extractString(attrs, 'RESOLUTION');

      // Sonraki satır URI
      if (i + 1 < lines.length) {
        final uri = lines[i + 1].trim();
        if (uri.isNotEmpty && !uri.startsWith('#')) {
          variants.add(M3U8Variant(
            uri: uri,
            bandwidth: bandwidth,
            resolution: resolution,
          ));
        }
      }
    }

    return variants;
  }

  /// İçeriğin master playlist mi yoksa media playlist mi olduğunu belirle.
  static bool isMasterPlaylist(String content) {
    return content.contains('#EXT-X-STREAM-INF:');
  }

  /// Variant (media) playlist metninden segment listesi çıkar.
  static List<M3U8Segment> parseSegments(String content) {
    final lines = content.split('\n');
    final segments = <M3U8Segment>[];

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (!line.startsWith('#EXTINF:')) continue;

      // Duration parse: #EXTINF:6.006,
      final durationStr =
          line.substring('#EXTINF:'.length).split(',').first.trim();
      final duration = double.tryParse(durationStr) ?? 0.0;

      // Sonraki satır URI
      if (i + 1 < lines.length) {
        final uri = lines[i + 1].trim();
        if (uri.isNotEmpty && !uri.startsWith('#')) {
          segments.add(M3U8Segment(uri: uri, duration: duration));
        }
      }
    }

    return segments;
  }

  /// Tüm segment URI'lerini düz liste olarak döndür (hızlı cache key listesi).
  static List<String> segmentUris(String content) {
    return parseSegments(content).map((s) => s.uri).toList();
  }

  /// En yüksek bandwidth'li variant'ı seç.
  static M3U8Variant? bestVariant(List<M3U8Variant> variants) {
    if (variants.isEmpty) return null;
    return variants.reduce((a, b) => a.bandwidth >= b.bandwidth ? a : b);
  }

  /// Verilen resolution'a en yakın variant'ı seç (ör. "1280x720").
  static M3U8Variant? variantForResolution(
      List<M3U8Variant> variants, String targetResolution) {
    if (variants.isEmpty) return null;
    for (final v in variants) {
      if (v.resolution == targetResolution) return v;
    }
    // Bulunamazsa en yüksek bandwidth
    return bestVariant(variants);
  }

  // --- Helpers ---

  static int? _extractInt(String attrs, String key) {
    final regex = RegExp('$key=(\\d+)');
    final match = regex.firstMatch(attrs);
    if (match != null) return int.tryParse(match.group(1)!);
    return null;
  }

  static String? _extractString(String attrs, String key) {
    // Tırnaklı value: KEY="value" veya tırnaksız: KEY=value
    final regexQuoted = RegExp('$key="([^"]*)"');
    final matchQuoted = regexQuoted.firstMatch(attrs);
    if (matchQuoted != null) return matchQuoted.group(1);

    final regexUnquoted = RegExp('$key=([^,\\s]+)');
    final matchUnquoted = regexUnquoted.firstMatch(attrs);
    if (matchUnquoted != null) return matchUnquoted.group(1);

    return null;
  }
}
