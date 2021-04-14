import 'online_screens/profile_screen.dart';
import 'package:blackbox/constants.dart';
//import 'package:blackbox/screens/welcome_screen.dart';
import 'package:flutter/material.dart';
//import 'online_screens/choose_board_screen.dart';
import 'my_firebase.dart';
import 'online_screens/reg_n_login_screen.dart';

class GameHubMenu extends StatelessWidget {
  GameHubMenu(this.gameHubContext);

  final BuildContext gameHubContext;

  List<Widget> getItems(BuildContext context) {
    List<Widget> _menuList = [
//      Item(text: 'New game setup', goto: OnlineWelcomeScreen()),
      Item(
        text: 'My profile',
        value: () {
          Navigator.push(context, MaterialPageRoute(builder: (context){
            return ProfileScreen();
          }));
        },
      ),
      Item(
        text: 'Change user',
        value: () async {
//          Navigator.popUntil(context, ModalRoute.withName('reg_n_log') ?? ModalRoute.of(context).isFirst);
          Route endRoute;
          Navigator.of(context).popUntil((route) {
            bool done = false;
            if (route.isFirst) {
              done = true;
              endRoute = route;
            }
            if(route.settings.name == 'reg_n_log'){
              done = true;
              endRoute = route;
            }
            return done;
          });
          if(endRoute.isFirst){
            Navigator.push(context, MaterialPageRoute(builder: (context){
              return RegistrationAndLoginScreen();
            }));
          }
//          await Future.delayed(Duration(milliseconds: 500));
//          MyFirebase.logOut();
        },
      ),
      Item(
        text: 'Log out',
        value: () async {
          Navigator.of(context).popUntil((route) => route.isFirst);
          await Future.delayed(Duration(milliseconds: 500));
          MyFirebase.logOut();
        },
      ),
    ];
    print('_menuList in getItems() is $_menuList');
    return _menuList;
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      itemBuilder: (context) {
        List<Widget> menuList = getItems(context);
        List<PopupMenuEntry<dynamic>> itemList = [];
        for (int i = 0; i < menuList.length; i++) {
          itemList.add(
            PopupMenuItem(child: menuList[i]),
          );
        }
        return itemList;
      },
      onSelected: (value) {
        value();
      },
      color: kHubDividerColor,
      shape: RoundedRectangleBorder(side: BorderSide(color: kHubDividerColor)),
    );
  }
}

class Item extends StatelessWidget {
//class Item extends PopupMenuEntry {
  Item({@required this.text, this.goto, this.value});

  final String text;
  final Object goto;
  final Function value;

  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return text;
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuItem(
      child: Text('${text.toString()}'),
      //If both goto and value are null, return null. Otherwise return value or if it's null push goto:
      value: goto == null
          ? value ?? null
          : () {
        Navigator.push(context, MaterialPageRoute(builder: (context) {
          return goto;
        }));
      },
    );
  }
}