part of 'about_profile.dart';

extension _AboutProfileContentPart on _AboutProfileState {
  Widget _buildAboutProfileContent() {
    return Column(
      children: [
        BackButtons(text: "about_profile.title".tr),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                ClipOval(
                  child: SizedBox(
                    width: 70,
                    height: 70,
                    child: controller.avatarUrl.value != ""
                        ? CachedNetworkImage(
                            imageUrl: controller.avatarUrl.value,
                            fit: BoxFit.cover,
                          )
                        : Center(
                            child: CupertinoActivityIndicator(
                              color: Colors.grey,
                            ),
                          ),
                  ),
                ),
                RozetContent(size: 20, userID: widget.userID)
              ],
            )
          ],
        ),
        SizedBox(
          height: 15,
        ),
        Text(
          controller.nickname.value,
          style: TextStyle(
            color: Colors.black,
            fontSize: 15,
            fontFamily: "MontserratMedium",
          ),
        ),
        Text(
          controller.fullName.value,
          style: TextStyle(
            color: Colors.grey,
            fontSize: 15,
            fontFamily: "Montserrat",
          ),
        ),
        SizedBox(
          height: 12,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Text(
            "about_profile.description".tr,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black,
              fontSize: 13,
              fontFamily: "MontserratMedium",
            ),
          ),
        ),
        SizedBox(
          height: 20,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Row(
            children: [
              Icon(
                CupertinoIcons.calendar,
                size: 25,
                color: Colors.black,
              ),
              SizedBox(
                width: 12,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (controller.createdDate.value != "")
                      Text(
                        "about_profile.joined_on".trParams(
                          <String, String>{
                            'date': formatTimeStampAyYil(
                              controller.createdDate.value,
                            ),
                          },
                        ),
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontFamily: "MontserratMedium",
                        ),
                      )
                  ],
                ),
              )
            ],
          ),
        )
      ],
    );
  }
}
