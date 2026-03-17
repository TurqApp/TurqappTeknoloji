import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Models/job_model.dart';

import 'job_creator_controller.dart';

class JobCreator extends StatelessWidget {
  JobCreator({super.key, this.existingJob});

  final JobModel? existingJob;
  late final controller =
      Get.put(JobCreatorController(existingJob: existingJob));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: Get.back,
          icon: const Icon(CupertinoIcons.arrow_left, color: Colors.black),
        ),
        title: Text(
          existingJob == null ? 'İlan Ekle' : 'İlan Düzenle',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontFamily: 'MontserratBold',
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Obx(
          () => ListView(
            padding: const EdgeInsets.fromLTRB(15, 8, 15, 24),
            children: [
              _buildLogoPicker(),
              const SizedBox(height: 18),
              _sectionTitle('Temel Bilgiler'),
              const SizedBox(height: 8),
              TextField(
                controller: controller.brand,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(150),
                ],
                decoration: _inputDecoration('Firma Adı'),
              ),
              const SizedBox(height: 18),
              _sectionTitle('Konum'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _selectionField(
                      label: controller.sehir.value.isEmpty
                          ? 'Şehir'
                          : controller.sehir.value,
                      onTap: controller.showSehirSelect,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _selectionField(
                      label: controller.ilce.value.isEmpty
                          ? 'İlçe'
                          : controller.ilce.value,
                      onTap: controller.showIlceSelect,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _sectionTitle('İş Tanımı'),
              const SizedBox(height: 8),
              TextField(
                controller: controller.ilanBasligi,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(100),
                ],
                decoration: _inputDecoration('İlan Başlığı'),
              ),
              const SizedBox(height: 8),
              _selectionField(
                label: controller.selectedCalismaTuruList.isEmpty
                    ? 'Çalışma Türü'
                    : controller.selectedCalismaTuruList.join(', '),
                onTap: controller.selectCalismaTuru,
              ),
              const SizedBox(height: 8),
              _selectionField(
                label: 'Çalışma Günleri',
                onTap: controller.selectCalismaGunleri,
              ),
              const SizedBox(height: 8),
              _fieldLabel('Çalışma Saatleri'),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller.calismaSaatiBaslangic,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        _TimeTextInputFormatter(),
                      ],
                      decoration: _inputDecoration('Başlangıç'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: controller.calismaSaatiBitis,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        _TimeTextInputFormatter(),
                      ],
                      decoration: _inputDecoration('Bitiş'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _selectionField(
                label:
                    controller.meslek.value.isEmpty ? 'Meslek' : controller.meslek.value,
                onTap: controller.showMeslekSelector,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller.isTanimi,
                minLines: 4,
                maxLines: 8,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(2000),
                ],
                decoration: _inputDecoration('İş Tanımı'),
              ),
              const SizedBox(height: 8),
              _selectionField(
                label: controller.selectedYanHaklar.isEmpty
                    ? 'Ek İmkanlar'
                    : controller.selectedYanHaklar.join(', '),
                onTap: () => controller.selectYanHaklar(context),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Alınacak Personel Sayısı',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        fontFamily: 'MontserratMedium',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 96,
                    child: TextField(
                      controller: controller.pozisyonSayisi,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(3),
                      ],
                      textAlign: TextAlign.center,
                      decoration: _inputDecoration('1'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => controller.maasOpen.value = !controller.maasOpen.value,
                child: Container(
                  height: 58,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0x22000000)),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Maaş Aralığı',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 15,
                            fontFamily: 'MontserratMedium',
                          ),
                        ),
                      ),
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.black),
                          color: controller.maasOpen.value
                              ? Colors.black
                              : Colors.transparent,
                        ),
                        child: const Icon(
                          CupertinoIcons.checkmark,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (controller.maasOpen.value) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                    child: TextField(
                      controller: controller.maas1,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        _ThousandsTextInputFormatter(),
                      ],
                      decoration: _inputDecoration('Min Ücret'),
                    ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                    child: TextField(
                      controller: controller.maas2,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        _ThousandsTextInputFormatter(),
                      ],
                      decoration: _inputDecoration('Max Ücret'),
                    ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 22),
              SizedBox(
                height: 52,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    existingJob == null ? 'Yayınla' : 'Güncelle',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontFamily: 'MontserratBold',
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

  Future<void> _submit() async {
    if (controller.croppedImage.value == null &&
        (existingJob?.logo.isEmpty ?? true)) {
      AppSnackbar('Eksik alan', 'Firma logosu seçmeden devam edemezsiniz');
      return;
    }
    if (controller.brand.text.trim().isEmpty) {
      AppSnackbar('Eksik alan', 'Firma ismini girmeden devam edemezsiniz');
      return;
    }
    if (controller.sehir.value.isEmpty || controller.ilce.value.isEmpty) {
      AppSnackbar('Eksik alan', 'Şehir ve ilçe seçmeden devam edemezsiniz');
      return;
    }
    if (controller.adres.value.isEmpty && controller.lat.value == 0) {
      AppSnackbar(
        'Eksik alan',
        'Mevcut konumunuzu kullanarak firma adresinizi belirtiniz',
      );
      return;
    }
    if (controller.selectedCalismaTuruList.isEmpty) {
      AppSnackbar('Eksik alan', 'Çalışma türü seçmeden devam edemezsiniz');
      return;
    }
    if (controller.meslek.value.isEmpty) {
      AppSnackbar('Eksik alan', 'Meslek seçmeden devam edemezsiniz');
      return;
    }
    if (controller.isTanimi.text.trim().isEmpty) {
      AppSnackbar('Eksik alan', 'İş tanımını açıklamak zorundasınız');
      return;
    }
    if (controller.selectedYanHaklar.isEmpty) {
      AppSnackbar('Eksik alan', 'En az bir ek imkan seçmek zorundasın');
      return;
    }
    if (controller.maasOpen.value && controller.maas1.text.trim().isEmpty) {
      AppSnackbar('Eksik alan', 'Minimum maaş alanını doldurmalısınız');
      return;
    }
    if (controller.maasOpen.value && controller.maas2.text.trim().isEmpty) {
      AppSnackbar('Eksik alan', 'Maksimum maaş alanını doldurmalısınız');
      return;
    }
    if (controller.maasOpen.value &&
        controller.parseMoneyInput(controller.maas2.text) <
            controller.parseMoneyInput(controller.maas1.text)) {
      AppSnackbar('Hatalı Aralık', 'Maksimum maaş, minimum maaştan düşük olamaz');
      return;
    }
    await controller.setData();
  }

  Widget _buildLogoPicker() {
    Widget preview;
    final bytes = controller.croppedImage.value;
    if (bytes != null) {
      preview = ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 112,
          height: 112,
          child: Image.memory(bytes, fit: BoxFit.cover),
        ),
      );
    } else if ((existingJob?.logo.isNotEmpty ?? false)) {
      preview = ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 112,
          height: 112,
          child: CachedNetworkImage(
            imageUrl: existingJob!.logo,
            fit: BoxFit.cover,
          ),
        ),
      );
    } else {
      preview = Container(
        width: 112,
        height: 112,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF6F7FB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0x22000000)),
        ),
        child: const Icon(
          CupertinoIcons.building_2_fill,
          color: Colors.black38,
          size: 40,
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        preview,
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            children: [
              _imageActionButton(
                label: 'Galeriden Seç',
                primary: true,
                onTap: () => controller.pickImage(source: ImageSource.gallery),
              ),
              const SizedBox(height: 8),
              _imageActionButton(
                label: 'Kameradan Çek',
                onTap: () => controller.pickImage(source: ImageSource.camera),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _imageActionButton({
    required String label,
    required VoidCallback onTap,
    bool primary = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: primary ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: primary ? null : Border.all(color: const Color(0x22000000)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: primary ? Colors.white : Colors.black,
            fontSize: 13,
            fontFamily: 'MontserratBold',
          ),
        ),
      ),
    );
  }

  Widget _selectionField({
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0x22000000)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 15,
                  fontFamily: 'MontserratMedium',
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              CupertinoIcons.chevron_down,
              size: 18,
              color: Colors.black54,
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.black,
        fontSize: 22,
        fontFamily: 'MontserratBold',
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.black,
        fontSize: 14,
        fontFamily: 'MontserratSemiBold',
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Colors.grey,
        fontSize: 15,
        fontFamily: 'MontserratMedium',
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0x22000000)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0x22000000)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0x33000000)),
      ),
    );
  }
}

class _TimeTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final clipped = digits.length > 4 ? digits.substring(0, 4) : digits;

    if (clipped.length >= 2) {
      final hour = int.tryParse(clipped.substring(0, 2)) ?? -1;
      if (hour < 0 || hour > 23) {
        return oldValue;
      }
    }

    if (clipped.length >= 3) {
      final minuteTens = int.tryParse(clipped.substring(2, 3)) ?? -1;
      if (minuteTens < 0 || minuteTens > 5) {
        return oldValue;
      }
    }

    if (clipped.length == 4) {
      final minute = int.tryParse(clipped.substring(2, 4)) ?? -1;
      if (minute < 0 || minute > 59) {
        return oldValue;
      }
    }

    String formatted;
    if (clipped.length <= 2) {
      formatted = clipped;
    } else {
      formatted = '${clipped.substring(0, 2)}:${clipped.substring(2)}';
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _ThousandsTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final reversed = digits.split('').reversed.join();
    final chunks = <String>[];
    for (var i = 0; i < reversed.length; i += 3) {
      final end = (i + 3 < reversed.length) ? i + 3 : reversed.length;
      chunks.add(reversed.substring(i, end));
    }
    final formatted = chunks
        .map((chunk) => chunk.split('').reversed.join())
        .toList()
        .reversed
        .join('.');

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
