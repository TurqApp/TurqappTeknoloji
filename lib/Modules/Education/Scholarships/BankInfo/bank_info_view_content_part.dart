part of 'bank_info_view.dart';

extension _BankInfoViewContentPart on _BankInfoViewState {
  Widget _buildBody(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            _buildLoadingOrContent(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: BackButtons(text: 'bank_info.title'.tr),
        ),
        PullDownButton(
          itemBuilder: (context) => [
            PullDownMenuItem(
              title: 'bank_info.reset_menu'.tr,
              icon: CupertinoIcons.restart,
              onTap: _showResetConfirmation,
            ),
          ],
          buttonBuilder: (context, showMenu) => AppHeaderActionButton(
            onTap: showMenu,
            child: const Icon(
              Icons.more_vert,
              color: Colors.black,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingOrContent(BuildContext context) {
    return Obx(
      () => controller.isLoading.value
          ? const AppStateView.loading()
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFastTypeSelector(context),
                      const SizedBox(height: 20),
                      _buildBankSelector(context),
                      const SizedBox(height: 20),
                      _buildValueInput(),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(15),
                  child: _buildSaveButton(),
                ),
              ],
            ),
    );
  }

  Widget _buildFastTypeSelector(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'bank_info.fast_title'.tr,
          style: TextStyles.textFieldTitle,
        ),
        GestureDetector(
          onTap: () => controller.showKolayAdresBottomSheet(context),
          child: Container(
            height: 50,
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: Colors.grey.withAlpha(20),
              borderRadius: const BorderRadius.all(Radius.circular(8)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Obx(
                () => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      controller.localizedFastType(controller.kolayAdres.value),
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        fontFamily: 'MontserratMedium',
                      ),
                    ),
                    const Icon(
                      CupertinoIcons.chevron_down,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBankSelector(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'bank_info.bank_label'.tr,
          style: TextStyles.textFieldTitle,
        ),
        GestureDetector(
          onTap: () => controller.showBankBottomSheet(context),
          child: Container(
            height: 50,
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: Colors.grey.withAlpha(20),
              borderRadius: const BorderRadius.all(Radius.circular(8)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Obx(
                () => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      controller.selectedBank.value ==
                              controller.defaultBankSelection
                          ? 'bank_info.select_bank'.tr
                          : controller.selectedBank.value,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        fontFamily: 'MontserratMedium',
                      ),
                    ),
                    const Icon(
                      CupertinoIcons.chevron_down,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildValueInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          controller.localizedFastType(controller.kolayAdres.value),
          style: TextStyles.textFieldTitle,
        ),
        Container(
          alignment: Alignment.centerLeft,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.grey.withAlpha(20),
            borderRadius: const BorderRadius.all(Radius.circular(8)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Obx(() => _buildPrefix()),
                Expanded(
                  child: TextField(
                    controller: controller.iban,
                    inputFormatters: _inputFormattersForSelection(),
                    keyboardType:
                        controller.isIbanSelected || controller.isPhoneSelected
                            ? TextInputType.number
                            : TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: controller
                          .localizedFastType(controller.kolayAdres.value),
                      hintStyle: const TextStyle(
                        color: Colors.grey,
                        fontFamily: 'MontserratMedium',
                      ),
                      border: InputBorder.none,
                    ),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontFamily: 'MontserratMedium',
                    ),
                    onChanged: (val) => controller.iban.text = val,
                  ),
                ),
                GestureDetector(
                  onTap: controller.pasteFromClipboard,
                  child: const Icon(
                    CupertinoIcons.doc_on_doc,
                    color: Colors.black,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrefix() {
    if (controller.isIbanSelected) {
      return const Row(
        children: [
          Text(
            'TR',
            style: TextStyle(
              color: Colors.black,
              fontSize: 15,
              fontFamily: 'MontserratMedium',
            ),
          ),
          SizedBox(width: 4),
        ],
      );
    }
    if (controller.isPhoneSelected) {
      return const Row(
        children: [
          Text(
            '(+90) ',
            style: TextStyle(
              color: Colors.black,
              fontSize: 15,
              fontFamily: 'MontserratMedium',
            ),
          ),
          SizedBox(width: 4),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  List<TextInputFormatter> _inputFormattersForSelection() {
    if (controller.isIbanSelected) {
      return [
        LengthLimitingTextInputFormatter(16),
        FilteringTextInputFormatter.digitsOnly,
      ];
    }
    if (controller.isPhoneSelected) {
      return [
        LengthLimitingTextInputFormatter(10),
        FilteringTextInputFormatter.digitsOnly,
      ];
    }
    if (controller.isEmailSelected) {
      return [
        LengthLimitingTextInputFormatter(50),
      ];
    }
    return [];
  }

  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: controller.saveData,
      child: Container(
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Color(controller.color.value),
          borderRadius: const BorderRadius.all(Radius.circular(12)),
        ),
        child: Text(
          'common.save'.tr,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontFamily: 'MontserratMedium',
          ),
        ),
      ),
    );
  }
}
