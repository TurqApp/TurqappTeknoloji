part of 'applications_view.dart';

extension _ApplicationsViewActionsPart on _ApplicationsViewState {
  void _openApplicationDetail(Map<String, dynamic> application) {
    Get.to(
      () => ScholarshipDetailView(),
      arguments: {
        'model': _toScholarshipModel(application),
        'type': kIndividualScholarshipType,
        'userData': {
          'nickname': application['nickname'],
          'userID': application['userID'],
          'avatarUrl': application['avatarUrl'],
        },
        'docId': application['bursID'],
      },
    );
  }

  IndividualScholarshipsModel _toScholarshipModel(
    Map<String, dynamic> application,
  ) {
    return IndividualScholarshipsModel(
      baslik: application['title'],
      img: application['img'],
      aciklama: application['desc'],
      shortDescription: application['shortDescription'] ?? '',
      basvuruKosullari: application['basvuruKosullari'],
      basvuruURL: application['basvuruURL'],
      timeStamp: application['timeStamp'],
      baslangicTarihi: application['baslangicTarihi'],
      bitisTarihi: application['bitisTarihi'],
      belgeler:
          (application['belgeler'] as List<dynamic>?)?.cast<String>() ?? [],
      aylar: (application['aylar'] as List<dynamic>?)?.cast<String>() ?? [],
      egitimKitlesi: application['egitimKitlesi'],
      altEgitimKitlesi:
          (application['altEgitimKitlesi'] as List<dynamic>?)?.cast<String>() ??
              [],
      universiteler:
          (application['universiteler'] as List<dynamic>?)?.cast<String>() ??
              [],
      mukerrerDurumu: application['mukerrerDurumu'],
      geriOdemeli: application['geriOdemeli'],
      basvuruYapilacakYer: application['basvuruYapilacakYer'],
      begeniler: [],
      goruntuleme: [],
      kaydedilenler: [],
      hedefKitle: application['hedefKitle'],
      liseOrtaOkulIlceler: [],
      liseOrtaOkulSehirler: [],
      ogrenciSayisi: application['ogrenciSayisi'],
      sehirler:
          (application['sehirler'] as List<dynamic>?)?.cast<String>() ?? [],
      tutar: application['tutar'],
      userID: application['userID'],
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
    );
  }

  void _showWithdrawSheet(
      BuildContext context, Map<String, dynamic> application) {
    final actionButtonWidth =
        (MediaQuery.of(context).size.width * 0.38).clamp(124.0, 150.0);
    Get.bottomSheet(
      ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          color: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'scholarship.withdraw_confirm_title'.tr,
                style: const TextStyle(
                  fontSize: 20,
                  color: Colors.black,
                  fontFamily: 'MontserratMedium',
                ),
              ),
              Text(
                'scholarship.withdraw_confirm_body'.tr,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                  fontFamily: 'MontserratMedium',
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _withdrawActionButton(
                      width: actionButtonWidth,
                      label: 'common.no'.tr,
                      textColor: Colors.black,
                      backgroundColor: Colors.white,
                      borderColor: Colors.black,
                      onTap: Get.back,
                    ),
                    _withdrawActionButton(
                      width: actionButtonWidth,
                      label: 'common.yes'.tr,
                      textColor: Colors.white,
                      backgroundColor: Colors.black,
                      onTap: () {
                        controller.withdrawApplication(application['bursID']);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _withdrawActionButton({
    required double width,
    required String label,
    required Color textColor,
    required Color backgroundColor,
    Color? borderColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: borderColor == null
              ? null
              : Border.all(width: 1, color: borderColor),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            color: textColor,
            fontFamily: 'MontserratMedium',
          ),
        ),
      ),
    );
  }
}
