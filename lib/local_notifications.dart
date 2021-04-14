import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'my_firebase_labels.dart';
// import 'my_firebase.dart';
import 'package:flutter/material.dart';

class LocalNotifications {
  static String myUid;
  static FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static void initiate(BuildContext context) async {
    // flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    // var android = AndroidInitializationSettings('ic_launcher');  //MyGiggz version
    // All it needed was a f** rebuild........!
    var android = AndroidInitializationSettings('@drawable/ic_stat_name');

    var iOS = IOSInitializationSettings();
    var initSettings = InitializationSettings(android: android, iOS: iOS);

    Future onSelectNotification(String payload) async {
      debugPrint("payload : $payload");
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Alert'),
          content: Text('$payload'),
        ),
      );
    }

    flutterLocalNotificationsPlugin.initialize(initSettings, onSelectNotification: onSelectNotification);
  }
  static void showNotification(String title, String notification) async {
    String channelId = 'GameHub';
    String channelName = 'GameHub';
    String channelDescription = 'New game hub events';
    var android = AndroidNotificationDetails(
      '$channelId', '$channelName', '$channelDescription',
      priority: Priority.high,
      importance: Importance.max,
      // sound: RawResourceAndroidNotificationSound('C:\\Users\\karol\\AndroidStudioProjects\\my_giggz\\assets\\note3.wav'),
      // sound: UriAndroidNotificationSound('C:\\Users\\karol\\AndroidStudioProjects\\my_giggz\\assets\\note3.wav'),
      // sound: UriAndroidNotificationSound('assets/note3.wav'),
    );
    var iOS = IOSNotificationDetails();
    var bothPlatforms = NotificationDetails(android: android, iOS: iOS);
    await flutterLocalNotificationsPlugin.show(5, '$title', '$notification', bothPlatforms, payload: 'Hard-coded payload');
  }
}
