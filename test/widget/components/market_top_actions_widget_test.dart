import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Modules/Education/widgets/market_top_action_button.dart';

import '../../helpers/pump_app.dart';

class _MarketTopActionsHarness extends StatefulWidget {
  const _MarketTopActionsHarness();

  @override
  State<_MarketTopActionsHarness> createState() =>
      _MarketTopActionsHarnessState();
}

class _MarketTopActionsHarnessState extends State<_MarketTopActionsHarness> {
  bool _isGridMode = true;
  String _lastSheet = 'none';

  Future<void> _openSheet(BuildContext context, String name) async {
    setState(() {
      _lastSheet = name;
    });
    await showModalBottomSheet<void>(
      context: context,
      builder: (_) => SizedBox(
        height: 120,
        child: Center(child: Text('sheet=$name')),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              MarketTopActionButton(
                semanticsLabel: IntegrationTestKeys.marketTopActionViewMode,
                icon: _isGridMode
                    ? Icons.grid_view_rounded
                    : Icons.view_agenda_outlined,
                onTap: () {
                  setState(() {
                    _isGridMode = !_isGridMode;
                  });
                },
              ),
              const SizedBox(width: 8),
              MarketTopActionButton(
                semanticsLabel: IntegrationTestKeys.marketTopActionSort,
                icon: Icons.swap_vert_rounded,
                onTap: () => _openSheet(context, 'sort'),
              ),
              const SizedBox(width: 8),
              MarketTopActionButton(
                semanticsLabel: IntegrationTestKeys.marketTopActionFilter,
                icon: Icons.filter_alt_outlined,
                active: _lastSheet == 'filter',
                onTap: () => _openSheet(context, 'filter'),
              ),
            ],
          ),
          Text('grid=$_isGridMode'),
          Text('lastSheet=$_lastSheet'),
        ],
      ),
    );
  }
}

void main() {
  testWidgets('all market top action keys are rendered by production widget', (
    tester,
  ) async {
    await pumpApp(tester, const _MarketTopActionsHarness());

    expect(
      find.byKey(const ValueKey(IntegrationTestKeys.marketTopActionViewMode)),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey(IntegrationTestKeys.marketTopActionSort)),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey(IntegrationTestKeys.marketTopActionFilter)),
      findsOneWidget,
    );
  });

  testWidgets('view mode action toggles listing mode state', (tester) async {
    await pumpApp(tester, const _MarketTopActionsHarness());

    expect(find.text('grid=true'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey(IntegrationTestKeys.marketTopActionViewMode)),
    );
    await tester.pump();

    expect(find.text('grid=false'), findsOneWidget);
  });

  testWidgets('sort and filter actions open their sheets', (tester) async {
    await pumpApp(tester, const _MarketTopActionsHarness());

    await tester.tap(
      find.byKey(const ValueKey(IntegrationTestKeys.marketTopActionSort)),
    );
    await tester.pumpAndSettle();
    expect(find.text('sheet=sort'), findsOneWidget);

    Navigator.of(tester.element(find.text('sheet=sort'))).pop();
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey(IntegrationTestKeys.marketTopActionFilter)),
    );
    await tester.pumpAndSettle();

    expect(find.text('sheet=filter'), findsOneWidget);
    expect(find.text('lastSheet=filter'), findsOneWidget);
  });
}
