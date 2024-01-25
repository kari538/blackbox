import 'firebase_options.dart'; //File added in new project
import 'package:flutter/services.dart';
import 'theme.dart';
import 'global.dart';
// import 'package:wakelock/wakelock.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:navigation_history_observer/navigation_history_observer.dart';
import 'local_notifications.dart';
import 'fcm.dart';
import 'package:flutter/material.dart';
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
  MyFirebase.myFutureFirebaseApp = Firebase.initializeApp();
  initializeFcm('');
  userChangesListener();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler); //This seems to be working!
  // Wakelock.enable();  // Prevents screen from sleeping for as long as main() is running.
  LocalNotifications.initiate();

  runApp(Blackbox());
}


class Blackbox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<GameHubUpdates>(
      create: (_) {
        return GameHubUpdates();
      },
      lazy: true, // Don't remember why I put this to true!...
      // Removing it doesn't seem to do anything...
      // In InheritedProvider - an ancestor of ChangeNotifierProvider - it says that
      // if lazy is false, it forces "the value to be computed"... Seems null will count as true...
      child: MaterialApp(
        theme: blackboxTheme,
//        home: BlackBoxScreen(),
//        home: ResultsScreen(),
//        home: WelcomeScreen(),
        home: AnnotatedRegion<SystemUiOverlayStyle>(
          child: WelcomeScreen(),
          value: SystemUiOverlayStyle.dark.copyWith(
            statusBarColor: Colors.black,
            systemNavigationBarColor: Colors.black,
          ),
        ),
//        home: ConversationsScreen(),
//        home: RegistrationAndLoginScreen(),
        debugShowCheckedModeBanner: false,
        navigatorObservers: [NavigationHistoryObserver()],
        navigatorKey: GlobalVariable.navState,
      ),
    );
  }
}

// Found in other crashed file:
// import 'package:wakelock/wakelock.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'local_notifications.dart';
// import 'fcm.dart';
// import 'package:flutter/material.dart';
// import 'constants.dart';
// import 'package:blackbox/screens/welcome_screen.dart';
// import 'package:provider/provider.dart';
// import 'package:blackbox/game_hub_updates.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'my_firebase.dart';
//
// //import 'screens/play_screen.dart';
// //import 'screens/results_screen.dart';
// //import 'screens/rules_screen.dart';
// //import 'online_screens/game_hub_screen.dart';
// //import 'online_screens/reg_n_login_screen.dart';
//
// void main() {
//   print('Running main()');
//   WidgetsFlutterBinding.ensureInitialized();
//   MyFirebase.myFutureFirebaseApp = Firebase.initializeApp();
//   initializeFcm('');
//   userChangesListener();
//   FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);  //This seems to be working!
//   // Wakelock.enable();  // Prevents screen from sleeping for as long as main() is running.
//
//   // Map<String, dynamic> map = {
//   //   'one': 1,
//   //   'two': 2,
//   // };
//   // print('map before is $map');
//   // changeMap(map);
//   // print('map after is $map');
//
//   runApp(Blackbox());
// }
//
// // void changeMap(Map<String, dynamic> _map){
// //   _map = {
// //     'one': 1,
// //     'two': 2,
// //     'three': 3,
// //   };
// // }
//
// class Blackbox extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     LocalNotifications.initiate(context);
//     return ChangeNotifierProvider<GameHubUpdates>(
//       create: (_) {
//         return GameHubUpdates();
//       },
//       child: MaterialApp(
//         theme: ThemeData.dark().copyWith(
//           appBarTheme: AppBarTheme(color: Colors.black),
//           scaffoldBackgroundColor: kScaffoldBackgroundColor,
// //          scaffoldBackgroundColor: Colors.pink,
//           buttonTheme: ButtonThemeData(textTheme: ButtonTextTheme.primary),
//           textTheme: TextTheme(
//             bodyText2: TextStyle(
//               fontSize: 18,
//             ),
//             button: TextStyle(color: Colors.pink),
//           ),
//         ),
// //        home: BlackBoxScreen(),
// //        home: ResultsScreen(),
// //        home: WelcomeScreen(),
//         home: WelcomeScreen(),
// //        home: ConversationsScreen(),
// //        home: RegistrationAndLoginScreen(),
//         debugShowCheckedModeBanner: false,
//       ),
//     );
//   }
// }