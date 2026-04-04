import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';

import '../../helpers/pump_app.dart';

class _NotificationsMenuHarness extends StatefulWidget {
  const _NotificationsMenuHarness({
    this.initialCount = 2,
  });

  final int initialCount;

  @override
  State<_NotificationsMenuHarness> createState() =>
      _NotificationsMenuHarnessState();
}

class _NotificationsMenuHarnessState extends State<_NotificationsMenuHarness> {
  late int _notificationCount;
  int _deleteAllCalls = 0;

  @override
  void initState() {
    super.initState();
    _notificationCount = widget.initialCount;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          if (_notificationCount > 0)
            PullDownButton(
              itemBuilder: (context) => [
                PullDownMenuItem(
                  title: 'notifications.delete_all',
                  isDestructive: true,
                  onTap: () {
                    setState(() {
                      _deleteAllCalls += 1;
                      _notificationCount = 0;
                    });
                  },
                ),
              ],
              buttonBuilder: (context, showMenu) => IconButton(
                key: const ValueKey(IntegrationTestKeys.actionNotificationsMore),
                onPressed: showMenu,
                icon: const Icon(Icons.more_horiz),
              ),
            ),
          Text('count=$_notificationCount'),
          Text('deleteAll=$_deleteAllCalls'),
        ],
      ),
    );
  }
}

void main() {
  testWidgets('more action stays hidden when notification list is empty', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const _NotificationsMenuHarness(initialCount: 0),
    );

    expect(
      find.byKey(const ValueKey(IntegrationTestKeys.actionNotificationsMore)),
      findsNothing,
    );
  });

  testWidgets('more action opens production notification action menu', (
    tester,
  ) async {
    await pumpApp(tester, const _NotificationsMenuHarness());

    await tester.tap(
      find.byKey(const ValueKey(IntegrationTestKeys.actionNotificationsMore)),
    );
    await tester.pumpAndSettle();

    expect(find.text('notifications.delete_all'), findsOneWidget);
  });

  testWidgets('delete all action clears the list', (tester) async {
    await pumpApp(tester, const _NotificationsMenuHarness(initialCount: 2));

    await tester.tap(
      find.byKey(const ValueKey(IntegrationTestKeys.actionNotificationsMore)),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.text('notifications.delete_all'),
    );
    await tester.pumpAndSettle();

    expect(find.text('deleteAll=1'), findsOneWidget);
    expect(find.text('count=0'), findsOneWidget);
  });
}
