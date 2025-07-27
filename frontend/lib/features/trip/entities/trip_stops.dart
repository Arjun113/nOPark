// Purpose: indicate Trips and Stops

class Trip {
  final String from;
  final String to;
  final String fromCode;
  final String toCode;
  final DateTime startTime;
  final List<Stop> stops;

  Trip({
    required this.from,
    required this.to,
    required this.fromCode,
    required this.toCode,
    required this.startTime,
    required this.stops,
  });
}

class Stop {
  final String label;
  final DateTime time;
  final double distanceKm;
  final Duration duration;

  Stop({
    required this.label,
    required this.time,
    required this.distanceKm,
    required this.duration,
  });
}
