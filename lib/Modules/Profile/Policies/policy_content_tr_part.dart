part of 'policy_content.dart';

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
