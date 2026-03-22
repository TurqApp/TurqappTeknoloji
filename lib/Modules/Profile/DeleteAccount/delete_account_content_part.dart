part of 'delete_account.dart';

extension _DeleteAccountContentPart on _DeleteAccountState {
  Widget _buildPage(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(15),
              child: Row(
                children: [BackButtons(text: 'delete_account.title'.tr)],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.03),
                      borderRadius: const BorderRadius.all(Radius.circular(14)),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'delete_account.confirm_title'.tr,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontFamily: "MontserratBold",
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'delete_account.confirm_body'.tr,
                          style: TextStyle(
                            color: Colors.black.withValues(alpha: 0.75),
                            fontSize: 14,
                            fontFamily: "Montserrat",
                          ),
                        ),
                        if (_email.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            _email,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 13,
                              fontFamily: "MontserratMedium",
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.03),
                      borderRadius: const BorderRadius.all(Radius.circular(12)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Row(
                      children: [
                        Flexible(
                          child: TextField(
                            controller: _codeController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(6),
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(
                              hintText: 'delete_account.code_hint'.tr,
                              hintStyle: const TextStyle(
                                color: Colors.grey,
                                fontFamily: "Montserrat",
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
                        GestureDetector(
                          onTap: _isBusy ? null : _sendDeleteCode,
                          child: Text(
                            _countdown > 0
                                ? "${_countdown}s"
                                : (_isCodeSent
                                    ? 'delete_account.resend'.tr
                                    : 'delete_account.send_code'.tr),
                            style: TextStyle(
                              color:
                                  _countdown > 0 ? Colors.grey : Color(_color),
                              fontSize: 14,
                              fontFamily: "MontserratMedium",
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'delete_account.validity_notice'
                        .trParams({
                          'days': '${_DeleteAccountState._deletionGraceDays}',
                        }),
                    style: TextStyle(
                      color: Colors.black.withValues(alpha: 0.6),
                      fontSize: 12,
                      fontFamily: "Montserrat",
                    ),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: _isBusy ? null : _verifyAndDelete,
                    child: Container(
                      alignment: Alignment.center,
                      height: 50,
                      decoration: BoxDecoration(
                        color: _isBusy
                            ? Colors.black.withValues(alpha: 0.35)
                            : Color(_color),
                        borderRadius:
                            const BorderRadius.all(Radius.circular(12)),
                      ),
                      child: Text(
                        _isBusy
                            ? 'delete_account.processing'.tr
                            : 'delete_account.delete_my_account'.tr,
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
          ],
        ),
      ),
    );
  }
}
