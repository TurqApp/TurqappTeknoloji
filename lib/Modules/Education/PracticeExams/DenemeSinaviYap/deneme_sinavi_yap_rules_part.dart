part of 'deneme_sinavi_yap.dart';

extension _DenemeSinaviYapRulesPart on _DenemeSinaviYapState {
  Widget _buildRulesSection(DenemeSinaviYapController controller) {
    return Container(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Text(
              'practice.exam_started_title'.tr,
              style: const TextStyle(
                color: Colors.purple,
                fontSize: 25,
                fontFamily: "MontserratBold",
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'practice.exam_started_body'.tr,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontFamily: "MontserratMedium",
              ),
            ),
            const SizedBox(height: 12),
            const Divider(color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              'practice.rules_title'.tr,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontFamily: "MontserratBold",
              ),
            ),
            const SizedBox(height: 15),
            _buildRuleRow("1-)", 'practice.rule_1'.tr),
            const SizedBox(height: 15),
            _buildRuleRow("2-)", 'practice.rule_2'.tr),
            const SizedBox(height: 15),
            _buildRuleRow("3-)", 'practice.rule_3'.tr),
            const SizedBox(height: 15),
            GestureDetector(
              onTap: () => controller.selection.value = 0,
              child: Container(
                height: 45,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Colors.indigo,
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                child: Text(
                  'practice.start_exam'.tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontFamily: "MontserratMedium",
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleRow(String index, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 30,
          height: 30,
          child: Text(
            index,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontFamily: "MontserratBold",
            ),
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontFamily: "MontserratMedium",
            ),
          ),
        ),
      ],
    );
  }
}
