import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/DenemeGrid/deneme_grid.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/sinav_model.dart';

class MyPracticeExams extends StatelessWidget {
  const MyPracticeExams({super.key});

  SinavModel _fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return SinavModel(
      docID: doc.id,
      cover: (data["cover"] ?? '') as String,
      sinavTuru: (data["sinavTuru"] ?? '') as String,
      timeStamp: (data["timeStamp"] ?? 0) as num,
      sinavAciklama: (data["sinavAciklama"] ?? '') as String,
      sinavAdi: (data["sinavAdi"] ?? '') as String,
      kpssSecilenLisans: (data["kpssSecilenLisans"] ?? '') as String,
      dersler: List<String>.from(data['dersler'] ?? const []),
      userID: (data["userID"] ?? '') as String,
      public: (data["public"] ?? false) as bool,
      taslak: (data["taslak"] ?? false) as bool,
      soruSayilari: List<String>.from(data['soruSayilari'] ?? const []),
      bitis: (data["bitis"] ?? 0) as num,
      bitisDk: (data["bitisDk"] ?? 0) as num,
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    if (uid.isEmpty) {
      return Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            children: const [
              BackButtons(text: "Yayınladıklarım"),
              Expanded(
                child: Center(
                  child: Text(
                    "Kullanıcı oturumu bulunamadı.",
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 15,
                      fontFamily: "MontserratMedium",
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final query = FirebaseFirestore.instance
        .collection("practiceExams")
        .where("userID", isEqualTo: uid);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const BackButtons(text: "Yayınladıklarım"),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: query.snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text(
                        "Sınavlar yüklenemedi.",
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 15,
                          fontFamily: "MontserratMedium",
                        ),
                      ),
                    );
                  }

                  if (!snapshot.hasData) {
                    return const Center(
                      child: CupertinoActivityIndicator(),
                    );
                  }

                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          "Henüz yayınladığınız bir online sınav yok.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 15,
                            fontFamily: "MontserratMedium",
                          ),
                        ),
                      ),
                    );
                  }

                  final exams = docs.map(_fromDoc).toList()
                    ..sort((a, b) => b.timeStamp.compareTo(a.timeStamp));
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: GridView.builder(
                      padding: const EdgeInsets.only(bottom: 20),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 4,
                        mainAxisSpacing: 4,
                        childAspectRatio: 0.49,
                      ),
                      itemCount: exams.length,
                      itemBuilder: (context, index) {
                        return DenemeGrid(
                          model: exams[index],
                          getData: () {},
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
