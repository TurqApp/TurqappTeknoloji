import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Modules/Agenda/widgets/feed_inbox_actions_row.dart';
import 'package:turqappv2/Modules/Education/widgets/market_top_action_button.dart';
import 'package:turqappv2/Modules/InAppNotifications/notification_actions_sheet_content.dart';
import 'package:turqappv2/Modules/Social/Comments/comment_composer_bar.dart';

void main() {
  testWidgets(
    'Production widgets stay accessible under large text scale',
    (tester) async {
      final semantics = tester.ensureSemantics();
      var chatTapped = 0;
      var notificationsTapped = 0;
      var clearReplyTapped = 0;
      var gifTapped = 0;
      var sendTapped = 0;
      var markAllReadTapped = 0;
      var deleteAllTapped = 0;
      var marketTapped = 0;

      final textController = TextEditingController(text: 'Merhaba TurqApp');
      addTearDown(textController.dispose);
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      try {
        await tester.pumpWidget(
          GetMaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(
                textScaler: TextScaler.linear(1.6),
              ),
              child: Scaffold(
                body: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FeedInboxActionsRow(
                        actionSize: 40,
                        spacing: 12,
                        showChatBadge: true,
                        showNotificationBadge: true,
                        onChatTap: () => chatTapped++,
                        onNotificationsTap: () => notificationsTapped++,
                      ),
                      CommentComposerBar(
                        textController: textController,
                        focusNode: focusNode,
                        avatarUrl: '',
                        replyingToNickname: 'tester',
                        selectedGifUrl: '',
                        onTextChanged: (_) {},
                        onClearReply: () => clearReplyTapped++,
                        onPickGif: () => gifTapped++,
                        onClearGif: () {},
                        onSend: () => sendTapped++,
                      ),
                      NotificationActionsSheetContent(
                        unreadCount: 3,
                        busyMarkAllRead: false,
                        onMarkAllRead: () => markAllReadTapped++,
                        onDeleteAll: () => deleteAllTapped++,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            MarketTopActionButton(
                              icon: Icons.view_stream_outlined,
                              onTap: () => marketTapped++,
                              active: true,
                              semanticsLabel:
                                  IntegrationTestKeys.marketTopActionViewMode,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(
          find.byKey(const ValueKey(IntegrationTestKeys.actionCommentSend)),
          findsOneWidget,
        );

        await tester
            .tap(find.byKey(const ValueKey(IntegrationTestKeys.navChat)));
        await tester.tap(
          find.byKey(
            const ValueKey(IntegrationTestKeys.actionOpenNotifications),
          ),
        );
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
        await tester.tap(
          find.byKey(const ValueKey(IntegrationTestKeys.actionCommentSend)),
        );
        await tester.tap(
          find.text('notifications.mark_all_read'),
        );
        await tester.tap(
          find.text('notifications.delete_all'),
        );
        await tester.tap(
          find.byKey(
            const ValueKey(IntegrationTestKeys.marketTopActionViewMode),
          ),
        );
        await tester.pumpAndSettle();

        expect(chatTapped, 1);
        expect(notificationsTapped, 1);
        expect(clearReplyTapped, 1);
        expect(gifTapped, 1);
        expect(sendTapped, 1);
        expect(markAllReadTapped, 1);
        expect(deleteAllTapped, 1);
        expect(marketTapped, 1);
        expect(tester.takeException(), isNull);

        expect(
          tester.getSemantics(
            find.byKey(const ValueKey(IntegrationTestKeys.navChat)),
          ),
          matchesSemantics(
            label: 'Open inbox',
            isButton: true,
            hasTapAction: true,
          ),
        );
        expect(
          tester.getSemantics(
            find.byKey(
              const ValueKey(IntegrationTestKeys.actionOpenNotifications),
            ),
          ),
          matchesSemantics(
            label: 'Open notifications',
            isButton: true,
            hasTapAction: true,
          ),
        );
        expect(
          tester.getSemantics(
            find.byKey(
              const ValueKey(IntegrationTestKeys.actionCommentGifPicker),
            ),
          ),
          matchesSemantics(
            label: 'Open comment GIF picker\nchat.gif',
            isButton: true,
            hasTapAction: true,
          ),
        );
        expect(
          tester.getSemantics(
            find.byKey(const ValueKey(IntegrationTestKeys.actionCommentSend)),
          ),
          matchesSemantics(
            label: 'Send comment',
            isButton: true,
            hasTapAction: true,
          ),
        );
        expect(
          tester.getSemantics(
            find.byKey(
              const ValueKey(IntegrationTestKeys.marketTopActionViewMode),
            ),
          ),
          matchesSemantics(
            label: IntegrationTestKeys.marketTopActionViewMode,
            isButton: true,
            hasTapAction: true,
          ),
        );
      } finally {
        semantics.dispose();
      }
    },
  );
}
