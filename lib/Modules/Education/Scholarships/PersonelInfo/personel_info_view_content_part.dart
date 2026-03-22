part of 'personel_info_view.dart';

extension _PersonelInfoViewContentPart on _PersonelInfoViewState {
  Widget _buildPage(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          controller.resetToOriginal();
        }
      },
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  BackButtons(text: 'personal_info.title'.tr),
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
                            padding: const EdgeInsets.all(15),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'personal_info.registry_info'.tr,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 15,
                                    fontFamily: "MontserratMedium",
                                  ),
                                ),
                                const SizedBox(height: 8),
                                DropdownField(
                                  config: controller.fieldConfigs[0],
                                  controller: controller,
                                ),
                                if (controller.isTurkeySelected &&
                                    controller.county.value.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Flexible(
                                        child: DropdownField(
                                          config: FieldConfig(
                                            label: "common.city".tr,
                                            title: "common.select_city".tr,
                                            value: controller.city,
                                            items: controller.sehirler,
                                            onSelect: (val) =>
                                                controller.updateCity(val),
                                            isSearchable: true,
                                          ),
                                          controller: controller,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Flexible(
                                        child: DropdownField(
                                          config: FieldConfig(
                                            label: "common.district".tr,
                                            title: "common.select_district".tr,
                                            value: controller.town,
                                            items: (() {
                                              final towns = controller
                                                  .sehirlerVeIlcelerData
                                                  .where(
                                                    (e) =>
                                                        e.il ==
                                                        controller.city.value,
                                                  )
                                                  .map((e) => e.ilce)
                                                  .toList();
                                              sortTurkishStrings(towns);
                                              return towns;
                                            })(),
                                            onSelect: (val) =>
                                                controller.updateTown(val),
                                            isSearchable: true,
                                          ),
                                          controller: controller,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 16),
                                Text(
                                  'scholarship.applicant.birth_date'.tr,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 15,
                                    fontFamily: "MontserratMedium",
                                  ),
                                ),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: () => _showBirthDatePicker(context),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withAlpha(20),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Obx(
                                          () => Text(
                                            controller.selectedDate.value ==
                                                    null
                                                ? 'personal_info.select_birth_date'
                                                    .tr
                                                : DateFormat(
                                                    "dd.MM.yyyy",
                                                  ).format(
                                                    controller
                                                        .selectedDate.value!,
                                                  ),
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: controller
                                                          .selectedDate.value ==
                                                      null
                                                  ? Colors.grey
                                                  : Colors.black,
                                            ),
                                          ),
                                        ),
                                        const Icon(CupertinoIcons.calendar),
                                      ],
                                    ),
                                  ),
                                ),
                                ...controller.fieldConfigs.sublist(1).map(
                                      (config) => Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 16),
                                          DropdownField(
                                            config: config,
                                            controller: controller,
                                          ),
                                        ],
                                      ),
                                    ),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Obx(
                  () => GestureDetector(
                    onTap:
                        controller.isSaving.value ? null : controller.saveData,
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(12),
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: controller.isSaving.value
                          ? const CupertinoActivityIndicator(
                              color: Colors.white,
                            )
                          : Text(
                              'common.save'.tr,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontFamily: "MontserratMedium",
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DropdownField extends StatelessWidget {
  final FieldConfig config;
  final PersonelInfoController controller;

  const DropdownField({
    super.key,
    required this.config,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          controller.localizedFieldLabel(config.label),
          style: const TextStyle(
            color: Colors.black,
            fontSize: 15,
            fontFamily: "MontserratMedium",
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => controller.toggleDropdown(context, config),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Obx(
                  () => Text(
                    config.value.value.isEmpty ||
                            config.value.value == controller.defaultSelectValue
                        ? controller.localizedPlaceholder(config.label)
                        : controller.localizedStaticValue(config.value.value),
                    style: TextStyle(
                      fontSize: 16,
                      color: config.value.value.isEmpty
                          ? Colors.grey
                          : Colors.black,
                    ),
                  ),
                ),
                const Icon(CupertinoIcons.chevron_down, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
