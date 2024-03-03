import 'package:blackbox/constants.dart';
import 'package:flutter/material.dart';

ThemeData blackboxTheme = ThemeData.dark().copyWith(
  appBarTheme: AppBarTheme(color: Colors.black),
  scaffoldBackgroundColor: kScaffoldBackgroundColor,
  buttonTheme: ButtonThemeData(textTheme: ButtonTextTheme.primary),

  textTheme: TextTheme(
    bodyText2: TextStyle(
      fontSize: 18,
    ),
    button: TextStyle(color: Colors.pink),
  ),

  popupMenuTheme: PopupMenuThemeData().copyWith(
    elevation: 5,
    color: kHubDividerColor,
      shape: RoundedRectangleBorder(side: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(10)))
  ),
);