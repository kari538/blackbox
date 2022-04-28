import 'route_names.dart';
import 'package:blackbox/units/small_functions.dart';

import 'my_firebase_labels.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:provider/provider.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'game_hub_updates.dart';
import 'units/blackbox_popup.dart';
import 'upload_setup_button.dart';
import 'online_screens/game_hub_screen.dart';
import 'online_screens/reg_n_login_screen.dart';
import 'my_firebase.dart';
import 'atom_n_beam.dart';
import 'play.dart';
import 'package:flutter/material.dart';

/// Menu consisting of:
/// - Clear all atoms
/// - Fill with atoms
/// - Clear all mark-up
/// - Fill with mark-up
/// - Upload setup to game hub

enum selected { clearAtoms, clearMarkUp, fillAtoms, fillMarkUp, toGameHub }

class PlayScreenMenu extends StatelessWidget {
  const PlayScreenMenu(this.thisGame, {this.rebuildPlayScreen, this.entries});

  final Play thisGame;
  final Function rebuildPlayScreen;
  final List<int> entries;

  static const List<PopupMenuItem> menu = [
    PopupMenuItem(child: Text("Clear all atoms"), value: selected.clearAtoms),
    PopupMenuItem(child: Text("Clear all mark-up"), value: selected.clearMarkUp),
    PopupMenuItem(child: Text("Fill with atoms"), value: selected.fillAtoms),
    PopupMenuItem(child: Text("Fill with mark-up"), value: selected.fillMarkUp),
    PopupMenuItem(child: Text("Upload this setup to game hub"), value: selected.toGameHub),
  ];

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(itemBuilder: (context) {
      List<PopupMenuItem> _menuEntries = [];
      if (entries == null) {
        _menuEntries = menu;
      } else {
        for (int i = 0; i < menu.length; i++) {
          if (entries.contains(i)) _menuEntries.add(menu[i]);
        }
      }
      return _menuEntries;
    }, onSelected: (value) async {
      print('$value');

      switch (value) {
        case selected.clearAtoms:
          {
            thisGame.playerAtoms = [];
            rebuildPlayScreen();
          }
          break;
        case selected.clearMarkUp:
          {
            thisGame.markUpList = [];
            rebuildPlayScreen();
          }
          break;
        case selected.fillAtoms:
          {
            thisGame.playerAtoms = [];
            for (int x = 1; x <= thisGame.widthOfPlayArea; x++) {
              for (int y = 1; y <= thisGame.heightOfPlayArea; y++) {
                thisGame.playerAtoms.add(Atom(x, y));
              }
            }
            rebuildPlayScreen();
          }
          break;
        case selected.fillMarkUp:
          {
            thisGame.markUpList = [];
            for (int x = 1; x <= thisGame.widthOfPlayArea; x++) {
              for (int y = 1; y <= thisGame.heightOfPlayArea; y++) {
                thisGame.markUpList.add([x, y]);
              }
            }
            rebuildPlayScreen();
          }
          break;
        case selected.toGameHub:
          {
            print('Selected upload to game hub');
            // If not logged in: Go to Log in Sign up page. No popup needed.
            // If logged in: Popup to ask if you want to upload as User
            // - If yes: Upload
            // - If no: Cancel
            // - If change user: Go to Log in Sign up page.
            print('MyFirebase.authObject.currentUser is ${MyFirebase.authObject.currentUser}');
            // String myUid = '';
            if (MyFirebase.authObject.currentUser == null) {
              // Not logged in
              changeLoginThenUpload(context, /*myUid,*/ thisGame);
            } else {
              String myScreenName = MyFirebase.authObject.currentUser.displayName;
              if (myScreenName == null) {
                DocumentSnapshot userInfo = await MyFirebase.storeObject.collection(kCollectionUserInfo).doc(myUid).get();
                Map<String, dynamic> myUserInfo = userInfo.data();
                if (myUserInfo.containsKey(kFieldScreenName)) {
                  myScreenName = myUserInfo[kFieldScreenName];
                  MyFirebase.authObject.currentUser.updateDisplayName(myScreenName);
                }
              }
              // Future<String> getMyPlayerId() async {
              // String myScreenName;
              // String myEmail = MyFirebase.authObject.currentUser.email;
              // QuerySnapshot loggedInUserInfo = await MyFirebase.storeObject
              //     .collection('userinfo')
              //     .where('email', isEqualTo: myEmail)
              //     .get(); //No stream needed, coz the document no is not supposed to change
              // if (ListEquality().equals(loggedInUserInfo.docs, [])) {
              //   //I don't have an entry in 'userinfo', which shouldn't ever happen:
              //   print("I don't have an entry in 'userinfo', which shouldn't ever happen!!");
              //   myScreenName = 'no screen name';
              // } else {
              //   Map myUserInfo = loggedInUserInfo.docs[0].data();
              //   myScreenName = myUserInfo[kFieldScreenName];
              // }
              // print("My screen name is '$myScreenName'");
              // }

              // String myScreenName = Provider.of<GameHubUpdates>(context, listen: false).providerUserIdMap[myUid];
              await BlackboxPopup(
                      context: context,
                      title: 'Upload',
                      desc: 'Upload this setup to the game hub as $myScreenName?',
                      buttons: [
                        BlackboxPopupButton(
                            text: 'Ok',
                            onPressed: () async {
                              Navigator.pop(context);

                              await UploadSetupButton.uploadButtonPress(context: context, thisGame: thisGame, popToEndRoute: false);

                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      settings: RouteSettings(name: routeGameHub),
                                      builder: (context) {
                                        return GameHubScreen();
                                      }));
                            }),
                        BlackboxPopupButton(
                            text: 'Cancel',
                            onPressed: () {
                              Navigator.pop(context);
                            }),
                        BlackboxPopupButton(
                            text: 'Change User',
                            onPressed: () {
                              Navigator.pop(context);
                              changeLoginThenUpload(context, /* myUid, */ thisGame);
                            }),
                      ],
                      buttonsDirection: ButtonsDirection.column)
                  .show();
            }
          }
          break;
      }
    });
  }
}

void changeLoginThenUpload(BuildContext context, Play thisGame) async {
  auth.User userBefore;
  String uidBefore;
  auth.User userAfter;
  String uidAfter;
  bool userChanged = false;

  userBefore = MyFirebase.authObject.currentUser;
  if (userBefore != null) uidBefore = userBefore.uid;
  await Navigator.push(context, MaterialPageRoute(settings: RouteSettings(name: routeRegLogin), builder: (context) {
    return RegistrationAndLoginScreen(withPop: true);
  }));
  userAfter = MyFirebase.authObject.currentUser;
  if (userAfter != null) uidAfter = userAfter.uid;

  userChanged = uidBefore != uidAfter;

  if (userChanged) {
    print('There was a user change in changeLoginThenUpload()');
    await UploadSetupButton.uploadButtonPress(context: context, thisGame: thisGame, popToEndRoute: false);

    Navigator.push(
        context,
        MaterialPageRoute(
            settings: RouteSettings(name: routeGameHub),
            builder: (context) {
              return GameHubScreen();
            }));
  } else {
    print('There was no user change in changeLoginThenUpload(). No action.');
  }
}
