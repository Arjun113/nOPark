import 'package:flutter/material.dart';
import 'package:nopark/features/trip/entities/user.dart';

class WhereToNextWidget extends StatelessWidget {
  final User user;
  final List<Map<String, dynamic>> addresses;

  const WhereToNextWidget({super.key, required this.user, required this.addresses});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTile(
          icon: Icons.location_on_outlined,
          text: "Where to next?",
          context: context)
      ],
    );
  }

  Widget _buildTile({
    IconData? icon,
    String? iconImage,
    required String text,
    required BuildContext context
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.grey.shade200, // matches light gray background
        borderRadius: BorderRadius.circular(12),
      ),
      width: MediaQuery.of(context).size.width*0.87,
      child: Row(
        children: [
          if (icon != null)
            Icon(icon, color: Colors.black87)
          else if (iconImage != null)
            Image.asset(iconImage, height: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 20,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}