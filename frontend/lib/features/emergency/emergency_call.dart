import '../../constants/emergency_contact.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyCaller {
  static void callEmergencyServices() {
    launchUrl(Uri.parse('tel: $victoriaEmergencyContact'));
  }
}
