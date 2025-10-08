import 'package:flutter/material.dart';
import 'package:nopark/features/feeds/presentation/screens/driver_home.dart';
import 'package:nopark/features/feeds/presentation/screens/passenger_home.dart';

import '../trip/entities/user.dart';

class RoleSwitcher extends StatelessWidget {
  final User user;
  final String userRole;
  final List<Map<String, dynamic>> addresses;

  const RoleSwitcher({
    super.key,
    required this.user,
    required this.userRole,
    required this.addresses
  });

  @override
  Widget build(BuildContext context) {
    switch (userRole) {
      case "passenger": 
        return PassengerHomePage(user: user, addresses: addresses);
      case "driver":
        return DriverHomePage(user: user, addresses: addresses);
      case "both":
        return PassengerHomePage(user: user, addresses: addresses);
    }
    return PassengerHomePage(user: user, addresses: addresses);
  }
}