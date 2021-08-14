import 'package:blackbox/my_firebase_labels.dart';
import 'package:blackbox/token.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:blackbox/units/fcm_send_msg.dart';

// import 'package:collection/collection.dart';
// import 'package:blackbox/atom_n_beam.dart';
// import 'package:blackbox/multiple_solutions.dart';
// import 'results_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'play_screen.dart';

// import 'file:///C:/Users/karol/AndroidStudioProjects/blackbox/lib/units/play.dart';
import 'package:blackbox/play.dart';
import 'settings_screen.dart';
import 'rules_screen.dart';
import 'make_setup_screen.dart';
import 'package:blackbox/online_screens/reg_n_login_screen.dart';

// import 'file:///C:/Users/karol/AndroidStudioProjects/blackbox/lib/units/online_button.dart';
import 'package:blackbox/online_button.dart';
import 'package:blackbox/my_firebase.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:blackbox/online_screens/game_hub_screen.dart';
import 'package:google_api_availability/google_api_availability.dart';
import 'package:blackbox/route_names.dart';

class WelcomeScreen extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('blackbox')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // RaisedButton(
            //   child: Text('Test'),
            //   color: Colors.red,
            //   onPressed: (){
            //
            //     print('pressed Test');
            //     List list1 = [1, 2, 3];
            //     List list2 = [1, 2, 3];
            //     List list3 = [1, 3, 2];
            //     print('list1 and list2 equal: ${list1.equals(list2)}');
            //     print('list1 and list3 equal: ${list1.equals(list3)}');
            //     Play thisGame = Play(numberOfAtoms: 4, heightOfPlayArea: 3, widthOfPlayArea: 3);
            //     // // thisGame.getAtomsRandomly();
            //     // // thisGame.atoms = [
            //     // //   Atom(1, 1),
            //     // //   Atom(2, 2),
            //     // //   Atom(3, 3),
            //     // //   Atom(4, 4),
            //     // // ];
            //     thisGame.online=false;
            //     thisGame.showAtomSetting = true;
            //     alternativeSolutions(context, thisGame);
            //     // bool unique;
            //     // unique = isSetupUnique([Atom(1, 1), Atom(1,2)]);
            //     // print('Setup [1,1  1,2] unique: $unique');
            //     // unique = isSetupUnique([Atom(1, 1), Atom(2,1)]);
            //     // print('Setup [1,1  2,1] unique: $unique');
            //     // unique = isSetupUnique([Atom(1, 1), Atom(2,2)]);
            //     // print('Setup [1,1  2,2] unique: $unique');
            //     // unique = isSetupUnique([Atom(2, 1), Atom(1,2)]);
            //     // print('Setup [2,1  1,2] unique: $unique');
            //     // print('thisGame.atoms on WelcomeScreen() are ${thisGame.atoms}');
            //   },
            // ),
            RaisedButton(
              child: Text('Play'),
              onPressed: (){
                print('pressed Test');
                Play thisGame = Play(numberOfAtoms: 4, heightOfPlayArea: 8, widthOfPlayArea: 8);
                thisGame.getAtomsRandomly();
                thisGame.online=false;
//                Navigator.pushNamed(context, '/blackbox_screen');
                Navigator.push(context, MaterialPageRoute(builder: (context){
                  return PlayScreen(thisGame: thisGame);
                }));
              },
            ),
            RaisedButton(
              child: Text('Make Setup'),
              onPressed: (){
                Navigator.push(context, MaterialPageRoute(builder: (context){
                  Play thisGame = Play(numberOfAtoms: 4, heightOfPlayArea: 8, widthOfPlayArea: 8);
                  thisGame.online = false;
                  return MakeSetupScreen(thisGame: thisGame);
                }));
              },
            ),
            RaisedButton(
              child: Text('Settings'),
              onPressed: (){
                Navigator.push(context, MaterialPageRoute(builder: (context){
                  return SettingsScreen(online: false);
                }));
              },
            ),
            OnlineButton(
              text: 'Online',
              color: Colors.white,
              fontSize: 14,
              textColor: Colors.teal,
              borderColor: Colors.greenAccent,
//              onPressed: null,
              onPressed: () async {
                CircularProgressIndicator();
                GooglePlayServicesAvailability availability = await GoogleApiAvailability.instance.checkGooglePlayServicesAvailability();
                print('availability in Online button is $availability');
                await MyFirebase.myFutureFirebaseApp;
                auth.User loggedInUser = auth.FirebaseAuth.instance.currentUser;
                if(loggedInUser == null) {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          settings: RouteSettings(name: routeRegLogin),
                          builder: (context) {
                            return RegistrationAndLoginScreen();
                          }));
                } else {
                  Navigator.push(context, MaterialPageRoute(settings: RouteSettings(name: routeGameHub), builder: (context){
                    return GameHubScreen();
                  }));
                }
              },
            ),
            RaisedButton(
              child: Text('How to Play'),
              onPressed: () async {
                ///Test send msg:
                // TODO: Remove test message:
                // String localNotification = jsonEncode({
                //   kApiNotification: {
                //     "title": "hi",
                //     "body": "hi hi",
                //   },
                //   "data": {
                //     "click_action": "FLUTTER_NOTIFICATION_CLICK",
                //     "collapse_key": "local_not",
                //   },
                // });
                // Future<http.Response> sendMsgRes = fcmSendMsg(
                //     jsonEncode({
                //       "notification": {
                //         "title": "Message from Welcome Screen to Developer",
                //         "body": "from ${MyFirebase.authObject.currentUser.displayName}",
                //       },
                //       "data": {
                //         "collapse_key": "welcome_screen",
                //         "click_action": "FLUTTER_NOTIFICATION_CLICK",
                //         kApiShowLocalNotification: localNotification,
                //         // kApiOverride: kApiOverrideYes,
                //       },
                //       // Nokia:
                //       // "token": 'f2F3dytfT9iW8LYUq796aa:APA91bG0OnzHIkQtv9Iq_z-sy93lanzHSbe53lBiwXFp1z6uY6ghn6IxgqxePZYCKr8MQ29z-rMiPWgXiB59JAD-2IO5VR7ixS0GVj1GKU-a0rvEUepRKnPHWRcB7xoph5u_bShgnNUF',
                //       // Small Nexus:
                //       // "token": 'doxTxf2VR0eGAf6RlmCDZ7:APA91bFfo8eGiOzEC_d4oyrzpYz4z6L2laIm3vJc_fWjWolvqgKh2HirX8cQgH-cv6i0IfAktSXxIjWGLvTA4fESwDnonSrf9khh3z1g0j8CgkpRT2obA_9bMOcHeiPvdiryKWXzgCFR',
                //       // "token": '${await myGlobalToken}',
                //       "topic": kTopicDeveloper,
                //     }),
                //     context);
                //
                // http.Response res = await sendMsgRes;
                // print('ressssssssssssssssssssssssssss in ${this} is $res');
                // print('The res body is ${res != null ? '${res.body}'
                //     '\nof type ${res.body.runtimeType}'
                //     '\nand res.statusCode is ${res.statusCode}' : 'null'}');
                //
                ///How to play:
//                Navigator.pushNamed(context, '/rules_screen');
                Navigator.push(context, MaterialPageRoute(builder: (context){
                  return RulesScreen();
                }));
              },
            ),
          ],
        ),
      ),
    );
  }
}
