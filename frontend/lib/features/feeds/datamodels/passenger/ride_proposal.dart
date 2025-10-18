class RideProposal {
  final int proposalID;
  String proposalStatus;
  final int driverID;
  final int rideID;
  final String polyline;
  final int duration;
  final double distance;
  final DateTime creationDate;
  final DateTime updationDate;

  RideProposal({
   required this.proposalID,
   required this.proposalStatus,
   required this.driverID,
   required this.rideID,
   required this.polyline,
   required this.duration,
   required this.distance,
   required this.creationDate,
   required this.updationDate
  });

  factory RideProposal.fromJson(Map<String, dynamic> json) {
    return RideProposal(
        proposalID: (json['request_id'] ?? 0) as int,
        proposalStatus: (json['status'] ?? ""),
        driverID: (json['driver_id'] ?? 0) as int,
        rideID: (json['ride_id'] ?? 0) as int,
        polyline: (json['polyline'] ?? ""),
        duration: (json['duration'] ?? 0) as int,
        distance: (json['distance'] ?? 0.0) as double,
        creationDate: DateTime.parse(json['created_at']),
        updationDate: DateTime.parse(json['updated_at'])
    );
  }

}

/*
ID        int64   `json:"id"`
	RequestID int64   `json:"request_id"`
	Status    string  `json:"status"`
	DriverID  int64   `json:"driver_id"`
	RideID    int64   `json:"ride_id"`
	Polyline  string  `json:"polyline"`
	Duration  int64   `json:"duration"`
	Distance  float64 `json:"distance"`
	CreatedAt string  `json:"created_at"`
	UpdatedAt string  `json:"updated_at"`
 */