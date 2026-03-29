import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class WidgetHarnessVariant {
  const WidgetHarnessVariant({
    required this.name,
    required this.size,
    this.devicePixelRatio = 1.0,
    this.textScale = 1.0,
    this.platform = TargetPlatform.android,
    this.platformBrightness = Brightness.light,
  });

  final String name;
  final Size size;
  final double devicePixelRatio;
  final double textScale;
  final TargetPlatform platform;
  final Brightness platformBrightness;

  Size get physicalSize => Size(
        size.width * devicePixelRatio,
        size.height * devicePixelRatio,
      );
}

class WidgetHarnessVariants {
  static const WidgetHarnessVariant phoneSmallAndroid = WidgetHarnessVariant(
    name: 'phone_small_android',
    size: Size(360, 640),
    devicePixelRatio: 3.0,
    platform: TargetPlatform.android,
  );

  static const WidgetHarnessVariant phoneSmallAndroidLargeText =
      WidgetHarnessVariant(
        name: 'phone_small_android_large_text',
        size: Size(360, 640),
        devicePixelRatio: 3.0,
        textScale: 1.6,
        platform: TargetPlatform.android,
      );

  static const WidgetHarnessVariant phoneSmallIos = WidgetHarnessVariant(
    name: 'phone_small_ios',
    size: Size(360, 640),
    devicePixelRatio: 3.0,
    platform: TargetPlatform.iOS,
  );

  static const WidgetHarnessVariant phoneSmallIosLargeText =
      WidgetHarnessVariant(
        name: 'phone_small_ios_large_text',
        size: Size(360, 640),
        devicePixelRatio: 3.0,
        textScale: 1.6,
        platform: TargetPlatform.iOS,
      );

  static const WidgetHarnessVariant phoneAndroid = WidgetHarnessVariant(
    name: 'phone_android',
    size: Size(393, 852),
    devicePixelRatio: 3.0,
    platform: TargetPlatform.android,
  );

  static const WidgetHarnessVariant phoneIos = WidgetHarnessVariant(
    name: 'phone_ios',
    size: Size(393, 852),
    devicePixelRatio: 3.0,
    platform: TargetPlatform.iOS,
  );

  static const WidgetHarnessVariant phoneLargeText = WidgetHarnessVariant(
    name: 'phone_large_text',
    size: Size(393, 852),
    devicePixelRatio: 3.0,
    textScale: 1.6,
    platform: TargetPlatform.android,
  );

  static const WidgetHarnessVariant tabletAndroid = WidgetHarnessVariant(
    name: 'tablet_android',
    size: Size(1024, 1366),
    devicePixelRatio: 2.0,
    platform: TargetPlatform.android,
  );

  static const List<WidgetHarnessVariant> responsiveAuditMatrix = [
    phoneSmallAndroid,
    phoneSmallAndroidLargeText,
    phoneSmallIos,
    phoneSmallIosLargeText,
    phoneAndroid,
    tabletAndroid,
  ];

  static const List<WidgetHarnessVariant> accessibilityMatrix = [
    phoneAndroid,
    phoneIos,
    phoneLargeText,
    tabletAndroid,
  ];
}

Future<void> configureHarnessSurface(
  WidgetTester tester, {
  WidgetHarnessVariant variant = WidgetHarnessVariants.phoneAndroid,
}) async {
  tester.view
    ..physicalSize = variant.physicalSize
    ..devicePixelRatio = variant.devicePixelRatio
    ..platformDispatcher.platformBrightnessTestValue =
        variant.platformBrightness;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
  await tester.binding.setSurfaceSize(variant.size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

Widget buildHarnessApp(
  Widget child, {
  WidgetHarnessVariant variant = WidgetHarnessVariants.phoneAndroid,
  Locale locale = const Locale('tr'),
  ThemeData? theme,
  bool wrapInScaffold = true,
}) {
  final body = wrapInScaffold ? Scaffold(body: child) : child;
  return GetMaterialApp(
    locale: locale,
    theme: theme ??
        ThemeData(
          platform: variant.platform,
          useMaterial3: false,
        ),
    home: MediaQuery(
      data: MediaQueryData(
        size: variant.size,
        devicePixelRatio: variant.devicePixelRatio,
        platformBrightness: variant.platformBrightness,
        textScaler: TextScaler.linear(variant.textScale),
      ),
      child: body,
    ),
  );
}
