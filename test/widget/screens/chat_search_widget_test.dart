import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Modules/Chat/ChatListing/chat_search_field.dart';

import '../../helpers/pump_app.dart';

class _ChatSearchHarness extends StatefulWidget {
  const _ChatSearchHarness();

  @override
  State<_ChatSearchHarness> createState() => _ChatSearchHarnessState();
}

class _ChatSearchHarnessState extends State<_ChatSearchHarness> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _allChats = <String>['Ali', 'Ayse', 'Burak'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = _allChats
        .where((chat) => chat.toLowerCase().contains(query))
        .toList(growable: false);

    return Scaffold(
      body: Column(
        children: [
          ChatSearchField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
          ),
          if (filtered.isEmpty)
            const Text('No results')
          else
            Expanded(
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final chat = filtered[index];
                  return ListTile(
                    key: ValueKey(IntegrationTestKeys.chatTile(chat)),
                    title: Text(chat),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

void main() {
  testWidgets('production chat search field renders with integration key', (
    tester,
  ) async {
    await pumpApp(tester, const _ChatSearchHarness());

    expect(
      find.byKey(const ValueKey(IntegrationTestKeys.inputChatSearch)),
      findsOneWidget,
    );
    expect(find.text('Ali'), findsOneWidget);
    expect(find.text('Ayse'), findsOneWidget);
    expect(find.text('Burak'), findsOneWidget);
  });

  testWidgets('typing filters visible chat tiles', (tester) async {
    await pumpApp(tester, const _ChatSearchHarness());

    await tester.enterText(
      find.byKey(const ValueKey(IntegrationTestKeys.inputChatSearch)),
      'ay',
    );
    await tester.pump();

    expect(find.text('Ayse'), findsOneWidget);
    expect(find.text('Ali'), findsNothing);
    expect(find.text('Burak'), findsNothing);
    expect(
      find.byKey(ValueKey(IntegrationTestKeys.chatTile('Ayse'))),
      findsOneWidget,
    );
  });

  testWidgets('empty search result shows empty state', (tester) async {
    await pumpApp(tester, const _ChatSearchHarness());

    await tester.enterText(
      find.byKey(const ValueKey(IntegrationTestKeys.inputChatSearch)),
      'zzz',
    );
    await tester.pump();

    expect(find.text('No results'), findsOneWidget);
  });
}
