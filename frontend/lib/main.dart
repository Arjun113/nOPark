import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:nopark/firebase_options.dart';
import 'features/signup/interface/widgets/login_screen.dart';
import 'features/signup/interface/widgets/register_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    Firebase.initializeApp(name: 'com.example.nopark', options: DefaultFirebaseOptions.android);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'nOPark App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const LoginScreen(),
      routes: {
        '/register': (context) => const RegisterScreen(),
        '/login': (context) => const LoginScreen(),
      },
    );
  }
}
