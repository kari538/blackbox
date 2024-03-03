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
    this.color = Colors.blue,
    this.textColor = Colors.white,
    this.shape = const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
    Key? key,
  }) : super(key: key);
  final Function? onPressed;
  final Widget child;
  // final String text;
  final Color color;
  final Color textColor;
  final OutlinedBorder shape;

  @override
  Widget build(BuildContext context) {
    // if (color != null && shape != null) {
      return ElevatedButton(
        // onPressed: onPressed,
        onPressed: onPressed != null ? (){onPressed!();} : null,
        child: child,
        // child: Text('$text'),
        // From ChatGPT:
        style: ButtonStyle(
          foregroundColor: MaterialStatePropertyAll<Color>(Colors.white),
          // foregroundColor: MaterialStatePropertyAll<Color>(textColor),
          shape: MaterialStatePropertyAll<OutlinedBorder>(shape),
          backgroundColor: MaterialStateProperty.resolveWith<Color>(
                (Set<MaterialState> states) {
              if (states.contains(MaterialState.disabled)) {
                // Return the color you want for inactive state
                return Colors.blueGrey.shade700; // Change to your desired inactive color
                // return Colors.grey; // Change to your desired inactive color
              }
              // Return the default color for enabled state
              return Colors.blue; // Change to your desired active color
            },
          ),
        ),
        // style: ButtonStyle(
        //   backgroundColor: MaterialStatePropertyAll<Color>(color),
        //   foregroundColor: MaterialStatePropertyAll<Color>(textColor),
        //   shape: MaterialStatePropertyAll<OutlinedBorder>(shape),
        // ),
      );
    // }
    // return ElevatedButton(onPressed: onPressed(), child: child);
  }
}
