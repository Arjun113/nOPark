import 'package:flutter/material.dart';

// Data model for Ride Options
class RideOption {
  final String name;
  final double rating;
  final String address;
  final double detourKm;
  final int detourMin;
  final double price;

  RideOption({
    required this.name,
    required this.rating,
    required this.address,
    required this.detourKm,
    required this.detourMin,
    required this.price,
  });
}

// Mock backend data (replace later with API call)
Future<List<RideOption>> fetchRideOptions() async {
  await Future.delayed(const Duration(seconds: 1)); // simulate network delay
  return [
    RideOption(
      name: "Lachlan MacPhee",
      rating: 4.8,
      address: "1341 Dandenong Road, Chadstone, VIC",
      detourKm: 2.7,
      detourMin: 7,
      price: 18.04,
    ),
    RideOption(
      name: "Taiyeb M. Radiowala",
      rating: 4.7,
      address: "37 Alliance Walk, Clayton, VIC",
      detourKm: 1.7,
      detourMin: 7,
      price: 8.04,
    ),
    RideOption(
      name: "Arjun Sanghi",
      rating: 4.0,
      address: "37 Alliance Walk, Clayton, VIC",
      detourKm: 1.7,
      detourMin: 7,
      price: 4.04,
    ),
  ];
}

class RideOptionsScreen extends StatelessWidget {
  const RideOptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "CA Caulfield",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: FutureBuilder<List<RideOption>>(
        future: fetchRideOptions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading ride options"));
          }

          final rides = snapshot.data ?? [];

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: rides.length,
            itemBuilder: (context, index) {
              final ride = rides[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + Rating
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          ride.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              ride.rating.toString(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 18,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Address
                    Text(
                      ride.address,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Detour
                    Text(
                      "${ride.detourKm}km detour (+${ride.detourMin}min)",
                      style: TextStyle(color: Colors.grey[700], fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    // Price
                    Text(
                      "AUD${ride.price.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// Use the following code to test the RideOptionsScreen independently copy paste it on the main.dart file and it should work
// import 'package:flutter/material.dart';
// import 'ride_options_screen.dart';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: "Ride Options Demo",
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//       ),
//       home: const RideOptionsScreen(),
//     );
//   }
// }
