// Purpose: Data Entry in forms for login and signup.

import 'package:flutter/material.dart';

class FormField extends StatefulWidget{
  final String fieldTitle;
  final TextEditingController controller;

  const FormField({super.key, required this.fieldTitle, required this.controller});

  @override
  State<StatefulWidget> createState() {
    return FormFieldState();
  }

}

class FormFieldState extends State<FormField> {

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
         widget.fieldTitle
        ),
        SizedBox(height: 5),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(50),
            color: Theme.of(context).primaryColor
          ),
          child: TextField(
            controller: widget.controller,
          ),
        )
      ],
    );
  }
}