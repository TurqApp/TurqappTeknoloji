import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
      'core slider story market and job uploads delegate storage to WebpUploadService',
      () async {
    final checkedSources = <String, String>{
      'slider admin actions':
          'lib/Core/Slider/slider_admin_view_actions_part.dart',
      'job creator controller':
          'lib/Modules/JobFinder/JobCreator/job_creator_controller.dart',
      'job creator submission':
          'lib/Modules/JobFinder/JobCreator/job_creator_controller_submission_part.dart',
      'market create controller':
          'lib/Modules/Market/market_create_controller.dart',
      'market create submission':
          'lib/Modules/Market/market_create_controller_submission_part.dart',
      'story maker save':
          'lib/Modules/Story/StoryMaker/story_maker_controller_save_part.dart',
      'story highlights controller':
          'lib/Modules/Story/StoryHighlights/story_highlights_controller_library.dart',
      'story highlights cover':
          'lib/Modules/Story/StoryHighlights/story_highlights_controller_cover_part.dart',
    };

    final combinedSources = StringBuffer();
    for (final sourcePath in checkedSources.values) {
      combinedSources.writeln(await File(sourcePath).readAsString());
    }
    final source = combinedSources.toString();

    expect(source, contains('WebpUploadService.uploadFileAsWebp'));
    expect(source, contains('WebpUploadService.uploadBytesAsWebp'));
    expect(source, contains('slider/\${widget.sliderId}/\$itemId'));
    expect(source, contains('isBul/\$docID/logo'));
    expect(source, contains('marketStore/\$uid/\$itemId/cover'));
    expect(source, contains('stories/\$resolvedUid/\$storyId/\$ts'));
    expect(source, contains('highlights/\$uid/\$highlightId/cover'));
    expect(source, isNot(contains('storage: AppFirebaseStorage.instance')));
  });
}
