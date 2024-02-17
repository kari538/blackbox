// import 'package:collection/collection.dart';
// import 'package:blackbox/atom_n_beam.dart';
// import 'package:blackbox/multiple_solutions.dart';
// import 'results_screen.dart';
import 'package:blackbox/units/small_widgets.dart';
import 'package:flutter/material.dart';
import 'play_screen.dart';
import 'package:blackbox/play.dart';
import 'settings_screen.dart';
import 'rules_screen.dart';
import 'make_setup_screen.dart';
import 'package:blackbox/online_screens/reg_n_login_screen.dart';
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
            MyRaisedButton(
              child: Text('Play'),
              onPressed: (){
                print('pressed Play');
                Play thisGame = Play(numberOfAtoms: 4, heightOfPlayArea: 8, widthOfPlayArea: 8);
                thisGame.getAtomsRandomly();
                thisGame.online=false;
                Navigator.push(context, MaterialPageRoute(builder: (context){
                  return PlayScreen(thisGame: thisGame);
                }));
              },
            ),
            MyRaisedButton(
              child: Text('Make Setup'),
              onPressed: (){
                Navigator.push(context, MaterialPageRoute(builder: (context){
                  Play thisGame = Play(numberOfAtoms: 4, heightOfPlayArea: 8, widthOfPlayArea: 8);
                  thisGame.online = false;
                  return MakeSetupScreen(thisGame: thisGame);
                }));
              },
            ),
            MyRaisedButton(
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
                // CircularProgressIndicator();
                // GooglePlayServicesAvailability availability = GooglePlayServicesAvailability.unknown;
                // try {
                //   availability = await GoogleApiAvailability.instance.checkGooglePlayServicesAvailability();
                //   // GooglePlayServicesAvailability availability = await GoogleApiAvailability.instance.checkGooglePlayServicesAvailability();
                //   print('availability in Online button is $availability');
                // } catch (e) {
                //   print('GoogleApiAvailability error: $e');
                // }
                await Future.delayed(Duration(milliseconds: 3000));
                await MyFirebase.myFutureFirebaseApp;
                auth.User? loggedInUser = auth.FirebaseAuth.instance.currentUser;
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
            MyRaisedButton(
              child: Text('How to Play'),
              onPressed: () async {
                ///How to play:
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
