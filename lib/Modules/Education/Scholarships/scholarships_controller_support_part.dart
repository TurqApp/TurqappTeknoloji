part of 'scholarships_controller.dart';

const int _scholarshipShortLinkPrefetchLimit = 6;
const String _scholarshipDefaultOgImage =
    'https://cdn.turqapp.com/og/default.jpg';

extension ScholarshipsControllerSupportPart on ScholarshipsController {
  int get minSearchLength => 2;
}
