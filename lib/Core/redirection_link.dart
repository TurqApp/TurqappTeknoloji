import 'package:turqappv2/Core/Helpers/safe_external_link_guard.dart';

class RedirectionLink {
  Future<void> goToLink(String url, {String? uniqueKey}) async {
    await confirmAndLaunchExternalUrl(Uri.parse(url));
  }
}
