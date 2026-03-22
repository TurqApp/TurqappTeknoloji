import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Modules/Social/Comments/comment_composer_bar.dart';

import '../../helpers/pump_app.dart';

class _CommentsInputHarness extends StatefulWidget {
  const _CommentsInputHarness();

  @override
  State<_CommentsInputHarness> createState() => _CommentsInputHarnessState();
}

class _CommentsInputHarnessState extends State<_CommentsInputHarness> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _replyTo = 'reply_target';
  String _gifUrl = '';
  String _lastSubmitted = '';
  int _gifTapCount = 0;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CommentComposerBar(
        avatarUrl: '',
        textController: _controller,
        focusNode: _focusNode,
        replyingToNickname: _replyTo,
        selectedGifUrl: _gifUrl,
        onTextChanged: (_) => setState(() {}),
        onClearReply: () {
          setState(() {
            _replyTo = '';
          });
        },
        onPickGif: () {
          setState(() {
            _gifTapCount += 1;
            _gifUrl = 'https://example.com/mock.gif';
          });
        },
        onClearGif: () {
          setState(() {
            _gifUrl = '';
          });
        },
        onSend: () {
          setState(() {
            _lastSubmitted = _controller.text;
            _controller.clear();
            _gifUrl = '';
          });
        },
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('submitted=$_lastSubmitted'),
          Text('gif=$_gifTapCount'),
        ],
      ),
    );
  }
}

void main() {
  testWidgets('send button stays hidden until text or gif exists',
      (tester) async {
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

  testWidgets('gif-only selection exposes send button in production composer', (
    tester,
  ) async {
    await pumpApp(tester, const _CommentsInputHarness());

    await tester.tap(
      find.byKey(
        const ValueKey(IntegrationTestKeys.actionCommentGifPicker),
      ),
    );
    await tester.pump();

    expect(find.text('gif=1'), findsOneWidget);
    expect(
      find.byKey(const ValueKey(IntegrationTestKeys.actionCommentSend)),
      findsOneWidget,
    );
  });

  testWidgets('sending comment clears input and gif state', (tester) async {
    await pumpApp(tester, const _CommentsInputHarness());

    await tester.enterText(
      find.byKey(const ValueKey(IntegrationTestKeys.inputComment)),
      'TurqApp comment',
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey(IntegrationTestKeys.actionCommentSend)),
    );
    await tester.pumpAndSettle();

    expect(find.text('submitted=TurqApp comment'), findsOneWidget);
    expect(
      find.byKey(const ValueKey(IntegrationTestKeys.actionCommentSend)),
      findsNothing,
    );
    expect(find.text('gif=0'), findsOneWidget);
  });

  testWidgets('clear reply action removes reply banner', (tester) async {
    await pumpApp(tester, const _CommentsInputHarness());

    expect(
        find.byKey(const ValueKey(IntegrationTestKeys.actionCommentClearReply)),
        findsOneWidget);

    await tester.tap(
      find.byKey(
        const ValueKey(IntegrationTestKeys.actionCommentClearReply),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(
        const ValueKey(IntegrationTestKeys.actionCommentClearReply),
      ),
      findsNothing,
    );
  });
}
