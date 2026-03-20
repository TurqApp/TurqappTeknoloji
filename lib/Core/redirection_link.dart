import 'package:get/get.dart';
import 'package:turqappv2/Core/BottomSheets/no_yes_alert.dart';
import 'package:url_launcher/url_launcher.dart';

class RedirectionLink {
  Future<void> goToLink(String url, {String? uniqueKey}) async {
    await noYesAlert(
      title: 'external_link.title'.tr,
      message: 'external_link.body'.tr,
      cancelText: 'external_link.stay'.tr,
      yesText: 'external_link.go'.tr,
      onYesPressed: () {
        launchUrl(Uri.parse(url));
      },
    );
  }
}
