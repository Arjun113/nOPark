// Purpose - Holds Static Imagery (logo, icons, etc)

import 'package:flutter/material.dart';

class ImageHolder extends StatelessWidget {
  final String image;

  const ImageHolder({super.key, required this.image});

  @override
  Widget build(BuildContext context) {
    return Image.asset(image, fit: BoxFit.cover);
  }
}
