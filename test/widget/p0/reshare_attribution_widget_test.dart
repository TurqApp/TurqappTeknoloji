import 'package:firebase_core/firebase_core.dart';
// ignore: depend_on_referenced_packages
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Modules/Agenda/Common/post_content_controller.dart';
import 'package:turqappv2/Modules/Agenda/Common/reshare_attribution.dart';
import 'package:turqappv2/Services/reshare_helper.dart';

import '../../helpers/test_helper.dart';

class _FakePostContentController extends Fake implements PostContentController {
  _FakePostContentController({
    String reShareUserUserID = '',
    String reShareUserNickname = '',
    bool yenidenPaylasildiMi = false,
  })  : _reShareUserUserID = reShareUserUserID.obs,
        _reShareUserNickname = reShareUserNickname.obs,
        _yenidenPaylasildiMi = yenidenPaylasildiMi.obs;

  final RxString _reShareUserUserID;
  final RxString _reShareUserNickname;
  final RxBool _yenidenPaylasildiMi;

  @override
  RxString get reShareUserUserID => _reShareUserUserID;

  @override
  RxString get reShareUserNickname => _reShareUserNickname;

  @override
  RxBool get yenidenPaylasildiMi => _yenidenPaylasildiMi;
}

class _ReshareTestTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'tr': {
          'post.reshared_by': '@name tarafindan yeniden paylasildi',
          'post.reshared_you': 'Sen yeniden paylastin',
        },
      };
}

PostsModel _buildPost({
  String originalUserID = '',
}) {
  return PostsModel(
    ad: false,
    arsiv: false,
    aspectRatio: 1,
    debugMode: false,
    deletedPost: false,
    deletedPostTime: 0,
    docID: 'post_1',
    flood: false,
    floodCount: 0,
    gizlendi: false,
    img: const [],
    isAd: false,
    izBirakYayinTarihi: 0,
    konum: '',
    mainFlood: '',
    metin: 'Merhaba',
    originalPostID: '',
    originalUserID: originalUserID,
    paylasGizliligi: 0,
    scheduledAt: 0,
    sikayetEdildi: false,
    stabilized: true,
    stats: PostStats(),
    tags: const [],
    thumbnail: '',
    timeStamp: 0,
    userID: 'author_1',
    video: '',
    yorum: true,
  );
}

Future<void> _pumpReshareHarness(
  WidgetTester tester,
  Widget child, {
  WidgetHarnessVariant variant = WidgetHarnessVariants.phoneAndroid,
}) async {
  await configureHarnessSurface(tester, variant: variant);
  await tester.pumpWidget(
    GetMaterialApp(
      locale: const Locale('tr'),
      translations: _ReshareTestTranslations(),
      home: MediaQuery(
        data: MediaQueryData(
          size: variant.size,
          devicePixelRatio: variant.devicePixelRatio,
          textScaler: TextScaler.linear(variant.textScale),
        ),
        child: Scaffold(body: child),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ReshareAttribution', () {
    setUpAll(() async {
      setupFirebaseCoreMocks();
      try {
        await Firebase.initializeApp(
          options: const FirebaseOptions(
            apiKey: 'test',
            appId: 'test',
            messagingSenderId: 'test',
            projectId: 'test',
          ),
        );
      } on FirebaseException catch (error) {
        if (error.code != 'duplicate-app') rethrow;
      }
    });

    tearDown(ReshareHelper.clearNicknameCache);

    testWidgets(
      'shows cached nickname for explicit reshare user',
      (tester) async {
        final model = _buildPost();
        final controller = _FakePostContentController();
        ReshareHelper.cacheNickname('reshare_user', 'testernick');

        await _pumpReshareHarness(
          tester,
          ReshareAttribution(
            controller: controller,
            model: model,
            explicitReshareUserId: 'reshare_user',
          ),
          variant: WidgetHarnessVariants.phoneAndroid,
        );

        expect(
          find.text('testernick tarafindan yeniden paylasildi'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'uses placeholder when post already has original owner',
      (tester) async {
        final model = _buildPost(originalUserID: 'original_owner');
        final controller = _FakePostContentController();

        await _pumpReshareHarness(
          tester,
          ReshareAttribution(
            controller: controller,
            model: model,
            explicitReshareUserId: 'reshare_user',
            placeholder: const Text('placeholder'),
          ),
          variant: WidgetHarnessVariants.phoneIos,
        );

        expect(find.text('placeholder'), findsOneWidget);
        expect(
          find.textContaining('yeniden paylasildi'),
          findsNothing,
        );
      },
    );

    testWidgets(
      'reacts to controller nickname for non-explicit reshare state',
      (tester) async {
        final model = _buildPost();
        final controller = _FakePostContentController(
          reShareUserUserID: 'reshare_user',
          reShareUserNickname: 'akif',
        );

        await _pumpReshareHarness(
          tester,
          ReshareAttribution(
            controller: controller,
            model: model,
            placeholder: const Text('placeholder'),
          ),
          variant: WidgetHarnessVariants.phoneLargeText,
        );

        expect(find.text('akif tarafindan yeniden paylasildi'), findsOneWidget);
        expect(find.text('placeholder'), findsNothing);
      },
    );
  });
}
