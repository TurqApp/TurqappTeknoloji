import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/video_state_manager.dart';

void main() {
  test('external on-demand fetch claims authorize active story docs', () {
    final manager = VideoStateManager();

    expect(manager.allowsOnDemandSegmentFetchFor('story-a'), isFalse);

    manager.claimExternalOnDemandFetch('story-a');
    expect(manager.allowsOnDemandSegmentFetchFor('story-a'), isTrue);

    manager.claimExternalOnDemandFetch('story-a');
    manager.releaseExternalOnDemandFetch('story-a');
    expect(manager.allowsOnDemandSegmentFetchFor('story-a'), isTrue);

    manager.releaseExternalOnDemandFetch('story-a');
    expect(manager.allowsOnDemandSegmentFetchFor('story-a'), isFalse);
  });
}
