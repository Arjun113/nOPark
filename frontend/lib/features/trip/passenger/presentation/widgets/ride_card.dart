import 'package:flutter/material.dart';

class RideCard extends StatefulWidget {
  final String title;
  final String carName;
  final String carColor;
  final String plateNumber;
  final String plateState;
  final String carImageUrl;
  final VoidCallback onRideCompleted;

  const RideCard({
    super.key,
    required this.title,
    required this.carName,
    required this.carColor,
    required this.plateNumber,
    required this.plateState,
    required this.carImageUrl,
    required this.onRideCompleted
  });

  @override
  State<StatefulWidget> createState() {
    return RideCardState();
  }
}

class RideCardState extends State<RideCard> {

  @override
  void initState() {
    super.initState();
    if (mounted) {
      widget.onRideCompleted.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: 470,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                Image.network(widget.carImageUrl, height: 120),
                const SizedBox(height: 10),
                Text(
                  widget.carName,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 3),
                Text(
                  widget.carColor,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 13),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black54, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        widget.plateNumber,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                        ),
                      ),
                      Text(
                        widget.plateState,
                        style: const TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )
    );
  }
}
