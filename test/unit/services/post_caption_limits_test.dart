import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/post_caption_limits.dart';

void main() {
  group('PostCaptionLimits', () {
    test('returns unbadged limit for empty badge values', () {
      expect(PostCaptionLimits.forRozet(''), PostCaptionLimits.unbadged);
      expect(PostCaptionLimits.forRozet('   '), PostCaptionLimits.unbadged);
      expect(
        PostCaptionLimits.forRozet('rozetsiz'),
        PostCaptionLimits.unbadged,
      );
    });

    test('returns badged limit for badge values', () {
      expect(PostCaptionLimits.forRozet('mavi'), PostCaptionLimits.badged);
      expect(PostCaptionLimits.forRozet('blue'), PostCaptionLimits.badged);
      expect(PostCaptionLimits.forRozet('yellow'), PostCaptionLimits.badged);
    });
  });
}
