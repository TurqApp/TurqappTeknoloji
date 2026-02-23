import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';

import '../../../Core/external.dart';
import '../../../Services/phone_account_limiter.dart';
import '../../../Core/functions.dart';
import '../../SignIn/sign_in.dart';

class DeleteAccount extends StatefulWidget {
  const DeleteAccount({super.key});

  @override
  State<DeleteAccount> createState() => _DeleteAccountState();
}

class _DeleteAccountState extends State<DeleteAccount> {
  TextEditingController inputcode = TextEditingController();
  int color = 0xFF000000;
  String phoneNumber = "";
  String email = "";
  String sifre = "";
  int randomCode = Random().nextInt(90000) + 10000;
  bool sent = false;
  @override
  void initState() {
    super.initState();
    FirebaseFirestore.instance
        .collection("users")
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .snapshots()
        .listen((DocumentSnapshot doc) {
      String phone = doc.get("phoneNumber");
      String email = doc.get("email");
      String sifre = doc.get("sifre");
      setState(() {
        phoneNumber = phone;
        this.email = email;
        this.sifre = sifre;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(15),
              child: Row(
                children: [BackButtons(text: "Hesabını Sil")],
              ),
            ),
            Expanded(
              child: Container(
                color: Colors.white,
                child: ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        "Biz, burada sizinle bir bağ kurduk ve bu bağın bir kopuşu her zaman zor olacaktır. Sizin deneyiminizden memnuniyet duymak ve ihtiyaçlarınıza en iyi şekilde cevap vermek bizim önceliğimizdir.",
                        textAlign: TextAlign.start,
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontFamily: "MontserratMedium"),
                      ),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.03),
                            borderRadius:
                                BorderRadius.all(Radius.circular(12))),
                        child: Padding(
                          padding: EdgeInsets.all(15),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info,
                                size: 20,
                                color: Color(color),
                              ),
                              SizedBox(
                                width: 12,
                              ),
                              Flexible(
                                child: Text(
                                  "Telefon numarana bir doğrulama kodu göndereceğiz",
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 15,
                                      fontFamily: "Montserrat"),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.03),
                            borderRadius:
                                BorderRadius.all(Radius.circular(12))),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: Row(
                            children: [
                              Flexible(
                                child: TextField(
                                  controller: inputcode,
                                  keyboardType: TextInputType.phone,
                                  inputFormatters: [
                                    LengthLimitingTextInputFormatter(5),
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'[0-9]')),
                                  ],
                                  decoration: InputDecoration(
                                      hintText: "Doğrulama Kodu",
                                      hintStyle: TextStyle(
                                          color: Colors.grey,
                                          fontFamily: "Montserrat"),
                                      border: InputBorder.none),
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 15,
                                      fontFamily: "Montserrat"),
                                ),
                              ),
                              if (!sent)
                                GestureDetector(
                                  onTap: () {
                                    sendRequestForDelete(
                                        "$randomCode", phoneNumber);
                                    setState(() {
                                      sent = !sent;
                                    });
                                    showAlertDialog(context, "Kod Gönderildi!",
                                        "Mesaj kutunuza düşen doğrulama kodunu giriniz");
                                  },
                                  child: Text(
                                    "Kod Gönder",
                                    style: TextStyle(
                                        color: Color(color),
                                        fontSize: 15,
                                        fontFamily: "Montserrat"),
                                  ),
                                )
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: GestureDetector(
                        onTap: () {
                          if ("$randomCode" == inputcode.text) {
                            _reauthenticateAndDeleteAccount(context);
                          } else {
                            showAlertDialog(context, "Geçersiz Kod",
                                "Girdiğiniz doğrulama kodu hatalıdır. Tekrar kontrol edebilir misiniz ?");
                          }
                        },
                        child: Container(
                          alignment: Alignment.center,
                          height: 50,
                          decoration: BoxDecoration(
                              color: Color(color),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(12))),
                          child: Text(
                            "Hesabımı Sil",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontFamily: "MontserratMedium"),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _reauthenticateAndDeleteAccount(BuildContext context) async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final user = auth.currentUser;
    if (user != null) {
      try {
        await user.reauthenticateWithCredential(
          EmailAuthProvider.credential(
            email: email,
            password: sifre,
          ),
        );
        // Decrement phone account counter first for consistency
        try {
          await PhoneAccountLimiter()
              .decrementOnUserDelete(uid: user.uid, phone: phoneNumber);
        } catch (_) {}

        // Delete user document
        await FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .delete();

        // Finally delete auth user
        await user.delete();
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => PopScope(
                      canPop: false,
                      child: SignIn(),
                    )));

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hesabın kalıcı olarak silinmiştir!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Hesabınızı silerken bir hata oluştu. Lütfen daha sonra tekrar deneyiniz')),
        );
      }
    }
  }
}
