import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('feed poster contract keeps iOS cover threshold at 220ms', () async {
    final source = await File(
      '/Users/turqapp/Desktop/TurqApp/lib/Modules/Agenda/Common/post_content_base.dart',
    ).readAsString();

    expect(
      source,
      contains(
        'const iosFeedVisiblePlaybackThreshold = Duration(milliseconds: 220);',
      ),
    );
    expect(
      source,
      contains("if (defaultTargetPlatform == TargetPlatform.iOS &&"),
    );
    expect(
      source,
      contains('value.isPlaying &&'),
    );
    expect(
      source,
      contains('value.position > iosFeedVisiblePlaybackThreshold;'),
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
        'visualReadyPositionThreshold: const Duration(milliseconds: 220),',
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

  test(
      'feed-style inline surfaces keep iOS overlay but suppress Android poster',
      () async {
    final agendaSource = await File(
      '/Users/turqapp/Desktop/TurqApp/lib/Modules/Agenda/AgendaContent/agenda_content_body_part.dart',
    ).readAsString();
    final classicSource = await File(
      '/Users/turqapp/Desktop/TurqApp/lib/Modules/Agenda/ClassicContent/classic_content_body_part.dart',
    ).readAsString();

    for (final source in <String>[agendaSource, classicSource]) {
      expect(source, contains('isFeedStyleInlineSurface &&'));
      expect(
        source,
        anyOf(
          contains('defaultTargetPlatform != TargetPlatform.iOS'),
          contains('defaultTargetPlatform !=\n'
              '                                                          TargetPlatform.iOS'),
        ),
      );
      expect(source, contains('SizedBox.shrink()'));
    }
  });
}
