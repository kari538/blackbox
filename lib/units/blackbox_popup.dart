import 'package:flutter/material.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

class BlackboxPopup extends Alert {
  BlackboxPopup({
    required this.context,
    required this.title,
    required this.desc,
    this.buttons,
    this.buttonsDirection,
  }) : super (context: context) {
//  Function onPressed = (){Navigator.pop(context);};
    buttons = buttons ?? [
      DialogButton(
        child: Text('OK', style: TextStyle(color: Colors.black)),
        onPressed: (){Navigator.pop(context);},
        color: Colors.white,
      )
    ];

    style = AlertStyle(
      isOverlayTapDismiss: false,
      backgroundColor: Colors.deepPurple.shade200,
      // backgroundColor: Color(0xff7488c1),
      overlayColor: Colors.black45,
      isCloseButton: true,
      buttonsDirection: buttonsDirection ?? ButtonsDirection.row,
    );
  }

  String title;
  String desc;
  BuildContext context;
  List<DialogButton>? buttons;
  ButtonsDirection? buttonsDirection;

  late AlertStyle style;

}


class BlackboxPopupButton extends DialogButton {
  BlackboxPopupButton({required this.text, required this.onPressed}) : super(child: null, onPressed: null);
  // BlackboxPopupButton({required this.text, required this.onPressed});
  final String text;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DialogButton(
        child: Text(text, style: TextStyle(color: Colors.black)),
        color: Colors.white,
        onPressed: onPressed,
    );
  }
}
