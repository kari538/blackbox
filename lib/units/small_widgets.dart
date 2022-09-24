import 'blackbox_popup.dart';
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

/// Button with text 'Cancel'. Pops the popup with result 'false'.
class CancelPopupButton extends BlackboxPopupButton {
  CancelPopupButton(this.context) : super (text: '', onPressed: (){});

  final BuildContext context;
  final String text = 'Cancel';

  @override
  Widget build(BuildContext buttonContext) {
    return BlackboxPopupButton(
      text: text,
      onPressed: (){
        Navigator.pop(context, false);
      },
    );
  }
}