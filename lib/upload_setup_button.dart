// import 'units/fcm_send_msg.dart';
// import 'my_firebase_labels.dart';
// import 'dart:convert';
// import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'screens/make_setup_screen.dart';
import 'online_button.dart';
import 'my_firebase.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'blackbox_popup.dart';
import 'package:provider/provider.dart';
import 'online_screens/reg_n_login_screen.dart';
import 'game_hub_updates.dart';
import 'online_screens/game_hub_screen.dart';
import 'atom_n_beam.dart';
import 'route_names.dart';

Future<String> token;
final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

class UploadSetupButton extends StatelessWidget {
  const UploadSetupButton({
    @required this.widget,
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

  Future<String> getToken() async {
    String _token = await _firebaseMessaging.getToken();
    print("Token in Upload Button is $_token");
    return _token;
  }

  Future<String> getMyPlayerId() async {
    String _myId;
    if (MyFirebase.authObject.currentUser == null) {
      return null;
    } else {
      String myEmail = MyFirebase.authObject.currentUser.email;
      QuerySnapshot loggedInUserInfo = await MyFirebase.storeObject
          .collection('userinfo')
          .where('email', isEqualTo: myEmail)
          .get(); //No stream needed, coz the document no is not supposed to change
      if (ListEquality().equals(loggedInUserInfo.docs, [])) {
        //I don't have an entry in 'userinfo', which shouldn't ever happen:
        print("I don't have an entry in 'userinfo', which shouldn't ever happen!!");
        _myId = 'no screen name';
      } else {
        _myId = loggedInUserInfo.docs[0].id;
      }
      print("My player ID is '$_myId'");
      return _myId;
    }
  }

  @override
  Widget build(BuildContext context) {
    token = getToken();
    return OnlineButton(
      text: 'Upload',
      onPressed: () async {
        print("Token in onPressed is ${await token}");

        // //TODO: Turn the below back from Cloud Function:
        // fcmSendMsg(context);

        // http.Response res;
        // String desc = '';
        // String code = '';
        // String jsonBody = jsonEncode({
        //   "notification": {
        //     "title": "New Game Hub Setup",
        //     "body": "Upload button: A new blackbox setup has come in to game hub",
        //   },
        //   "data": {
        //     "click_action": "FLUTTER_NOTIFICATION_CLICK",
        //   },
        //   // "token": "${await token}",
        //   "topic": kTopicNewSetup,
        // });
        // print("jsonString is $jsonBody");
        // Map<String, String> headers = {
        //   "content-type": "application/json"
        // };
        //
        // try {
        //   res = await http.post(
        //     'https://us-central1-blackbox-6b836.cloudfunctions.net/sendMsg',
        //     headers: headers,
        //     body: jsonBody,
        //   );
        // } catch (e) {
        //   print('Caught an error in sendMsg to topic $kTopicNewSetup API call!');
        //   print('e is: ${e.toString()}');
        //   // errorMsg = e.toString();
        //   BlackboxPopup(context: context, title: 'Error', desc: '$e').show();
        //   if (res != null) print('Status code in apiCall() catch is ${res.statusCode}');
        // }
        // if (res != null) {
        //   print('sendMsg to topic $kTopicNewSetup API call response body: ${res.body}');
        //   print('sendMsg to topic $kTopicNewSetup API call response code: ${res.statusCode}');
        //   desc = res.body;
        //   code = res.statusCode.toString();
        // } else {
        //   print('sendMsg to topic $kTopicNewSetup API call response is $res');
        // }
        // // BlackboxPopup(context: context, title: 'Response $code', desc: '$desc').show();
        // print('code is $code and desc is $desc in Upload Setup Button');

        String myPlayerId = await getMyPlayerId();
        print('OnlineButton printing player ID: $myPlayerId');
        bool needLogin = false;
        if (myPlayerId == null) {
          //If no user is logged in
          await BlackboxPopup(
            context: context,
            title: 'Not Logged In!',
            desc: 'You are no longer logged in. Click OK to log in again.',
          ).show();
          needLogin = true;
        } else {
          String me = Provider.of<GameHubUpdates>(context, listen: false).providerUserIdMap[myPlayerId];
          print('Me in OnlineButton is $me.');
        }
        if (needLogin) {
          await Navigator.push(context, MaterialPageRoute(builder: (context) {
            return RegistrationAndLoginScreen(fromSetup: true);
          }));
          print("On return from new login, User is ${MyFirebase.authObject.currentUser.email}");
          myPlayerId = await getMyPlayerId();
        }
        List<int> atomArray = [];
        for (Atom atom in widget.thisGame.atoms) {
          atomArray.add(atom.position.x);
          atomArray.add(atom.position.y);
        }
        MyFirebase.storeObject.collection('setups').add({
          'sender': myPlayerId,
          'atoms': atomArray,
          'widthAndHeight': [widget.thisGame.widthOfPlayArea, widget.thisGame.heightOfPlayArea],
          'timestamp': FieldValue.serverTimestamp(),
          // 'playing': {}, //Why should I add this?? It just takes up unnecessary space and it's not logical!...
                            //I wanted to make it easier to avoid "called on null" but I'll just have to manage that some other way...
        });
        ModalRoute endRoute;
        Navigator.popUntil(context, (route) {
          if (route.isFirst) {
            endRoute = route;
            return true;
          }
          if (route.settings.name == routeGameHub) {
            endRoute = route;
            return true;
          }
          return false;
        });
        if (endRoute.isFirst) {
          print('endRoute is first');
          Navigator.push(context, MaterialPageRoute(builder: (context) {
            return GameHubScreen();
//            return SettingsScreen(online: true);
          }));
        }
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
