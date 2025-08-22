import 'package:flutter/material.dart';
import 'package:nopark/constants/monash_campus_locs.dart';

class PricingOverlay extends StatefulWidget {
  final String fromAddressName;
  final MonashCampusCodes? fromCampusCode;
  final String toAddressName;
  final MonashCampusCodes? toCampusCode;
  final double recommendedBidAUD;
  final Offset initialPosition;
  final Size initialSize;

  /// Called when the user submits the bid
  final void Function(double modifiedBid)? onSubmit;

  /// Optional callback to go back in the overlay
  final VoidCallback? onBack;

  const PricingOverlay({
    super.key,
    required this.fromAddressName,
    this.fromCampusCode,
    required this.toAddressName,
    this.toCampusCode,
    required this.recommendedBidAUD,
    this.onSubmit,
    this.onBack,
    required this.initialPosition,
    required this.initialSize
  });

  @override
  State<PricingOverlay> createState() => _PricingOverlayState();
}

class _PricingOverlayState extends State<PricingOverlay> {
  late double modifiedTripCost;
  late TextEditingController controller;

  @override
  void initState() {
    super.initState();
    modifiedTripCost = widget.recommendedBidAUD;
    controller =
        TextEditingController(text: widget.recommendedBidAUD.toString());
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void adjustBidAmount(bool up) {
    setState(() {
      if (up) {
        modifiedTripCost += 0.5;
      } else {
        modifiedTripCost -= 0.5;
      }
      controller.text = modifiedTripCost.toStringAsFixed(2);
    });
  }

  void submitBid() {
    if (widget.onSubmit != null) {
      widget.onSubmit!(modifiedTripCost);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)
              ),
              elevation: 8,
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // From address
                    widget.fromCampusCode == null
                        ? Center(child: Text(widget.fromAddressName, style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),))
                        : Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(widget.fromCampusCode.toString()),
                        const SizedBox(width: 8),
                        Text(widget.fromAddressName),
                      ],
                    ),

                    const SizedBox(height: 8,),

                    const Center(child: Icon(Icons.arrow_downward_rounded)),

                    const SizedBox(height: 8,),

                    // To address
                    widget.toCampusCode == null
                        ? Center(child: Text(widget.toAddressName, style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold)))
                        : Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(widget.toCampusCode.toString()),
                        const SizedBox(width: 8),
                        Text(widget.toAddressName),
                      ],
                    ),

                    const SizedBox(height: 15,),

                    Center(
                      child: Text(
                        "Recommended Bid",
                        style: Theme
                            .of(context)
                            .textTheme
                            .titleMedium,
                      ),
                    ),

                    // Bid adjust buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () => adjustBidAmount(false),
                          child: const Icon(Icons.remove, color: Colors.black),
                        ),
                        const SizedBox(width: 16),
                        Text("${controller.text} AUD", style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: () => adjustBidAmount(true),
                          child: const Icon(Icons.add, color: Colors.black),
                        ),
                      ],
                    ),

                    const SizedBox(height: 15,),

                    // Submit button
                    GestureDetector(
                      onTap: submitBid,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.blue, // button color
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            "Submit Bid",
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        )
    );
  }
}