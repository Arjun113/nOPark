// Purpose: obsfucated data such as passwords

import 'package:flutter/material.dart';

class ObfuscatedFormField extends StatefulWidget {
  final String fieldTitle;
  final TextEditingController controller;

  const ObfuscatedFormField({
    super.key,
    required this.fieldTitle,
    required this.controller,
  });

  @override
  State<StatefulWidget> createState() {
    return ObfuscatedFormFieldState();
  }
}

class ObfuscatedFormFieldState extends State<ObfuscatedFormField> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.fieldTitle),
        SizedBox(height: 5),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(50),
            color: Theme.of(context).primaryColor,
          ),
          child: TextField(obscureText: true, controller: widget.controller),
        ),
      ],
    );
  }
}
