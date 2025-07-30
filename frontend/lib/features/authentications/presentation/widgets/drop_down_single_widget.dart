// Purpose - select one option out of what is given

import 'package:flutter/material.dart';

class DropDownSingleSelect extends StatefulWidget {
  final List<String> options;
  final TextEditingController controller;
  final String purpose;

  const DropDownSingleSelect({
    super.key,
    required this.options,
    required this.controller,
    required this.purpose,
  });

  @override
  State<StatefulWidget> createState() {
    return DropDownSingleSelectState();
  }
}

class DropDownSingleSelectState extends State<DropDownSingleSelect> {
  String? selectedItem;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(widget.purpose),
        SizedBox(height: 10),
        DropdownButton(
          items:
              widget.options.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  child: Text(value),
                  value: value,
                );
              }).toList(),
          onChanged: (_) => onUpdate(),
          hint: Text(widget.purpose),
          value: selectedItem,
        ),
      ],
    );
  }

  void onUpdate() {
    widget.controller.text = selectedItem!;
  }
}
