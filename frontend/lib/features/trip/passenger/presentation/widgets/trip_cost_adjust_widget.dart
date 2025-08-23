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
        TextEditingController(text: widget.recommendedBidAUD.toStringAsFixed(2));
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
          padding: const EdgeInsets.all(16),
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: 400,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // From address
                  widget.fromCampusCode == null
                      ? Text(
                    widget.fromAddressName,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                      fontFamily: 'B612'
                    ),
                    textAlign: TextAlign.center,
                  )
                      : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        widget.fromCampusCode.toString().split('.').last.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                          letterSpacing: 2,
                          fontFamily: 'B612'
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          widget.fromAddressName,
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                            fontFamily: 'B612'
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  const Icon(
                    Icons.arrow_downward_rounded,
                    size: 24,
                    color: Colors.black54,
                  ),

                  const SizedBox(height: 8),

                  // To address
                  widget.toCampusCode == null
                      ? Text(
                    widget.toAddressName,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                      fontFamily: 'B612'
                    ),
                    textAlign: TextAlign.center,
                  )
                      : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        widget.toCampusCode.toString().split('.').last.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                          letterSpacing: 2,
                          fontFamily: 'B612'
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          widget.toAddressName,
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                            fontFamily: 'B612'
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 15),

                  // Recommended Bid text
                  const Text(
                    "Recommended Bid",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black54,
                      fontFamily: 'GoogleSans'
                    ),
                  ),

                  // Bid adjust buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                        child: IconButton(
                          onPressed: modifiedTripCost > 0.5 ? () => adjustBidAmount(false) : null,
                          icon: const Icon(
                            Icons.remove,
                            color: Colors.black54,
                            size: 20,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                      ),

                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          "AUD${controller.text}",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                            fontFamily: 'GoogleSans'
                          ),
                        ),
                      ),

                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                        child: IconButton(
                          onPressed: () => adjustBidAmount(true),
                          icon: const Icon(
                            Icons.add,
                            color: Colors.black54,
                            size: 20,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 15),

                  // Submit button
                  GestureDetector(
                    onTap: submitBid,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          "Bid",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                            fontFamily: 'GoogleSans'
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}