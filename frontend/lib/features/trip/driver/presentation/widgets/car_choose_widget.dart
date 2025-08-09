// Purpose: Choose multiple cars

import 'package:flutter/material.dart';
import 'package:nopark/features/trip/entities/car.dart';

class ChooseCarCard extends StatefulWidget {
  final List<Car> cars;

  const ChooseCarCard({super.key, required this.cars});

  @override
  State<ChooseCarCard> createState() => _ChooseCarCardState();
}

class _ChooseCarCardState extends State<ChooseCarCard> {
  int _currentIndex = 0;
  final PageController _pageController = PageController(viewportFraction: 0.85);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 8,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Choose Car",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                // Horizontal scroll for cars
                SizedBox(
                  height: 180,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: widget.cars.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      final car = widget.cars[index];
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            car.carImage,
                            height: 100,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            car.carMake,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            car.carModel,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                const SizedBox(height: 12),

                // Choose button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, widget.cars[_currentIndex]);
                    },
                    child: const Text("Choose"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}