part of 'account_center_view.dart';

class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.account,
    required this.avatar,
    required this.onTap,
    required this.onLongPress,
  });

  final StoredAccount account;
  final Widget avatar;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              avatar,
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            account.username.trim().isNotEmpty
                                ? account.username
                                : account.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontFamily: 'MontserratBold',
                            ),
                          ),
                        ),
                        RozetContent(
                          size: 17,
                          userID: account.uid,
                          rozetValue: account.rozet,
                        ),
                      ],
                    ),
                    if (account.displayName.trim().isNotEmpty &&
                        account.displayName.trim() !=
                            account.username.trim()) ...[
                      const SizedBox(height: 2),
                      Text(
                        account.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                          fontFamily: 'MontserratMedium',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                CupertinoIcons.chevron_right,
                color: Colors.black38,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
