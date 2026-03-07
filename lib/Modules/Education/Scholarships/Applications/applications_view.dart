import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/empty_row.dart';
import 'package:turqappv2/Modules/Education/Scholarships/Applications/applications_controller.dart';
import 'package:turqappv2/Models/Education/individual_scholarships_model.dart';
import 'package:turqappv2/Modules/Education/Scholarships/ScholarshipDetail/scholarship_detail_view.dart';

class ApplicationsView extends StatelessWidget {
  ApplicationsView({super.key});

  final ApplicationsController controller = Get.put(ApplicationsController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: "Burs Başvurularım"),
            Expanded(
              child: Obx(
                () => controller.isLoading.value
                    ? Center(child: CupertinoActivityIndicator())
                    : SingleChildScrollView(
                        physics: AlwaysScrollableScrollPhysics(),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Obx(
                                () => controller.applications.isEmpty
                                    ? Center(
                                        child: EmptyRow(
                                            text:
                                                'Burs Başvurunuz Bulunmamaktadır!'))
                                    : ListView.builder(
                                        shrinkWrap: true,
                                        physics: NeverScrollableScrollPhysics(),
                                        itemCount:
                                            controller.applications.length,
                                        itemBuilder: (context, index) {
                                          final application =
                                              controller.applications[index];
                                          final screenWidth =
                                              MediaQuery.of(context).size.width;
                                          final thumbnailWidth =
                                              (screenWidth * 0.31)
                                                  .clamp(96.0, 120.0);
                                          final thumbnailHeight =
                                              (thumbnailWidth * 0.75)
                                                  .clamp(72.0, 90.0);
                                          return GestureDetector(
                                            onTap: () {
                                              Get.to(
                                                () => ScholarshipDetailView(),
                                                arguments: {
                                                  'model':
                                                      IndividualScholarshipsModel(
                                                    baslik:
                                                        application['title'],
                                                    img: application['img'],
                                                    aciklama:
                                                        application['desc'],
                                                    shortDescription: application[
                                                            'shortDescription'] ??
                                                        '',
                                                    basvuruKosullari:
                                                        application[
                                                            'basvuruKosullari'],
                                                    basvuruURL: application[
                                                        'basvuruURL'],
                                                    timeStamp: application[
                                                        'timeStamp'],
                                                    baslangicTarihi:
                                                        application[
                                                            'baslangicTarihi'],
                                                    bitisTarihi: application[
                                                        'bitisTarihi'],
                                                    belgeler: (application[
                                                                    'belgeler']
                                                                as List<
                                                                    dynamic>?)
                                                            ?.cast<String>() ??
                                                        [],
                                                    aylar: (application['aylar']
                                                                as List<
                                                                    dynamic>?)
                                                            ?.cast<String>() ??
                                                        [],
                                                    egitimKitlesi: application[
                                                        'egitimKitlesi'],
                                                    altEgitimKitlesi: (application[
                                                                    'altEgitimKitlesi']
                                                                as List<
                                                                    dynamic>?)
                                                            ?.cast<String>() ??
                                                        [],
                                                    universiteler: (application[
                                                                    'universiteler']
                                                                as List<
                                                                    dynamic>?)
                                                            ?.cast<String>() ??
                                                        [],
                                                    mukerrerDurumu: application[
                                                        'mukerrerDurumu'],
                                                    geriOdemeli: application[
                                                        'geriOdemeli'],
                                                    basvuruYapilacakYer:
                                                        application[
                                                            'basvuruYapilacakYer'],
                                                    begeniler: [],
                                                    goruntuleme: [],
                                                    kaydedilenler: [],
                                                    hedefKitle: application[
                                                        'hedefKitle'],
                                                    liseOrtaOkulIlceler: [],
                                                    liseOrtaOkulSehirler: [],
                                                    ogrenciSayisi: application[
                                                        'ogrenciSayisi'],
                                                    sehirler: (application[
                                                                    'sehirler']
                                                                as List<
                                                                    dynamic>?)
                                                            ?.cast<String>() ??
                                                        [],
                                                    tutar: application['tutar'],
                                                    userID:
                                                        application['userID'],
                                                    website: '',
                                                    ilceler: [],
                                                    kaydedenler: [],
                                                    img2: '',
                                                    basvurular: [],
                                                    lisansTuru: '',
                                                    bursVeren: '',
                                                    logo: '',
                                                    template: '',
                                                    ulke: '',
                                                  ),
                                                  'type': 'bireysel',
                                                  'userData': {
                                                    'nickname':
                                                        application['nickname'],
                                                    'userID':
                                                        application['userID'],
                                                    'avatarUrl': application[
                                                        'avatarUrl'],
                                                  },
                                                  'docId':
                                                      application['bursID'],
                                                },
                                              );
                                            },
                                            child: Container(
                                              padding: EdgeInsets.all(8),
                                              margin: EdgeInsets.symmetric(
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color:
                                                    Colors.grey.withAlpha(50),
                                                borderRadius:
                                                    BorderRadius.circular(
                                                  12,
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  SizedBox(
                                                    width: thumbnailWidth,
                                                    height: thumbnailHeight,
                                                    child: Stack(
                                                      alignment:
                                                          Alignment.center,
                                                      children: [
                                                        application['img']
                                                                .isNotEmpty
                                                            ? Image.network(
                                                                application[
                                                                    'img'],
                                                                width:
                                                                    thumbnailWidth,
                                                                height:
                                                                    thumbnailHeight,
                                                                fit: BoxFit
                                                                    .cover,
                                                                loadingBuilder:
                                                                    (
                                                                  context,
                                                                  child,
                                                                  loadingProgress,
                                                                ) {
                                                                  if (loadingProgress ==
                                                                      null) {
                                                                    return child;
                                                                  }
                                                                  return CupertinoActivityIndicator();
                                                                },
                                                                errorBuilder: (
                                                                  context,
                                                                  error,
                                                                  stackTrace,
                                                                ) {
                                                                  return Image
                                                                      .asset(
                                                                    'assets/images/placeholder.webp',
                                                                    width:
                                                                        thumbnailWidth,
                                                                    height:
                                                                        thumbnailHeight,
                                                                    fit: BoxFit
                                                                        .cover,
                                                                  );
                                                                },
                                                              )
                                                            : Image.asset(
                                                                'assets/images/placeholder.webp',
                                                                width:
                                                                    thumbnailWidth,
                                                                height:
                                                                    thumbnailHeight,
                                                                fit: BoxFit
                                                                    .cover,
                                                              ),
                                                      ],
                                                    ),
                                                  ),
                                                  SizedBox(width: 12),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Row(
                                                          children: [
                                                            Expanded(
                                                              child: Text(
                                                                "${application['title']} BURS BAŞVURULARI",
                                                                style:
                                                                    TextStyle(
                                                                  color: Colors
                                                                      .black,
                                                                  fontSize: 16,
                                                                  fontFamily:
                                                                      'MontserratBold',
                                                                ),
                                                                maxLines: 1,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                              ),
                                                            ),
                                                            PullDownButton(
                                                              itemBuilder: (
                                                                context,
                                                              ) =>
                                                                  [
                                                                PullDownMenuItem(
                                                                  title:
                                                                      'Başvurunu Geri Al',
                                                                  icon: CupertinoIcons
                                                                      .restart,
                                                                  onTap: () {
                                                                    final actionButtonWidth = (MediaQuery.of(context).size.width *
                                                                            0.38)
                                                                        .clamp(
                                                                            124.0,
                                                                            150.0);
                                                                    Get.bottomSheet(
                                                                      ClipRRect(
                                                                        borderRadius:
                                                                            BorderRadius.only(
                                                                          topLeft:
                                                                              Radius.circular(
                                                                            20,
                                                                          ),
                                                                          topRight:
                                                                              Radius.circular(
                                                                            20,
                                                                          ),
                                                                        ),
                                                                        child:
                                                                            Container(
                                                                          padding:
                                                                              EdgeInsets.all(
                                                                            20,
                                                                          ),
                                                                          color:
                                                                              Colors.white,
                                                                          child:
                                                                              Column(
                                                                            mainAxisSize:
                                                                                MainAxisSize.min,
                                                                            children: [
                                                                              Text(
                                                                                'Dikkat!',
                                                                                style: TextStyle(
                                                                                  fontSize: 20,
                                                                                  color: Colors.black,
                                                                                  fontFamily: 'MontserratMedium',
                                                                                ),
                                                                              ),
                                                                              Text(
                                                                                'Başvurunu geri almak istediğinden emin misin?',
                                                                                style: TextStyle(
                                                                                  fontSize: 16,
                                                                                  color: Colors.black,
                                                                                  fontFamily: 'MontserratMedium',
                                                                                ),
                                                                              ),
                                                                              SizedBox(
                                                                                height: 20,
                                                                              ),
                                                                              SizedBox(
                                                                                width: double.infinity,
                                                                                child: Row(
                                                                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                                                  children: [
                                                                                    GestureDetector(
                                                                                      onTap: () => Get.back(),
                                                                                      child: Container(
                                                                                        width: actionButtonWidth,
                                                                                        alignment: Alignment.center,
                                                                                        height: 40,
                                                                                        decoration: BoxDecoration(
                                                                                          color: Colors.white,
                                                                                          borderRadius: BorderRadius.circular(
                                                                                            12,
                                                                                          ),
                                                                                          border: Border.all(
                                                                                            width: 1,
                                                                                            color: Colors.black,
                                                                                          ),
                                                                                        ),
                                                                                        child: Text(
                                                                                          'Hayır',
                                                                                          style: TextStyle(
                                                                                            fontSize: 15,
                                                                                            color: Colors.black,
                                                                                            fontFamily: 'MontserratMedium',
                                                                                          ),
                                                                                        ),
                                                                                      ),
                                                                                    ),
                                                                                    GestureDetector(
                                                                                      onTap: () {
                                                                                        controller.withdrawApplication(
                                                                                          application['bursID'],
                                                                                        );
                                                                                      },
                                                                                      child: Container(
                                                                                        width: actionButtonWidth,
                                                                                        alignment: Alignment.center,
                                                                                        height: 40,
                                                                                        decoration: BoxDecoration(
                                                                                          color: Colors.black,
                                                                                          borderRadius: BorderRadius.circular(
                                                                                            12,
                                                                                          ),
                                                                                        ),
                                                                                        child: Text(
                                                                                          'Evet',
                                                                                          style: TextStyle(
                                                                                            fontFamily: 'MontserratMedium',
                                                                                            color: Colors.white,
                                                                                            fontSize: 15,
                                                                                          ),
                                                                                        ),
                                                                                      ),
                                                                                    ),
                                                                                  ],
                                                                                ),
                                                                              ),
                                                                            ],
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      isScrollControlled:
                                                                          true,
                                                                    );
                                                                  },
                                                                ),
                                                              ],
                                                              buttonBuilder: (
                                                                context,
                                                                showMenu,
                                                              ) =>
                                                                  IconButton(
                                                                icon: Icon(
                                                                  Icons
                                                                      .more_vert,
                                                                  color: Colors
                                                                      .black,
                                                                ),
                                                                onPressed:
                                                                    showMenu,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        Text(
                                                          application[
                                                              'nickname'],
                                                          style: TextStyle(
                                                            color: Colors
                                                                .blue.shade900,
                                                            fontSize: 14,
                                                            fontFamily:
                                                                'MontserratMedium',
                                                          ),
                                                        ),
                                                        Text(
                                                          application['desc'],
                                                          style: TextStyle(
                                                            color:
                                                                Colors.black87,
                                                            fontSize: 14,
                                                            fontFamily:
                                                                'MontserratMedium',
                                                          ),
                                                          maxLines: 2,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
