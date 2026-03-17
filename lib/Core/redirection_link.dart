import 'package:turqappv2/Core/BottomSheets/no_yes_alert.dart';
import 'package:url_launcher/url_launcher.dart';

class RedirectionLink {
  Future<void> goToLink(String url, {String? uniqueKey}) async {
    await noYesAlert(
      title: "Uygulamadan Ayrılıyorsunuz",
      message:
          "Gitmek üzere olduğunuz bağlantı, uygulama dışında bir siteye yönlendirecek. Güvenlik ve içerik sorumluluğu ilgili siteye aittir. Devam etmek istiyor musunuz?",
      cancelText: "Hayır, Uygulamada Kal",
      yesText: "Evet, Siteye Git",
      onYesPressed: () {
        launchUrl(Uri.parse(url));
      },
    );
  }
}
