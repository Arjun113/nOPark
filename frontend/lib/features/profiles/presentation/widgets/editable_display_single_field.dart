// Purpose: inline elegant editable single-line fields

import 'package:flutter/material.dart';

class EditableSingleLine extends StatefulWidget {
  final String initialValue;
  final ValueChanged<String> onUpdate;
  final TextInputType keyboardType;

  const EditableSingleLine({
    super.key,
    required this.initialValue,
    required this.onUpdate,
    required this.keyboardType,
  });

  @override
  State<StatefulWidget> createState() {
    return EditableSingleLineState();
  }
}

class EditableSingleLineState extends State<EditableSingleLine> {
  bool isEditing = false;
  late TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.initialValue);
  }

  void toggleEdit() {
    isEditing = !isEditing;
  }

  @override
  Widget build(BuildContext context) {
    if (isEditing == true) {
      return Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: true,
              autocorrect: false,
              keyboardType: widget.keyboardType,
              style: const TextStyle(fontSize: 24),
              onSubmitted: (value) {
                widget.onUpdate(value);
                toggleEdit();
              },
            ),
          ),
          IconButton(
            onPressed: () {
              widget.onUpdate(controller.text);
              toggleEdit();
            },
            icon: const Icon(Icons.check),
          ),
        ],
      );
    } else {
      return Row(
        children: [
          Expanded(
            child: Text(controller.text, style: const TextStyle(fontSize: 24)),
          ),
          IconButton(onPressed: toggleEdit, icon: const Icon(Icons.edit)),
        ],
      );
    }
  }
}
