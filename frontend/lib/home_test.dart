import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nopark/features/feeds/presentation/screens/test_home.dart';

import 'features/trip/entities/user.dart';

void main() {
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