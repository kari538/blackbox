import 'package:blackbox/upload_player_atoms.dart';

import 'upload_markup.dart';
import 'route_names.dart';
import 'my_firebase_labels.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:rflutter_alert/rflutter_alert.dart';
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

/// If entry 0, "clear all atoms" is used, rebuildPlayScreen can not be null.
/// If thisGame.online, setup can not be null.
class PlayScreenMenu extends StatelessWidget {
  const PlayScreenMenu(this.thisGame, {this.setup, this.rebuildScreen, this.entries});

  final Play thisGame;
  final DocumentSnapshot? setup;
  final Function? rebuildScreen;
  final List<int>? entries;

  static const List<PopupMenuItem> menu = [
    PopupMenuItem(child: Text("Clear all atoms"), value: selected.clearAtoms),
    PopupMenuItem(child: Text("Clear all mark-up"), value: selected.clearMarkUp),
    PopupMenuItem(child: Text("Fill with atoms"), value: selected.fillAtoms),
    PopupMenuItem(child: Text("Fill with mark-up"), value: selected.fillMarkUp),
    PopupMenuItem(child: Text("Upload this setup to game hub"), value: selected.toGameHub),
  ];

  @override
  Widget build(BuildContext context) {
    // Some checks before we execute:
    if (entries != null && entries!.contains(0) && rebuildScreen == null) {
      throw 'Error in ${this.runtimeType}:'
          '\n rebuildScreen can\'t be null if menu entry "Clear all atoms" is used.';
    }
    if (thisGame.online && setup == null) {
      throw 'Error in ${this.runtimeType}:'
          '\n thisGame.online is true, but setup is null!';
    }

    return PopupMenuButton(itemBuilder: (context) {
      List<PopupMenuItem> _menuEntries = [];
      if (entries == null) {
        _menuEntries = menu;
      } else {
        for (int i = 0; i < menu.length; i++) {
          if (entries!.contains(i)) _menuEntries.add(menu[i]);
        }
      }
      return _menuEntries;

    }, onSelected: (dynamic value) async {
      // Where all the action happens:

      print('$value');

      switch (value) {
        case selected.clearAtoms:
          {
            thisGame.playerAtoms = [];
            thisGame.setPlayerMoves(clearAllAtoms: true);
            rebuildScreen!();

            if (thisGame.online){
              uploadPlayerAtoms(thisGame, setup!);
              // List<int> playingAtomsArray = [];
              // for (Atom pAtom in thisGame.playerAtoms) {
              //   playingAtomsArray.add(pAtom.position.x);
              //   playingAtomsArray.add(pAtom.position.y);
              // }
              // MyFirebase.storeObject.collection('setups').doc(setup!.id).update({
              //   'playing.${thisGame.playerUid}.playingAtoms': playingAtomsArray,
              //   'playing.${thisGame.playerUid}.$kSubFieldLastMove': FieldValue.serverTimestamp(),
              // });
            }
          }
          break;
        case selected.clearMarkUp:
          {
            thisGame.markUpList = [];
            thisGame.setPlayerMoves(clearAllMarkup: true);
            rebuildScreen!();

            if (thisGame.online){
              uploadMarkup(thisGame, setup!);
              // List<int> markUpArray = [];
              // for (List<int> markUp in thisGame.markUpList){
              //   markUpArray.add(markUp[0]);
              //   markUpArray.add(markUp[1]);
              // }
              // MyFirebase.storeObject.collection(kCollectionSetups).doc(setup!.id).update({
              //   'playing.${thisGame.playerUid}.$kSubFieldMarkUpList': markUpArray,
              // });
            }
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
            thisGame.setPlayerMoves(fillWithAtoms: true);

            rebuildScreen!();
            if (thisGame.online) {
              uploadPlayerAtoms(thisGame, setup!);
            }
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
            thisGame.setPlayerMoves(fillWithMarkup: true);
            rebuildScreen!();
            if (thisGame.online) {
              uploadMarkup(thisGame, setup!);
            }
          }
          break;
        case selected.toGameHub:
          {
            print('Selected upload to game hub');
            // If not logged in: Go to reg_n_login_screen. No popup needed.
            // If logged in: Popup to ask if you want to upload as User
            // - If yes: Upload
            // - If no: Cancel
            // - If change user: Go to Log in Sign up page.
            //   - If change user successful: Upload
            //   - If not successful: .....?
            print('MyFirebase.authObject.currentUser is ${MyFirebase.authObject.currentUser}');
            // String myUid = '';
            if (MyFirebase.authObject.currentUser == null) {
              // Not logged in
              changeLoginThenUpload(context, /*myUid,*/ thisGame);
            } else {
              String myUid = MyFirebase.authObject.currentUser!.uid;
              String? myScreenName = MyFirebase.authObject.currentUser!.displayName;

              if (myScreenName == null) {
                // Attempt to get hold of a screenName:
                DocumentSnapshot? userInfo;
                Map<String, dynamic>? myUserInfo;
                try {
                  userInfo = await MyFirebase.storeObject.collection(kCollectionUserInfo).doc(myUid).get();
                  myUserInfo = userInfo.data() as Map<String, dynamic>;
                }  catch (e) {
                  print('Error in ${this.runtimeType}: $e');
                  // await BlackboxPopup(context: context, title: 'Error connecting to database', desc: '$e').show();
                }
                if (myUserInfo != null && myUserInfo.containsKey(kFieldScreenName)) {
                  myScreenName = myUserInfo[kFieldScreenName];
                  MyFirebase.authObject.currentUser!.updateDisplayName(myScreenName);
                }
              }

              // With or without screenName:
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
  auth.User? userBefore;
  String? uidBefore;
  auth.User? userAfter;
  String? uidAfter;
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
