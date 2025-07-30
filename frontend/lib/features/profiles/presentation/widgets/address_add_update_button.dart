import 'package:flutter/material.dart';
import '../../../../constants/address_actions.dart';

ValueNotifier<AddressActions?> carActionNotifier = ValueNotifier(null);

class OptionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const OptionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 100,
          height: 100,
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: Colors.black),
              const SizedBox(height: 8),
              Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}

void showCarActionDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      return AlertDialog(
        backgroundColor: Colors.grey.shade200,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Do you wish to add a new car\nor update an existing one?",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OptionButton(
                  icon: Icons.add,
                  label: "Add",
                  color: Colors.amber.shade300,
                  onTap: () {
                    carActionNotifier.value = AddressActions.addNew;
                    Navigator.of(context).pop();
                  },
                ),
                const SizedBox(width: 16),
                OptionButton(
                  icon: Icons.edit,
                  label: "Update",
                  color: Colors.blue.shade300,
                  onTap: () {
                    carActionNotifier.value = AddressActions.updateExisting;
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}
