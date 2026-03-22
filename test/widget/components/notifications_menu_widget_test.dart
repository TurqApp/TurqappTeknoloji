import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Modules/InAppNotifications/notification_actions_sheet_content.dart';

import '../../helpers/pump_app.dart';

class _NotificationsMenuHarness extends StatefulWidget {
  const _NotificationsMenuHarness({
    this.initialCount = 2,
    this.initialUnreadCount = 1,
  });

  final int initialCount;
  final int initialUnreadCount;

  @override
  State<_NotificationsMenuHarness> createState() =>
      _NotificationsMenuHarnessState();
}

class _NotificationsMenuHarnessState extends State<_NotificationsMenuHarness> {
  late int _notificationCount;
  late int _unreadCount;
  int _markAllReadCalls = 0;
  int _deleteAllCalls = 0;

  @override
  void initState() {
    super.initState();
    _notificationCount = widget.initialCount;
    _unreadCount = widget.initialUnreadCount;
  }

  Future<void> _showActions(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      builder: (_) {
        return NotificationActionsSheetContent(
          unreadCount: _unreadCount,
          busyMarkAllRead: false,
          onMarkAllRead: () {
            setState(() {
              _markAllReadCalls += 1;
              _unreadCount = 0;
            });
            Navigator.of(context).pop();
          },
          onDeleteAll: () {
            setState(() {
              _deleteAllCalls += 1;
              _notificationCount = 0;
              _unreadCount = 0;
            });
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          if (_notificationCount > 0)
            IconButton(
              key: const ValueKey(IntegrationTestKeys.actionNotificationsMore),
              onPressed: () => _showActions(context),
              icon: const Icon(Icons.more_horiz),
            ),
          Text('count=$_notificationCount'),
          Text('unread=$_unreadCount'),
          Text('markAll=$_markAllReadCalls'),
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
      const _NotificationsMenuHarness(initialCount: 0, initialUnreadCount: 0),
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

    expect(
      find.byKey(
        const ValueKey(IntegrationTestKeys.actionNotificationsMarkAllRead),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey(IntegrationTestKeys.actionNotificationsDeleteAll),
      ),
      findsOneWidget,
    );
  });

  testWidgets('mark all read respects unread availability', (tester) async {
    await pumpApp(
      tester,
      const _NotificationsMenuHarness(initialCount: 2, initialUnreadCount: 0),
    );

    await tester.tap(
      find.byKey(const ValueKey(IntegrationTestKeys.actionNotificationsMore)),
    );
    await tester.pumpAndSettle();

    final markAll = tester.widget<InkWell>(
      find.byKey(
        const ValueKey(IntegrationTestKeys.actionNotificationsMarkAllRead),
      ),
    );
    expect(markAll.onTap, isNull);

    await tester.tap(
      find.byKey(
        const ValueKey(IntegrationTestKeys.actionNotificationsDeleteAll),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('deleteAll=1'), findsOneWidget);
    expect(find.text('count=0'), findsOneWidget);
  });
}
