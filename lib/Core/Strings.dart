import '../Models/report_model.dart';

List<ReportModel> reportSelections = [
  ReportModel(
    key: "impersonation",
    title: "Taklit / Sahte Hesap / Kimlik Kullanımı",
    description:
        "Bu hesap veya içerik, kimlik taklidi, sahte hesap kullanımı ya da başka bir kişiyi izinsiz temsil etme şüphesi taşıyor.",
  ),
  ReportModel(
    key: "copyright",
    title: "Telif / İzinsiz İçerik Kullanımı",
    description:
        "Bu içerik telif hakkıyla korunan materyalleri izinsiz kullanıyor veya fikri mülkiyet ihlali içeriyor olabilir.",
  ),
  ReportModel(
    key: "harassment",
    title: "Taciz / Hedef Gösterme / Zorbalık",
    description:
        "Bu içerik bir kişiyi rahatsız etme, aşağılamaya çalışma, hedef gösterme ya da sistematik zorbalık içeriği taşıyor.",
  ),
  ReportModel(
    key: "hate_speech",
    title: "Nefret Söylemi",
    description:
        "Bu içerik bir gruba veya kişiye karşı nefret, ayrımcılık ya da aşağılayıcı söylem içeriyor.",
  ),
  ReportModel(
    key: "nudity",
    title: "Çıplaklık / Cinsel İçerik",
    description:
        "Bu içerik çıplaklık, müstehcenlik ya da açık cinsel içerik barındırıyor olabilir.",
  ),
  ReportModel(
    key: "violence",
    title: "Şiddet / Tehdit",
    description:
        "Bu içerik fiziksel şiddet, tehdit, korkutma ya da zarar verme çağrısı içeriyor olabilir.",
  ),
  ReportModel(
    key: "spam",
    title: "Spam / Alakasız Tekrar İçerik",
    description:
        "Bu içerik tekrar eden, alakasız, yanıltıcı ya da rahatsız edici biçimde spam niteliği taşıyor.",
  ),
  ReportModel(
    key: "scam",
    title: "Dolandırıcılık / Yanıltma",
    description:
        "Bu içerik para, bilgi ya da güven istismarı amacıyla yanıltıcı veya dolandırıcılık içerikli olabilir.",
  ),
  ReportModel(
    key: "misinformation",
    title: "Yanlış Bilgi / Manipülasyon",
    description:
        "Bu içerik gerçeği çarpıtan, yanlış bilgi yayan ya da manipülatif yönlendirme yapan unsurlar içeriyor olabilir.",
  ),
  ReportModel(
    key: "illegal_content",
    title: "Yasa Dışı İçerik",
    description:
        "Bu içerik yasa dışı faaliyet, suç teşviki ya da hukuka aykırı materyal içeriyor olabilir.",
  ),
  ReportModel(
    key: "child_safety",
    title: "Çocuk Güvenliği İhlali",
    description:
        "Bu içerik çocuk güvenliğini tehlikeye atıyor ya da çocuklara uygun olmayan zararlı unsurlar taşıyor olabilir.",
  ),
  ReportModel(
    key: "self_harm",
    title: "Kendine Zarar Verme / İntihar Teşviki",
    description:
        "Bu içerik kendine zarar verme, intihar teşviki ya da bu yönde yönlendirme içeriyor olabilir.",
  ),
  ReportModel(
    key: "privacy_violation",
    title: "Gizlilik İhlali",
    description:
        "Bu içerik kişisel verilerin izinsiz paylaşımı, doxxing ya da mahremiyet ihlali içeriyor olabilir.",
  ),
  ReportModel(
    key: "fake_engagement",
    title: "Sahte Etkileşim / Bot / Manipülatif Büyütme",
    description:
        "Bu içerik sahte beğeni, bot etkileşimi ya da yapay büyütme amaçlı manipülatif davranış içeriyor olabilir.",
  ),
  ReportModel(
    key: "other",
    title: "Diğer",
    description:
        "Yukarıdaki seçeneklerin dışında kalan, ayrıca incelenmesini istediğiniz başka bir ihlal nedeni bulunuyor.",
  ),
];
