// Purpose: set dates (rego, birth etc)

import 'package:flutter/material.dart';

class DatePickerField extends StatefulWidget {
  final String datePurpose;
  final TextEditingController controller;

  const DatePickerField({
    super.key,
    required this.datePurpose,
    required this.controller,
  });

  @override
  State<StatefulWidget> createState() {
    return DatePickerFieldState();
  }
}

class DatePickerFieldState extends State<DatePickerField> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.datePurpose),
        SizedBox(height: 5),
        TextField(
          controller: widget.controller,
          decoration: const InputDecoration(
            icon: Icon(Icons.calendar_today_sharp),
          ),
          readOnly: true,
          onTap: () async {
            DateTime? selectedDate = await showDatePicker(
              context: context,
              firstDate: DateTime(1900),
              lastDate: DateTime.now().subtract(Duration(days: 365 * 17)),
            );

            if (selectedDate != null) {
              String formattedDate = selectedDate.toString();
              setState(() {
                widget.controller.text = formattedDate;
              });
            }
          },
        ),
      ],
    );
  }
}
