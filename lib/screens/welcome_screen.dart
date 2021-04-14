import 'package:collection/collection.dart';
import 'package:blackbox/atom_n_beam.dart';
import 'package:blackbox/multiple_solutions.dart';
import 'results_screen.dart';
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
            RaisedButton(
              child: Text('Test'),
              color: Colors.red,
              onPressed: (){

                print('pressed Test');
                List list1 = [1, 2, 3];
                List list2 = [1, 2, 3];
                List list3 = [1, 3, 2];
                print('list1 and list2 equal: ${list1.equals(list2)}');
                print('list1 and list3 equal: ${list1.equals(list3)}');
                Play thisGame = Play(numberOfAtoms: 4, heightOfPlayArea: 3, widthOfPlayArea: 3);
                // // thisGame.getAtomsRandomly();
                // // thisGame.atoms = [
                // //   Atom(1, 1),
                // //   Atom(2, 2),
                // //   Atom(3, 3),
                // //   Atom(4, 4),
                // // ];
                thisGame.online=false;
                thisGame.showAtomSetting = true;
                alternativeSolutions(context, thisGame);
                // bool unique;
                // unique = isSetupUnique([Atom(1, 1), Atom(1,2)]);
                // print('Setup [1,1  1,2] unique: $unique');
                // unique = isSetupUnique([Atom(1, 1), Atom(2,1)]);
                // print('Setup [1,1  2,1] unique: $unique');
                // unique = isSetupUnique([Atom(1, 1), Atom(2,2)]);
                // print('Setup [1,1  2,2] unique: $unique');
                // unique = isSetupUnique([Atom(2, 1), Atom(1,2)]);
                // print('Setup [2,1  1,2] unique: $unique');
                // print('thisGame.atoms on WelcomeScreen() are ${thisGame.atoms}');
              },
            ),
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
                  Navigator.push(context, MaterialPageRoute(settings: RouteSettings(name: routeRegLogin), builder: (context){
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
              onPressed: (){
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

