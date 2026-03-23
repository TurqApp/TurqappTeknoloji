part of 'market_filter_sheet.dart';

extension MarketFilterSheetActionsPart on _MarketFilterSheetState {
  Future<void> _openCityPicker(BuildContext context) async {
    final cityItems = <DropdownMenuItem<String>>[
      DropdownMenuItem<String>(
        value: '',
        child: Text(
          'pasaj.market.filter.all_cities'.tr,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontFamily: 'MontserratMedium',
          ),
        ),
      ),
      ...controller.availableCities.map(
        (city) => DropdownMenuItem<String>(
          value: city,
          child: Text(
            city,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 14,
              fontFamily: 'MontserratMedium',
            ),
          ),
        ),
      ),
    ];

    await ListBottomSheet.show(
      context: context,
      items: cityItems.map((item) => item.value!).toList(),
      title: 'common.city'.tr,
      searchHintText: 'pasaj.market.filter.search_city'.tr,
      selectedItem: selectedCity,
      onSelect: (value) {
        setState(() {
          selectedCity = value?.toString() ?? '';
        });
      },
    );
  }

  void _clearFilters(BuildContext context) {
    controller.clearAdvancedFilters();
    Navigator.of(context).pop();
  }

  void _applyFilters(BuildContext context) {
    controller.applyAdvancedFilters(
      city: selectedCity,
      contactPreference: '',
      minPrice: minPriceController.text,
      maxPrice: maxPriceController.text,
      sortBy: selectedSort,
    );
    Navigator.of(context).pop();
  }

  Widget _sortChip({
    required String label,
    required String value,
  }) {
    final selected = selectedSort == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedSort = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? Colors.black : Colors.grey.withAlpha(40),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black,
            fontSize: 13,
            fontFamily: 'MontserratBold',
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF5F6F8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.black12),
      ),
      hintStyle: const TextStyle(
        color: Colors.black45,
        fontSize: 14,
        fontFamily: 'MontserratMedium',
      ),
    );
  }
}
