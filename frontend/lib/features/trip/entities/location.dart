class Location {
  final double lat;
  final double long;

  Location({required this.lat, required this.long});

  factory Location.fromJson (dynamic json) {
    return Location(lat: json['lat'] as double, long: json['long'] as double);
  }

  Map<String, dynamic> toJson() {
    return {
      'lat': lat,
      'long': long
    };
  }
}