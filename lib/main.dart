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
  MyFirebase.myFutureFirebaseApp = Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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

// import 'package:flutter/material.dart';
//
// void main() {
//   runApp(const MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   // This widget is the root of your application.
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Flutter Demo',
//       theme: ThemeData(
//         // This is the theme of your application.
//         //
//         // TRY THIS: Try running your application with "flutter run". You'll see
//         // the application has a purple toolbar. Then, without quitting the app,
//         // try changing the seedColor in the colorScheme below to Colors.green
//         // and then invoke "hot reload" (save your changes or press the "hot
//         // reload" button in a Flutter-supported IDE, or press "r" if you used
//         // the command line to start the app).
//         //
//         // Notice that the counter didn't reset back to zero; the application
//         // state is not lost during the reload. To reset the state, use hot
//         // restart instead.
//         //
//         // This works for code too, not just values: Most code changes can be
//         // tested with just a hot reload.
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
//         useMaterial3: true,
//       ),
//       home: const MyHomePage(title: 'Flutter Demo Home Page'),
//     );
//   }
// }
//
// class MyHomePage extends StatefulWidget {
//   const MyHomePage({super.key, required this.title});
//
//   // This widget is the home page of your application. It is stateful, meaning
//   // that it has a State object (defined below) that contains fields that affect
//   // how it looks.
//
//   // This class is the configuration for the state. It holds the values (in this
//   // case the title) provided by the parent (in this case the App widget) and
//   // used by the build method of the State. Fields in a Widget subclass are
//   // always marked "final".
//
//   final String title;
//
//   @override
//   State<MyHomePage> createState() => _MyHomePageState();
// }
//
// class _MyHomePageState extends State<MyHomePage> {
//   int _counter = 0;
//
//   void _incrementCounter() {
//     setState(() {
//       // This call to setState tells the Flutter framework that something has
//       // changed in this State, which causes it to rerun the build method below
//       // so that the display can reflect the updated values. If we changed
//       // _counter without calling setState(), then the build method would not be
//       // called again, and so nothing would appear to happen.
//       _counter++;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     // This method is rerun every time setState is called, for instance as done
//     // by the _incrementCounter method above.
//     //
//     // The Flutter framework has been optimized to make rerunning build methods
//     // fast, so that you can just rebuild anything that needs updating rather
//     // than having to individually change instances of widgets.
//     return Scaffold(
//       appBar: AppBar(
//         // TRY THIS: Try changing the color here to a specific color (to
//         // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
//         // change color while the other colors stay the same.
//         backgroundColor: Theme.of(context).colorScheme.inversePrimary,
//         // Here we take the value from the MyHomePage object that was created by
//         // the App.build method, and use it to set our appbar title.
//         title: Text(widget.title),
//       ),
//       body: Center(
//         // Center is a layout widget. It takes a single child and positions it
//         // in the middle of the parent.
//         child: Column(
//           // Column is also a layout widget. It takes a list of children and
//           // arranges them vertically. By default, it sizes itself to fit its
//           // children horizontally, and tries to be as tall as its parent.
//           //
//           // Column has various properties to control how it sizes itself and
//           // how it positions its children. Here we use mainAxisAlignment to
//           // center the children vertically; the main axis here is the vertical
//           // axis because Columns are vertical (the cross axis would be
//           // horizontal).
//           //
//           // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
//           // action in the IDE, or press "p" in the console), to see the
//           // wireframe for each widget.
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: <Widget>[
//             const Text(
//               'You have pushed the button this many times:',
//             ),
//             Text(
//               '$_counter',
//               style: Theme.of(context).textTheme.headlineMedium,
//             ),
//           ],
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: _incrementCounter,
//         tooltip: 'Increment',
//         child: const Icon(Icons.add),
//       ), // This trailing comma makes auto-formatting nicer for build methods.
//     );
//   }
// }
