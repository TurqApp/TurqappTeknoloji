import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/BottomSheets/app_bottom_sheet.dart';
import 'package:turqappv2/Core/BottomSheets/list_bottom_sheet.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Services/user_schema_fields.dart';

class BankInfoController extends GetxController {
  final UserRepository _userRepository = UserRepository.ensure();
  // Reactive variables
  final RxInt color = 0xFF000000.obs;
  final RxString selectedBank = "Banka Seç".obs;
  final RxString kolayAdres = "E-Posta".obs;
  final RxBool isLoading = true.obs;
  final TextEditingController iban = TextEditingController();

  // Lists
  final List<String> kolayAdresList = ["E-Posta", "Telefon", "IBAN"];
  final List<String> banks = [
    "Akbank",
    "Albaraka Türk Katılım Bankası",
    "Alternatifbank",
    "Anadolubank",
    "Arap Türk Bankası",
    "Citibank",
    "Denizbank",
    "Fibabank",
    "Hsbc Bank",
    "İng Bank",
    "Kuveyt Türk Katılım Bankası",
    "Odea Bank",
    "Qnb Finansbank",
    "Şekerbank",
    "Turkish Bank",
    "Türk Ekonomi Bankası",
    "Türk Ticaret Bankası",
    "Türkiye Emlak Katılım Bankası",
    "Türkiye Finans Katılım Bankası",
    "Türkiye Garanti Bankası",
    "Türkiye Halk Bankası",
    "Türkiye İş Bankası",
    "Türkiye Vakıflar Bankası",
    "Vakıf Katılım Bankası",
    "Yapı Ve Kredi Bankası",
    "Ziraat Bankası",
    "Ziraat Katılım Bankası",
  ];

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  Future<void> loadData() async {
    try {
      final data = await _userRepository.getUserRaw(
            FirebaseAuth.instance.currentUser!.uid,
          ) ??
          const <String, dynamic>{};
      final bank = userString(data, key: "bank", scope: "finance");
      final iban = userString(data, key: "iban", scope: "finance");
      final kolayAdresFromDb = userString(
        data,
        key: "kolayAdresSelection",
        scope: "preferences",
        fallback: "E-Posta",
      );
      selectedBank.value = bank.isNotEmpty ? bank : "Banka Seç";
      this.iban.text = iban.startsWith("TR") ? iban.substring(2) : iban;
      kolayAdres.value = kolayAdresList.contains(kolayAdresFromDb)
          ? kolayAdresFromDb
          : "E-Posta";
    } catch (e) {
      AppSnackbar('Hata', 'Veri yüklenemedi.');
    } finally {
      isLoading.value = false;
    }
  }

  void showBankBottomSheet(BuildContext context) {
    ListBottomSheet.show(
      context: context,
      items: banks,
      title: "Banka Seç",
      selectedItem:
          selectedBank.value == "Banka Seç" ? null : selectedBank.value,
      onSelect: (item) {
        selectedBank.value = item;
      },
    );
  }

  void showKolayAdresBottomSheet(BuildContext context) {
    AppBottomSheet.show(
      context: context,
      items: kolayAdresList,
      title: "Kolay Adres Tipi Seç",
      selectedItem: kolayAdres.value,
      onSelect: (item) {
        kolayAdres.value = item;
        iban.text = ''; // Clear the TextField when kolayAdres changes
      },
    );
  }

  Future<void> pasteFromClipboard() async {
    ClipboardData? data = await Clipboard.getData('text/plain');
    if (data != null) {
      // Remove spaces and "TR" prefix for IBAN
      String cleanedText = data.text!.replaceAll(' ', '');
      if (kolayAdres.value == "IBAN" && cleanedText.startsWith("TR")) {
        cleanedText = cleanedText.substring(2);
      }
      iban.text = cleanedText;
    }
  }

  void saveData() {
    if (iban.text.isEmpty) {
      AppSnackbar(
        'Tamamlanmadı',
        'IBAN bilgisini tamamlamadan devam edemeyiz.',
      );
      return;
    }
    if (selectedBank.value == "Banka Seç") {
      AppSnackbar(
        'Tamamlanmadı',
        'Ödeme alacağınız banka seçmediniz. Bursunuz onaylanması durumunda bu bilgi paylaşılacaktır.',
      );
      return;
    }
    if (kolayAdres.value == "E-Posta" &&
        !RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$").hasMatch(iban.text)) {
      AppSnackbar('Hata', 'Lütfen geçerli bir e-posta adresi girin.');
      return;
    }

    // Save to Firestore
    _userRepository
        .updateUserFields(FirebaseAuth.instance.currentUser!.uid, {
      ...scopedUserUpdate(
        scope: 'finance',
        values: {
          "iban": kolayAdres.value == "IBAN" ? "TR${iban.text}" : iban.text,
          "bank": selectedBank.value,
        },
      ),
      ...scopedUserUpdate(
        scope: 'preferences',
        values: {
          "kolayAdresSelection": kolayAdres.value,
        },
      ),
    }).then((_) {
      Get.back();
      AppSnackbar('Başarılı', 'Banka bilgileri kaydedildi.');
    }).catchError((e) {
      AppSnackbar('Hata', 'Bilgiler kaydedilemedi.');
    });
  }
}
