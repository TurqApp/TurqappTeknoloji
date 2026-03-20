import 'package:flutter/cupertino.dart';

class PolicyDocument {
  const PolicyDocument({
    required this.id,
    required this.title,
    required this.summary,
    required this.updatedAt,
    required this.icon,
    required this.sections,
  });

  final String id;
  final String title;
  final String summary;
  final String updatedAt;
  final IconData icon;
  final List<PolicySection> sections;
}

class PolicySection {
  const PolicySection({
    required this.title,
    this.body = const [],
    this.bullets = const [],
  });

  final String title;
  final List<String> body;
  final List<String> bullets;
}

List<PolicyDocument> localizedTurqAppPolicies(String? languageCode) {
  switch (languageCode) {
    case 'en':
      return _englishPolicies;
    case 'de':
      return _germanPolicies;
    default:
      return _turkishPolicies;
  }
}

const List<PolicyDocument> _turkishPolicies = [
  PolicyDocument(
    id: 'agreement',
    title: 'Üyelik ve Sözleşme',
    summary:
        'TurqApp kullanımı, platformun rolü, kullanıcı sorumlulukları, telifler ve yaptırım çerçevesini belirler.',
    updatedAt: '19 Mart 2026',
    icon: CupertinoIcons.doc_plaintext,
    sections: [
      PolicySection(
        title: 'Sözleşmenin Kapsamı',
        body: [
          'Bu sözleşme, TurqApp içindeki sosyal içerik, mesajlaşma, eğitim, burs, özel ders, iş ilanları, başvuru süreçleri, pazar yeri benzeri alanlar ve bunlarla bağlantılı tüm dijital yüzeylerde geçerlidir.',
          'TurqApp kullanılarak hesap açılması, giriş yapılması veya uygulamadaki özelliklerin kullanılması bu metnin kabul edildiği anlamına gelir.',
        ],
      ),
      PolicySection(
        title: 'Platformun Rolü',
        body: [
          'TurqApp, kullanıcılar arasındaki her iletişim, başvuru, iş ilişkisi, ders ilişkisi, burs süreci, ürün devri, ödeme veya teslimatın doğrudan tarafı değildir.',
          'Platform, teknoloji altyapısı ve topluluk güvenliği sağlar; ancak kullanıcıların oluşturduğu her içeriğin, her ilanın veya her vaadin doğruluğunu garanti etmez.',
        ],
      ),
      PolicySection(
        title: 'Kullanıcı Taahhütleri',
        bullets: [
          'Doğru, güncel ve yanıltıcı olmayan bilgi sunmak',
          'Başkasını taklit etmemek',
          'Hukuka aykırı, dolandırıcı veya istismar niteliğindeki kullanımlardan kaçınmak',
          'Platformu topluluğu bozacak, manipüle edecek veya güvenliği zayıflatacak şekilde kullanmamak',
          'Kendi hesabından gerçekleşen işlemlerden sorumlu olmak',
        ],
      ),
      PolicySection(
        title: 'İçerik Sorumluluğu',
        body: [
          'TurqApp içinde paylaşılan metin, görsel, video, belge, yorum, profil alanı, ilan ve benzeri tüm içeriklerden öncelikle içeriği yükleyen kullanıcı sorumludur.',
          'TurqApp, gerekli gördüğünde bu içerikleri inceleyebilir, indeksleyebilir, teknik olarak işleyebilir, görünürlüğünü sınırlayabilir veya kaldırabilir.',
        ],
      ),
      PolicySection(
        title: 'Telif ve Fikri Mülkiyet',
        body: [
          'Kullanıcılar, yükledikleri içerik üzerinde gerekli haklara sahip olduklarını veya bu içeriği paylaşmak için yeterli izne sahip bulunduklarını kabul eder.',
          '5846 sayılı Fikir ve Sanat Eserleri Kanunu başta olmak üzere uygulanabilir fikri mülkiyet mevzuatına aykırı içerikler TurqApp\'te barındırılmamalıdır.',
          'TurqApp markası, arayüzü, tasarım unsurları, yazılım altyapısı, veri organizasyonu, logo, servis akışları ve uygulamaya ait özgün unsurlar TurqApp\'e veya ilgili hak sahiplerine aittir.',
        ],
        bullets: [
          'İzinsiz kopyalama, çoğaltma, yeniden yayımlama veya ticari kullanım yasaktır',
          'Telif ihlali bildirimi alan içerikler geçici veya kalıcı olarak kaldırılabilir',
          'Tekrarlayan ihlaller hesap kısıtlamasına veya kapatmaya yol açabilir',
        ],
      ),
      PolicySection(
        title: 'TurqApp\'e Verilen Lisans',
        body: [
          'Kullanıcı, TurqApp\'te paylaştığı içeriğin hizmetin sunulabilmesi için gerekli olduğu ölçüde depolanmasına, işlenmesine, gösterilmesine, farklı cihaz boyutlarına uyarlanmasına, önizleme veya kısa bağlantı sistemlerinde kullanılmasına ve moderasyon amacıyla incelenmesine izin verir.',
          'Bu izin, içeriğin sahipliğini TurqApp\'e geçirmez; yalnızca hizmetin işleyişi ve güvenliği için gereken teknik kullanım alanlarını kapsar.',
        ],
      ),
      PolicySection(
        title: 'Yaptırım ve Hak Saklı Tutma',
        bullets: [
          'TurqApp içeriği kaldırabilir veya gizleyebilir',
          'Hesap özelliklerini kısıtlayabilir',
          'İlgili kullanıcıyı geçici veya kalıcı olarak platformdan uzaklaştırabilir',
          'Gerekli durumlarda resmî mercilere bildirim yapabilir',
        ],
      ),
      PolicySection(
        title: 'Sorumluluğun Sınırlandırılması',
        body: [
          'TurqApp, mevzuatın izin verdiği en geniş ölçüde; kullanıcılar arası işlemlerden, üçüncü taraf davranışlarından, ilanların sonucundan, iş veya burs kabullerinden, ders ilişkilerinden veya platform dışı görüşmelerden doğan doğrudan ya da dolaylı riskleri tamamen üstlenmez.',
          'Platform, tüm riskleri ortadan kaldıracağını garanti etmez; ancak güvenlik, raporlama ve moderasyon araçlarıyla makul koruma sağlamayı hedefler.',
        ],
      ),
    ],
  ),
  PolicyDocument(
    id: 'privacy',
    title: 'Gizlilik',
    summary:
        'TurqApp içinde hangi bilgilerin oluşabileceğini ve bunların nasıl kullanıldığını açıklar.',
    updatedAt: '19 Mart 2026',
    icon: CupertinoIcons.lock_shield,
    sections: [
      PolicySection(
        title: 'Genel Bakış',
        body: [
          'TurqApp, gizliliği yalnızca teknik bir konu olarak değil, uygulama deneyiminin temel parçalarından biri olarak görür.',
          'Bu politika; sosyal içerik, mesajlaşma, eğitim, burs, özel ders, iş ilanları ve pazar yeri yüzeylerinde ortaya çıkabilecek bilgilerin genel kullanım çerçevesini açıklar.',
        ],
      ),
      PolicySection(
        title: 'Toplanabilecek Bilgiler',
        bullets: [
          'Hesap ve profil bilgileri',
          'Paylaşılan post, hikâye, yorum, mesaj ve diğer içerikler',
          'Burs, özel ders, iş ilanı ve pazar alanlarına girilen bilgiler',
          'Başvurular, değerlendirmeler ve kullanıcı etkileşimleri',
          'Cihaz, uygulama sürümü, hata ve güvenlik kayıtları',
          'İzin verilirse konum, kamera, galeri, bildirim veya rehber verileri',
        ],
      ),
      PolicySection(
        title: 'Bilgileri Neden Kullanırız',
        bullets: [
          'Uygulamayı çalıştırmak ve hesap deneyimini yönetmek',
          'İçerikleri göstermek, sıralamak ve eşleştirmek',
          'Mesajlaşma, başvuru ve ilan akışlarını yürütmek',
          'Güvenlik risklerini, spam\'i ve kötüye kullanımı azaltmak',
          'Destek taleplerini ve kullanıcı raporlarını değerlendirmek',
          'Uygulamayı iyileştirmek ve hataları gidermek',
        ],
      ),
      PolicySection(
        title: 'Mahremiyet',
        body: [
          'TurqApp içinde paylaştığınız bazı içerikler, paylaşıldıkları yüzeyin doğası gereği diğer kullanıcılar tarafından görülebilir.',
          'Raporlanan içerikler, güvenlik riski taşıyan olaylar veya hukuki zorunluluk doğuran durumlar sınırlı incelemeye konu olabilir.',
        ],
      ),
      PolicySection(
        title: 'Seçimleriniz',
        bullets: [
          'Profil bilgilerini güncelleme',
          'Belirli izinleri cihaz ayarlarından yönetme',
          'Bildirim tercihlerini değiştirme',
          'Hesap kapatma veya veri taleplerine ilişkin başvuru yapma',
        ],
      ),
    ],
  ),
  PolicyDocument(
    id: 'notice',
    title: 'Aydınlatma',
    summary:
        'TurqApp kullanılırken hangi veri türlerinin hangi amaçlarla işlenebileceğini genel çerçevede anlatır.',
    updatedAt: '19 Mart 2026',
    icon: CupertinoIcons.doc_text_search,
    sections: [
      PolicySection(
        title: 'Kapsam',
        body: [
          'TurqApp; sosyal paylaşım, eğitim içerikleri, burs ilanları, özel ders ilanları, iş ilanları, başvuru akışları ve mesajlaşma gibi dijital yüzeyleri kapsar.',
          'Bu hizmetler kullanılırken bazı kişisel veriler işlenebilir.',
        ],
      ),
      PolicySection(
        title: 'İşlenebilecek Veri Türleri',
        bullets: [
          'Hesap ve profil bilgileri',
          'İletişim bilgileri',
          'Yüklenen metin, görsel, video ve belgeler',
          'Yorum, mesaj, kaydetme, beğeni ve rapor kayıtları',
          'İlan, başvuru ve değerlendirme bilgileri',
          'Şehir, ilçe ve izin verilirse konum verileri',
          'Cihaz, oturum, hata ve güvenlik logları',
        ],
      ),
      PolicySection(
        title: 'İşleme Amaçları',
        bullets: [
          'Hesapları oluşturmak ve yönetmek',
          'İçerik, ilan, başvuru ve mesajlaşma süreçlerini çalıştırmak',
          'Güvenlik, spam önleme ve kötüye kullanım tespiti yapmak',
          'Rapor ve moderasyon süreçlerini yürütmek',
          'Teknik sorunları gidermek ve performansı iyileştirmek',
          'Hukuki yükümlülükleri yerine getirmek',
        ],
      ),
      PolicySection(
        title: 'Saklama ve Silme',
        body: [
          'Veriler, hizmetin amacı veya uygulanabilir hukuki gereklilikler devam ettiği sürece saklanabilir.',
          'Gerek kalmadığında makul sürede silme, yok etme veya anonimleştirme süreçleri uygulanır.',
        ],
      ),
    ],
  ),
  PolicyDocument(
    id: 'community',
    title: 'Topluluk',
    summary:
        'TurqApp içindeki davranış standartlarını ve kabul edilmeyecek içerik türlerini açıklar.',
    updatedAt: '19 Mart 2026',
    icon: CupertinoIcons.person_2_fill,
    sections: [
      PolicySection(
        title: 'Saygılı Kalın',
        bullets: [
          'Hakaret etmeyin',
          'Tehdit etmeyin',
          'Kişileri aşağılamayın',
          'Hedef gösterme yapmayın',
        ],
      ),
      PolicySection(
        title: 'Düzgün ve Gerçekçi Olun',
        bullets: [
          'Sahte hesap kullanmayın',
          'Başkalarını taklit etmeyin',
          'Yanıltıcı ilan, sahte profil veya sahte referans paylaşmayın',
        ],
      ),
      PolicySection(
        title: 'Güvenliği Tehlikeye Atmayın',
        bullets: [
          'Dolandırıcılık yapmayın',
          'Platform dışı riskli ödemeye zorlamayın',
          'Kullanıcılardan hassas bilgi toplamaya çalışmayın',
          'Özel bilgileri izinsiz yaymayın',
        ],
      ),
      PolicySection(
        title: 'Çocuk Güvenliği',
        body: [
          'Reşit olmayan kullanıcıları hedef alan uygunsuz iletişim, manipülasyon, cinsel içerik, buluşma baskısı veya sömürü niteliğindeki her davranış kesin olarak yasaktır.',
        ],
      ),
    ],
  ),
  PolicyDocument(
    id: 'moderation',
    title: 'Güvenlik ve Moderasyon',
    summary:
        'TurqApp\'in rapor, güvenlik sinyali ve ihlal durumlarında nasıl müdahale edebileceğini açıklar.',
    updatedAt: '19 Mart 2026',
    icon: CupertinoIcons.shield_lefthalf_fill,
    sections: [
      PolicySection(
        title: 'Neleri İnceleyebiliriz',
        bullets: [
          'Postlar ve hikayeler',
          'Yorumlar',
          'Profil alanları',
          'Burs, özel ders, iş ilanı ve pazar yeri içerikleri',
          'Mesajlaşma ve başvuru ekleri',
          'Görseller, videolar ve belgeler',
        ],
      ),
      PolicySection(
        title: 'Moderasyon Kaynakları',
        bullets: [
          'Kullanıcı raporları',
          'Otomatik güvenlik kontrolleri',
          'Spam veya suistimal sinyalleri',
          'Uygunsuz görsel veya medya tespiti',
          'Tekrar eden ihlal geçmişi',
        ],
      ),
      PolicySection(
        title: 'Hızlı Müdahale Alanları',
        bullets: [
          'Çocuk güvenliği riski',
          'Cinsel istismar veya sömürü',
          'Şiddet tehdidi',
          'Dolandırıcılık ve sahte ilan',
          'Özel bilgilerin ifşası',
          'Ağır taciz ve toplu hedef gösterme',
        ],
      ),
      PolicySection(
        title: 'Uygulanabilecek Aksiyonlar',
        bullets: [
          'Uyarı verilmesi',
          'İçeriğin kaldırılması',
          'İçeriğin geçici olarak gizlenmesi',
          'Hesap özelliklerinin kısıtlanması',
          'Geçici askı',
          'Kalıcı hesap kapatma',
        ],
      ),
    ],
  ),
];

const List<PolicyDocument> _englishPolicies = [
  PolicyDocument(
    id: 'agreement',
    title: 'Membership and Agreement',
    summary:
        'Defines TurqApp usage, the platform’s role, user responsibilities, copyright, and enforcement framework.',
    updatedAt: '19 March 2026',
    icon: CupertinoIcons.doc_plaintext,
    sections: [
      PolicySection(
        title: 'Scope of the Agreement',
        body: [
          'This agreement applies to social content, messaging, education, scholarships, tutoring, job listings, application processes, marketplace-like areas, and all connected digital surfaces within TurqApp.',
          'Creating an account, signing in, or using features within TurqApp means this text is accepted.',
        ],
      ),
      PolicySection(
        title: 'Role of the Platform',
        body: [
          'TurqApp is not the direct party to communications, applications, employment relationships, tutoring relationships, scholarship processes, product transfers, payments, or deliveries between users.',
          'The platform provides technology infrastructure and community safety, but does not guarantee the accuracy of every piece of user-generated content, listing, or promise.',
        ],
      ),
      PolicySection(
        title: 'User Commitments',
        bullets: [
          'Provide accurate, up-to-date, and non-misleading information',
          'Do not impersonate others',
          'Avoid unlawful, fraudulent, or exploitative use',
          'Do not use the platform in ways that disrupt the community, manipulate systems, or weaken safety',
          'Remain responsible for actions carried out through your account',
        ],
      ),
      PolicySection(
        title: 'Content Responsibility',
        body: [
          'The user who uploads text, images, videos, documents, comments, profile fields, listings, and similar content in TurqApp is primarily responsible for that content.',
          'TurqApp may review, index, technically process, limit the visibility of, or remove such content when necessary.',
        ],
      ),
      PolicySection(
        title: 'Copyright and Intellectual Property',
        body: [
          'Users agree that they hold the necessary rights to the content they upload or that they have sufficient permission to share it.',
          'Content that violates applicable intellectual property laws, including copyright legislation, must not be hosted on TurqApp.',
          'The TurqApp brand, interface, design elements, software infrastructure, data organization, logo, service flows, and original application elements belong to TurqApp or the relevant rights holders.',
        ],
        bullets: [
          'Unauthorized copying, reproduction, republication, or commercial use is prohibited',
          'Content subject to copyright notices may be removed temporarily or permanently',
          'Repeated violations may lead to account restrictions or closure',
        ],
      ),
      PolicySection(
        title: 'License Granted to TurqApp',
        body: [
          'The user allows content shared on TurqApp to be stored, processed, displayed, adapted to different device sizes, used in previews or short-link systems, and reviewed for moderation purposes to the extent necessary to provide the service.',
          'This permission does not transfer ownership of the content to TurqApp; it only covers technical uses needed for service operation and safety.',
        ],
      ),
      PolicySection(
        title: 'Enforcement and Reservation of Rights',
        bullets: [
          'TurqApp may remove or hide content',
          'TurqApp may restrict account features',
          'TurqApp may temporarily or permanently remove a user from the platform',
          'TurqApp may notify official authorities when required',
        ],
      ),
      PolicySection(
        title: 'Limitation of Liability',
        body: [
          'To the fullest extent permitted by law, TurqApp does not fully assume direct or indirect risks arising from transactions between users, third-party behavior, listing outcomes, job or scholarship acceptances, tutoring relationships, or off-platform discussions.',
          'The platform does not guarantee that all risks will be eliminated; however, it aims to provide reasonable protection through safety, reporting, and moderation tools.',
        ],
      ),
    ],
  ),
  PolicyDocument(
    id: 'privacy',
    title: 'Privacy',
    summary:
        'Explains what kinds of information may arise within TurqApp and how they may be used.',
    updatedAt: '19 March 2026',
    icon: CupertinoIcons.lock_shield,
    sections: [
      PolicySection(
        title: 'Overview',
        body: [
          'TurqApp sees privacy not only as a technical issue, but as a core part of the app experience.',
          'This policy outlines the general use of information that may arise across social content, messaging, education, scholarships, tutoring, job listings, and marketplace surfaces.',
        ],
      ),
      PolicySection(
        title: 'Information That May Be Collected',
        bullets: [
          'Account and profile information',
          'Shared posts, stories, comments, messages, and other content',
          'Information entered into scholarship, tutoring, job listing, and marketplace areas',
          'Applications, reviews, and user interaction records',
          'Device, app version, error, and security records',
          'Location, camera, gallery, notifications, or contacts data when permission is granted',
        ],
      ),
      PolicySection(
        title: 'Why We Use Information',
        bullets: [
          'To operate the app and manage the account experience',
          'To display, rank, and match content',
          'To run messaging, application, and listing flows',
          'To reduce safety risks, spam, and abuse',
          'To review support requests and user reports',
          'To improve the app and fix problems',
        ],
      ),
      PolicySection(
        title: 'Privacy Expectations',
        body: [
          'Some content you share on TurqApp may be visible to other users by the nature of the surface where it is posted.',
          'Reported content, safety-risk incidents, or situations involving legal obligations may be subject to limited review.',
        ],
      ),
      PolicySection(
        title: 'Your Choices',
        bullets: [
          'Update profile information',
          'Manage certain permissions from device settings',
          'Change notification preferences',
          'Submit account closure or data-related requests',
        ],
      ),
    ],
  ),
  PolicyDocument(
    id: 'notice',
    title: 'Privacy Notice',
    summary:
        'Outlines, at a general level, which categories of data may be processed while using TurqApp and for what purposes.',
    updatedAt: '19 March 2026',
    icon: CupertinoIcons.doc_text_search,
    sections: [
      PolicySection(
        title: 'Scope',
        body: [
          'TurqApp covers digital surfaces such as social sharing, educational content, scholarship listings, tutoring listings, job listings, application flows, and messaging.',
          'Certain personal data may be processed while these services are used.',
        ],
      ),
      PolicySection(
        title: 'Categories of Data That May Be Processed',
        bullets: [
          'Account and profile information',
          'Contact information',
          'Uploaded text, images, videos, and documents',
          'Comments, messages, saves, likes, and report records',
          'Listing, application, and review information',
          'City, district, and, when allowed, location data',
          'Device, session, error, and security logs',
        ],
      ),
      PolicySection(
        title: 'Purposes of Processing',
        bullets: [
          'To create and manage accounts',
          'To operate content, listings, applications, and messaging flows',
          'To perform security, spam prevention, and abuse detection',
          'To run reporting and moderation processes',
          'To resolve technical issues and improve performance',
          'To comply with legal obligations',
        ],
      ),
      PolicySection(
        title: 'Retention and Deletion',
        body: [
          'Data may be retained as long as the service purpose continues or applicable legal requirements remain in effect.',
          'When no longer needed, deletion, destruction, or anonymization processes are applied within a reasonable time.',
        ],
      ),
    ],
  ),
  PolicyDocument(
    id: 'community',
    title: 'Community',
    summary:
        'Explains behavior standards within TurqApp and the types of content that will not be accepted.',
    updatedAt: '19 March 2026',
    icon: CupertinoIcons.person_2_fill,
    sections: [
      PolicySection(
        title: 'Be Respectful',
        bullets: [
          'Do not insult others',
          'Do not threaten others',
          'Do not humiliate people',
          'Do not target individuals or encourage dogpiling',
        ],
      ),
      PolicySection(
        title: 'Be Honest and Realistic',
        bullets: [
          'Do not use fake accounts',
          'Do not impersonate others',
          'Do not share misleading listings, fake profiles, or false references',
        ],
      ),
      PolicySection(
        title: 'Do Not Endanger Safety',
        bullets: [
          'Do not commit fraud',
          'Do not force risky off-platform payments',
          'Do not attempt to collect sensitive information from users',
          'Do not expose private information without consent',
        ],
      ),
      PolicySection(
        title: 'Child Safety',
        body: [
          'Any behavior targeting minors involving inappropriate communication, manipulation, sexual content, pressure to meet, or exploitation is strictly prohibited.',
        ],
      ),
    ],
  ),
  PolicyDocument(
    id: 'moderation',
    title: 'Safety and Moderation',
    summary:
        'Explains how TurqApp may respond to reports, security signals, and violations.',
    updatedAt: '19 March 2026',
    icon: CupertinoIcons.shield_lefthalf_fill,
    sections: [
      PolicySection(
        title: 'What We May Review',
        bullets: [
          'Posts and stories',
          'Comments',
          'Profile fields',
          'Scholarship, tutoring, job listing, and marketplace content',
          'Messaging and application attachments',
          'Images, videos, and documents',
        ],
      ),
      PolicySection(
        title: 'Moderation Sources',
        bullets: [
          'User reports',
          'Automated safety checks',
          'Spam or abuse signals',
          'Inappropriate visual or media detection',
          'Repeated violation history',
        ],
      ),
      PolicySection(
        title: 'Rapid Intervention Areas',
        bullets: [
          'Child safety risks',
          'Sexual abuse or exploitation',
          'Threats of violence',
          'Fraud and fake listings',
          'Disclosure of private information',
          'Severe harassment and coordinated targeting',
        ],
      ),
      PolicySection(
        title: 'Possible Actions',
        bullets: [
          'Issuing a warning',
          'Removing content',
          'Temporarily hiding content',
          'Restricting account features',
          'Temporary suspension',
          'Permanent account closure',
        ],
      ),
    ],
  ),
];

const List<PolicyDocument> _germanPolicies = [
  PolicyDocument(
    id: 'agreement',
    title: 'Mitgliedschaft und Vereinbarung',
    summary:
        'Definiert die Nutzung von TurqApp, die Rolle der Plattform, Nutzerpflichten, Urheberrechte und den Sanktionsrahmen.',
    updatedAt: '19. März 2026',
    icon: CupertinoIcons.doc_plaintext,
    sections: [
      PolicySection(
        title: 'Umfang der Vereinbarung',
        body: [
          'Diese Vereinbarung gilt für soziale Inhalte, Nachrichten, Bildung, Stipendien, Nachhilfe, Stellenanzeigen, Bewerbungsprozesse, marktplatzähnliche Bereiche und alle damit verbundenen digitalen Oberflächen innerhalb von TurqApp.',
          'Das Erstellen eines Kontos, die Anmeldung oder die Nutzung von Funktionen in TurqApp bedeutet, dass dieser Text akzeptiert wird.',
        ],
      ),
      PolicySection(
        title: 'Rolle der Plattform',
        body: [
          'TurqApp ist nicht unmittelbare Vertragspartei für Kommunikation, Bewerbungen, Arbeitsverhältnisse, Nachhilfeverhältnisse, Stipendienprozesse, Produktübertragungen, Zahlungen oder Lieferungen zwischen Nutzern.',
          'Die Plattform stellt technische Infrastruktur und Community-Sicherheit bereit, garantiert jedoch nicht die Richtigkeit jedes nutzergenerierten Inhalts, jeder Anzeige oder jedes Versprechens.',
        ],
      ),
      PolicySection(
        title: 'Verpflichtungen der Nutzer',
        bullets: [
          'Genaue, aktuelle und nicht irreführende Informationen bereitstellen',
          'Andere nicht imitieren',
          'Rechtswidrige, betrügerische oder ausbeuterische Nutzung vermeiden',
          'Die Plattform nicht so nutzen, dass die Community gestört, Systeme manipuliert oder Sicherheit geschwächt wird',
          'Für Aktivitäten verantwortlich bleiben, die über das eigene Konto erfolgen',
        ],
      ),
      PolicySection(
        title: 'Verantwortung für Inhalte',
        body: [
          'Für Texte, Bilder, Videos, Dokumente, Kommentare, Profilfelder, Anzeigen und ähnliche Inhalte in TurqApp ist in erster Linie der hochladende Nutzer verantwortlich.',
          'TurqApp kann solche Inhalte bei Bedarf prüfen, indexieren, technisch verarbeiten, in ihrer Sichtbarkeit einschränken oder entfernen.',
        ],
      ),
      PolicySection(
        title: 'Urheberrecht und geistiges Eigentum',
        body: [
          'Nutzer erklären, dass sie über die erforderlichen Rechte an hochgeladenen Inhalten verfügen oder ausreichende Berechtigungen zur Freigabe besitzen.',
          'Inhalte, die gegen geltendes Recht zum geistigen Eigentum verstoßen, dürfen nicht auf TurqApp gehostet werden.',
          'Die Marke TurqApp, die Oberfläche, Designelemente, Softwareinfrastruktur, Datenorganisation, das Logo, Serviceabläufe und originale Anwendungselemente gehören TurqApp oder den jeweiligen Rechteinhabern.',
        ],
        bullets: [
          'Unerlaubtes Kopieren, Vervielfältigen, erneutes Veröffentlichen oder kommerzielle Nutzung ist untersagt',
          'Inhalte mit Urheberrechtsverletzungen können vorübergehend oder dauerhaft entfernt werden',
          'Wiederholte Verstöße können zu Kontobeschränkungen oder Schließung führen',
        ],
      ),
      PolicySection(
        title: 'TurqApp erteilte Lizenz',
        body: [
          'Der Nutzer erlaubt, dass auf TurqApp geteilte Inhalte soweit gespeichert, verarbeitet, angezeigt, an verschiedene Gerätegrößen angepasst, in Vorschauen oder Kurzlink-Systemen genutzt und zu Moderationszwecken überprüft werden, wie es für die Bereitstellung des Dienstes erforderlich ist.',
          'Diese Erlaubnis überträgt das Eigentum am Inhalt nicht auf TurqApp; sie umfasst nur technische Nutzungen, die für Betrieb und Sicherheit erforderlich sind.',
        ],
      ),
      PolicySection(
        title: 'Durchsetzung und Rechtevorbehalt',
        bullets: [
          'TurqApp kann Inhalte entfernen oder ausblenden',
          'TurqApp kann Kontofunktionen einschränken',
          'TurqApp kann Nutzer vorübergehend oder dauerhaft von der Plattform ausschließen',
          'TurqApp kann bei Bedarf Behörden informieren',
        ],
      ),
      PolicySection(
        title: 'Haftungsbeschränkung',
        body: [
          'Soweit gesetzlich zulässig, übernimmt TurqApp direkte oder indirekte Risiken aus Transaktionen zwischen Nutzern, Verhalten Dritter, Ergebnissen von Anzeigen, Job- oder Stipendienzusagen, Nachhilfebeziehungen oder Gesprächen außerhalb der Plattform nicht vollständig.',
          'Die Plattform garantiert nicht, dass alle Risiken beseitigt werden; sie will jedoch durch Sicherheits-, Melde- und Moderationstools angemessenen Schutz bieten.',
        ],
      ),
    ],
  ),
  PolicyDocument(
    id: 'privacy',
    title: 'Datenschutz',
    summary:
        'Erklärt, welche Arten von Informationen innerhalb von TurqApp entstehen können und wie sie verwendet werden können.',
    updatedAt: '19. März 2026',
    icon: CupertinoIcons.lock_shield,
    sections: [
      PolicySection(
        title: 'Überblick',
        body: [
          'TurqApp betrachtet Datenschutz nicht nur als technisches Thema, sondern als zentralen Bestandteil des App-Erlebnisses.',
          'Diese Richtlinie beschreibt die allgemeine Nutzung von Informationen, die in sozialen Inhalten, Nachrichten, Bildung, Stipendien, Nachhilfe, Stellenanzeigen und Marktplatzoberflächen entstehen können.',
        ],
      ),
      PolicySection(
        title: 'Welche Informationen erhoben werden können',
        bullets: [
          'Konto- und Profilinformationen',
          'Geteilte Beiträge, Storys, Kommentare, Nachrichten und andere Inhalte',
          'Informationen aus Stipendien-, Nachhilfe-, Stellen- und Marktplatzbereichen',
          'Bewerbungen, Bewertungen und Interaktionsdaten',
          'Geräte-, App-Version-, Fehler- und Sicherheitsdaten',
          'Standort-, Kamera-, Galerie-, Benachrichtigungs- oder Kontaktdaten bei erteilter Berechtigung',
        ],
      ),
      PolicySection(
        title: 'Warum wir Informationen verwenden',
        bullets: [
          'Um die App zu betreiben und das Kontoerlebnis zu verwalten',
          'Um Inhalte anzuzeigen, zu sortieren und zuzuordnen',
          'Um Nachrichten-, Bewerbungs- und Anzeigenabläufe auszuführen',
          'Um Sicherheitsrisiken, Spam und Missbrauch zu verringern',
          'Um Supportanfragen und Nutzerberichte zu prüfen',
          'Um die App zu verbessern und Probleme zu beheben',
        ],
      ),
      PolicySection(
        title: 'Datenschutz-Erwartungen',
        body: [
          'Einige Inhalte, die du auf TurqApp teilst, können aufgrund der Art der Oberfläche für andere Nutzer sichtbar sein.',
          'Gemeldete Inhalte, sicherheitsrelevante Vorfälle oder Situationen mit rechtlichen Verpflichtungen können eingeschränkt überprüft werden.',
        ],
      ),
      PolicySection(
        title: 'Deine Wahlmöglichkeiten',
        bullets: [
          'Profilinformationen aktualisieren',
          'Bestimmte Berechtigungen in den Geräteeinstellungen verwalten',
          'Benachrichtigungseinstellungen ändern',
          'Anfragen zu Kontolöschung oder Daten stellen',
        ],
      ),
    ],
  ),
  PolicyDocument(
    id: 'notice',
    title: 'Datenschutzhinweis',
    summary:
        'Beschreibt auf allgemeiner Ebene, welche Datenkategorien bei der Nutzung von TurqApp verarbeitet werden können und zu welchen Zwecken.',
    updatedAt: '19. März 2026',
    icon: CupertinoIcons.doc_text_search,
    sections: [
      PolicySection(
        title: 'Umfang',
        body: [
          'TurqApp umfasst digitale Oberflächen wie soziales Teilen, Bildungsinhalte, Stipendienanzeigen, Nachhilfeanzeigen, Stellenanzeigen, Bewerbungsabläufe und Nachrichten.',
          'Bei der Nutzung dieser Dienste können bestimmte personenbezogene Daten verarbeitet werden.',
        ],
      ),
      PolicySection(
        title: 'Kategorien verarbeitbarer Daten',
        bullets: [
          'Konto- und Profilinformationen',
          'Kontaktdaten',
          'Hochgeladene Texte, Bilder, Videos und Dokumente',
          'Kommentare, Nachrichten, Speicherungen, Likes und Meldedaten',
          'Anzeigen-, Bewerbungs- und Bewertungsinformationen',
          'Stadt-, Bezirks- und – sofern erlaubt – Standortdaten',
          'Geräte-, Sitzungs-, Fehler- und Sicherheitsprotokolle',
        ],
      ),
      PolicySection(
        title: 'Zwecke der Verarbeitung',
        bullets: [
          'Konten erstellen und verwalten',
          'Inhalte, Anzeigen, Bewerbungen und Nachrichtenabläufe betreiben',
          'Sicherheit, Spam-Prävention und Missbrauchserkennung durchführen',
          'Melde- und Moderationsprozesse ausführen',
          'Technische Probleme beheben und Leistung verbessern',
          'Rechtliche Verpflichtungen erfüllen',
        ],
      ),
      PolicySection(
        title: 'Speicherung und Löschung',
        body: [
          'Daten können gespeichert werden, solange der Zweck des Dienstes besteht oder geltende rechtliche Anforderungen fortbestehen.',
          'Wenn sie nicht mehr benötigt werden, werden Lösch-, Vernichtungs- oder Anonymisierungsprozesse innerhalb angemessener Frist angewandt.',
        ],
      ),
    ],
  ),
  PolicyDocument(
    id: 'community',
    title: 'Community',
    summary:
        'Erklärt die Verhaltensstandards innerhalb von TurqApp und die Arten von Inhalten, die nicht akzeptiert werden.',
    updatedAt: '19. März 2026',
    icon: CupertinoIcons.person_2_fill,
    sections: [
      PolicySection(
        title: 'Bleib respektvoll',
        bullets: [
          'Beleidige niemanden',
          'Droh niemandem',
          'Demütige keine Personen',
          'Stelle niemanden an den Pranger oder initiiere gezielte Angriffe',
        ],
      ),
      PolicySection(
        title: 'Sei ehrlich und realistisch',
        bullets: [
          'Nutze keine Fake-Konten',
          'Imitiere keine anderen Personen',
          'Teile keine irreführenden Anzeigen, Fake-Profile oder falschen Referenzen',
        ],
      ),
      PolicySection(
        title: 'Gefährde keine Sicherheit',
        bullets: [
          'Begehe keinen Betrug',
          'Dränge niemanden zu riskanten Zahlungen außerhalb der Plattform',
          'Versuche nicht, sensible Informationen von Nutzern zu sammeln',
          'Veröffentliche keine privaten Informationen ohne Zustimmung',
        ],
      ),
      PolicySection(
        title: 'Kinderschutz',
        body: [
          'Jedes Verhalten gegenüber Minderjährigen, das unangemessene Kommunikation, Manipulation, sexuelle Inhalte, Druck zu Treffen oder Ausbeutung beinhaltet, ist strikt verboten.',
        ],
      ),
    ],
  ),
  PolicyDocument(
    id: 'moderation',
    title: 'Sicherheit und Moderation',
    summary:
        'Erklärt, wie TurqApp auf Meldungen, Sicherheitssignale und Verstöße reagieren kann.',
    updatedAt: '19. März 2026',
    icon: CupertinoIcons.shield_lefthalf_fill,
    sections: [
      PolicySection(
        title: 'Was wir prüfen können',
        bullets: [
          'Beiträge und Storys',
          'Kommentare',
          'Profilfelder',
          'Stipendien-, Nachhilfe-, Stellen- und Marktplatzinhalte',
          'Nachrichten und Bewerbungsanhänge',
          'Bilder, Videos und Dokumente',
        ],
      ),
      PolicySection(
        title: 'Quellen der Moderation',
        bullets: [
          'Nutzermeldungen',
          'Automatisierte Sicherheitsprüfungen',
          'Spam- oder Missbrauchssignale',
          'Erkennung unangemessener Bilder oder Medien',
          'Wiederholte Verstoßhistorie',
        ],
      ),
      PolicySection(
        title: 'Bereiche schneller Intervention',
        bullets: [
          'Risiken für die Sicherheit von Kindern',
          'Sexueller Missbrauch oder Ausbeutung',
          'Gewaltdrohungen',
          'Betrug und Fake-Anzeigen',
          'Offenlegung privater Informationen',
          'Schwere Belästigung und koordinierte Angriffe',
        ],
      ),
      PolicySection(
        title: 'Mögliche Maßnahmen',
        bullets: [
          'Verwarnung aussprechen',
          'Inhalte entfernen',
          'Inhalte vorübergehend ausblenden',
          'Kontofunktionen einschränken',
          'Vorübergehende Sperre',
          'Dauerhafte Kontoschließung',
        ],
      ),
    ],
  ),
];
