part of 'cikmis_soru_olustur.dart';

extension _CikmisSoruOlusturShellContentPart on _CikmisSoruOlusturState {
  Widget _buildCikmisSoruOlusturHeaderContent() {
    return Container(
      height: 70,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        children: [
          AppBackButton(
            icon: Icons.arrow_back,
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: AppPageTitle(
              "education.past_exam_create_title",
              translate: true,
              fontSize: 25,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCikmisSoruOlusturStartBannerContent() {
    return Container(
      height: 50,
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: Colors.indigo),
      child: Text(
        "education.start_creating".tr,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontFamily: "MontserratBold",
        ),
      ),
    );
  }
}
