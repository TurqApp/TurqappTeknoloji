part of 'test_past_result_content.dart';

extension _TestPastResultContentCardPart on _TestPastResultContentState {
  Widget _buildResultCard() {
    return GestureDetector(
      onTap: () => const EducationResultNavigationService()
          .openTestPastResultPreview(model),
      child: Container(
        margin: const EdgeInsets.only(left: 15, right: 15, bottom: 15),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: const BorderRadius.all(Radius.circular(12)),
        ),
        child: Padding(
          padding: const EdgeInsets.only(
            left: 15,
            right: 15,
            top: 15,
            bottom: 7,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(3)),
                child: SizedBox(
                  width: 75,
                  height: 75,
                  child: CachedNetworkImage(
                    imageUrl: model.img,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        const Center(child: CupertinoActivityIndicator()),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.broken_image),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'tests.type_test'.trParams({
                        'type': model.testTuru,
                      }),
                      maxLines: 1,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        fontFamily: 'MontserratBold',
                      ),
                    ),
                    Text(
                      'tests.description_test'.trParams({
                        'description': model.aciklama,
                      }),
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        fontFamily: 'MontserratMedium',
                      ),
                    ),
                    Text(
                      timeAgo(controller.timeStamp.value),
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 12,
                        fontFamily: 'MontserratMedium',
                      ),
                    ),
                    if (controller.count.value != 0)
                      Text(
                        'tests.solve_count'.trParams({
                          'count': controller.count.value.toString(),
                        }),
                        style: const TextStyle(
                          color: Colors.indigo,
                          fontSize: 12,
                          fontFamily: 'MontserratMedium',
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
