import 'package:flutter/material.dart';
import 'package:turqappv2/Themes/AppColors.dart';

class MaintenanceView extends StatefulWidget {
  const MaintenanceView({super.key});

  @override
  State<MaintenanceView> createState() => _MaintenanceViewState();
}

class _MaintenanceViewState extends State<MaintenanceView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primaryColor, AppColors.secondColor],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(50),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(),
                Column(
                  children: [
                    RotationTransition(
                      turns: _animationController,
                      child: Image.asset(
                        "assets/images/logotrans.webp",
                        color: Colors.white,
                        height: 80,
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      "Kısa Bir Ara Veriyoruz",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 25,
                        color: Colors.white,
                        fontFamily: "MontserratBold",
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      "Daha hızlı, daha güvenli ve daha keyifli bir deneyim için altyapımızı geliştiriyoruz.",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontFamily: "MontserratMedium",
                        height: 2.0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                const Text(
                  "© 2025 TurqApp A.Ş.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
