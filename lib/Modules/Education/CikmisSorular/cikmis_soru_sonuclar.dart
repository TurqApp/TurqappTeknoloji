import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/info_message.dart';
import 'package:turqappv2/Core/Repositories/cikmis_sorular_repository.dart';
import 'package:turqappv2/Models/Education/cikmis_soru_sonuc_model.dart';
import 'package:turqappv2/Modules/Education/CikmisSorular/cikmis_sorular_sonuc_content.dart';
import 'package:turqappv2/Utils/empty_padding.dart';

class CikmisSoruSonuclar extends StatefulWidget {
  const CikmisSoruSonuclar({super.key});

  @override
  State<CikmisSoruSonuclar> createState() => _CikmisSoruSonuclarState();
}

class _CikmisSoruSonuclarState extends State<CikmisSoruSonuclar> {
  final CikmisSorularRepository _repository = CikmisSorularRepository.ensure();
  List<CikmisSoruSonucModel> list = [];
  @override
  void initState() {
    super.initState();
    getData();
  }

  Future<void> getData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return;
    final tempList = await _repository.fetchUserResults(uid);
    tempList.sort((a, b) => b.timeStamp.compareTo(a.timeStamp));
    if (mounted) {
      setState(() {
        list = tempList;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: "Sonuçlarım"),
            if (list.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: EdgeInsets.only(top: index == 0 ? 10 : 0),
                      child: Column(
                        children: [
                          CikmisSorularSonucContent(model: list[index]),
                          8.ph,
                        ],
                      ),
                    );
                  },
                ),
              )
            else
              Infomessage(infoMessage: "Her hangi bir sonuç yok"),
          ],
        ),
      ),
    );
  }
}
