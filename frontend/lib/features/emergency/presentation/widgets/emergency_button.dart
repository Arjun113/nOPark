// Purpose: make an emergency button for calling

import 'package:flutter/material.dart';
import '../../emergency_call.dart';
import '../../../../constants/emergency_contact.dart';

class EmergencyButton extends StatelessWidget {
  const EmergencyButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: EmergencyCaller.callEmergencyServices,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text("Call $victoriaEmergencyContact"),
      ),
    );
  }
}
