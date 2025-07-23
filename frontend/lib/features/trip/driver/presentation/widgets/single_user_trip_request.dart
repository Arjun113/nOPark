// Purpose: display one possible trip

import 'package:flutter/material.dart';
import 'package:nopark/features/profiles/presentation/widgets/address_scroller.dart';

class AddressCard extends StatelessWidget {
  final String name;
  final double rating;
  final AddressCardData address;
  final double detourInfo;
  final double cost;
  final bool selected;
  final VoidCallback onTap;

  const AddressCard({
    super.key,
    required this.name,
    required this.rating,
    required this.address,
    required this.detourInfo,
    required this.cost,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? Colors.purple.shade100 : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? Colors.blue : Colors.transparent,
            width: 4,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Row(
                  children: [
                    Text(
                      rating.toStringAsFixed(1),
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.star, color: Colors.amber, size: 18),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(address.addressLine1Controller.text, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 4),
            Text(address.addressLine2Controller.text, style: const TextStyle(fontSize: 14)),
            Text(detourInfo.toString(), style: TextStyle(fontSize: 12, color: Colors.black)),
            const SizedBox(height: 8),
            Center(
              child: Text(
                cost.toString(),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            )
          ],
        ),
      ),
    );
  }
}