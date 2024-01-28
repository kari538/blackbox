import 'package:blackbox/online_button.dart';

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
      onPressed: () {
        Navigator.pop(context, false);
      },
    );
  }
}

class MyRaisedButton extends StatelessWidget {
  const MyRaisedButton({
    required this.child,
    required this.onPressed,
    this.color,
    this.shape,
    Key? key,
  }) : super(key: key);
  final Function? onPressed;
  final Widget child;
  // final String text;
  final Color? color;
  final OutlinedBorder? shape;

  @override
  Widget build(BuildContext context) {
    // if (color != null && shape != null) {
      return ElevatedButton(
        // onPressed: onPressed,
        onPressed: onPressed != null ? (){onPressed!();} : null,
        child: child,
        // child: Text('$text'),
        style: ButtonStyle(
          backgroundColor: MaterialStatePropertyAll<Color?>(color),
          shape: MaterialStatePropertyAll<OutlinedBorder?>(shape),
        ),
      );
    // }
    // return ElevatedButton(onPressed: onPressed(), child: child);
  }
}
