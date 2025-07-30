import '../../../constants/licensetype.dart';
import '../../../constants/license_conditions.dart';

class License {
  final String licenseNumber;
  final LicenseType licenseType;
  final Set<LicenseCondition> licenseConditions;

  License({
    required this.licenseNumber,
    required this.licenseType,
    required this.licenseConditions,
  });

  Set<LicenseCondition> getConditions() {
    return licenseConditions;
  }

  bool checkIfConditionPresent(LicenseCondition condition) {
    return licenseConditions.contains(condition);
  }

  void addCondition(LicenseCondition condition) {
    licenseConditions.add(condition);
  }

  factory License.fromJson(Map<String, dynamic> json) {
    return License(
      licenseType: json['licenseType'],
      licenseConditions: json['licenseConditions'],
      licenseNumber: json['licenseNumber'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'licenseType': licenseType,
      'licenseConditions': licenseConditions.toString(),
      'licenseNumber': licenseNumber,
    };
  }

  int getMaxPassengerCarriage() {
    if (licenseType == LicenseType.l) {
      return 0;
    } else if (licenseType == LicenseType.p1 || licenseType == LicenseType.p2) {
      return 1;
    } else {
      return -1; // No limit on peer passenger carriage
    }
  }
}
