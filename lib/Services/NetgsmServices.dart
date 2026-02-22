import 'dart:convert';
import 'package:http/http.dart' as http;

class NetgsmService {
  Future<void> sendRequest(String otpCode, String phoneNumber) async {
    String xml =
        """<?xml version="1.0"?><mainbody><header><usercode>3326062598</usercode><password>BursCity42@</password><msgheader>TurqApp</msgheader></header><body><msg><![CDATA[$otpCode TurqApp hesabı doğrulama kodunuzdur.]]></msg><no>$phoneNumber</no></body></mainbody>""";

    Uri url = Uri.parse("https://api.netgsm.com.tr/sms/send/otp");
    try {
      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/xml'},
        body: utf8.encode(xml),
      );

      if (response.statusCode == 200) {
        print("NETGSM ${utf8.decode(response.bodyBytes)}");
        print("OTPFROMNETGSM $otpCode");
      } else {
        print("Error: ${response.statusCode}");
      }
    } catch (error) {
      print("Error: $error");
    }
  }
}
