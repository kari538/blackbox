import 'package:flutter/material.dart';
//import 'constants.dart';

class OnlineButton extends StatelessWidget {
  const OnlineButton({
    required this.onPressed,
    required this.text,
//    this.color = kSlightPurple,
    this.color = Colors.blueAccent,
    this.fontSize = 15,
    this.textColor = Colors.white,
    this.borderColor = Colors.transparent,
  });

  final Function? onPressed;
  final String text;
  final Color color;
  final double fontSize;
  final Color textColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return RaisedButton(
      child: Text('$text',
//        style: TextStyle(color: Colors.teal,
        style: TextStyle(
          color: textColor,
          fontSize: fontSize,
        ),
      ),
//              onPressed: null,
      onPressed: onPressed as void Function()?,
      color: color,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: borderColor),
        borderRadius: BorderRadius.circular(30),
      ),
    );
  }
}