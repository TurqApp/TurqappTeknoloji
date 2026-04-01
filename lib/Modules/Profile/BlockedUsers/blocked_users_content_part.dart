part of 'blocked_users.dart';

extension _BlockedUsersContentPart on _BlockedUsersState {
  Widget _buildBlockedUsersContent() {
    return Column(
      children: [
        Obx(() {
          if (controller.isLoading.value &&
              controller.blockedUserDetails.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: CircularProgressIndicator(
                  color: Colors.black,
                ),
              ),
            );
          }

          if (controller.blockedUserDetails.isEmpty) {
            return EmptyRow(text: "blocked_users.empty".tr);
          }

          return ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: controller.blockedUserDetails.length,
            itemBuilder: (context, index) {
              final user = controller.blockedUserDetails[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    user.avatarUrl.isNotEmpty
                        ? ClipOval(
                            child: SizedBox(
                              width: 40,
                              height: 40,
                              child: CachedNetworkImage(
                                imageUrl: user.avatarUrl,
                                fit: BoxFit.cover,
                              ),
                            ),
                          )
                        : Container(
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.grey.withAlpha(50),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              CupertinoIcons.person,
                              color: Colors.grey,
                            ),
                          ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                "${user.firstName} ${user.lastName}",
                                style: TextStyle(
                                  fontFamily: "MontserratMedium",
                                  fontSize: 15,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(width: 3),
                              RozetContent(size: 15, userID: user.userID)
                            ],
                          ),
                          Text(
                            user.nickname,
                            style: TextStyle(
                              fontFamily: "MontserratMedium",
                              fontSize: 15,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        controller.askToUserAndRemoveBlock(
                          user.userID,
                          user.nickname,
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        backgroundColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.withAlpha(50),
                          borderRadius:
                              const BorderRadius.all(Radius.circular(8)),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        child: Text(
                          "blocked_users.unblock".tr,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontFamily: "MontserratMedium",
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              );
            },
          );
        })
      ],
    );
  }
}
