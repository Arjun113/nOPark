import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nopark/features/feeds/presentation/screens/test_home.dart';
import 'package:nopark/features/trip/entities/trip_stops.dart';

import 'features/trip/entities/user.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
   runApp(const MyApp());
}

User test_user = User(
  firstName: "Arjun",
  middleName: "",
  lastName: "Sanghi",
  monashEmail: "asan0084@student.monash.edu",
  phoneNumber: "0434998568",
  imageUrl: "https://53.fs1.hubspotusercontent-na1.net/hubfs/53/image8-2.jpg",
  dateOfBirth: DateTime(2005, 9, 8)
);

Stop stop1 = Stop(label: "Arjun's House", time: DateTime.parse("2025-04-01 22:30:00"), distanceKm: 13, duration: Duration(minutes: 20));
Stop stop2 = Stop(label: "Lachlan's House", time: DateTime.parse("2025-04-01 22:45:00"), distanceKm: 15, duration: Duration(minutes: 15));

Trip demoTrip = Trip(
    from: "Clayton",
    to: "Caulfield",
    startTime: DateTime.parse("2025-04-01 22:00:00"), stops: [stop1, stop2]);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Disclaimer Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        appBarTheme: AppBarTheme(systemOverlayStyle: SystemUiOverlayStyle.light)
      ),
      home: HomePage(
          user: test_user,
          addresses: []
      ),
    );
  }
}