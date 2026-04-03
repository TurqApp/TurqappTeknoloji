part of 'optical_form_entry.dart';

extension _OpticalFormEntryResultPart on _OpticalFormEntryState {
  Widget _buildExamCard(BuildContext context) {
    final model = controller.model.value!;
    return GestureDetector(
      onTap: () => controller.handleExamTap(context),
      child: Container(
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: const BorderRadius.all(Radius.circular(12)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                model.name,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontFamily: 'MontserratBold',
                ),
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'answer_key.total_questions'.trParams({
                      'count': model.cevaplar.length.toString(),
                    }),
                    style: const TextStyle(
                      color: Colors.indigo,
                      fontSize: 15,
                      fontFamily: 'MontserratMedium',
                    ),
                  ),
                  Text(
                    formatTimestamp(model.baslangic.toInt()),
                    style: const TextStyle(
                      color: Colors.purple,
                      fontSize: 15,
                      fontFamily: 'MontserratMedium',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => controller.copyDocID(),
                    child: Row(
                      children: [
                        Text(
                          'ID: ${model.docID}',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontFamily: 'MontserratMedium',
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.copy,
                          color: Colors.black,
                          size: 15,
                        ),
                      ],
                    ),
                  ),
                  if (model.baslangic.toInt() <
                      DateTime.now().millisecondsSinceEpoch)
                    Text(
                      'answer_key.start_now'.tr,
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 15,
                        fontFamily: 'MontserratBold',
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeacherCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CachedUserAvatar(
              userId: controller.model.value?.userID,
              imageUrl: controller.avatarUrl.value,
              radius: 25,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    controller.fullName.value,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontFamily: 'MontserratBold',
                    ),
                  ),
                  Text(
                    'answer_key.teacher_created_info'.tr,
                    style: const TextStyle(
                      color: Colors.pink,
                      fontSize: 15,
                      fontFamily: 'MontserratMedium',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultPlaceholder() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Text(
        'answer_key.result_placeholder'.tr,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 15,
          fontFamily: 'MontserratBold',
        ),
      ),
    );
  }
}
