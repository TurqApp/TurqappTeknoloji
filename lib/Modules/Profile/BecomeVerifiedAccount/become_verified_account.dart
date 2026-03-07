import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/turq_app_button.dart';
import 'package:turqappv2/Core/verified_account_data_list.dart';
import 'package:turqappv2/Modules/Profile/BecomeVerifiedAccount/become_verified_account_controller.dart';
import 'package:turqappv2/Utils/empty_padding.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:turqappv2/Core/extension.dart';

class BecomeVerifiedAccount extends StatelessWidget {
  BecomeVerifiedAccount({super.key});
  final controller = Get.put(BecomeVerifiedAccountController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    if (controller.bodySelection.value != 0) {
                      controller.bodySelection--;
                    } else {
                      Get.back();
                    }
                  },
                  icon: const Icon(
                    CupertinoIcons.arrow_left,
                    color: Colors.black,
                    size: 20,
                  ),
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Obx(() {
                  return Padding(
                    padding:
                        const EdgeInsets.only(left: 15, right: 15, bottom: 15),
                    child: Column(
                      children: [
                        if (controller.bodySelection.value == 0)
                          build1()
                        else if (controller.bodySelection.value == 1)
                          build2()
                        else if (controller.bodySelection.value == 2)
                          build3()
                        else if (controller.bodySelection.value == 3)
                          build4()
                      ],
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget build1() {
    return Obx(() => Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.checkmark_seal_fill,
                        color: HexColor.hex(controller.selectedColor.value),
                        size: 45,
                      ),
                      const Text(
                        "Onaylı Hesap Ol",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                          fontFamily: "MontserratBold",
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Mobil uygulamamızda, farklı kullanıcı gruplarını tanımlamak ve güvenilirliklerini vurgulamak için onay rozetleri kullanılmaktadır.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontFamily: "MontserratMedium",
                        ),
                      ),
                      const SizedBox(height: 25),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: verifiedAccountData.length,
                        itemBuilder: (context, index) {
                          final item = verifiedAccountData[index];
                          final isSelected =
                              controller.selected.value?.title == item.title;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 15),
                            child: TextButton(
                              onPressed: () {
                                controller.selectItem(item, index);
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                backgroundColor: Colors.transparent,
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: isSelected
                                          ? HexColor.hex(
                                              controller.selectedColor.value)
                                          : Colors.grey.withAlpha(80)),
                                ),
                                padding: const EdgeInsets.all(15),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.title,
                                            style: const TextStyle(
                                              color: Colors.black,
                                              fontSize: 18,
                                              fontFamily: "MontserratBold",
                                            ),
                                          ),
                                        ),
                                        if (isSelected)
                                          Container(
                                            width: 22,
                                            height: 22,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.white,
                                              border: Border.all(
                                                  color: Colors.grey),
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(2),
                                              child: Container(
                                                decoration: const BoxDecoration(
                                                  color: Colors.indigo,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    if (isSelected)
                                      Text(
                                        item.desc,
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 15,
                                          fontFamily: "Montserrat",
                                        ),
                                      ),
                                    if (isSelected &&
                                        controller.selected.value?.title !=
                                            "Gri Onay Rozeti" &&
                                        controller.selected.value?.title !=
                                            "Turkuaz Onay Rozeti")
                                      const Text(
                                        "Her yıl yenilenmesi gerekmektedir.",
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 15,
                                          fontFamily: "MontserratBold",
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Text(
                          "Rozetlerimiz, topluluğumuzun güvenli ve şeffaf bir ortamda etkileşim kurmasını sağlamayı hedefler.\n\nProfil doğrulama hakkında daha fazla bilgi almak için TurqApp destek ekibimize ulaşabilirsiniz.",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontFamily: "Montserrat",
                          ),
                        ),
                      ),
                      TurqAppButton(
                        text: "Devam Et",
                        onTap: () {
                          controller.bodySelection.value++;
                        },
                      ),
                      const SizedBox(height: 12)
                    ],
                  ),
                ),
              ],
            )
          ],
        ));
  }

  Widget build2() {
    return Column(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.checkmark_seal_fill,
              color: HexColor.hex(controller.selectedColor.value),
              size: 50,
            ),
            SizedBox(
              height: 15,
            ),
            Text(
              verifiedAccountData[controller.selectedInt.value].title,
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontFamily: "MontserratBold"),
            ),
            SizedBox(
              height: 12,
            ),
            Text(
              verifiedAccountData[controller.selectedInt.value].desc,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontFamily: "MontserratMedium"),
            )
          ],
        ),
        SizedBox(
          height: 30,
        ),
        Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              color: Colors.white,
              border: Border.all(color: Colors.grey.withValues(alpha: 0.2))),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Reklamlar",
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontFamily: "MontserratBold"),
                      ),
                      Text(
                        "Sınırlı Reklam",
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontFamily: "Montserrat"),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Gönderi Öne Çıkartma",
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontFamily: "MontserratBold"),
                      ),
                      Text(
                        "En Yüksek",
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontFamily: "Montserrat"),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "Video İndirme",
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontFamily: "MontserratBold"),
                      ),
                      Icon(
                        CupertinoIcons.checkmark_circle,
                        color: Colors.green,
                        size: 18,
                      )
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "Uzun Süreli Video Yayınlama",
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontFamily: "MontserratBold"),
                      ),
                      Icon(
                        CupertinoIcons.checkmark_circle,
                        color: Colors.green,
                        size: 18,
                      )
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "İstatistikler",
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontFamily: "MontserratBold"),
                      ),
                      Icon(
                        CupertinoIcons.checkmark_circle,
                        color: Colors.green,
                        size: 18,
                      )
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "Kullanıcı Adı",
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontFamily: "MontserratBold"),
                      ),
                      Icon(
                        CupertinoIcons.checkmark_circle,
                        color: Colors.green,
                        size: 18,
                      )
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "Onay İşareti",
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontFamily: "MontserratBold"),
                      ),
                      Icon(
                        CupertinoIcons.checkmark_circle,
                        color: Colors.green,
                        size: 18,
                      )
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "Artırılmış Hesap Koruması",
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontFamily: "MontserratBold"),
                      ),
                      Icon(
                        CupertinoIcons.checkmark_circle,
                        color: Colors.green,
                        size: 18,
                      )
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "Kanal Oluşturma",
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontFamily: "MontserratBold"),
                      ),
                      Icon(
                        CupertinoIcons.checkmark_circle,
                        color: Colors.green,
                        size: 18,
                      )
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "Gelişmiş Destek",
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontFamily: "MontserratBold"),
                      ),
                      Icon(
                        CupertinoIcons.checkmark_circle,
                        color: Colors.green,
                        size: 18,
                      )
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "Zamanlanmış Video",
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontFamily: "MontserratBold"),
                      ),
                      Icon(
                        CupertinoIcons.checkmark_circle,
                        color: Colors.green,
                        size: 18,
                      )
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "Sınırsız İlan Oluşturma",
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontFamily: "MontserratBold"),
                      ),
                      Icon(
                        CupertinoIcons.checkmark_circle,
                        color: Colors.green,
                        size: 18,
                      )
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "Sınırsız Bağlantı Ekleme",
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontFamily: "MontserratBold"),
                      ),
                      Icon(
                        CupertinoIcons.checkmark_circle,
                        color: Colors.green,
                        size: 18,
                      )
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "Asistan Ol",
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontFamily: "MontserratBold"),
                      ),
                      Icon(
                        CupertinoIcons.checkmark_circle,
                        color: Colors.green,
                        size: 18,
                      )
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "Zamanlanmış İçerik Paylaşımı",
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontFamily: "MontserratBold"),
                      ),
                      Icon(
                        CupertinoIcons.checkmark_circle,
                        color: Colors.green,
                        size: 18,
                      )
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "Karakter Sınırı",
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontFamily: "MontserratBold"),
                    ),
                    Text(
                      "1000 Karakter",
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontFamily: "Montserrat"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        SizedBox(
          height: 20,
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Onay Rozetinin Kaybedilmesi",
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontFamily: "MontserratBold"),
            ),
            SizedBox(
              height: 15,
            ),
            Text(
              "Onay Rozetinin Kaybedilmesi: Ekibimiz, TurqApp’a abone olan hesabınızı inceledikten sonra, hesabın gereksinimlerimizi karşılamaya devam ettiğine karar verirse, onay işareti yeniden gösterilir. TurqApp ayrıca, TurqApp Kurallarını ihlal ettiği saptanan hesaplardan onay işaretini kaldırabilir.",
              style: TextStyle(
                  color: Colors.black, fontSize: 15, fontFamily: "Montserrat"),
            ),
          ],
        ),
        SizedBox(
          height: 20,
        ),
        TurqAppButton(onTap: () {
          controller.bodySelection.value++;
        }),
        SizedBox(
          height: 20,
        ),
      ],
    );
  }

  Widget build3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Kendinizi Tanıtın",
          style: TextStyle(
              color: Colors.black, fontSize: 20, fontFamily: "MontserratBold"),
        ),
        const SizedBox(
          height: 8,
        ),
        const Text(
          "1. Sosyal Medya Hesaplarınız",
          style: TextStyle(fontSize: 18, fontFamily: "MontserratBold"),
        ),
        const SizedBox(height: 12),
        ..._buildSocialField(controller.instagram, "Instagram",
            "assets/icons/instagramx.webp", controller.setInstagramDefault),
        ..._buildSocialField(controller.twitter, "Twitter",
            "assets/icons/twitterx.webp", controller.setTwitterDefault),
        ..._buildSocialField(controller.tiktok, "TikTok",
            "assets/icons/tiktokx.webp", controller.setTiktokDefault),
        const SizedBox(height: 25),
        const Text("2. Talep Ettiğiniz Kullanıcı Adı",
            style: TextStyle(fontSize: 18, fontFamily: "MontserratBold")),
        const SizedBox(height: 12),
        _buildCustomInput(controller.nickname, "Talep ettiğiniz kullanıcı adı",
            controller.setNicknameDefault),
        const SizedBox(height: 25),
        const Text("3. Kendinizi Tanıtın",
            style: TextStyle(fontSize: 18, fontFamily: "MontserratBold")),
        const SizedBox(height: 12),
        Column(
          children: [
            Container(
              height: (Get.height * 0.26).clamp(150.0, 200.0),
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: controller.aciklama,
                maxLines: null,
                inputFormatters: [LengthLimitingTextInputFormatter(1000)],
                onTap: controller.setShowTrue,
                decoration: const InputDecoration(
                  hintText: "Açıklama",
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text("${controller.aciklama.text.length}/1000",
                  style:
                      const TextStyle(fontSize: 12, fontFamily: "Montserrat")),
            )
          ],
        ),
        const SizedBox(height: 25),
        const Text("4. Sosyal Medya Onayı",
            style: TextStyle(fontSize: 18, fontFamily: "MontserratBold")),
        const SizedBox(height: 12),
        const Text(
          "Talep etmiş olduğunuz kullanıcı adı ile mevcut TurqApp kullanıcı adınızı, tarafınıza ait sosyal medya hesabınız üzerinden aşağıda belirtilen hesaplarımızdan birine mesaj yoluyla iletebilirsiniz.",
          style: TextStyle(fontSize: 15, fontFamily: "Montserrat"),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            GestureDetector(
              onTap: () => launchUrl(Uri.parse("https://x.com/turqapp")),
              child: Image.asset(
                "assets/icons/twitterx.webp",
                height: 40,
              ),
            ),
            GestureDetector(
              onTap: () =>
                  launchUrl(Uri.parse("https://instagram.com/turqapp")),
              child: Image.asset(
                "assets/icons/instagram.webp",
                height: 40,
              ),
            ),
            GestureDetector(
              onTap: () => launchUrl(Uri.parse("https://tiktok.com/@turqapp")),
              child: Image.asset(
                "assets/icons/tiktokx.webp",
                height: 40,
              ),
            ),
            GestureDetector(
              onTap: () =>
                  launchUrl(Uri.parse("https://linkedin.com/in/turqapp")),
              child: Image.asset(
                "assets/icons/linkedin.webp",
                height: 40,
              ),
            ),
            GestureDetector(
              onTap: () => launchUrl(Uri.parse("https://facebook.com/turqapp")),
              child: Image.asset(
                "assets/icons/facebook.webp",
                height: 40,
              ),
            ),
          ],
        ),
        15.ph,
        if (controller.selectedColor.value == Colors.red)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 25),
              const Text("5. E-Devlet Öğrenci Belgesi Barkod No",
                  style: TextStyle(fontSize: 18, fontFamily: "MontserratBold")),
              const SizedBox(height: 12),
              _buildCustomInput(
                  controller.eDevletBarcodeNo, "20 Haneli Barkod No"),
            ],
          ),
        controller.show.value
            ? Padding(
                padding: const EdgeInsets.only(top: 25),
                child: Text(
                  "\u2022 İlgi alanları, hobiler, uygulama kullanımı, sosyal yönler hakkında açıklayıcı bilgiler verin.",
                  style:
                      const TextStyle(fontSize: 14, fontFamily: "Montserrat"),
                ),
              )
            : const SizedBox(),
        if (controller.aciklamaText.isNotEmpty)
          GestureDetector(
            onTap: () {
              controller.submitApplication();
              controller.bodySelection++;
            },
            child: Container(
              height: 50,
              margin: const EdgeInsets.only(top: 25),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                "Başvur",
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: "MontserratBold",
                  fontSize: 15,
                ),
              ),
            ),
          )
      ],
    );
  }

  Widget build4() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Bekleme Sırasına Aldık!",
          style: TextStyle(
              color: Colors.black, fontSize: 20, fontFamily: "MontserratBold"),
        ),
        const SizedBox(
          height: 8,
        ),
        Text(
          "Doğrulanmış rozet ile gelişmiş destek, kimlik koruması ve markanızı büyütme fırsatlarına hazır olun!\n\nBu özellik, aşamalı olarak kullanıma sunuluyor ve bölgenizde aktif olduğunda size haber vereceğiz.\n\nBekleme süresi, hesabınızın aktiflik durumu gibi faktörlere bağlı olarak değişebilir. Daha fazla bilgi için destek ekibimize ulaşabilirsiniz.\n\nBildirimler e-posta yoluyla veya uygulama üzerinden gönderilebilir.",
          style: TextStyle(
              color: Colors.black,
              fontSize: 15,
              fontFamily: "MontserratMedium"),
        ),
        SizedBox(
          height: 12,
        ),
        TurqAppButton(
            text: "Tamam",
            onTap: () {
              Get.back();
            })
      ],
    );
  }

  List<Widget> _buildSocialField(TextEditingController ctrl, String hint,
      String? iconPath, VoidCallback onTap,
      {IconData? icon}) {
    return [
      Row(
        children: [
          iconPath != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(iconPath, width: 45, height: 45))
              : Container(
                  width: 45,
                  height: 45,
                  decoration: const BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.all(Radius.circular(8))),
                  alignment: Alignment.center,
                  child: Icon(icon ?? Icons.link, color: Colors.white)),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: TextField(
                  controller: ctrl,
                  onTap: onTap,
                  decoration: InputDecoration(
                    hintText: hint,
                    border: InputBorder.none,
                    hintStyle: const TextStyle(
                        color: Colors.grey, fontFamily: "Montserrat"),
                  ),
                  style: const TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontFamily: "Montserrat"),
                ),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 15),
    ];
  }

  Widget _buildCustomInput(TextEditingController ctrl, String hint,
      [VoidCallback? onTap, String? iconAsset]) {
    return Row(
      children: [
        Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
              color: Colors.black, borderRadius: BorderRadius.circular(8)),
          alignment: Alignment.center,
          child: iconAsset != null
              ? Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Image.asset(iconAsset),
                )
              : const Icon(Icons.person, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: TextField(
                controller: ctrl,
                onTap: onTap,
                decoration: InputDecoration(
                  hintText: hint,
                  border: InputBorder.none,
                  hintStyle: const TextStyle(
                      color: Colors.grey, fontFamily: "Montserrat"),
                ),
                style: const TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontFamily: "Montserrat"),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
