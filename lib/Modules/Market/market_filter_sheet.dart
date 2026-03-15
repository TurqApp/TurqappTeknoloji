import 'package:flutter/material.dart';
import 'package:turqappv2/Modules/Market/market_controller.dart';

class MarketFilterSheet extends StatefulWidget {
  const MarketFilterSheet({
    super.key,
    required this.controller,
  });

  final MarketController controller;

  @override
  State<MarketFilterSheet> createState() => _MarketFilterSheetState();
}

class _MarketFilterSheetState extends State<MarketFilterSheet> {
  late String selectedCity;
  late String selectedContact;
  late String selectedSort;
  late final TextEditingController minPriceController;
  late final TextEditingController maxPriceController;

  MarketController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    selectedCity = controller.selectedCityFilter.value;
    selectedContact = controller.selectedContactFilter.value;
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
    final cities = controller.availableCities;
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
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.grey.withAlpha(120),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const Text(
                'Filtreler',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontFamily: 'MontserratBold',
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Sehir',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontFamily: 'MontserratBold',
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: selectedCity.isEmpty ? null : selectedCity,
                decoration: _inputDecoration('Tum Sehirler'),
                items: cities
                    .map(
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
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedCity = value ?? '';
                  });
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Iletisim',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontFamily: 'MontserratBold',
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _choiceChip(label: 'Tum', value: ''),
                  _choiceChip(label: 'Mesaj', value: 'message_only'),
                  _choiceChip(label: 'Telefon', value: 'phone'),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Fiyat Araligi',
                style: TextStyle(
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
                      decoration: _inputDecoration('Min'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: maxPriceController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration('Max'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Siralama',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontFamily: 'MontserratBold',
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _sortChip(label: 'En Yeni', value: 'newest'),
                  _sortChip(label: 'Fiyat Artan', value: 'price_asc'),
                  _sortChip(label: 'Fiyat Azalan', value: 'price_desc'),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () {
                          controller.clearAdvancedFilters();
                          Navigator.of(context).pop();
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.withAlpha(120)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Temizle',
                          style: TextStyle(
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
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          controller.applyAdvancedFilters(
                            city: selectedCity,
                            contactPreference: selectedContact,
                            minPrice: minPriceController.text,
                            maxPrice: maxPriceController.text,
                            sortBy: selectedSort,
                          );
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Uygula',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontFamily: 'MontserratBold',
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _choiceChip({
    required String label,
    required String value,
  }) {
    final selected = selectedContact == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedContact = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
