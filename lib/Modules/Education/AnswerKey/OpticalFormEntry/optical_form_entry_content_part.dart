part of 'optical_form_entry.dart';

extension _OpticalFormEntryContentPart on _OpticalFormEntryState {
  Widget _buildBody(BuildContext context) {
    return Column(
      children: [
        BackButtons(text: 'answer_key.join_exam_title'.tr),
        Expanded(
          child: Container(
            color: Colors.white,
            child: ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      Text(
                        'tests.search_title'.tr,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                          fontFamily: 'MontserratBold',
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'tests.join_help'.tr,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontFamily: 'MontserratMedium',
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildSearchField(),
                      Obx(() => _buildSearchAction()),
                      Obx(() => _buildSearchResult(context)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: TextField(
          focusNode: controller.focusNode,
          controller: controller.search,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          inputFormatters: [LengthLimitingTextInputFormatter(50)],
          decoration: InputDecoration(
            hintText: 'answer_key.exam_id_hint'.tr,
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
          onChanged: (value) => controller.searchText.value = value,
        ),
      ),
    );
  }

  Widget _buildSearchAction() {
    if (controller.searchText.value.isEmpty) {
      return const SizedBox();
    }

    return GestureDetector(
      onTap: controller.searchDocID,
      child: Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Container(
          height: 50,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Colors.indigo,
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          child: Text(
            'answer_key.search_optical_form'.tr,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontFamily: 'MontserratMedium',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResult(BuildContext context) {
    if (controller.model.value == null) {
      return _buildResultPlaceholder();
    }

    return Column(
      children: [
        const SizedBox(height: 20),
        _buildExamCard(context),
        const SizedBox(height: 20),
        _buildTeacherCard(),
      ],
    );
  }
}
