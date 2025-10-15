class User {
  final String firstName;
  final String lastName;
  final String middleName;
  final String email;
  final String type;
  static String defaultImageUrl =
      'https://upload.wikimedia.org/wikipedia/commons/a/ac/Default_pfp.jpg';
  final String imageUrl;

  List<String> addresses;

  User({
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.email,
    required this.imageUrl,
    required this.type,

    List<String>? addresses,
  }) : addresses = addresses ?? [];

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      firstName: json['first_name'],
      middleName: json['middle_name'] ?? "",
      lastName: json['last_name'],
      imageUrl: defaultImageUrl,
      email: json['email'],
      type: json['type'],
      addresses: List<String>.from(json['addresses'] ?? []),
    );
  }

  static DateTime convertStrDateToDateTime(String strDate) {
    // Format: DD-MM-YYYY
    final List<String> splitDate = strDate.split('/');
    return DateTime(
      int.parse(splitDate[2]),
      int.parse(splitDate[1]),
      int.parse(splitDate[0]),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'middle_name': middleName,
      'last_name': lastName,
      'image_url': imageUrl,
      'email': email,
      'type': type,
      'addresses': addresses,
    };
  }
}
