import 'package:flutter/material.dart';
import 'package:blackbox/constants.dart';

class InfoText extends StatelessWidget {
  InfoText(this.text);
  final String text;
  final TextStyle style = TextStyle(
      fontSize: 14,
      color: kSmallResultsColor
  );

  @override
  Widget build(BuildContext context) {
    return Text(text, style: style);
  }
}
