part of 'market_filter_sheet.dart';

class _MarketFilterSheetState extends State<MarketFilterSheet> {
  late String selectedCity;
  late String selectedSort;
  late final TextEditingController minPriceController;
  late final TextEditingController maxPriceController;

  MarketController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    selectedCity = controller.selectedCityFilter.value;
    selectedSort = controller.sortSelection.value;
    minPriceController =
        TextEditingController(text: controller.minPriceFilter.value);
    maxPriceController =
        TextEditingController(text: controller.maxPriceFilter.value);
  }

  @override
  void dispose() {
    minPriceController.dispose();
    maxPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          15,
          18,
          15,
          MediaQuery.of(context).viewInsets.bottom + 18,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSheetHeader(title: 'pasaj.market.filter.title'.tr),
              const SizedBox(height: 16),
              _buildCityField(context),
              const SizedBox(height: 16),
              _buildPriceRangeSection(),
              const SizedBox(height: 16),
              _buildSortSection(),
              const SizedBox(height: 18),
              _buildFooterActions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCityField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'common.city'.tr,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontFamily: 'MontserratBold',
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _openCityPicker(context),
          child: AbsorbPointer(
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F6F8),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      selectedCity.isEmpty
                          ? 'pasaj.market.filter.all_cities'.tr
                          : selectedCity,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontFamily: 'MontserratMedium',
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Colors.black45,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRangeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'pasaj.market.filter.price_range'.tr,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontFamily: 'MontserratBold',
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: minPriceController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration('pasaj.market.filter.min'.tr),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: maxPriceController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration('pasaj.market.filter.max'.tr),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSortSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'pasaj.market.filter.sort'.tr,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontFamily: 'MontserratBold',
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _sortChip(
                label: 'pasaj.market.filter.newest'.tr,
                value: 'newest',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _sortChip(
                label: 'pasaj.market.filter.ascending'.tr,
                value: 'price_asc',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _sortChip(
                label: 'pasaj.market.filter.descending'.tr,
                value: 'price_desc',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFooterActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 40,
            child: OutlinedButton(
              onPressed: () => _clearFilters(context),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey.withAlpha(120)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'common.clear'.tr,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 13,
                  fontFamily: 'MontserratBold',
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SizedBox(
            height: 40,
            child: ElevatedButton(
              onPressed: () => _applyFilters(context),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'pasaj.market.filter.apply'.tr,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontFamily: 'MontserratBold',
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
