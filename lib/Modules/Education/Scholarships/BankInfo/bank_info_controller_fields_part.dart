part of 'bank_info_controller.dart';

class _BankInfoControllerState {
  final userRepository = UserRepository.ensure();
  final color = 0xFF000000.obs;
  final selectedBank = BankInfoController._selectBank.obs;
  final kolayAdres = BankInfoController._email.obs;
  final isLoading = true.obs;
  final iban = TextEditingController();
  final kolayAdresList = const <String>[
    BankInfoController._email,
    BankInfoController._phone,
    BankInfoController._ibanType,
  ];
  final banks = const <String>[
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
}

extension BankInfoControllerFieldsPart on BankInfoController {
  UserRepository get _userRepository => _state.userRepository;
  RxInt get color => _state.color;
  RxString get selectedBank => _state.selectedBank;
  RxString get kolayAdres => _state.kolayAdres;
  RxBool get isLoading => _state.isLoading;
  TextEditingController get iban => _state.iban;
  List<String> get kolayAdresList => _state.kolayAdresList;
  List<String> get banks => _state.banks;
}
