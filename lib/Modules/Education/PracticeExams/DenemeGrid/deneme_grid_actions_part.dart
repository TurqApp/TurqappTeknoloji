part of 'deneme_grid.dart';

extension _DenemeGridActionsPart on DenemeGrid {
  Future<void> _shareExternally() async {
    await ShareActionGuard.run(() async {
      final shareId = 'practice-exam:${model.docID}';
      final shortUrl = await ShortLinkService().getEducationPublicUrl(
        shareId: shareId,
        title: model.sinavAdi,
        desc: model.sinavAciklama.isNotEmpty
            ? model.sinavAciklama
            : model.sinavTuru,
        imageUrl: model.cover.isNotEmpty ? model.cover : null,
        existingShortUrl: model.shortUrl,
      );

      await ShareLinkService.shareUrl(
        url: shortUrl,
        title: model.sinavAdi,
        subject: model.sinavAdi,
      );
    });
  }

  void _openCard() {
    if (model.userID == _currentUid) {
      Get.dialog(
        AlertDialog(
          title: Text(
            model.sinavAdi,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontFamily: 'MontserratBold',
            ),
          ),
          content: ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            child: CachedNetworkImage(
              imageUrl: model.cover,
              fit: BoxFit.cover,
            ),
          ),
          backgroundColor: Colors.white,
          actions: [
            _ownerAction(
              label: 'common.view'.tr,
              color: Colors.purpleAccent,
              onTap: () {
                Get.back();
                Get.to(() => DenemeSinaviPreview(model: model));
              },
            ),
            4.ph,
            _ownerAction(
              label: 'common.delete'.tr,
              color: Colors.red,
              onTap: () {
                Get.back();
                Future.delayed(const Duration(milliseconds: 300), () {
                  noYesAlert(
                    title: 'common.delete'.tr,
                    message: 'tests.delete_confirm'.tr,
                    cancelText: 'common.cancel'.tr,
                    yesText: 'common.delete'.tr,
                    onYesPressed: () async {
                      await FirebaseFirestore.instance
                          .collection('practiceExams')
                          .doc(model.docID)
                          .delete();
                      await getData();
                    },
                  );
                });
              },
            ),
            4.ph,
            _ownerAction(
              label: 'tests.edit_title'.tr,
              color: Colors.indigo,
              onTap: () {
                Get.back();
                Get.to(() => SinavHazirla(sinavModel: model));
              },
            ),
            4.ph,
            _ownerAction(
              label: 'common.cancel'.tr,
              color: Colors.black,
              onTap: Get.back,
            ),
          ],
        ),
      );
      return;
    }
    Get.to(() => DenemeSinaviPreview(model: model));
  }

  Widget _ownerAction({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        height: 40,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            color: color,
            fontFamily: 'MontserratMedium',
          ),
        ),
      ),
    );
  }
}
