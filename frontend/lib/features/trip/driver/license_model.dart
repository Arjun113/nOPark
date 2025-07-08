import '../../../constants/licensetype.dart';
import '../../../constants/licenseConditions.dart';

class License {
  final String licenseNumber;
  final LicenseType licenseType;
  final Set<LicenseCondition> licenseConditions;

  License ({
    required this.licenseNumber,
    required this.licenseType,
    required this.licenseConditions
  });

  Set<LicenseCondition> getConditions() {
    return this.licenseConditions;
  }

  bool checkIfConditionPresent (LicenseCondition condition) {
    return this.licenseConditions.contains(condition);
  }

  void addCondition (LicenseCondition condition) {
    this.licenseConditions.add(condition);
  }

  factory License.fromJson (Map<String, dynamic> json) {
    return License (
      licenseType: json['licenseType'],
      licenseConditions: json['licenseConditions'],
      licenseNumber: json['licenseNumber']
    );
  }

  Map <String, dynamic> toJson () {
    return {
      'licenseType': this.licenseType,
      'licenseConditions': this.licenseConditions.toString(),
      'licenseNumber': this.licenseNumber
    };
  }

  int getMaxPassengerCarriage () {
    if (licenseType == LicenseType.l) {
      return 0;
    }
    else if (licenseType == LicenseType.p1 || licenseType == LicenseType.p2) {
      return 1;
    }
    else {
      return -1; // No limit on peer passenger carriage
    }
  }


}