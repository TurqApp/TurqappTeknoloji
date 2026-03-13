import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Utils/cdn_url_builder.dart';

void main() {
  test('CdnUrlBuilder keeps CDN URLs and rewrites Firebase hosts', () {
    const firebaseUrl =
        'https://firebasestorage.googleapis.com/v0/b/turqappteknoloji.firebasestorage.app/o/Posts%2Fabc%2Fthumbnail.webp?alt=media&token=token123';
    const appBucketUrl =
        'https://turqappteknoloji.firebasestorage.app/v0/b/turqappteknoloji.firebasestorage.app/o/Posts%2Fabc%2Fthumbnail.webp?alt=media';
    const cdnUrl =
        'https://cdn.turqapp.com/v0/b/turqappteknoloji.firebasestorage.app/o/Posts%2Fabc%2Fthumbnail.webp?alt=media';

    expect(
      CdnUrlBuilder.toCdnUrl(firebaseUrl),
      contains('https://cdn.turqapp.com/'),
    );
    expect(
      CdnUrlBuilder.toCdnUrl(appBucketUrl),
      contains('https://cdn.turqapp.com/'),
    );
    expect(CdnUrlBuilder.toCdnUrl(cdnUrl), cdnUrl);
  });

  test('CdnUrlBuilder builds canonical storage asset paths', () {
    expect(
      CdnUrlBuilder.buildHlsUrl('post123'),
      'https://cdn.turqapp.com/Posts/post123/hls/master.m3u8',
    );
    expect(
      CdnUrlBuilder.buildVideoUrl('post123'),
      'https://cdn.turqapp.com/Posts/post123/video.mp4',
    );
    expect(
      CdnUrlBuilder.buildThumbnailUrl('post123'),
      'https://cdn.turqapp.com/Posts/post123/thumbnail.webp',
    );
    expect(
      CdnUrlBuilder.buildFromPath('stories/story123/hls/master.m3u8'),
      'https://cdn.turqapp.com/stories/story123/hls/master.m3u8',
    );
  });
}
