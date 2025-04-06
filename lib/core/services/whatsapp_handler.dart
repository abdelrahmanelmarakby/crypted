import 'dart:io';

import 'package:url_launcher/url_launcher.dart';

class WhatsappHandlers {
  static Future<void> openWhatsApp({required String phoneNumber, String countryCode='', String message= '',}) async {
  
    String url = Platform.isAndroid
        ? 'https://wa.me/$countryCode$phoneNumber/?text=$message'//"whatsapp://send?phone=$countryCode$phoneNumber"
        : "https://api.whatsapp.com/send?phone=$countryCode$phoneNumber/&text=$message";
    //Uri.parse("https://wa.me/$phoneNumber");
    try {
      if (await launchUrl(Uri.parse(url),
          mode: LaunchMode.externalApplication)) {}
    } catch (e) {
      
      rethrow;
    }
  }
}