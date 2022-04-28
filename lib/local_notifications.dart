import 'package:navigation_history_observer/navigation_history_observer.dart';
import 'units/small_functions.dart';
import 'global.dart';
import 'my_firebase.dart';
import 'my_firebase_labels.dart';
import 'package:collection/collection.dart';
import 'dart:convert';

import 'package:pretty_json/pretty_json.dart';
import 'route_names.dart';
import 'package:blackbox/online_screens/game_hub_screen.dart';
import 'package:navigation_history_observer/navigation_history_observer.dart';
import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'my_firebase_labels.dart';
// import 'my_firebase.dart';
import 'package:flutter/material.dart';

class LocalNotifications {
  static String myUid;
  static FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static void initiate(BuildContext context) async {
    print('Running LocalNotifications.initiate()');

    // var android = AndroidInitializationSettings('ic_launcher');  //MyGiggz version
    // All it needed was a f** rebuild........!
    var android = AndroidInitializationSettings('@drawable/ic_stat_name');

    var iOS = IOSInitializationSettings();
    var initSettings = InitializationSettings(android: android, iOS: iOS);

    Future onSelectNotification(String payload) async {
      print('onSelectNotification() (Local notification opened app).');
      printPrettyJson(jsonDecode(payload));

      Map<String, dynamic> msgData = jsonDecode(payload);
      // Map<String, dynamic> msgData = remoteMsg.data.cast();
      bool containsData = !(MapEquality().equals(msgData, {}) || msgData == null);
      bool playingEvent = containsData && (msgData[kMsgEvent] == kMsgEventStartedPlaying || msgData[kMsgEvent] == kMsgEventResumedPlaying);
      bool newSetupEvent = containsData && msgData[kMsgEvent] == kMsgEventNewGameHubSetup;

      if (MyFirebase.authObject.currentUser != null) {
        if (playingEvent) {
          navigateFromNotificationToFollowing(msgData: msgData);
        } else if (newSetupEvent) {
          // Push GameHubScreen() if it's not already on top:
          Route topRoute = NavigationHistoryObserver().top;
          if (topRoute.settings.name != routeGameHub) {
            Navigator.push(GlobalVariable.navState.currentContext, MaterialPageRoute(settings: RouteSettings(name: routeGameHub), builder: (context){
                      return GameHubScreen();
            }));
          }
        }
      }

    }

    flutterLocalNotificationsPlugin.initialize(initSettings, onSelectNotification: onSelectNotification);
  }
  static void showNotification({String title, String notification, String data}) async {
    String channelId = 'GameHub';
    String channelName = 'GameHub';
    String channelDescription = 'New game hub events';
    var android = AndroidNotificationDetails(
      '$channelId', '$channelName', '$channelDescription',
      priority: Priority.high,
      importance: Importance.max,
      autoCancel: false,
      visibility: NotificationVisibility.public,
      // icon: '@drawable/ic_stat_name',
      styleInformation: BigTextStyleInformation(''),  // Gives multi-line notifications
      // ongoing: true, // BAD IDEA!! (Can't be dismissed.)
      // sound: RawResourceAndroidNotificationSound('C:\\Users\\karol\\AndroidStudioProjects\\my_giggz\\assets\\note3.wav'),
      // sound: UriAndroidNotificationSound('C:\\Users\\karol\\AndroidStudioProjects\\my_giggz\\assets\\note3.wav'),
      // sound: UriAndroidNotificationSound('assets/note3.wav'),
    );
    var iOS = IOSNotificationDetails();
    var bothPlatforms = NotificationDetails(android: android, iOS: iOS);
    await flutterLocalNotificationsPlugin.show(5, '$title', '$notification', bothPlatforms, payload: data);
  }
}
