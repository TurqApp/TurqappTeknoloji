part of 'scholarship_detail_view.dart';

extension ScholarshipDetailViewBodyPart on ScholarshipDetailView {
  Widget buildContent(BuildContext context) {
    final ScholarshipDetailController controller =
        Get.isRegistered<ScholarshipDetailController>()
            ? Get.find<ScholarshipDetailController>()
            : Get.put(ScholarshipDetailController());

    final scholarshipData = Get.arguments as Map<String, dynamic>?;
    if (scholarshipData == null || scholarshipData['model'] == null) {
      return Scaffold(
        body: Center(
          child: Text(
            "Hata: Burs verisi bulunamadı.",
            style: TextStyle(fontSize: 16, fontFamily: "MontserratMedium"),
          ),
        ),
      );
    }

    final IndividualScholarshipsModel baseModel =
        scholarshipData['model'] as IndividualScholarshipsModel;
    final String type = 'bireysel';
    final String scholarshipDocId =
        (scholarshipData['docId'] ?? scholarshipData['scholarshipId'] ?? '')
            .toString();
    final Map<String, dynamic> userData =
        (scholarshipData['userData'] as Map<String, dynamic>?) ??
            <String, dynamic>{};
    final userImage = (userData['avatarUrl'] ?? '').toString();
    final userNick = (userData['displayName'] ??
            userData['username'] ??
            userData['nickname'] ??
            'Kullanıcı')
        .toString();
    // Yeni ScrollController tanımlıyoruz
    final ScrollController detailScrollController = ScrollController();

    return Obx(() {
      final model = controller.resolvedModel.value ?? baseModel;
      final universityCount = model.universiteler.length;
      if (controller.hiddenUniversityCount.value !=
          (universityCount > 10 ? universityCount - 10 : 0)) {
        controller.hiddenUniversityCount.value =
            universityCount > 10 ? universityCount - 10 : 0;
      }

      return Scaffold(
        body: SafeArea(
          bottom: false,
          child: Stack(children: [
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: BackButtons(text: "Burs Detayı")),
                    EducationFeedShareIconButton(
                      onTap: () => shareService.shareScholarship(
                        scholarshipData,
                      ),
                      size: 30,
                      iconSize: 18,
                    ),
                    if (userData['userID']?.toString() ==
                        FirebaseAuth.instance.currentUser?.uid)
                      Padding(
                        padding: const EdgeInsets.only(left: 4, right: 10),
                        child: AppHeaderActionButton(
                          child: const Icon(
                            CupertinoIcons.trash,
                            color: Colors.red,
                            size: 20,
                          ),
                          onTap: () {
                            noYesAlert(
                              title: "Bursu Sil",
                              message:
                                  "Bu bursu silmek istediğinizden emin misiniz?",
                              onYesPressed: () async {
                                await controller.deleteScholarship(
                                  scholarshipData['docId'] ??
                                      scholarshipData['scholarshipId'] ??
                                      '',
                                  type,
                                );
                              },
                            );
                          },
                        ),
                      )
                    else
                      10.pw,
                  ],
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: detailScrollController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (model.img.isNotEmpty)
                          Column(
                            children: [
                              model.img2.isNotEmpty
                                  ? Column(
                                      children: [
                                        AspectRatio(
                                          aspectRatio: 4 / 3,
                                          child: PageView.builder(
                                            itemCount: 2,
                                            itemBuilder: (context, pageIndex) {
                                              final imageUrl = pageIndex == 0
                                                  ? model.img
                                                  : model.img2;
                                              return CachedNetworkImage(
                                                memCacheHeight: 1000,
                                                imageUrl: imageUrl,
                                                width: double.infinity,
                                                fit: BoxFit.cover,
                                                placeholder: (context, url) =>
                                                    Center(
                                                  child:
                                                      CupertinoActivityIndicator(),
                                                ),
                                                errorWidget:
                                                    (context, url, error) =>
                                                        Icon(
                                                  Icons.error,
                                                  color: Colors.red,
                                                  size: 40,
                                                ),
                                              );
                                            },
                                            onPageChanged: (pageIndex) {
                                              controller
                                                  .updatePageIndex(pageIndex);
                                            },
                                          ),
                                        ),
                                        8.ph,
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children:
                                              List.generate(2, (dotIndex) {
                                            return Obx(
                                              () => Container(
                                                margin: EdgeInsets.symmetric(
                                                  horizontal: 4,
                                                ),
                                                width: 8,
                                                height: 8,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: controller
                                                              .currentPageIndex
                                                              .value ==
                                                          dotIndex
                                                      ? Colors.black
                                                      : Colors.grey,
                                                ),
                                              ),
                                            );
                                          }),
                                        ),
                                      ],
                                    )
                                  : AspectRatio(
                                      aspectRatio: 4 / 3,
                                      child: CachedNetworkImage(
                                        imageUrl: model.img,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => Center(
                                          child: CupertinoActivityIndicator(),
                                        ),
                                        errorWidget: (context, url, error) =>
                                            Icon(
                                          Icons.error,
                                          color: Colors.red,
                                          size: 40,
                                        ),
                                      ),
                                    ),
                            ],
                          ),
                        Padding(
                          padding: EdgeInsets.all(15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${model.baslik} BURS BAŞVURULARI",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontFamily: "MontserratBold",
                                ),
                              ),
                              8.ph,
                              Text.rich(
                                ScholarshipRichText.build(
                                  model.aciklama,
                                  baseStyle: TextStyle(
                                    fontSize: 16,
                                    fontFamily: "Montserrat",
                                  ),
                                ),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontFamily: "Montserrat",
                                ),
                              ),
                              appDivider(),
                              if (model.basvuruKosullari.isNotEmpty) ...[
                                _buildDetail('Başvuru Koşulları',
                                    model.basvuruKosullari),
                                appDivider(),
                              ],
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "İlan Yayınlanma Tarihi",
                                    style: TextStyles.bold18Black,
                                  ),
                                  Text(
                                    controller.formatTimestamp(model.timeStamp),
                                    style: TextStyles.rBlack16,
                                  ),
                                ],
                              ),
                              appDivider(),
                              _buildDetail(
                                'Başvuru Tarihleri',
                                '${model.baslangicTarihi} - ${model.bitisTarihi}',
                              ),
                              if (model.belgeler.isNotEmpty) ...[
                                appDivider(),
                                _buildDetail(
                                  'Gerekli Belgeler',
                                  model.belgeler.map((e) => '• $e').join('\n'),
                                ),
                              ],
                              if (model.aylar.isNotEmpty) ...[
                                appDivider(),
                                _buildDetail(
                                  'Burs Verilecek Aylar',
                                  model.aylar.map((ay) => '• $ay').join('\n'),
                                ),
                              ],
                              // appDivider(),
                              // _buildDetail(
                              //   'Eğitim Kitlesi',
                              //   '• ${model.egitimKitlesi.isNotEmpty ? model.egitimKitlesi : 'Belirtilmemiş'}',
                              // ),
                              // ...[
                              //   appDivider(),
                              //   _buildDetail(
                              //     'Eğitim Düzeyi',
                              //     model.altEgitimKitlesi.isNotEmpty
                              //         ? '• ${model.altEgitimKitlesi.join('\n• ')}'
                              //         : 'Belirtilmemiş',
                              //   ),
                              // ],
                              if (model.universiteler.isNotEmpty) ...[
                                appDivider(),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Üniversiteler',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: "MontserratMedium",
                                          ),
                                        ),
                                        if (model.universiteler.length > 10)
                                          Obx(
                                            () => GestureDetector(
                                              onTap: () {
                                                controller
                                                    .toggleUniversityList();
                                                controller.hiddenUniversityCount
                                                    .refresh();
                                              },
                                              child: Text(
                                                controller.showAllUniversities
                                                        .value
                                                    ? 'Daha az göster'
                                                    : 'Tümünü Göster',
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  color: Colors.black,
                                                  fontFamily:
                                                      "MontserratMedium",
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    8.ph,
                                    Obx(
                                      () => Text(
                                        controller.showAllUniversities.value
                                            ? model.universiteler
                                                .map((e) => '• $e')
                                                .join('\n')
                                            : model.universiteler
                                                .take(10)
                                                .map((e) => '• $e')
                                                .join('\n'),
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontFamily: "Montserrat",
                                        ),
                                      ),
                                    ),
                                    if (model.universiteler.length > 10)
                                      Obx(
                                        () => Padding(
                                          padding:
                                              const EdgeInsets.only(top: 8.0),
                                          child: GestureDetector(
                                            onTap: () {
                                              controller.toggleUniversityList();
                                              controller.hiddenUniversityCount
                                                  .refresh();
                                            },
                                            child: Text(
                                              controller
                                                      .showAllUniversities.value
                                                  ? 'Daha az göster'
                                                  : '+${controller.hiddenUniversityCount.value} üniversite daha',
                                              style: const TextStyle(
                                                fontSize: 15,
                                                color: Colors.black,
                                                fontFamily: "MontserratMedium",
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                              ...[
                                appDivider(),
                                _buildDetail(
                                  'Diğer Bilgiler',
                                  '• Mükerrer Durumu: ${model.mukerrerDurumu.isNotEmpty ? model.mukerrerDurumu : 'Belirtilmemiş'}\n'
                                      '• Geri Ödeme Durumu: ${model.geriOdemeli.isNotEmpty ? model.geriOdemeli : 'Belirtilmemiş'}',
                                ),
                              ],
                              ...[
                                appDivider(),
                                _buildDetail(
                                    "Başvuru Nasıl Yapılacak?",
                                    model.basvuruYapilacakYer == 'TurqApp'
                                        ? Text.rich(
                                            TextSpan(
                                              children: [
                                                const TextSpan(
                                                  text:
                                                      "Başvurular TurqApp üzerinden ",
                                                  style: TextStyle(
                                                    fontFamily: "Montserrat",
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                TextSpan(
                                                  text: "ALINMAKTADIR.",
                                                  style: const TextStyle(
                                                    color: Colors.black,
                                                    fontFamily:
                                                        "MontserratBold",
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        : Text.rich(
                                            TextSpan(
                                              children: [
                                                const TextSpan(
                                                  text:
                                                      "Başvurular TurqApp üzerinden ",
                                                  style: TextStyle(
                                                    fontFamily: "Montserrat",
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                TextSpan(
                                                  text: "ALINMAMAKTADIR.",
                                                  style: TextStyle(
                                                    color: Colors.red.shade700,
                                                    fontFamily:
                                                        "MontserratBold",
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )),
                              ],
                              appDivider(),
                              GestureDetector(
                                onTap: () => _handleProviderCardTap(
                                  website: model.website,
                                  userId: userData['userID']?.toString() ?? '',
                                ),
                                child: Container(
                                  padding: EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: Colors.black, width: 1)),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 35,
                                        child: userImage.isNotEmpty
                                            ? ClipOval(
                                                child: CachedNetworkImage(
                                                  memCacheHeight: 500,
                                                  imageUrl: userImage,
                                                  placeholder: (context, url) =>
                                                      CupertinoActivityIndicator(),
                                                  errorWidget:
                                                      (context, url, error) =>
                                                          Icon(Icons.error),
                                                  width: 72,
                                                  height: 72,
                                                  fit: BoxFit.cover,
                                                ),
                                              )
                                            : Icon(Icons.person, size: 36),
                                      ),
                                      12.pw,
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Align(
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    child: Wrap(
                                                      spacing: 0,
                                                      crossAxisAlignment:
                                                          WrapCrossAlignment
                                                              .center,
                                                      children: [
                                                        Text(
                                                          (userData['userID']
                                                                          ?.toString() ??
                                                                      '')
                                                                  .isNotEmpty
                                                              ? '${_truncateLabel(userNick, maxChars: 34)} '
                                                              : _truncateLabel(
                                                                  userNick,
                                                                  maxChars: 34,
                                                                ),
                                                          style: TextStyle(
                                                            fontSize: 16,
                                                            fontFamily:
                                                                "MontserratBold",
                                                            color: Colors.black,
                                                          ),
                                                          maxLines: 1,
                                                          overflow:
                                                              TextOverflow.clip,
                                                          softWrap: false,
                                                        ),
                                                        if ((userData['userID']
                                                                    ?.toString() ??
                                                                '')
                                                            .isNotEmpty)
                                                          RozetContent(
                                                            size: 14,
                                                            userID: userData[
                                                                        'userID']
                                                                    ?.toString() ??
                                                                '',
                                                            leftSpacing: 0,
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Text(
                                              'Web sitesini ziyaret et',
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.black,
                                                fontFamily: "Montserrat",
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              16.ph,
                              _buildActionSection(
                                context: context,
                                controller: controller,
                                model: model,
                                scholarshipData: scholarshipData,
                                scholarshipDocId: scholarshipDocId,
                                type: type,
                                userData: userData,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (controller.detailLoading.value)
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(minHeight: 2),
              ),
            ScrollTotopButton(
              scrollController: detailScrollController, // Yeni ScrollController
              visibilityThreshold: 200,
            ),
          ]),
        ),
      );
    });
  }
}
