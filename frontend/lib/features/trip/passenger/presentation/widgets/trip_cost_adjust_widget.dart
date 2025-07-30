// Purpose: Adjust bid amount and check trip details

import 'package:flutter/material.dart';
import 'package:nopark/constants/monash_campus_locs.dart';

class TripCostAdjust extends StatefulWidget {
  final String fromAddressName;
  final MonashCampusCodes? fromCampusCode;
  final String toAddressName;
  final MonashCampusCodes? toCampusCode;
  final double recommendedBidAUD;

  const TripCostAdjust({
    super.key,
    required this.fromAddressName,
    required this.fromCampusCode,
    required this.toAddressName,
    required this.toCampusCode,
    required this.recommendedBidAUD,
  });

  @override
  State<StatefulWidget> createState() {
    return TripCostAdjustState();
  }
}

class TripCostAdjustState extends State<TripCostAdjust> {
  late double modifiedTripCost;
  late TextEditingController controller;

  @override
  void initState() {
    super.initState();
    modifiedTripCost = widget.recommendedBidAUD;
    controller = TextEditingController(
      text: widget.recommendedBidAUD.toString(),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  void adjustBidAmount(bool up) {
    if (up == true) {
      modifiedTripCost = modifiedTripCost + 0.5;
      controller.text = modifiedTripCost.toString();
    } else {
      modifiedTripCost = modifiedTripCost - 0.5;
      controller.text = modifiedTripCost.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        widget.fromCampusCode == null
            ? Center(child: Text(widget.fromAddressName))
            : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(widget.fromCampusCode.toString()),
                Text(widget.fromAddressName),
              ],
            ),

        Center(child: const Icon(Icons.arrow_circle_down_outlined)),

        widget.toCampusCode == null
            ? Center(child: Text(widget.toAddressName))
            : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(widget.toCampusCode.toString()),
                Text(widget.toAddressName),
              ],
            ),

        Center(
          child: Text(
            "Recommended Bid",
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                adjustBidAmount(false);
              },
              child: const Center(
                child: const Icon(Icons.remove, color: Colors.black),
              ),
            ),
            Text(controller.text),
            ElevatedButton(
              onPressed: () {
                adjustBidAmount(true);
              },
              child: const Center(
                child: const Icon(Icons.add, color: Colors.black),
              ),
            ),
          ],
        ),

        GestureDetector(
          onTap: () => Navigator.pop(context, modifiedTripCost),
          child: const Padding(
            padding: EdgeInsets.only(left: 15, right: 15, top: 5, bottom: 5),
            child: Text("Submit Bid"),
          ),
        ),
      ],
    );
  }
}
