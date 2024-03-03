import 'play.dart';
import 'units/fcm_send_msg.dart';
import 'my_firebase_labels.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:blackbox/my_firebase_labels.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'screens/make_setup_screen.dart';
import 'online_button.dart';
import 'my_firebase.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'units/blackbox_popup.dart';
import 'package:provider/provider.dart';
import 'online_screens/reg_n_login_screen.dart';
import 'game_hub_updates.dart';
import 'online_screens/game_hub_screen.dart';
import 'atom_n_beam.dart';
import 'route_names.dart';

Future<String?>? token;
final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

class UploadSetupButton extends StatelessWidget {
  const UploadSetupButton({
    required this.widget,
//    this.currentUser
  });

  final MakeSetupScreen widget; //So that I can make widget. constructions

//  final currentUser;

//  Future<String> getLoggedInUser() async {
//    auth.FirebaseAuth authObject = auth.FirebaseAuth.instance;
//    FirebaseFirestore firestoreObject = FirebaseFirestore.instance;
////    var loggedInUser = await authObject.currentUser();
//    var loggedInUser;
//    authObject.userChanges().listen((event) {
////      if(){
//      loggedInUser = authObject.currentUser;
////      }
//      print("MakeSetupScreen getLoggedInUser() event.email is ${event.email}");
//    });
//
////    print('Setup screen printing user email: ${loggedInUser.email}');
////    return loggedInUser.email;
////    futureLoggedInUser = firebaseAuthObject.currentUser();
////    loggedInUser = await futureLoggedInUser;
//    String _myId;
//    QuerySnapshot loggedInUserInfo = await firestoreObject.collection('userinfo').where('email', isEqualTo: loggedInUser.email).get();  //No stream needed, coz the document no is not supposed to change
//    if (ListEquality().equals(loggedInUserInfo.docs, [])){
//      //I don't have an entry in 'userinfo', which shouldn't ever happen:
//      print("I don't have an entry in 'userinfo', which shouldn't ever happen!!");
//      _myId = 'anonymous';
//    } else {
//      _myId = loggedInUserInfo.docs[0].id;
//    }
//    print("My player ID is '$_myId'");
//    return _myId;
//  }
  final Map<String, String> data = const {
    "title": "New game hub setup",
    "body": "A new setup has come in to the game hub",
  };

  Future<String?> getToken() async {
    String? _token = await _firebaseMessaging.getToken();
    print("Token in Upload Button is $_token");
    return _token;
  }

  // I believe this was rendered unnecessary when I made all 'userinfo' doc IDs into the Uid!...
  // Future<String> getMyPlayerId() async {
  //   String _myId;
  //   if (MyFirebase.authObject.currentUser == null) {
  //     return null;
  //   } else {
  //     String myEmail = MyFirebase.authObject.currentUser.email;
  //     QuerySnapshot loggedInUserInfo = await MyFirebase.storeObject
  //         .collection('userinfo')
  //         .where('email', isEqualTo: myEmail)
  //         .get(); //No stream needed, coz the document no is not supposed to change
  //     if (ListEquality().equals(loggedInUserInfo.docs, [])) {
  //       //I don't have an entry in 'userinfo', which shouldn't ever happen:
  //       print("I don't have an entry in 'userinfo', which shouldn't ever happen!!");
  //       _myId = 'no screen name';
  //     } else {
  //       _myId = loggedInUserInfo.docs[0].id;
  //     }
  //     print("My player ID is '$_myId'");
  //     return _myId;
  //   }
  // }

  static Future uploadButtonPress({required BuildContext context, required Play thisGame, bool popToEndRoute = true}) async {
    // print("Token in onPressed is ${await token}");
    String myUid = MyFirebase.authObject.currentUser!.uid;
    // String myUid = await getMyPlayerId();   // I believe this was rendered unnecessary when I made all 'userinfo' doc IDs into the Uid!...
    print('OnlineButton printing player ID: $myUid');
    bool? needLogin = false;

    if (myUid == null) {
      //If no user is logged in
      needLogin = await (BlackboxPopup(
        context: context,
        title: 'Not Logged In!',
        desc: 'You are no longer logged in. Click OK to log in again.',
      ).show());
      // ).show() as FutureOr<bool>);
      // needLogin = true;
      if (needLogin == false) return; // If the user cancelled login, do nothing.
    }

    if (needLogin == true) {
      await Navigator.push(context, MaterialPageRoute(settings: RouteSettings(name: routeRegLogin), builder: (context) {
        return RegistrationAndLoginScreen(withPop: true);
      }));
      print("On return from new login, User is ${MyFirebase.authObject.currentUser}");
    }

    if (MyFirebase.authObject.currentUser != null) {
      myUid = MyFirebase.authObject.currentUser!.uid;

      List<int?> atomArray = [];
      for (Atom atom in thisGame.atoms) {
        atomArray.add(atom.position.x);
        atomArray.add(atom.position.y);
      }

      DocumentReference setupRef;
      String? setupID;
      try {
        setupRef = await MyFirebase.storeObject.collection('setups').add({
          'sender': myUid,
          'atoms': atomArray,
          'widthAndHeight': [thisGame.widthOfPlayArea, thisGame.heightOfPlayArea],
          'timestamp': FieldValue.serverTimestamp(),
          kFieldShuffleA: thisGame.beamImageIndexA,
          kFieldShuffleB: thisGame.beamImageIndexB,
          // 'playing': {}, //Why should I add this?? It just takes up unnecessary space and it's not logical!...
          //I wanted to make it easier to avoid "called on null" but I'll just have to manage that some other way...
        });

        setupID = setupRef.id;
      } catch (e) {
        print("Error adding setup: $e");
      }

      fcmSendMsg(jsonEncode({
        "data": {
          "event": kMsgEventNewGameHubSetup,
          "setupSender": "$myUid",
          "$kMsgSetupID": setupID,
          // "collapse_key": myUid + "...",
        },
        // "token": "${await myGlobalToken}",
        "topic": kTopicGameHubSetup,
      }));

      // To pop back to game hub from Add button:
      if (popToEndRoute == true) {
        late ModalRoute endRoute;
        Navigator.popUntil(context, (route) {
          if (route.isFirst) {
            endRoute = route as ModalRoute<dynamic>;
            return true;
          }

          if (route.settings.name == routeGameHub) {
            endRoute = route as ModalRoute<dynamic>;
            return true;
          }
          return false;
        });

        if (endRoute.isFirst) {
          print('endRoute is first');
          Navigator.push(context, MaterialPageRoute(settings: RouteSettings(name: routeGameHub), builder: (context){
                      return GameHubScreen();
          }));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    token = getToken();
    String myUid = MyFirebase.authObject.currentUser!.uid;

    return OnlineButton(
      text: 'Upload',
      onPressed: () {
        uploadButtonPress(thisGame: widget.thisGame, context: context);
      },
    );
  }
}

//--------
//Popup that I decided I didn't want, after pressing "Upload":
//          await BlackboxPopup(
//              context: context,
//              title: 'Upload',
//              desc: 'Upload this setup as $me?',
//              buttons: [
//                DialogButton(
//                  child: Text('Yes', style: TextStyle(color: Colors.black)),
//                  onPressed: (){
//                    Navigator.pop(context);
//                  },
//                  color: Colors.white,
//                ),
//                DialogButton(
//                  child: Text('Change user', style: TextStyle(color: Colors.black)),
//                  onPressed: (){
//                    Navigator.pop(context);
//                    needLogin = true;
//                  },
//                  color: Colors.white,
//                )
//              ]
//          ).show();