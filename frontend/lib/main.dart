// import 'package:flutter/material.dart';
// import 'package:dynamic_color/dynamic_color.dart';
// import 'package:nopark/logic/utilities/theme_builder.dart';

// void main() {
//   runApp(const MainApp());
// }

// class MainApp extends StatelessWidget {
//   const MainApp({super.key});

//   static final Color fallbackSeed = Colors.blueAccent;

//   @override
//   Widget build(BuildContext context) {
//     return DynamicColorBuilder(
//       builder: (dynamicLightTheme, dynamicDarkTheme) {
//         final dynamicLightScheme =
//             dynamicLightTheme ?? ColorScheme.fromSeed(seedColor: fallbackSeed);
//         final dynamicDarkScheme =
//             dynamicDarkTheme ??
//             ColorScheme.fromSeed(
//               seedColor: fallbackSeed,
//               brightness: Brightness.dark,
//             );

//         return MaterialApp(
//           title: 'nOPark',
//           debugShowCheckedModeBanner: false,
//           theme: createTheme(dynamicLightScheme),
//           darkTheme: createTheme(dynamicDarkScheme),
//           themeMode: ThemeMode.system,
//         );
//       },
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'features/signup/interface/widgets/login_screen.dart';
import 'features/signup/interface/widgets/register_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NoPark App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const LoginScreen(),
      routes: {
        '/register': (context) => const RegisterScreen(),
        '/login': (context) => const LoginScreen(),
      },
    );
  }
}
