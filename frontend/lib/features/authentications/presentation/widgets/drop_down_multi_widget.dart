// Purpose: multiple-choice entry (license conditions, e.g.)

import 'package:flutter/material.dart';

class DropDownMultiSelect extends StatefulWidget{
  final List<String> options;
  final String purpose;
  final TextEditingController controller;

  const DropDownMultiSelect({super.key, required this.purpose, required this.options, required this.controller});

  @override
  State<StatefulWidget> createState() {
    return DropDownMultiSelectState();
  }
}


class DropDownMultiSelectState extends State<DropDownMultiSelect> {
  List<String> selectedOptions = [];

  void openDialogBox () async {
    final Set<String> initialSelected = Set.from(selectedOptions);

    final result = await showDialog(context: context, builder: (context) {
      return StatefulBuilder (
        builder: (context, setStateDialog) {
          return AlertDialog(
           title: Text(widget.purpose),
            content: SingleChildScrollView(
              child: Column(
                children: widget.options.map((item) {
                  final isChecked = selectedOptions.contains(item);
                  return CheckboxListTile(
                      value: isChecked,
                      title: Text(item),
                      onChanged: (checked) {
                        if (checked == true) {
                          initialSelected.add(item);
                        }
                        else {
                          initialSelected.remove(item);
                        }
                      });
                }).toList(),
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel')),
              ElevatedButton(
                  onPressed: () => Navigator.pop(context, selectedOptions),
                  child: Text('Confirm'))
            ],
          );
      },
    );
    }
    );

    if (result != null) {
      setState(() {
        selectedOptions = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedOptionsList = List.from(selectedOptions);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(widget.purpose),
        SizedBox(height: 10),
        GestureDetector(
          onTap: openDialogBox,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black87),
              borderRadius: BorderRadius.circular(6)
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: selectedOptionsList.map((item) {
                return Chip(
                  label: Text(item),
                  onDeleted: () {
                    setState(() {
                      selectedOptions.remove(item);
                      selectedOptionsList.remove(item);
                    });
                  },
                );
              }).toList(),
            ),
          ),
        )
      ],
    );

  }
}