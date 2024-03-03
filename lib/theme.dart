import 'package:blackbox/constants.dart';
import 'package:flutter/material.dart';

ThemeData blackboxTheme = ThemeData.dark().copyWith(
  appBarTheme: const AppBarTheme(color: Colors.black),
  scaffoldBackgroundColor: kScaffoldBackgroundColor,
  buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),

  textTheme: const TextTheme(
    bodyText2: TextStyle(
      fontSize: 18,
    ),
    button: TextStyle(color: Colors.pink),
  ),

  popupMenuTheme: const PopupMenuThemeData().copyWith(
    elevation: 5,
    color: kHubDividerColor,
      shape: const RoundedRectangleBorder(side: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(10)))
  ),
);