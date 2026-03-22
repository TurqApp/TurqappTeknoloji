import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';

import '../../helpers/pump_app.dart';

class _CommentsInputHarness extends StatefulWidget {
  const _CommentsInputHarness();

  @override
  State<_CommentsInputHarness> createState() => _CommentsInputHarnessState();
}

class _CommentsInputHarnessState extends State<_CommentsInputHarness> {
  final TextEditingController _controller = TextEditingController();
  String? _replyTo = 'reply_target';
  String _lastSubmitted = '';
  int _gifTapCount = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() {
      _lastSubmitted = _controller.text;
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final canSend = _controller.text.isNotEmpty;

    return Scaffold(
      body: Column(
        children: [
          if (_replyTo != null)
            Row(
              children: [
                Text('reply=$_replyTo'),
                IconButton(
                  key: const ValueKey(
                    IntegrationTestKeys.actionCommentClearReply,
                  ),
                  onPressed: () {
                    setState(() {
                      _replyTo = null;
                    });
                  },
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          TextField(
            key: const ValueKey(IntegrationTestKeys.inputComment),
            controller: _controller,
            onChanged: (_) => setState(() {}),
          ),
          Row(
            children: [
              TextButton(
                key: const ValueKey(IntegrationTestKeys.actionCommentGifPicker),
                onPressed: () {
                  setState(() {
                    _gifTapCount += 1;
                  });
                },
                child: const Text('GIF'),
              ),
              if (canSend)
                ElevatedButton(
                  key: const ValueKey(IntegrationTestKeys.actionCommentSend),
                  onPressed: _submit,
                  child: const Icon(Icons.send),
                ),
            ],
          ),
          Text('submitted=$_lastSubmitted'),
          Text('gif=$_gifTapCount'),
        ],
      ),
    );
  }
}

void main() {
  testWidgets('send button stays hidden until user enters comment text', (
    tester,
  ) async {
    await pumpApp(tester, const _CommentsInputHarness());

    expect(
      find.byKey(const ValueKey(IntegrationTestKeys.inputComment)),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey(IntegrationTestKeys.actionCommentSend)),
      findsNothing,
    );

    await tester.enterText(
      find.byKey(const ValueKey(IntegrationTestKeys.inputComment)),
      'hello',
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey(IntegrationTestKeys.actionCommentSend)),
      findsOneWidget,
    );
  });

  testWidgets('sending comment submits text and clears input', (tester) async {
    await pumpApp(tester, const _CommentsInputHarness());

    await tester.enterText(
      find.byKey(const ValueKey(IntegrationTestKeys.inputComment)),
      'TurqApp comment',
    );
    await tester.tap(
      find.byKey(const ValueKey(IntegrationTestKeys.actionCommentSend)),
    );
    await tester.pump();

    expect(find.text('submitted=TurqApp comment'), findsOneWidget);
    expect(
      find.byKey(const ValueKey(IntegrationTestKeys.actionCommentSend)),
      findsNothing,
    );
  });

  testWidgets('clear reply action removes reply banner and gif picker works', (
    tester,
  ) async {
    await pumpApp(tester, const _CommentsInputHarness());

    expect(find.text('reply=reply_target'), findsOneWidget);

    await tester.tap(
      find.byKey(
        const ValueKey(IntegrationTestKeys.actionCommentClearReply),
      ),
    );
    await tester.tap(
      find.byKey(
        const ValueKey(IntegrationTestKeys.actionCommentGifPicker),
      ),
    );
    await tester.pump();

    expect(find.text('reply=reply_target'), findsNothing);
    expect(find.text('gif=1'), findsOneWidget);
  });
}
