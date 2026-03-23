part of 'my_q_r_code.dart';

extension _MyQrCodeShellPart on _MyQRCodeState {
  Widget _buildMyQrCodeShell(BuildContext context) {
    return Scaffold(
      key: const ValueKey(IntegrationTestKeys.screenMyQr),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryColor,
              AppColors.secondColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildMyQrHeader(),
              Expanded(child: _buildMyQrCodeContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMyQrHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () {
            Get.back();
          },
          icon: const Icon(
            CupertinoIcons.xmark,
            color: Colors.white,
            size: 25,
          ),
        ),
        Text(
          'qr.title'.tr,
          style: TextStyle(
            color: Colors.white,
            fontSize: FontSizes.size18,
            fontFamily: AppFontFamilies.mbold,
          ),
        ),
        IconButton(
          onPressed: () {
            controller.showQrScannerModal();
          },
          icon: const Icon(
            CupertinoIcons.camera,
            color: Colors.white,
            size: 25,
          ),
        ),
      ],
    );
  }
}
