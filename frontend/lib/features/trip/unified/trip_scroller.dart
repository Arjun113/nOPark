import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nopark/features/trip/driver/presentation/widgets/ride_options_screen.dart';
import 'package:nopark/logic/network/dio_client.dart';
import '../entities/trip_stops.dart';

class PastRidesOverlay extends StatefulWidget {
  final VoidCallback? onBack;

  const PastRidesOverlay({super.key, this.onBack});

  @override
  State<PastRidesOverlay> createState() => _PastRidesOverlayState();
}

class _PastRidesOverlayState extends State<PastRidesOverlay> {
  late List<Trip> pastRides;
  @override
  void initState() async {
    // TODO: implement initState
    super.initState();
    // Fetch from backend

    try {
      final trip_history_full = await DioClient().client.get(
        '/rides/history',
        data: {}
      );

      if (trip_history_full.statusCode != 201) {
        pastRides = [];
        return;
      }

      final trip_history_list = trip_history_full.data['rides'];

      for (var trip_history in trip_history_list) {
        // No errors, now proceed
        final indiv_trips = trip_history.data['requests'] as List<Map<String, dynamic>>;
        List<Stop> trip_stops = [];
        for (var trip in indiv_trips) {
          final distance_est = await DioClient().client.get(
              '/maps/route',
              data: {
                'start_lat': double.parse(trip['pickup_latitude']),
                'start_lng': double.parse(trip['pickup_longitude']),
                'end_lat': double.parse(trip['dropoff_latitude']),
                'end_lng': double.parse(trip['dropoff_longitude'])
              }
          );

          if (distance_est.statusCode != 201){
            return;
          }

          final new_stop = Stop(label: trip['pickup_location'], time: DateTime.parse(trip['updated_at']), distanceKm: double.parse(distance_est.data['distance']), duration: Duration(minutes: int.parse(distance_est.data['duration'])));
          trip_stops.add(new_stop);
        }
        final new_trip = Trip(from: trip_stops[0].label, to: trip_history['dropoff_location'], startTime: trip_history['updated_at'], stops: trip_stops);
        pastRides.add(new_trip);
      }

    }
    catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error fetching past rides")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            // Optional back button at top
            Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: widget.onBack ?? () => Navigator.of(context).pop(),
              ),
            ),

            // Spacer to push cards to bottom
            const Spacer(),

            // Horizontal scrollable trip cards at bottom
            Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                height: 700, // Constrained height
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: pastRides.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: TripCard(trip: pastRides[index]),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TripCard extends StatelessWidget {
  final Trip trip;

  const TripCard({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 410),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(10),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Origin and Destination with arrow
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        trip.fromCode ?? "",
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 50,
                          color: Colors.black,
                          height: 1.0,
                          fontFamily: 'B612',
                        ),
                      ),
                      const SizedBox(width: 24),
                      Text(
                        trip.from,
                        style: const TextStyle(
                          fontSize: 40,
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'B612',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  const Icon(
                    Icons.arrow_downward_rounded,
                    color: Colors.black,
                    size: 40,
                  ),

                  const SizedBox(height: 8),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        trip.toCode ?? "",
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 48,
                          color: Colors.black,
                          height: 1.0,
                          fontFamily: 'B612',
                        ),
                      ),
                      const SizedBox(width: 24),
                      Text(
                        trip.to,
                        style: const TextStyle(
                          fontSize: 40,
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'B612',
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Trip date and time
              Text(
                DateFormat('d MMMM yyyy').format(trip.startTime),
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                  fontFamily: 'GoogleSans',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('hh:mm a zzz').format(trip.startTime),
                style: const TextStyle(
                  fontSize: 25,
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'GoogleSans',
                ),
              ),

              const SizedBox(height: 20),

              // Scrollable stops list
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children:
                          trip.stops.asMap().entries.map((entry) {
                            int index = entry.key;
                            Stop stop = entry.value;
                            bool isLast = index == trip.stops.length - 1;

                            return StopWidget(stop: stop, isLast: isLast);
                          }).toList(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StopWidget extends StatelessWidget {
  final Stop stop;
  final bool isLast;

  const StopWidget({super.key, required this.stop, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Stop name
        Text(
          stop.label,
          style: const TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w700,
            color: Colors.black,
            fontFamily: 'GoogleSans',
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 4),

        // Stop time
        Text(
          DateFormat('hh:mm a zzz').format(stop.time),
          style: const TextStyle(
            fontSize: 15,
            color: Colors.black,
            fontWeight: FontWeight.w500,
            fontFamily: 'GoogleSans',
          ),
        ),

        if (!isLast) ...[
          const SizedBox(height: 12),

          // Arrow and distance/duration info
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.arrow_downward_rounded,
                color: Colors.black,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                '${stop.distanceKm}km, ${stop.duration.inMinutes}min',
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.black,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'GoogleSans',
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
        ],
      ],
    );
  }
}
