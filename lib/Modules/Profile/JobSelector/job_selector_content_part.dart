part of 'job_selector.dart';

extension JobSelectorContentPart on _JobSelectorState {
  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.20),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: TextField(
          onChanged: controller.filterJobs,
          decoration: InputDecoration(
            icon: const Icon(Icons.search, color: Colors.grey),
            hintText: 'job_selector.search_hint'.tr,
            hintStyle: const TextStyle(
              color: Colors.grey,
              fontFamily: "Montserrat",
              fontSize: 14,
            ),
            border: InputBorder.none,
          ),
          style: const TextStyle(
            color: Colors.black,
            fontSize: 15,
            fontFamily: "Montserrat",
          ),
        ),
      ),
    );
  }

  Widget _buildJobList() {
    return Obx(() {
      final selectedJob = controller.job.value;
      final jobs = controller.filteredJobs;

      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: jobs.length,
        itemBuilder: (context, index) {
          final job = jobs[index];
          final isSelected = job.trim() == selectedJob.trim();
          return Padding(
            padding: EdgeInsets.only(top: index == 0 ? 14 : 8),
            child: GestureDetector(
              onTap: () {
                controller.selectJob(job);
              },
              child: _buildJobTile(job: job, isSelected: isSelected),
            ),
          );
        },
      );
    });
  }

  Widget _buildJobTile({
    required String job,
    required bool isSelected,
  }) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white.withValues(alpha: 0.10) : Colors.white,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        border: Border.all(
          color:
              isSelected ? Colors.black : Colors.grey.withValues(alpha: 0.20),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              job,
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontFamily: isSelected ? "MontserratBold" : "Montserrat",
              ),
            ),
          ),
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? Colors.black : Colors.white,
              borderRadius: const BorderRadius.all(
                Radius.circular(15),
              ),
              border: Border.all(
                color: isSelected ? Colors.black : Colors.grey,
              ),
            ),
            child: isSelected
                ? const Icon(
                    CupertinoIcons.checkmark,
                    color: Colors.white,
                    size: 12,
                  )
                : const SizedBox(),
          ),
        ],
      ),
    );
  }
}
