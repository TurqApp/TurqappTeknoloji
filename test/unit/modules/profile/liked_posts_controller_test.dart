import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Modules/Profile/LikedPosts/liked_posts_controller.dart';

void main() {
  test('liked posts controller classifies series by flood count', () {
    final normalPost = PostsModel.empty().copyWith(
      docID: 'post-1',
      img: const ['https://example.com/photo.jpg'],
      floodCount: 1,
    );
    final seriesPost = PostsModel.empty().copyWith(
      docID: 'post-2',
      thumbnail: 'https://example.com/thumb.jpg',
      video: 'https://example.com/video.mp4',
      floodCount: 3,
    );

    expect(LikedPostControllers.isSeriesPost(normalPost), isFalse);
    expect(LikedPostControllers.isSeriesPost(seriesPost), isTrue);
  });
}
