// Purpose: OTP entry

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OTPEntry extends StatefulWidget {
  final int otpLength;
  final TextEditingController controller;

  const OTPEntry({
    super.key,
    required this.otpLength,
    required this.controller,
  });

  @override
  State<StatefulWidget> createState() {
    return OTPEntryState();
  }
}

class OTPEntryState extends State<OTPEntry> {
  late List<FocusNode> focusNodes;
  late List<TextEditingController> textControllers;

  @override
  void initState() {
    super.initState();
    focusNodes = List.generate(widget.otpLength, (_) => FocusNode());
    textControllers = List.generate(
      widget.otpLength,
      (_) => TextEditingController(),
    );
  }

  void updateMainController() {
    widget.controller.text = textControllers.map((c) => c.text).join();
  }

  void onInputChanged(String value, int index) {
    if (value.isNotEmpty && index < widget.otpLength - 1) {
      focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      focusNodes[index - 1].requestFocus();
    }

    updateMainController();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(widget.otpLength, (index) {
        return SizedBox(
          width: 60,
          child: TextField(
            controller: textControllers[index],
            textAlign: TextAlign.center,
            focusNode: focusNodes[index],
            maxLength: 1,
            decoration: InputDecoration(
              counterText: '',
              border: OutlineInputBorder(),
            ),
            style: TextStyle(fontSize: 20),
            keyboardType: TextInputType.number,
            inputFormatters: [LengthLimitingTextInputFormatter(1)],
            onChanged: (value) => onInputChanged(value, index),
          ),
        );
      }),
    );
  }
}
