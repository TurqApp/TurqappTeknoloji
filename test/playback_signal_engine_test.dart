import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/playback_signal_engine.dart';

void main() {
  test('mid-progress playback has high resume probability', () {
    final signal = PlaybackSignalEngine.fromWatchProgress(0.45);

    expect(signal.resumeProbability, greaterThan(0.8));
    expect(signal.likelyConsumed, isFalse);
    expect(signal.likelyUnstarted, isFalse);
  });

  test('near-complete playback is treated as likely consumed', () {
    final signal = PlaybackSignalEngine.fromWatchProgress(0.95);

    expect(signal.likelyConsumed, isTrue);
    expect(signal.resumeProbability, lessThan(0.3));
  });
}
