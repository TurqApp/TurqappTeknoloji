import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('feed poster contract keeps iOS visible-frame guard explicit', () async {
    final source = await File(
      '/Users/turqapp/Desktop/TurqApp/lib/Modules/Agenda/Common/post_content_base.dart',
    ).readAsString();

    expect(
      source,
      contains("if (defaultTargetPlatform == TargetPlatform.iOS &&"),
    );
    expect(
      source,
      contains('value.hasVisibleVideoFrame ||'),
    );
    expect(
      source,
      contains('value.position >= const Duration(milliseconds: 100)'),
    );
  });

  test('feed startup placeholder stays enabled for iOS until poster hide flips',
      () async {
    final source = await File(
      '/Users/turqapp/Desktop/TurqApp/lib/Modules/Agenda/Common/post_content_base.dart',
    ).readAsString();

    expect(
      source,
      contains(
        'visualReadyPositionThreshold: const Duration(milliseconds: 80),',
      ),
    );
    expect(
      source,
      contains('if (defaultTargetPlatform == TargetPlatform.iOS) {'),
    );
    expect(
      source,
      contains('return !shouldHidePlaybackPoster('),
    );
  });

  test('feed-style inline surfaces keep stable startup buffer policy',
      () async {
    final agendaSource = await File(
      '/Users/turqapp/Desktop/TurqApp/lib/Modules/Agenda/AgendaContent/agenda_content_body_part.dart',
    ).readAsString();
    final classicSource = await File(
      '/Users/turqapp/Desktop/TurqApp/lib/Modules/Agenda/ClassicContent/classic_content_body_part.dart',
    ).readAsString();

    for (final source in <String>[agendaSource, classicSource]) {
      expect(source, contains('isFeedStyleInlineSurface'));
      expect(source, contains('preferStableFeedStartupBuffer('));
      expect(source, contains('isFeedStyleSurface:'));
    }
  });
}
