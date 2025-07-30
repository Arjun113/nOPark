//Purpose - Assign roles

import 'package:flutter/material.dart';

class RoleButton extends StatefulWidget {
  final String role;
  final String description;
  final Icon icon;
  final Color color;

  const RoleButton({
    super.key,
    required this.role,
    required this.icon,
    required this.description,
    required this.color,
  });

  @override
  State<StatefulWidget> createState() {
    return RoleButtonState();
  }
}

class RoleButtonState extends State<RoleButton> {
  bool selected = false;
  Color fillCol = Colors.grey.shade400;

  void selectionChange() {
    if (selected == true) {
      selected == false;
      fillCol = Colors.grey.shade400;
    } else {
      selected == true;
      fillCol = Colors.grey.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: selectionChange,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(width: 5, color: widget.color),
          color: fillCol,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Text(widget.role, style: TextStyle(fontSize: 50)),
                SizedBox(height: 10),
                widget.icon,
              ],
            ),
            Row(
              children: [
                Text(widget.description, style: TextStyle(fontSize: 25)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
