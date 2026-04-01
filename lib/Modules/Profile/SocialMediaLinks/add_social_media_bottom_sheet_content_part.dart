part of 'add_social_media_bottom_sheet.dart';

extension AddSocialMediaBottomSheetContentPart on AddSocialMediaBottomSheet {
  Widget _buildSheetContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'social_links.add_title'.tr,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          _buildPresetIcons(),
          const SizedBox(height: 12),
          _buildEditorRow(context),
          const SizedBox(height: 20),
          _buildSaveButton(),
          const SizedBox(height: 15),
        ],
      ),
    );
  }

  Widget _buildPresetIcons() {
    return SizedBox(
      height: 54,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: controller.sosyal.length,
        itemBuilder: (context, index) {
          final item = controller.sosyal[index];
          return Obx(
            () => GestureDetector(
              onTap: () => _applyPresetSelection(item),
              child: Container(
                margin: EdgeInsets.only(right: 10, left: index == 0 ? 15 : 0),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: controller.selected.value == item
                        ? Colors.blueAccent
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: Image.asset('assets/icons/${item}_s.webp'),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEditorRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImageSelector(context),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTitleField(),
                  _buildUrlField(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSelector(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        children: [
          Obx(
            () => GestureDetector(
              onTap: () => controller.pickImage(context),
              child: controller.selected.value.isNotEmpty
                  ? GestureDetector(
                      onTap: _clearPresetSelection,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                            color: Colors.grey.withValues(alpha: 0.4),
                            width: 2,
                          ),
                          borderRadius: const BorderRadius.all(
                            Radius.circular(50),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.all(
                            Radius.circular(50),
                          ),
                          child: SizedBox(
                            width: 70,
                            height: 70,
                            child: Image.asset(
                              'assets/icons/${controller.selected.value}_s.webp',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    )
                  : ClipRRect(
                      borderRadius: const BorderRadius.all(
                        Radius.circular(50),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 70,
                            height: 70,
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.grey.withValues(alpha: 0.1),
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(50),
                                ),
                              ),
                              child: const Icon(
                                Icons.add,
                                size: 30,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          if (controller.imageFile.value != null)
                            SizedBox(
                              width: 70,
                              height: 70,
                              child: ClipRRect(
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(75),
                                ),
                                child: Image.file(
                                  controller.imageFile.value!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            socialMediaDisplayTitleForKey(controller.selected.value),
            style: const TextStyle(
              color: Colors.black,
              fontSize: 12,
              fontFamily: 'MontserratMedium',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleField() {
    return SizedBox(
      height: 40,
      child: TextField(
        controller: controller.textController,
        inputFormatters: [
          LengthLimitingTextInputFormatter(20),
        ],
        decoration: const InputDecoration(
          hintText: '',
          border: InputBorder.none,
        ).copyWith(
          hintText: 'social_links.label_title'.tr,
          hintStyle: const TextStyle(
            color: Colors.grey,
            fontFamily: 'MontserratBold',
          ),
        ),
        style: const TextStyle(
          color: Colors.black,
          fontSize: 15,
          fontFamily: 'MontserratBold',
        ),
      ),
    );
  }

  Widget _buildUrlField() {
    return Obx(() {
      final isTurq = controller.selected.value == kSocialMediaTurqApp;
      return SizedBox(
        height: 40,
        child: TextField(
          controller: controller.urlController,
          keyboardType: isTurq ? TextInputType.text : TextInputType.url,
          decoration: const InputDecoration(
            hintText: '',
            border: InputBorder.none,
          ).copyWith(
            hintText: isTurq ? 'social_links.username_hint'.tr : 'https://',
            hintStyle: const TextStyle(
              color: Colors.grey,
              fontFamily: 'MontserratMedium',
            ),
          ),
          style: const TextStyle(
            color: Colors.black,
            fontSize: 15,
            fontFamily: 'MontserratMedium',
          ),
        ),
      );
    });
  }

  Widget _buildSaveButton() {
    return Obx(() {
      if (!controller.enableSave.value) {
        return const SizedBox.shrink();
      }
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Stack(
          alignment: Alignment.center,
          children: [
            TurqAppButton(onTap: _saveLink),
            if (controller.isUploading.value)
              Positioned.fill(
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}
