import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Modules/Agenda/widgets/feed_create_fab.dart';
import 'package:turqappv2/Modules/Agenda/widgets/feed_inbox_actions_row.dart';

import '../../helpers/pump_app.dart';

class _FeedHeaderActionsHarness extends StatefulWidget {
  const _FeedHeaderActionsHarness();

  @override
  State<_FeedHeaderActionsHarness> createState() =>
      _FeedHeaderActionsHarnessState();
}

class _FeedHeaderActionsHarnessState extends State<_FeedHeaderActionsHarness> {
  int _createTaps = 0;
  int _chatTaps = 0;
  int _notificationTaps = 0;
  bool _showChatBadge = true;
  bool _showNotificationBadge = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FeedInboxActionsRow(
            actionSize: 36,
            spacing: 8,
            showChatBadge: _showChatBadge,
            showNotificationBadge: _showNotificationBadge,
            onChatTap: () {
              setState(() {
                _chatTaps += 1;
                _showChatBadge = false;
              });
            },
            onNotificationsTap: () {
              setState(() {
                _notificationTaps += 1;
                _showNotificationBadge = false;
              });
            },
          ),
          const SizedBox(height: 24),
          FeedCreateFab(
            onTap: () {
              setState(() {
                _createTaps += 1;
              });
            },
          ),
          Text('create=$_createTaps'),
          Text('chat=$_chatTaps'),
          Text('notifications=$_notificationTaps'),
        ],
      ),
    );
  }
}

void main() {
  testWidgets('renders critical feed action keys from production widgets', (
    tester,
  ) async {
    await pumpApp(tester, const _FeedHeaderActionsHarness());

    expect(
      find.byKey(const ValueKey(IntegrationTestKeys.actionFeedCreate)),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey(IntegrationTestKeys.navChat)),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey(IntegrationTestKeys.actionOpenNotifications),
      ),
      findsOneWidget,
    );
  });

  testWidgets('tapping production actions triggers expected callbacks', (
    tester,
  ) async {
    await pumpApp(tester, const _FeedHeaderActionsHarness());

    await tester.tap(
      find.byKey(const ValueKey(IntegrationTestKeys.actionFeedCreate)),
    );
    await tester.tap(find.byKey(const ValueKey(IntegrationTestKeys.navChat)));
    await tester.tap(
      find.byKey(
        const ValueKey(IntegrationTestKeys.actionOpenNotifications),
      ),
    );
    await tester.pump();

    expect(find.text('create=1'), findsOneWidget);
    expect(find.text('chat=1'), findsOneWidget);
    expect(find.text('notifications=1'), findsOneWidget);
  });

  testWidgets('badges clear after inbox actions are tapped', (tester) async {
    await pumpApp(tester, const _FeedHeaderActionsHarness());

    expect(find.byKey(const ValueKey('feed-chat-badge')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('feed-notifications-badge')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey(IntegrationTestKeys.navChat)));
    await tester.tap(
      find.byKey(
        const ValueKey(IntegrationTestKeys.actionOpenNotifications),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('feed-chat-badge')), findsNothing);
    expect(
      find.byKey(const ValueKey('feed-notifications-badge')),
      findsNothing,
    );
  });
}
