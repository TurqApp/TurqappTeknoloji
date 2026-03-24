import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Helpers/ImagePreview/image_preview.dart';

import '../../helpers/test_helper.dart';

class _ImagePreviewTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'tr': {
          'chat.reply_prompt': 'Yanitla',
          'chat.you': 'Sen',
          'chat.message_hint': 'Mesaj yaz',
        },
      };
}

class _ImagePreviewRouteHarness extends StatelessWidget {
  const _ImagePreviewRouteHarness({
    required this.enableReplyBar,
    required this.onSendReply,
  });

  final bool enableReplyBar;
  final Future<void> Function(String text, String mediaUrl)? onSendReply;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Get.to(
              () => ImagePreview(
                imgs: const <String>[
                  'https://example.com/one.jpg',
                  'https://example.com/two.jpg',
                ],
                startIndex: 0,
                enableReplyBar: enableReplyBar,
                onSendReply: onSendReply,
                replyPreviewLabel: 'Preview satiri',
              ),
            );
          },
          child: const Text('open'),
        ),
      ),
    );
  }
}

Future<void> _pumpPreviewHarness(
  WidgetTester tester,
  Widget child, {
  WidgetHarnessVariant variant = WidgetHarnessVariants.phoneAndroid,
}) async {
  await configureHarnessSurface(tester, variant: variant);
  await tester.pumpWidget(
    GetMaterialApp(
      locale: const Locale('tr'),
      translations: _ImagePreviewTranslations(),
      theme: ThemeData(
        platform: variant.platform,
        useMaterial3: false,
      ),
      home: MediaQuery(
        data: MediaQueryData(
          size: variant.size,
          devicePixelRatio: variant.devicePixelRatio,
          textScaler: TextScaler.linear(variant.textScale),
        ),
        child: child,
      ),
    ),
  );
  await tester.pump();
}

Future<void> _pumpRouteTransition(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
}

void main() {
  group('ImagePreview', () {
    testWidgets(
      'opens and closes through the back button on iOS harness',
      (tester) async {
        await _pumpPreviewHarness(
          tester,
          const _ImagePreviewRouteHarness(
            enableReplyBar: false,
            onSendReply: null,
          ),
          variant: WidgetHarnessVariants.phoneIos,
        );

        await tester.tap(find.text('open'));
        await _pumpRouteTransition(tester);

        expect(find.byType(ImagePreview), findsOneWidget);
        expect(find.byType(PageView), findsOneWidget);
        expect(find.byIcon(CupertinoIcons.arrow_left), findsOneWidget);

        await tester.tap(find.byIcon(CupertinoIcons.arrow_left));
        await _pumpRouteTransition(tester);

        expect(find.byType(ImagePreview), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'opens reply composer, swipes media, and sends callback with active image',
      (tester) async {
        String? sentText;
        String? sentMediaUrl;

        await _pumpPreviewHarness(
          tester,
          _ImagePreviewRouteHarness(
            enableReplyBar: true,
            onSendReply: (text, mediaUrl) async {
              sentText = text;
              sentMediaUrl = mediaUrl;
            },
          ),
          variant: WidgetHarnessVariants.phoneLargeText,
        );

        await tester.tap(find.text('open'));
        await _pumpRouteTransition(tester);

        expect(find.text('Yanitla'), findsOneWidget);

        await tester.drag(find.byType(PageView), const Offset(-300, 0));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Yanitla'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(TextField), findsOneWidget);
        expect(find.text('Preview satiri'), findsOneWidget);

        await tester.enterText(find.byType(TextField), 'Selam');
        await tester.tap(find.byIcon(CupertinoIcons.paperplane_fill));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(sentText, 'Selam');
        expect(sentMediaUrl, 'https://example.com/two.jpg');
        expect(find.byType(TextField), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
