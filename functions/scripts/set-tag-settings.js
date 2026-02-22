const admin = require("firebase-admin");
const fs = require("fs");
const path = require("path");

try {
  admin.initializeApp({
    projectId: "turqappteknoloji",
  });
} catch (err) {}

const fallbackStopwords = [
  "ve","veya","ya","ya da","ile","ama","fakat","lakin","ancak","çünkü","zira",
  "madem","halbuki","oysa","oysa ki","dahi","ki","de","da","mi","mı","mu","mü",
  "sanki","gibi","kadar","rağmen","üzere","için","dolayı","ötürü","hakkında",
  "göre","karşı","tarafından","arasında","içinde","dışında","üstünde",
  "altında","yanında","önünde","arkasında","üzerinden","altından","içerden",
  "dışarı","içeri","burada","şurada","orada","burası","şurası","orası",
  "buna","şuna","ona","bunu","şunu","onu","benden","senden","ondan","bizden",
  "sizden","onlardan","ben","sen","o","biz","siz","onlar","benim","senin",
  "onun","bizim","sizin","onların","kendim","kendin","kendisi","kendimiz",
  "kendiniz","kendileri",
  "bir","birkaç","birçok","bazı","bazıları","tümü","her","hiç","hepsi","çoğu",
  "çok","az","daha","en","pek","bayağı","epey","fazla","eksik","tam",
  "şey","şeyler","kim","kimi","kime","kimse","kimin","ne","neyi","neyse",
  "nerde","nerede","nereye","nerden","neden","nasıl","niye","hangi","hangisi",
  "hangileri","kaç","kaçıncı",
  "bu","şu","o","böyle","şöyle","öyle","diğer","öteki","başka","herhangi",
  "hiçbir","kimi","kimisi","kimileri","birisi","birileri",
  "var","yok","vardı","yoktu","oldu","olmadı","olur","olmaz","oluyor",
  "olacak","olabilir","olmalı","olması","olduğunu","olduğum","olduğun",
  "olduğunda","olduğuna","olduğunu","olduğuyla",
  "yap","yapma","yapıyor","yapılır","yapıldı","yapacak","yapmış","yapmışsın",
  "et","etme","ediyor","edilir","edildi","edecek","etmiş",
  "ol","olma","oluyor","oldu","olacak","olmuş",
  "git","gel","kal","yür","dur","bak","gör","duy","bil","iste","al","ver",
  "de","dedi","demiş","diye","söyle","söyledi","söyledim","söyledin",
  "başla","bitir","geç","kal","çık","in","yakın","uzak",
  "gün","yıl","ay","saat","dakika","saniye","zaman",
  "bugün","yarın","dün","şimdi","sonra","önce","yakında","az önce",
  "herkes","kimse","hiçkimse","tüm","tümüyle","tamamen",
  "evet","hayır","belki","galiba","bence","sence","bize","size","ona",
  "nedeniyle","sayesinde","vasıtasıyla","aracılığıyla",
  "birlikte","ayrıca","özellikle","genelde","genellikle","çoğunlukla",
  "bazen","sık sık","nadiren","kimi zaman",
  "ileti","mesaj","yorum","gönderi","paylaşım",
  "kimseye","kimseden","kimlerle",
  "kendine","kendinden","kendince","kendilerine",
  "başkası","başkaları","başkasına","başkalarına",
  "böylesi","şöylesi","öylesi",
  "çokça","azıcık","biraz","hayli",
  "şart","şartıyla","koşul","koşuluyla",
  "mutlaka","kesinlikle","elbet","elbette",
  "aslında","normalde","çoğu zaman",
  "belirli","belirsiz","belli",
  "söz","sözü","sözler","sözleri",
  "dost","dostum","dostlar","insan","insanlar"
];

const fallbackSuffixes = ["lar", "ler", "dir", "dır"];
const fallbackBanned = [];

let stopwords = fallbackStopwords;
const stopwordsPath = path.join(__dirname, "stopwords_tr_500.json");
try {
  if (fs.existsSync(stopwordsPath)) {
    const parsed = JSON.parse(fs.readFileSync(stopwordsPath, "utf8"));
    if (Array.isArray(parsed) && parsed.length > 0) {
      stopwords = parsed;
    }
  }
} catch (err) {
  console.warn("Failed to load stopwords_tr_500.json, using fallback list.", err);
}

async function main() {
  const db = admin.firestore();
  await db.doc("adminConfig/tagSettings").set(
    {
      trendThreshold: 5,
      trendWindowHours: 24,
      tagMinLength: 3,
      tagMaxLength: 20,
      maxTags: 8,
      suffixes: fallbackSuffixes,
      bannedWords: fallbackBanned,
      enableBigrams: false,
      bigram: {
        minScore: 2,
        joinChar: "_",
        allowList: [],
        denyList: [],
      },
      stopwords,
    },
    { merge: true }
  );
  console.log("adminConfig/tagSettings updated");
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
