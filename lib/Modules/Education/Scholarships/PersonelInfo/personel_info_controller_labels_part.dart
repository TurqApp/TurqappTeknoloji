part of 'personel_info_controller.dart';

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

const String _countryFieldLabel = 'Ülke';
const String _maritalStatusFieldLabel = 'Medeni Hal';
const String _genderFieldLabel = 'Cinsiyet';
const String _disabilityFieldLabel = 'Engel Durumu';
const String _employmentFieldLabel = 'Çalışma Durumu';
const String _cityFieldLabel = 'İl';
const String _districtFieldLabel = 'İlçe';
const String _countryFieldTitleKey = 'personal_info.select_country_title';
const String _maritalStatusFieldTitleKey =
    'personal_info.select_marital_status_title';
const String _genderFieldTitleKey = 'personal_info.select_gender_title';
const String _disabilityFieldTitleKey = 'personal_info.select_disability_title';
const String _employmentFieldTitleKey =
    'personal_info.select_work_status_title';
const String _single = 'Bekar';
const String _married = 'Evli';
const String _divorced = 'Boşanmış';
const String _turkey = 'Türkiye';
const String _selectValue = 'Seçim Yap';
const String _none = 'Yok';
const String _working = 'Çalışıyor';
const String _notWorking = 'Çalışmıyor';
const String _male = 'Erkek';
const String _female = 'Kadın';
const String _hasReport = 'Var';

const List<String> _countryList = [
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

const Map<String, Map<String, String>> _countryLabels = {
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

extension PersonelInfoControllerLabelsPart on PersonelInfoController {
  String get defaultSelectValue => _selectValue;

  String get turkeyValue => _turkey;

  String get singleValue => _single;

  String get noneValue => _none;

  String get notWorkingValue => _notWorking;

  bool get isTurkeySelected => county.value == _turkey;

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
}
