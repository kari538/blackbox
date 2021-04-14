import 'package:firebase_messaging/firebase_messaging.dart';
import 'local_notifications.dart';
import 'fcm.dart';
import 'package:flutter/material.dart';
import 'constants.dart';
import 'package:blackbox/screens/welcome_screen.dart';
import 'package:provider/provider.dart';
import 'package:blackbox/game_hub_updates.dart';
import 'package:firebase_core/firebase_core.dart';
import 'my_firebase.dart';

//import 'screens/play_screen.dart';
//import 'screens/results_screen.dart';
//import 'screens/rules_screen.dart';
//import 'online_screens/game_hub_screen.dart';
//import 'online_screens/reg_n_login_screen.dart';

void main() {
  print('Running main()');
  WidgetsFlutterBinding.ensureInitialized();
  // FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);  //This seems to be working!
  MyFirebase.myFutureFirebaseApp = Firebase.initializeApp();
  initializeFcm();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  runApp(Blackbox());
}

class Blackbox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    LocalNotifications.initiate(context);
    return ChangeNotifierProvider<GameHubUpdates>(
      create: (_) {
        return GameHubUpdates();
      },
      child: MaterialApp(
        theme: ThemeData.dark().copyWith(
          appBarTheme: AppBarTheme(color: Colors.black),
          scaffoldBackgroundColor: kScaffoldBackgroundColor,
//          scaffoldBackgroundColor: Colors.pink,
          buttonTheme: ButtonThemeData(textTheme: ButtonTextTheme.primary),
          textTheme: TextTheme(
            bodyText2: TextStyle(
              fontSize: 18,
            ),
            button: TextStyle(color: Colors.pink),
          ),
        ),
//        home: BlackBoxScreen(),
//        home: ResultsScreen(),
//        home: WelcomeScreen(),
        home: WelcomeScreen(),
//        home: ConversationsScreen(),
//        home: RegistrationAndLoginScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}