import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/integration_test_fixture_contract.dart';

void main() {
  test('fixture contract returns empty when raw string is invalid', () {
    final contract = IntegrationTestFixtureContract.fromRaw('{');
    expect(contract.isConfigured, isFalse);
    expect(contract.surface('feed'), isNull);
  });

  test('fixture contract parses surface minimums and doc ids', () {
    final contract = IntegrationTestFixtureContract.fromRaw('''
{
  "feed": {
    "minCount": 3,
    "docIds": ["a", "b"]
  },
  "notifications": {
    "maxUnread": 10
  }
}
''');

    final feed = contract.surface('feed');
    expect(feed, isNotNull);
    expect(feed!.minCount, 3);
    expect(feed.requiredDocIds, <String>['a', 'b']);

    final notifications = contract.surface('notifications');
    expect(notifications, isNotNull);
    expect(notifications!.maxUnread, 10);
  });
}
