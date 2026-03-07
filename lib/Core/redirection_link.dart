import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class RedirectionLink {
  Future<void> goToLink(String url, {String? uniqueKey}) async {
    Get.bottomSheet(Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12), topRight: Radius.circular(12))),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 2,
                )
              ],
            ),
            Text(
              "Uygulamadan Ayrılıyorsunuz",
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontFamily: "MontserratBold"),
            ),
            SizedBox(
              height: 12,
            ),
            Text(
              "Gitmek üzere olduğunuz bağlantı, uygulama dışında bir siteye yönlendirecek. Güvenlik ve içerik sorumluluğu ilgili siteye aittir. Devam etmek istiyor musunuz?",
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontFamily: "MontserratMedium"),
            ),
            SizedBox(height: 20),
            GestureDetector(
              onTap: () => Get.back(),
              child: Container(
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                child: Text(
                  "Hayır, Uygulamada Kal",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontFamily: "MontserratMedium"),
                ),
              ),
            ),
            SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                launchUrl(Uri.parse(url));
              },
              child: Container(
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: Colors.grey.withAlpha(20),
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    border: Border.all(color: Colors.grey.withAlpha(100))),
                child: Text(
                  "Evet, Siteye Git",
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontFamily: "MontserratMedium"),
                ),
              ),
            ),
          ],
        ),
      ),
    ));
  }
}
