import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Core/Widgets/app_header_action_button.dart';

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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppHeaderActionButton(
                key: const ValueKey(IntegrationTestKeys.actionFeedCreate),
                onTap: () {
                  setState(() {
                    _createTaps += 1;
                  });
                },
                child: const Icon(CupertinoIcons.add),
              ),
              AppHeaderActionButton(
                key: const ValueKey(IntegrationTestKeys.navChat),
                showBadge: _showChatBadge,
                onTap: () {
                  setState(() {
                    _chatTaps += 1;
                    _showChatBadge = false;
                  });
                },
                child: const Icon(CupertinoIcons.mail),
              ),
              AppHeaderActionButton(
                key: const ValueKey(
                  IntegrationTestKeys.actionOpenNotifications,
                ),
                showBadge: _showNotificationBadge,
                onTap: () {
                  setState(() {
                    _notificationTaps += 1;
                    _showNotificationBadge = false;
                  });
                },
                child: const Icon(CupertinoIcons.bell),
              ),
            ],
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
  testWidgets('renders critical feed header action keys', (tester) async {
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

  testWidgets('tapping header actions triggers expected callbacks', (
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

  testWidgets('badges clear after chat and notification actions are tapped', (
    tester,
  ) async {
    await pumpApp(tester, const _FeedHeaderActionsHarness());

    expect(find.byType(Container), findsAtLeastNWidgets(2));

    await tester.tap(find.byKey(const ValueKey(IntegrationTestKeys.navChat)));
    await tester.tap(
      find.byKey(
        const ValueKey(IntegrationTestKeys.actionOpenNotifications),
      ),
    );
    await tester.pump();

    expect(find.text('chat=1'), findsOneWidget);
    expect(find.text('notifications=1'), findsOneWidget);
  });
}
