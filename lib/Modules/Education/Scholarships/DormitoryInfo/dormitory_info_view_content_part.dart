part of 'dormitory_info_view.dart';

extension _DormitoryInfoViewContentPart on _DormitoryInfoViewState {
  Widget _buildPage(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: BackButtons(text: 'dormitory.title'.tr),
                ),
                PullDownButton(
                  itemBuilder: (context) => _buildMenuItems(),
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
            ),
            Expanded(
              child: Obx(
                () => controller.isLoading.value
                    ? const Center(child: CupertinoActivityIndicator())
                    : SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (controller.yurt.value.isNotEmpty)
                                _buildCurrentDormitoryCard(),
                              const SizedBox(height: 16),
                              _buildSelectionRow(),
                              if (_canShowDormitorySelectors) ...[
                                _buildDormitorySelector(),
                                _buildNotListedToggle(),
                              ],
                              if (controller.listedeYok.value &&
                                  _canShowDormitorySelectors)
                                _buildManualDormitoryInput(),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
              ),
            ),
            Obx(
              () => _canSave
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: GestureDetector(
                        onTap: controller.saveData,
                        child: Container(
                          height: 50,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: const BorderRadius.all(
                              Radius.circular(12),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
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
                      ),
                    )
                  : const SizedBox(),
            ),
          ],
        ),
      ),
    );
  }

  bool get _canShowDormitorySelectors =>
      controller.sehir.value != controller.selectCityValue &&
      controller.sub.value != controller.selectAdminTypeValue;

  bool get _canSave =>
      (controller.listedeYok.value &&
          controller.yurtInputText.value.isNotEmpty) ||
      (!controller.listedeYok.value && controller.yurt.value.isNotEmpty);

  Widget _buildCurrentDormitoryCard() {
    return Container(
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'dormitory.current_info'.tr,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 15,
                fontFamily: 'MontserratBold',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              controller.yurt.value,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 15,
                fontFamily: 'MontserratMedium',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionRow() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: controller.showIlSec,
            child: Container(
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.all(Radius.circular(12)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Obx(
                  () => Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        controller.sehir.value == controller.selectCityValue
                            ? 'common.select_city'.tr
                            : controller.sehir.value,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontFamily: 'MontserratMedium',
                        ),
                      ),
                      const Icon(
                        CupertinoIcons.chevron_down,
                        size: 20,
                        color: Colors.black,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GestureDetector(
            onTap: controller.showIdariSec,
            child: Container(
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.all(Radius.circular(12)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Obx(
                  () => Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        controller.capitalize(
                          controller.localizedAdminType(controller.sub.value),
                        ),
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontFamily: 'MontserratMedium',
                        ),
                      ),
                      const Icon(
                        CupertinoIcons.chevron_down,
                        size: 20,
                        color: Colors.black,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDormitorySelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: GestureDetector(
        onTap: controller.showYurtSec,
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.1),
            borderRadius: const BorderRadius.all(Radius.circular(12)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: controller.yurtSelectionController,
              enabled: false,
              decoration: InputDecoration(
                hintText: 'dormitory.select_dormitory'.tr,
                hintStyle: const TextStyle(
                  color: Colors.grey,
                  fontFamily: 'MontserratMedium',
                ),
                border: InputBorder.none,
                suffixIcon: const Icon(
                  CupertinoIcons.chevron_down,
                  color: Colors.black,
                  size: 20,
                ),
              ),
              style: const TextStyle(
                color: Colors.black,
                fontSize: 15,
                fontFamily: 'MontserratMedium',
              ),
              textAlignVertical: TextAlignVertical.center,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotListedToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: controller.toggleListedeYok,
            child: Container(
              height: 20,
              width: 20,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.all(Radius.circular(4)),
                border: Border.all(color: Colors.grey),
              ),
              child: Obx(
                () => controller.listedeYok.value
                    ? const Icon(
                        Icons.check,
                        color: Colors.black,
                        size: 20,
                      )
                    : const SizedBox(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'common.not_listed'.tr,
            style: TextStyle(
              color: Colors.black,
              fontSize: 15,
              fontFamily: 'MontserratMedium',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualDormitoryInput() {
    return Container(
      alignment: Alignment.center,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: TextField(
          cursorColor: Colors.black,
          controller: controller.yurtInput,
          textCapitalization: TextCapitalization.sentences,
          keyboardType: TextInputType.text,
          inputFormatters: [
            LengthLimitingTextInputFormatter(50),
          ],
          decoration: InputDecoration(
            hintText: 'scholarship.dormitory_name_hint'.tr,
            hintStyle: const TextStyle(
              color: Colors.grey,
              fontFamily: 'MontserratMedium',
            ),
            border: InputBorder.none,
            suffixIcon: Obx(
              () => controller.yurtInputText.value.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.clear,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        controller.yurtInput.clear();
                        controller.yurtInputText.value = '';
                      },
                    )
                  : const SizedBox(),
            ),
          ),
          style: const TextStyle(
            color: Colors.black,
            fontSize: 15,
            fontFamily: 'MontserratMedium',
          ),
          textAlignVertical: TextAlignVertical.center,
        ),
      ),
    );
  }
}
