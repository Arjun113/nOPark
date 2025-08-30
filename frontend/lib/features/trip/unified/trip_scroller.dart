import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../entities/trip_stops.dart';

class PastRidesOverlay extends StatefulWidget {
  final List<Trip> trips;
  final VoidCallback? onBack;

  const PastRidesOverlay({super.key, required this.trips, this.onBack});

  @override
  State<PastRidesOverlay> createState() => _PastRidesOverlayState();
}

class _PastRidesOverlayState extends State<PastRidesOverlay> {
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
                  itemCount: widget.trips.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: TripCard(trip: widget.trips[index]),
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
            constraints: const BoxConstraints(
              maxWidth: 400
            ),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
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
                            fontWeight: FontWeight.w900,
                            fontSize: 48,
                            color: Colors.black,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(width: 24),
                        Text(
                          trip.from,
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.black87,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    const Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.black54,
                      size: 28,
                    ),

                    const SizedBox(height: 8),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          trip.toCode ?? "",
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 48,
                            color: Colors.black,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(width: 24),
                        Text(
                          trip.to,
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.black87,
                            fontWeight: FontWeight.w400,
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
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('hh:mm a zzz').format(trip.startTime),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 20),

                // Scrollable stops list
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        children: trip.stops.asMap().entries.map((entry) {
                          int index = entry.key;
                          Stop stop = entry.value;
                          bool isLast = index == trip.stops.length - 1;

                          return StopWidget(
                            stop: stop,
                            isLast: isLast,
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
    );
  }
}

class StopWidget extends StatelessWidget {
  final Stop stop;
  final bool isLast;

  const StopWidget({
    super.key,
    required this.stop,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Stop name
        Text(
          stop.label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 4),

        // Stop time
        Text(
          DateFormat('hh:mm a zzz').format(stop.time),
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black54,
            fontWeight: FontWeight.w400,
          ),
        ),

        if (!isLast) ...[
          const SizedBox(height: 12),

          // Arrow and distance/duration info
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.keyboard_arrow_down,
                color: Colors.black54,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                '${stop.distanceKm}km, ${stop.duration.inMinutes}min',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  fontWeight: FontWeight.w400,
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