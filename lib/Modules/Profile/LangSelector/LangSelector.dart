import 'package:flutter/material.dart';
import 'package:turqappv2/Core/Buttons/BackButtons.dart';

class LangSelector extends StatelessWidget {
  const LangSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 15, right: 15, top: 15),
              child: Row(
                children: [BackButtons(text: "Uygulama Dili")],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    containerRow("Türkçe", true),
                    containerRow("İngilizce", false),
                    containerRow("Almanca", false),
                    containerRow("Fransızca", false),
                    containerRow("Rusça", false),
                    containerRow("Arapça", false),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget containerRow(String title, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.grey.withAlpha(20),
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                    color: isSelected ? Colors.black : Colors.grey,
                    fontSize: 15,
                    fontFamily: "MontserratMedium",
                    decoration: !isSelected
                        ? TextDecoration.lineThrough
                        : TextDecoration.none),
              ),
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey)),
                child: isSelected
                    ? Padding(
                        padding: const EdgeInsets.all(3),
                        child: Container(
                          decoration: BoxDecoration(
                              shape: BoxShape.circle, color: Colors.black),
                        ),
                      )
                    : SizedBox(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
