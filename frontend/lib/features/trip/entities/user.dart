class User {
  final String firstName;
  final String lastName;
  final String middleName;
  final String phoneNumber;
  final DateTime dateOfBirth;
  final String monashEmail;
  static String defaultImageUrl = 'https://upload.wikimedia.org/wikipedia/commons/a/ac/Default_pfp.jpg';
  final String imageUrl;

  User({
   required this.firstName,
   required this.middleName,
    required this.lastName,
    required this.phoneNumber,
    required this.dateOfBirth,
    required this.monashEmail,
    required this.imageUrl
});

  factory User.fromJson(Map<String, dynamic> json) {
    return User (
      firstName: json['firstName'],
      middleName: json['middleName'],
      lastName: json['lastName'],
      imageUrl: json['ProfileImage'] ?? defaultImageUrl,
      phoneNumber: json['phoneNumber'],
      dateOfBirth: convertStrDateToDateTime(json['dateOfBirth']),
      monashEmail: json['monashEmail']
    );
  }

  static DateTime convertStrDateToDateTime (String strDate) {
    // Format: DD-MM-YYYY
    final List<String> splitDate = strDate.split('/');
    return DateTime(int.parse(splitDate[2]), int.parse(splitDate[1]), int.parse(splitDate[0]));
  }

  Map <String, dynamic> toJson () {
    return {
      'firstName': this.firstName,
      'middleName': this.middleName,
      'lastName': this.lastName,
      'imageUrl': this.imageUrl,
      'dateOfBirth': this.dateOfBirth.toString(),
      'phoneNumber': this.phoneNumber,
      'monashEmail': this.monashEmail
    };
  }
}