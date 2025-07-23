// Purpose: Get the new address in

import 'package:flutter/material.dart';
import 'package:nopark/features/profiles/presentation/widgets/address_scroller.dart';

Future<AddressCardData?> showAddressPopup(BuildContext context) async {
  final nameController = TextEditingController();
  final line1Controller = TextEditingController();
  final line2Controller = TextEditingController();

  return showDialog<AddressCardData>(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("New Address", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: _inputDecoration("Name"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: line1Controller,
                decoration: _inputDecoration("Address Line 1"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: line2Controller,
                decoration: _inputDecoration("Address Line 2"),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () {
                  final data = AddressCardData();
                  data.addressNameController.text = nameController.text;
                  data.addressLine1Controller.text = line1Controller.text;
                  data.addressLine2Controller.text = line2Controller.text;
                  Navigator.of(context).pop(data); // 👈 Return the data
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4A8FE7), Color(0xFFFFB74D)],
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  alignment: Alignment.center,
                  child: const Text("Add", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              )
            ],
          ),
        ),
      );
    },
  );
}


InputDecoration _inputDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(28),
      borderSide: const BorderSide(color: Colors.black38),
    ),
  );
}


class AddressAddInput extends StatelessWidget {
  const AddressAddInput({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        final result = await showAddressPopup(context);
        if (result != null) { // Print is only for debugging
          print("Name: ${result.addressNameController.text}");
          print("Line 1: ${result.addressLine1Controller.text}");
          print("Line 2: ${result.addressLine2Controller.text}");
        }
      },
      child: const Text("Add", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),),
    );
  }
}