import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('NavBar visibility can be controlled by global vertical swipes',
      () async {
    final shellSource = await File(
      'lib/Modules/NavBar/nav_bar_view_shell_content_part.dart',
    ).readAsString();
    final facadeSource = await File(
      'lib/Modules/NavBar/nav_bar_controller_facade_part.dart',
    ).readAsString();
    final supportSource = await File(
      'lib/Modules/NavBar/nav_bar_controller_support_part.dart',
    ).readAsString();

    expect(shellSource, contains('_GlobalNavBarSwipeGate'));
    expect(shellSource, contains('Listener('));
    expect(shellSource, contains('onPointerMove: _handlePointerMove'));
    expect(shellSource, contains("source: 'global_root_swipe'"));
    expect(shellSource, contains('updateVisibilityFromGlobalSwipe'));

    expect(facadeSource, contains('updateVisibilityFromGlobalSwipe'));
    expect(supportSource, contains('deltaY > 0'));
    expect(supportSource, contains('gesture=vertical_swipe'));
    expect(supportSource, contains('minSwipeDistance'));
    expect(supportSource, contains('verticalBias'));
  });
}
