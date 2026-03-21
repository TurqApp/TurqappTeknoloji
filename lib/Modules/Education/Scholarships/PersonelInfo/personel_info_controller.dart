import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/BottomSheets/list_bottom_sheet.dart';
import 'package:turqappv2/Core/BottomSheets/app_bottom_sheet.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Services/city_directory_service.dart';
import 'package:turqappv2/Core/Services/user_schema_fields.dart';
import 'package:turqappv2/Models/cities_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class FieldConfig {
  final String label;
  final String title;
  final RxString value;
  final List<String> items;
  final Function(String) onSelect;
  final bool isSearchable;

  FieldConfig({
    required this.label,
    required this.title,
    required this.value,
    required this.items,
    required this.onSelect,
    this.isSearchable = false,
  });
}

class PersonelInfoController extends GetxController
    with GetTickerProviderStateMixin {
  static const String _countryFieldLabel = 'Ülke';
  static const String _maritalStatusFieldLabel = 'Medeni Hal';
  static const String _genderFieldLabel = 'Cinsiyet';
  static const String _disabilityFieldLabel = 'Engel Durumu';
  static const String _employmentFieldLabel = 'Çalışma Durumu';
  static const String _cityFieldLabel = 'İl';
  static const String _districtFieldLabel = 'İlçe';
  static const String _countryFieldTitleKey = 'personal_info.select_country_title';
  static const String _maritalStatusFieldTitleKey =
      'personal_info.select_marital_status_title';
  static const String _genderFieldTitleKey = 'personal_info.select_gender_title';
  static const String _disabilityFieldTitleKey =
      'personal_info.select_disability_title';
  static const String _employmentFieldTitleKey =
      'personal_info.select_work_status_title';
  static const String _single = 'Bekar';
  static const String _married = 'Evli';
  static const String _divorced = 'Boşanmış';
  static const String _turkey = 'Türkiye';
  static const String _selectValue = 'Seçim Yap';
  static const String _none = 'Yok';
  static const String _working = 'Çalışıyor';
  static const String _notWorking = 'Çalışmıyor';
  static const String _male = 'Erkek';
  static const String _female = 'Kadın';
  static const String _hasReport = 'Var';
  final UserRepository _userRepository = UserRepository.ensure();
  final CityDirectoryService _cityDirectoryService =
      CityDirectoryService.ensure();
  final tc = ''.obs;
  final medeniHal = _single.obs;
  final county = _turkey.obs;
  final cinsiyet = _selectValue.obs;
  final engelliRaporu = _none.obs;
  final calismaDurumu = _notWorking.obs;
  final city = ''.obs;
  final town = ''.obs;
  final selectedDate = Rxn<DateTime>();

  final originalTC = ''.obs;
  final originalMedeniHal = _single.obs;
  final originalCounty = _turkey.obs;
  final originalCinsiyet = _selectValue.obs;
  final originalEngelliRaporu = _none.obs;
  final originalCalismaDurumu = _notWorking.obs;
  final originalCity = ''.obs;
  final originalTown = ''.obs;
  final originalSelectedDate = Rxn<DateTime>();

  final isLoading = true.obs;
  final isSaving = false.obs;
  final sehirlerVeIlcelerData = <CitiesModel>[].obs;
  final sehirler = <String>[].obs;

  final medeniHalList = [_single, _married, _divorced];
  final cinsiyetList = [_male, _female];
  final engelliRaporuList = [_hasReport, _none];
  final calismaDurumuList = [_working, _notWorking];
  final countryList = [
    "Türkiye",
    "Afganistan",
    "Almanya",
    "Amerika Birleşik Devletleri",
    "Arjantin",
    "Avustralya",
    "Avusturya",
    "Azerbaycan",
    "Bahreyn",
    "Bangladeş",
    "Belçika",
    "Birleşik Arap Emirlikleri",
    "Birleşik Krallık",
    "Bosna-Hersek",
    "Brezilya",
    "Çekya",
    "Çin",
    "Danimarka",
    "Endonezya",
    "Ermenistan",
    "Etiyopya",
    "Filipinler",
    "Finlandiya",
    "Fransa",
    "Gana",
    "Güney Afrika",
    "Güney Kore",
    "Gürcistan",
    "Hindistan",
    "Hırvatistan",
    "Hollanda",
    "Irak",
    "İran",
    "İsrail",
    "İsveç",
    "İsviçre",
    "İspanya",
    "İtalya",
    "Japonya",
    "Kamboçya",
    "Kanada",
    "Katar",
    "Kenya",
    "Kırgızistan",
    "Kuveyt",
    "Laos",
    "Lübnan",
    "Macaristan",
    "Malezya",
    "Meksika",
    "Moğolistan",
    "Mısır",
    "Myanmar",
    "Nepal",
    "Nijerya",
    "Norveç",
    "Özbekistan",
    "Pakistan",
    "Polonya",
    "Portekiz",
    "Rusya",
    "Singapur",
    "Slovakya",
    "Slovenya",
    "Sri Lanka",
    "Sırbistan",
    "Suudi Arabistan",
    "Suriye",
    "Tacikistan",
    "Tayland",
    "Türkmenistan",
    "Umman",
    "Ürdün",
    "Vietnam",
    "Yemen",
    "Yunanistan",
    "Yeni Zelanda",
  ];

  static const Map<String, Map<String, String>> _countryLabels = {
    'en': {
      'Türkiye': 'Turkey',
      'Afganistan': 'Afghanistan',
      'Almanya': 'Germany',
      'Amerika Birleşik Devletleri': 'United States',
      'Arjantin': 'Argentina',
      'Avustralya': 'Australia',
      'Avusturya': 'Austria',
      'Azerbaycan': 'Azerbaijan',
      'Bahreyn': 'Bahrain',
      'Bangladeş': 'Bangladesh',
      'Belçika': 'Belgium',
      'Birleşik Arap Emirlikleri': 'United Arab Emirates',
      'Birleşik Krallık': 'United Kingdom',
      'Bosna-Hersek': 'Bosnia and Herzegovina',
      'Brezilya': 'Brazil',
      'Çekya': 'Czechia',
      'Çin': 'China',
      'Danimarka': 'Denmark',
      'Endonezya': 'Indonesia',
      'Ermenistan': 'Armenia',
      'Etiyopya': 'Ethiopia',
      'Filipinler': 'Philippines',
      'Finlandiya': 'Finland',
      'Fransa': 'France',
      'Gana': 'Ghana',
      'Güney Afrika': 'South Africa',
      'Güney Kore': 'South Korea',
      'Gürcistan': 'Georgia',
      'Hindistan': 'India',
      'Hırvatistan': 'Croatia',
      'Hollanda': 'Netherlands',
      'Irak': 'Iraq',
      'İran': 'Iran',
      'İsrail': 'Israel',
      'İsveç': 'Sweden',
      'İsviçre': 'Switzerland',
      'İspanya': 'Spain',
      'İtalya': 'Italy',
      'Japonya': 'Japan',
      'Kamboçya': 'Cambodia',
      'Kanada': 'Canada',
      'Katar': 'Qatar',
      'Kenya': 'Kenya',
      'Kırgızistan': 'Kyrgyzstan',
      'Kuveyt': 'Kuwait',
      'Laos': 'Laos',
      'Lübnan': 'Lebanon',
      'Macaristan': 'Hungary',
      'Malezya': 'Malaysia',
      'Meksika': 'Mexico',
      'Moğolistan': 'Mongolia',
      'Mısır': 'Egypt',
      'Myanmar': 'Myanmar',
      'Nepal': 'Nepal',
      'Nijerya': 'Nigeria',
      'Norveç': 'Norway',
      'Özbekistan': 'Uzbekistan',
      'Pakistan': 'Pakistan',
      'Polonya': 'Poland',
      'Portekiz': 'Portugal',
      'Rusya': 'Russia',
      'Singapur': 'Singapore',
      'Slovakya': 'Slovakia',
      'Slovenya': 'Slovenia',
      'Sri Lanka': 'Sri Lanka',
      'Sırbistan': 'Serbia',
      'Suudi Arabistan': 'Saudi Arabia',
      'Suriye': 'Syria',
      'Tacikistan': 'Tajikistan',
      'Tayland': 'Thailand',
      'Türkmenistan': 'Turkmenistan',
      'Umman': 'Oman',
      'Ürdün': 'Jordan',
      'Vietnam': 'Vietnam',
      'Yemen': 'Yemen',
      'Yunanistan': 'Greece',
      'Yeni Zelanda': 'New Zealand',
    },
    'de': {
      'Türkiye': 'Türkei',
      'Afganistan': 'Afghanistan',
      'Almanya': 'Deutschland',
      'Amerika Birleşik Devletleri': 'Vereinigte Staaten',
      'Arjantin': 'Argentinien',
      'Avustralya': 'Australien',
      'Avusturya': 'Österreich',
      'Azerbaycan': 'Aserbaidschan',
      'Bahreyn': 'Bahrain',
      'Bangladeş': 'Bangladesch',
      'Belçika': 'Belgien',
      'Birleşik Arap Emirlikleri': 'Vereinigte Arabische Emirate',
      'Birleşik Krallık': 'Vereinigtes Königreich',
      'Bosna-Hersek': 'Bosnien und Herzegowina',
      'Brezilya': 'Brasilien',
      'Çekya': 'Tschechien',
      'Çin': 'China',
      'Danimarka': 'Dänemark',
      'Endonezya': 'Indonesien',
      'Ermenistan': 'Armenien',
      'Etiyopya': 'Äthiopien',
      'Filipinler': 'Philippinen',
      'Finlandiya': 'Finnland',
      'Fransa': 'Frankreich',
      'Gana': 'Ghana',
      'Güney Afrika': 'Südafrika',
      'Güney Kore': 'Südkorea',
      'Gürcistan': 'Georgien',
      'Hindistan': 'Indien',
      'Hırvatistan': 'Kroatien',
      'Hollanda': 'Niederlande',
      'Irak': 'Irak',
      'İran': 'Iran',
      'İsrail': 'Israel',
      'İsveç': 'Schweden',
      'İsviçre': 'Schweiz',
      'İspanya': 'Spanien',
      'İtalya': 'Italien',
      'Japonya': 'Japan',
      'Kamboçya': 'Kambodscha',
      'Kanada': 'Kanada',
      'Katar': 'Katar',
      'Kenya': 'Kenia',
      'Kırgızistan': 'Kirgisistan',
      'Kuveyt': 'Kuwait',
      'Laos': 'Laos',
      'Lübnan': 'Libanon',
      'Macaristan': 'Ungarn',
      'Malezya': 'Malaysia',
      'Meksika': 'Mexiko',
      'Moğolistan': 'Mongolei',
      'Mısır': 'Ägypten',
      'Myanmar': 'Myanmar',
      'Nepal': 'Nepal',
      'Nijerya': 'Nigeria',
      'Norveç': 'Norwegen',
      'Özbekistan': 'Usbekistan',
      'Pakistan': 'Pakistan',
      'Polonya': 'Polen',
      'Portekiz': 'Portugal',
      'Rusya': 'Russland',
      'Singapur': 'Singapur',
      'Slovakya': 'Slowakei',
      'Slovenya': 'Slowenien',
      'Sri Lanka': 'Sri Lanka',
      'Sırbistan': 'Serbien',
      'Suudi Arabistan': 'Saudi-Arabien',
      'Suriye': 'Syrien',
      'Tacikistan': 'Tadschikistan',
      'Tayland': 'Thailand',
      'Türkmenistan': 'Turkmenistan',
      'Umman': 'Oman',
      'Ürdün': 'Jordanien',
      'Vietnam': 'Vietnam',
      'Yemen': 'Jemen',
      'Yunanistan': 'Griechenland',
      'Yeni Zelanda': 'Neuseeland',
    },
    'fr': {
      'Türkiye': 'Turquie',
      'Afganistan': 'Afghanistan',
      'Almanya': 'Allemagne',
      'Amerika Birleşik Devletleri': 'États-Unis',
      'Arjantin': 'Argentine',
      'Avustralya': 'Australie',
      'Avusturya': 'Autriche',
      'Azerbaycan': 'Azerbaïdjan',
      'Bahreyn': 'Bahreïn',
      'Bangladeş': 'Bangladesh',
      'Belçika': 'Belgique',
      'Birleşik Arap Emirlikleri': 'Émirats arabes unis',
      'Birleşik Krallık': 'Royaume-Uni',
      'Bosna-Hersek': 'Bosnie-Herzégovine',
      'Brezilya': 'Brésil',
      'Çekya': 'Tchéquie',
      'Çin': 'Chine',
      'Danimarka': 'Danemark',
      'Endonezya': 'Indonésie',
      'Ermenistan': 'Arménie',
      'Etiyopya': 'Éthiopie',
      'Filipinler': 'Philippines',
      'Finlandiya': 'Finlande',
      'Fransa': 'France',
      'Gana': 'Ghana',
      'Güney Afrika': 'Afrique du Sud',
      'Güney Kore': 'Corée du Sud',
      'Gürcistan': 'Géorgie',
      'Hindistan': 'Inde',
      'Hırvatistan': 'Croatie',
      'Hollanda': 'Pays-Bas',
      'Irak': 'Irak',
      'İran': 'Iran',
      'İsrail': 'Israël',
      'İsveç': 'Suède',
      'İsviçre': 'Suisse',
      'İspanya': 'Espagne',
      'İtalya': 'Italie',
      'Japonya': 'Japon',
      'Kamboçya': 'Cambodge',
      'Kanada': 'Canada',
      'Katar': 'Qatar',
      'Kenya': 'Kenya',
      'Kırgızistan': 'Kirghizistan',
      'Kuveyt': 'Koweït',
      'Laos': 'Laos',
      'Lübnan': 'Liban',
      'Macaristan': 'Hongrie',
      'Malezya': 'Malaisie',
      'Meksika': 'Mexique',
      'Moğolistan': 'Mongolie',
      'Mısır': 'Égypte',
      'Myanmar': 'Myanmar',
      'Nepal': 'Népal',
      'Nijerya': 'Nigeria',
      'Norveç': 'Norvège',
      'Özbekistan': 'Ouzbékistan',
      'Pakistan': 'Pakistan',
      'Polonya': 'Pologne',
      'Portekiz': 'Portugal',
      'Rusya': 'Russie',
      'Singapur': 'Singapour',
      'Slovakya': 'Slovaquie',
      'Slovenya': 'Slovénie',
      'Sri Lanka': 'Sri Lanka',
      'Sırbistan': 'Serbie',
      'Suudi Arabistan': 'Arabie saoudite',
      'Suriye': 'Syrie',
      'Tacikistan': 'Tadjikistan',
      'Tayland': 'Thaïlande',
      'Türkmenistan': 'Turkménistan',
      'Umman': 'Oman',
      'Ürdün': 'Jordanie',
      'Vietnam': 'Viêt Nam',
      'Yemen': 'Yémen',
      'Yunanistan': 'Grèce',
      'Yeni Zelanda': 'Nouvelle-Zélande',
    },
    'it': {
      'Türkiye': 'Turchia',
      'Afganistan': 'Afghanistan',
      'Almanya': 'Germania',
      'Amerika Birleşik Devletleri': 'Stati Uniti',
      'Arjantin': 'Argentina',
      'Avustralya': 'Australia',
      'Avusturya': 'Austria',
      'Azerbaycan': 'Azerbaigian',
      'Bahreyn': 'Bahrein',
      'Bangladeş': 'Bangladesh',
      'Belçika': 'Belgio',
      'Birleşik Arap Emirlikleri': 'Emirati Arabi Uniti',
      'Birleşik Krallık': 'Regno Unito',
      'Bosna-Hersek': 'Bosnia ed Erzegovina',
      'Brezilya': 'Brasile',
      'Çekya': 'Cechia',
      'Çin': 'Cina',
      'Danimarka': 'Danimarca',
      'Endonezya': 'Indonesia',
      'Ermenistan': 'Armenia',
      'Etiyopya': 'Etiopia',
      'Filipinler': 'Filippine',
      'Finlandiya': 'Finlandia',
      'Fransa': 'Francia',
      'Gana': 'Ghana',
      'Güney Afrika': 'Sudafrica',
      'Güney Kore': 'Corea del Sud',
      'Gürcistan': 'Georgia',
      'Hindistan': 'India',
      'Hırvatistan': 'Croazia',
      'Hollanda': 'Paesi Bassi',
      'Irak': 'Iraq',
      'İran': 'Iran',
      'İsrail': 'Israele',
      'İsveç': 'Svezia',
      'İsviçre': 'Svizzera',
      'İspanya': 'Spagna',
      'İtalya': 'Italia',
      'Japonya': 'Giappone',
      'Kamboçya': 'Cambogia',
      'Kanada': 'Canada',
      'Katar': 'Qatar',
      'Kenya': 'Kenya',
      'Kırgızistan': 'Kirghizistan',
      'Kuveyt': 'Kuwait',
      'Laos': 'Laos',
      'Lübnan': 'Libano',
      'Macaristan': 'Ungheria',
      'Malezya': 'Malesia',
      'Meksika': 'Messico',
      'Moğolistan': 'Mongolia',
      'Mısır': 'Egitto',
      'Myanmar': 'Myanmar',
      'Nepal': 'Nepal',
      'Nijerya': 'Nigeria',
      'Norveç': 'Norvegia',
      'Özbekistan': 'Uzbekistan',
      'Pakistan': 'Pakistan',
      'Polonya': 'Polonia',
      'Portekiz': 'Portogallo',
      'Rusya': 'Russia',
      'Singapur': 'Singapore',
      'Slovakya': 'Slovacchia',
      'Slovenya': 'Slovenia',
      'Sri Lanka': 'Sri Lanka',
      'Sırbistan': 'Serbia',
      'Suudi Arabistan': 'Arabia Saudita',
      'Suriye': 'Siria',
      'Tacikistan': 'Tagikistan',
      'Tayland': 'Thailandia',
      'Türkmenistan': 'Turkmenistan',
      'Umman': 'Oman',
      'Ürdün': 'Giordania',
      'Vietnam': 'Vietnam',
      'Yemen': 'Yemen',
      'Yunanistan': 'Grecia',
      'Yeni Zelanda': 'Nuova Zelanda',
    },
    'ru': {
      'Türkiye': 'Турция',
      'Afganistan': 'Афганистан',
      'Almanya': 'Германия',
      'Amerika Birleşik Devletleri': 'Соединенные Штаты',
      'Arjantin': 'Аргентина',
      'Avustralya': 'Австралия',
      'Avusturya': 'Австрия',
      'Azerbaycan': 'Азербайджан',
      'Bahreyn': 'Бахрейн',
      'Bangladeş': 'Бангладеш',
      'Belçika': 'Бельгия',
      'Birleşik Arap Emirlikleri': 'Объединенные Арабские Эмираты',
      'Birleşik Krallık': 'Великобритания',
      'Bosna-Hersek': 'Босния и Герцеговина',
      'Brezilya': 'Бразилия',
      'Çekya': 'Чехия',
      'Çin': 'Китай',
      'Danimarka': 'Дания',
      'Endonezya': 'Индонезия',
      'Ermenistan': 'Армения',
      'Etiyopya': 'Эфиопия',
      'Filipinler': 'Филиппины',
      'Finlandiya': 'Финляндия',
      'Fransa': 'Франция',
      'Gana': 'Гана',
      'Güney Afrika': 'Южная Африка',
      'Güney Kore': 'Южная Корея',
      'Gürcistan': 'Грузия',
      'Hindistan': 'Индия',
      'Hırvatistan': 'Хорватия',
      'Hollanda': 'Нидерланды',
      'Irak': 'Ирак',
      'İran': 'Иран',
      'İsrail': 'Израиль',
      'İsveç': 'Швеция',
      'İsviçre': 'Швейцария',
      'İspanya': 'Испания',
      'İtalya': 'Италия',
      'Japonya': 'Япония',
      'Kamboçya': 'Камбоджа',
      'Kanada': 'Канада',
      'Katar': 'Катар',
      'Kenya': 'Кения',
      'Kırgızistan': 'Киргизия',
      'Kuveyt': 'Кувейт',
      'Laos': 'Лаос',
      'Lübnan': 'Ливан',
      'Macaristan': 'Венгрия',
      'Malezya': 'Малайзия',
      'Meksika': 'Мексика',
      'Moğolistan': 'Монголия',
      'Mısır': 'Египет',
      'Myanmar': 'Мьянма',
      'Nepal': 'Непал',
      'Nijerya': 'Нигерия',
      'Norveç': 'Норвегия',
      'Özbekistan': 'Узбекистан',
      'Pakistan': 'Пакистан',
      'Polonya': 'Польша',
      'Portekiz': 'Португалия',
      'Rusya': 'Россия',
      'Singapur': 'Сингапур',
      'Slovakya': 'Словакия',
      'Slovenya': 'Словения',
      'Sri Lanka': 'Шри-Ланка',
      'Sırbistan': 'Сербия',
      'Suudi Arabistan': 'Саудовская Аравия',
      'Suriye': 'Сирия',
      'Tacikistan': 'Таджикистан',
      'Tayland': 'Таиланд',
      'Türkmenistan': 'Туркменистан',
      'Umman': 'Оман',
      'Ürdün': 'Иордания',
      'Vietnam': 'Вьетнам',
      'Yemen': 'Йемен',
      'Yunanistan': 'Греция',
      'Yeni Zelanda': 'Новая Зеландия',
    },
  };

  late final List<FieldConfig> fieldConfigs;
  final Map<String, AnimationController> _animationControllers = {};
  final Map<String, RxDouble> _animationTurns = {};

  String get defaultSelectValue => _selectValue;
  String get turkeyValue => _turkey;
  String get singleValue => _single;
  String get noneValue => _none;
  String get notWorkingValue => _notWorking;
  bool get isTurkeySelected => county.value == _turkey;

  @override
  void onInit() {
    super.onInit();
    loadCitiesAndTowns();
    fetchData();
    _initFieldConfigs();
    _initAnimationControllers();
  }

  String localizedStaticValue(String value) {
    final localizedCountry = localizedCountryValue(value);
    if (localizedCountry != null) return localizedCountry;

    switch (value) {
      case _selectValue:
      case 'Ülke Seç':
      case 'Medeni Hal Seç':
      case 'Cinsiyet Seç':
      case 'Engel Durumu Seç':
      case 'Çalışma Durumu Seç':
      case 'İl Seç':
      case 'İlçe Seç':
        return 'common.select'.tr;
      case _turkey:
        return 'common.country_turkey'.tr;
      case _single:
        return 'personal_info.marital_single'.tr;
      case _married:
        return 'personal_info.marital_married'.tr;
      case _divorced:
        return 'personal_info.marital_divorced'.tr;
      case _male:
        return 'personal_info.gender_male'.tr;
      case _female:
        return 'personal_info.gender_female'.tr;
      case _hasReport:
        return 'personal_info.disability_yes'.tr;
      case _none:
        return 'personal_info.disability_no'.tr;
      case _working:
        return 'personal_info.working_yes'.tr;
      case _notWorking:
        return 'personal_info.working_no'.tr;
      default:
        return value;
    }
  }

  String? localizedCountryValue(String value) {
    if (!countryList.contains(value)) return null;
    final languageCode = Get.locale?.languageCode ?? 'tr';
    return _countryLabels[languageCode]?[value] ?? value;
  }

  String localizedFieldLabel(String label) {
    switch (label) {
      case _countryFieldLabel:
        return 'scholarship.country_label'.tr;
      case _maritalStatusFieldLabel:
        return 'scholarship.applicant.marital_status'.tr;
      case _genderFieldLabel:
        return 'scholarship.applicant.gender'.tr;
      case _disabilityFieldLabel:
        return 'scholarship.applicant.disability_report'.tr;
      case _employmentFieldLabel:
        return 'scholarship.applicant.employment_status'.tr;
      case _cityFieldLabel:
        return 'scholarship.applicant.registry_city'.tr;
      case _districtFieldLabel:
        return 'scholarship.applicant.registry_district'.tr;
      default:
        return label;
    }
  }

  String localizedFieldTitle(String title) {
    switch (title) {
      case _countryFieldTitleKey:
        return 'scholarship.select_country'.tr;
      case _maritalStatusFieldTitleKey:
        return 'personal_info.select_marital_status'.tr;
      case _genderFieldTitleKey:
        return 'personal_info.select_gender'.tr;
      case _disabilityFieldTitleKey:
        return 'personal_info.select_disability'.tr;
      case _employmentFieldTitleKey:
        return 'personal_info.select_employment'.tr;
      case 'İl Seç':
        return 'common.select_city'.tr;
      case 'İlçe Seç':
        return 'common.select_district'.tr;
      default:
        return title.tr;
    }
  }

  String localizedPlaceholder(String label) {
    switch (label) {
      case _countryFieldLabel:
        return 'scholarship.select_country'.tr;
      case _cityFieldLabel:
        return 'common.select_city'.tr;
      case _districtFieldLabel:
        return 'common.select_district'.tr;
      default:
        return 'personal_info.select_field'
            .trParams({'field': localizedFieldLabel(label)});
    }
  }

  void _initFieldConfigs() {
    fieldConfigs = [
      FieldConfig(
        label: _countryFieldLabel,
        title: _countryFieldTitleKey,
        value: county,
        items: countryList,
        onSelect: (val) {
          county.value = val;
          if (val != _turkey) {
            city.value = '';
            town.value = '';
          }
        },
        isSearchable: true,
      ),
      FieldConfig(
        label: _maritalStatusFieldLabel,
        title: _maritalStatusFieldTitleKey,
        value: medeniHal,
        items: medeniHalList,
        onSelect: (val) => medeniHal.value = val,
      ),
      FieldConfig(
        label: _genderFieldLabel,
        title: _genderFieldTitleKey,
        value: cinsiyet,
        items: cinsiyetList,
        onSelect: (val) => cinsiyet.value = val,
      ),
      FieldConfig(
        label: _disabilityFieldLabel,
        title: _disabilityFieldTitleKey,
        value: engelliRaporu,
        items: engelliRaporuList,
        onSelect: (val) => engelliRaporu.value = val,
      ),
      FieldConfig(
        label: _employmentFieldLabel,
        title: _employmentFieldTitleKey,
        value: calismaDurumu,
        items: calismaDurumuList,
        onSelect: (val) => calismaDurumu.value = val,
      ),
    ];
  }

  void _initAnimationControllers() {
    for (var config in fieldConfigs) {
      _animationControllers[config.label] = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 200),
      );
      _animationTurns[config.label] = 0.0.obs;
      _animationControllers[config.label]!.addListener(() {
        _animationTurns[config.label]!.value =
            _animationControllers[config.label]!.value * 0.5;
      });
    }
    // Initialize for city and town dropdowns
    _animationControllers[_cityFieldLabel] = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _animationTurns[_cityFieldLabel] = 0.0.obs;
    _animationControllers[_cityFieldLabel]!.addListener(() {
      _animationTurns[_cityFieldLabel]!.value =
          _animationControllers[_cityFieldLabel]!.value * 0.5;
    });
    _animationControllers[_districtFieldLabel] = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _animationTurns[_districtFieldLabel] = 0.0.obs;
    _animationControllers[_districtFieldLabel]!.addListener(() {
      _animationTurns[_districtFieldLabel]!.value =
          _animationControllers[_districtFieldLabel]!.value * 0.5;
    });
  }

  AnimationController getAnimationController(String label) {
    return _animationControllers[label]!;
  }

  RxDouble getAnimationTurns(String label) {
    return _animationTurns[label]!;
  }

  Future<void> toggleDropdown(BuildContext context, FieldConfig config) async {
    final animationController = _animationControllers[config.label];
    if (animationController == null) return;

    animationController.forward();

    // Use AppBottomSheet for Medeni Hal, Cinsiyet, Engel Durumu, Çalışma Durumu
    if ([
      _maritalStatusFieldLabel,
      _genderFieldLabel,
      _disabilityFieldLabel,
      _employmentFieldLabel,
    ].contains(config.label)) {
      final localizedItems = config.items.map(localizedStaticValue).toList();
      await AppBottomSheet.show(
        context: context,
        items: localizedItems,
        title: localizedFieldTitle(config.title),
        onSelect: (dynamic val) {
          final selectedIndex = localizedItems.indexOf(val as String);
          config.onSelect(
            selectedIndex >= 0 ? config.items[selectedIndex] : val,
          );
        },
        selectedItem: config.value.value.isEmpty
            ? null
            : localizedStaticValue(config.value.value),
        isSearchable: config.isSearchable,
      );
    } else {
      // Use ListBottomSheet for other fields (e.g., Ülke, İl, İlçe)
      final bool useLocalizedLabels = config.label == _countryFieldLabel;
      await ListBottomSheet.show(
        context: context,
        items: config.items,
        title: localizedFieldTitle(config.title),
        onSelect: (dynamic val) => config.onSelect(val as String),
        selectedItem: config.value.value.isEmpty ? null : config.value.value,
        isSearchable: config.isSearchable,
        itemLabelBuilder:
            useLocalizedLabels ? (item) => localizedStaticValue('$item') : null,
        searchTextBuilder:
            useLocalizedLabels ? (item) => localizedStaticValue('$item') : null,
      );
    }

    animationController.reverse();
  }

  @override
  void onClose() {
    for (var controller in _animationControllers.values) {
      controller.dispose();
    }
    _animationControllers.clear();
    _animationTurns.clear();
    super.onClose();
  }

  Future<void> loadCitiesAndTowns() async {
    isLoading.value = true;
    try {
      sehirlerVeIlcelerData.value =
          await _cityDirectoryService.getCitiesAndDistricts();
      sehirler.value = await _cityDirectoryService.getSortedCities();
    } catch (e, stackTrace) {
      print("Şehir ve ilçe verileri yüklenirken hata: $e\n$stackTrace");
      AppSnackbar('common.error'.tr, 'personal_info.city_load_failed'.tr);
    } finally {
      isLoading.value = false;
    }
  }

  void updateCity(String newCity) {
    if (sehirler.contains(newCity)) {
      city.value = newCity;
      town.value = '';
    }
  }

  void updateTown(String newTown) {
    final validTowns = sehirlerVeIlcelerData
        .where((e) => e.il == city.value)
        .map((e) => e.ilce)
        .toList();
    if (validTowns.contains(newTown)) {
      town.value = newTown;
    }
  }

  Future<void> fetchData() async {
    final uid = CurrentUserService.instance.userId;
    if (uid.isEmpty) {
      AppSnackbar('common.error'.tr, 'scholarship.session_missing'.tr);
      isLoading.value = false;
      return;
    }

    try {
      isLoading.value = true;
      final data = await _userRepository.getUserRaw(uid);
      if (data != null) {
        tc.value =
            originalTC.value = userString(data, key: "tc", scope: "profile");
        medeniHal.value = originalMedeniHal.value = userString(
          data,
          key: "medeniHal",
          scope: "profile",
          fallback: _single,
        );
        county.value = originalCounty.value = userString(
          data,
          key: "ulke",
          scope: "profile",
          fallback: _turkey,
        ).trim();
        cinsiyet.value = originalCinsiyet.value = userString(
          data,
          key: "cinsiyet",
          scope: "profile",
          fallback: _selectValue,
        );
        engelliRaporu.value = originalEngelliRaporu.value = userString(
          data,
          key: "engelliRaporu",
          scope: "family",
          fallback: _none,
        );
        calismaDurumu.value = originalCalismaDurumu.value = userString(
          data,
          key: "calismaDurumu",
          scope: "profile",
          fallback: _notWorking,
        );
        city.value = originalCity.value = (county.value == _turkey
            ? userString(data, key: "nufusSehir", scope: "profile")
            : "");
        town.value = originalTown.value = (county.value == _turkey
            ? userString(data, key: "nufusIlce", scope: "profile")
            : "");

        final dateStr = userString(data, key: "dogumTarihi", scope: "profile");
        if (dateStr.isNotEmpty) {
          try {
            selectedDate.value = originalSelectedDate.value = DateFormat(
              "dd.MM.yyyy",
              "tr_TR",
            ).parse(dateStr);
          } catch (e) {
            print("Tarih parse hatası: $e");
            selectedDate.value = originalSelectedDate.value = null;
          }
        } else {
          selectedDate.value = originalSelectedDate.value = null;
        }
      } else {
        AppSnackbar(
          'common.warning'.tr,
          'personal_info.user_data_missing'.tr,
        );
        resetToOriginal();
      }
    } catch (e) {
      print("Veri yüklenirken hata.");
      AppSnackbar('common.error'.tr, 'personal_info.load_failed'.tr);
    } finally {
      isLoading.value = false;
    }
  }

  void resetToOriginal() {
    tc.value = originalTC.value;
    medeniHal.value = originalMedeniHal.value;
    county.value = originalCounty.value;
    cinsiyet.value = originalCinsiyet.value;
    engelliRaporu.value = originalEngelliRaporu.value;
    calismaDurumu.value = originalCalismaDurumu.value;
    city.value = originalCity.value;
    town.value = originalTown.value;
    selectedDate.value = originalSelectedDate.value;
  }

  Future<void> saveData() async {
    final uid = CurrentUserService.instance.userId;
    if (uid.isEmpty) {
      AppSnackbar('common.error'.tr, 'scholarship.session_missing'.tr);
      return;
    }

    if (county.value.isEmpty) {
      AppSnackbar('common.error'.tr, 'personal_info.select_country_error'.tr);
      return;
    }

    if (county.value == _turkey &&
        (city.value.isEmpty || town.value.isEmpty)) {
      AppSnackbar('common.error'.tr, 'personal_info.fill_city_district'.tr);
      return;
    }

    try {
      isSaving.value = true;
      final formattedDate = selectedDate.value != null
          ? DateFormat("dd.MM.yyyy", "tr_TR").format(selectedDate.value!)
          : "";

      await _userRepository.updateUserFields(uid, {
        ...scopedUserUpdate(
          scope: 'family',
          values: {"engelliRaporu": engelliRaporu.value},
        ),
        ...scopedUserUpdate(
          scope: 'profile',
          values: {
            "tc": tc.value,
            "medeniHal": medeniHal.value,
            "ulke": county.value,
            "nufusSehir": county.value == _turkey ? city.value : "",
            "nufusIlce": county.value == _turkey ? town.value : "",
            "cinsiyet": cinsiyet.value,
            "calismaDurumu": calismaDurumu.value,
            "dogumTarihi": formattedDate,
          },
        ),
      });

      originalTC.value = tc.value;
      originalMedeniHal.value = medeniHal.value;
      originalCounty.value = county.value;
      originalCinsiyet.value = cinsiyet.value;
      originalEngelliRaporu.value = engelliRaporu.value;
      originalCalismaDurumu.value = calismaDurumu.value;
      originalCity.value = county.value == _turkey ? city.value : "";
      originalTown.value = county.value == _turkey ? town.value : "";
      originalSelectedDate.value = selectedDate.value;
      Get.back();

      AppSnackbar('common.success'.tr, 'personal_info.saved'.tr);
    } catch (e) {
      print("Veri kaydedilirken hata.");
      AppSnackbar('common.error'.tr, 'personal_info.save_failed'.tr);
    } finally {
      isSaving.value = false;
    }
  }
}
