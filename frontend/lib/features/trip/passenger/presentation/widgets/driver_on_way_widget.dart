// Purpose: Showcase the driver being 'on the way'

import 'package:flutter/material.dart';

class DriverOnTheWay extends StatelessWidget {
  final String carImageURL;
  final String driverName;
  final String carRegistration;
  final String carMakeModel;
  final String carColour;

  const DriverOnTheWay({
    super.key,
    required this.driverName,
    required this.carImageURL,
    required this.carMakeModel,
    required this.carColour,
    required this.carRegistration,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text(
            "Your driver is on the way",
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          Center(child: Image(image: NetworkImage(carImageURL))),
          Center(
            child: Text(
              carMakeModel,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          Center(
            child: Text(
              carColour,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          const SizedBox(height: 15),
          Center(
            child: Text(
              carRegistration,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ],
      ),
    );
  }
}
