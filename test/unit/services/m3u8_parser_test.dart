import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/SegmentCache/m3u8_parser.dart';

void main() {
  test('M3U8Parser parses master playlist variants and best variant', () {
    const playlist = '''
#EXTM3U
#EXT-X-STREAM-INF:BANDWIDTH=800000,RESOLUTION=640x360
low/index.m3u8
#EXT-X-STREAM-INF:BANDWIDTH=1400000,RESOLUTION=1280x720
mid/index.m3u8
#EXT-X-STREAM-INF:BANDWIDTH=2400000,RESOLUTION=1920x1080
high/index.m3u8
''';

    final variants = M3U8Parser.parseVariants(playlist);

    expect(M3U8Parser.isMasterPlaylist(playlist), isTrue);
    expect(variants, hasLength(3));
    expect(M3U8Parser.bestVariant(variants)?.uri, 'high/index.m3u8');
    expect(
      M3U8Parser.variantForResolution(variants, '1280x720')?.uri,
      'mid/index.m3u8',
    );
  });

  test('M3U8Parser parses media playlist segments and durations', () {
    const playlist = '''
#EXTM3U
#EXTINF:6.006,
segment-001.ts
#EXTINF:5.500,
segment-002.ts
#EXTINF:4.000,
segment-003.ts
''';

    final segments = M3U8Parser.parseSegments(playlist);

    expect(segments, hasLength(3));
    expect(segments.first.uri, 'segment-001.ts');
    expect(segments.first.duration, 6.006);
    expect(M3U8Parser.segmentUris(playlist), [
      'segment-001.ts',
      'segment-002.ts',
      'segment-003.ts',
    ]);
  });
}
