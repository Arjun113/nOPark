import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:intl/intl.dart';

import '../entities/trip_stops.dart';

class TripScroller extends StatefulWidget {
  final List<Trip> trips;

  const TripScroller({super.key, required this.trips});

  @override
  State<TripScroller> createState() => _TripScrollerState();
}

class _TripScrollerState extends State<TripScroller> {
  final PageController _pageController = PageController();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // PageView with horizontally scrollable trip cards
        SizedBox(
          height: 600, // Adjust based on your layout
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.trips.length,
            itemBuilder: (context, index) {
              return TripCard(trip: widget.trips[index]);
            },
          ),
        ),

        const SizedBox(height: 12),

        // SmoothPageIndicator with purple active dot
        SmoothPageIndicator(
          controller: _pageController,
          count: widget.trips.length,
          effect: WormEffect(
            dotHeight: 8,
            dotWidth: 8,
            spacing: 8,
            activeDotColor: Colors.deepPurple.shade800,
            dotColor: Colors.deepPurple.shade200,
          ),
        ),
      ],
    );
  }
}

class TripCard extends StatelessWidget {
  final Trip trip;

  const TripCard({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            // Origin → Destination Header
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    Text(
                      trip.fromCode,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                      ),
                    ),
                    Text(trip.from, style: const TextStyle(fontSize: 18)),
                  ],
                ),
                const SizedBox(width: 16),
                const Icon(Icons.arrow_downward),
                const SizedBox(width: 16),
                Column(
                  children: [
                    Text(
                      trip.toCode,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                      ),
                    ),
                    Text(trip.to, style: const TextStyle(fontSize: 18)),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Trip Date and Time
            Text(
              DateFormat('d MMMM yyyy\nhh:mm a zzz').format(trip.startTime),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 16),

            // Scrollable Stop List in white box
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children:
                        trip.stops
                            .map((stop) => StopWidget(stop: stop))
                            .toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StopWidget extends StatelessWidget {
  final Stop stop;

  const StopWidget({super.key, required this.stop});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          stop.label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        Text(
          DateFormat('hh:mm a zzz').format(stop.time),
          style: const TextStyle(fontSize: 14),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            '${stop.distanceKm}km, ${stop.duration.inMinutes}min',
            style: const TextStyle(fontSize: 14),
          ),
        ),
        const Icon(Icons.arrow_downward),
      ],
    );
  }
}
