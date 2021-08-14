import 'package:blackbox/global.dart';
import 'package:collection/collection.dart';
import 'online_screens/game_hub_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'route_names.dart';
import 'package:navigation_history_observer/navigation_history_observer.dart';
import 'package:blackbox/units/small_functions.dart';
import 'package:pretty_json/pretty_json.dart';

import 'units/fcm_send_msg.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:blackbox/token.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'local_notifications.dart';
import 'my_firebase_labels.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'my_firebase.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Future<String> token;
// TODO: change testingNotifications to false:
// bool testingNotifications = true;
bool testingNotifications = false;

// TODO Notification sound!
void initializeFcm(String token, GlobalKey myGlobalKey) async {
  print('Initializing Firebase Cloud Messaging...');
  await MyFirebase.myFutureFirebaseApp;
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  if (MyFirebase.authObject.currentUser != null) {
    String myUid = MyFirebase.authObject.currentUser.uid;
    _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    _firebaseMessaging.requestPermission(
      sound: true,
      //The rest as default
    );
    _firebaseMessaging.setAutoInitEnabled(true);

    ///If a message comes with the construction (see Welcome Screen):
    ///                String localNotification = jsonEncode({
    ///                    kApiNotification: {
    ///                      "title": "hi",
    ///                      "body": "hi hi",
    ///                    },
    ///                    "data": {
    ///                      "click_action": "FLUTTER_NOTIFICATION_CLICK",
    ///                      "collapse_key": "some_string", //This does nothing
    ///                    },
    ///                  });
    ///                  Future<http.Response> sendMsgRes = fcmSendMsg(
    ///                      jsonEncode({
    ///                        "notification": {
    ///                          "title": "Message from Welcome Screeeeeeeeeeeeeeeeeen",
    ///                          "body": "from ${MyFirebase.authObject.currentUser.displayName}",
    ///                        },
    ///                       "data": {
    ///                          "collapse_key": "welcome_screen",
    ///                          "click_action": "FLUTTER_NOTIFICATION_CLICK",
    ///                          kApiShowLocalNotification: localNotification,
    ///                          // kApiOverride: kApiOverrideYes,
    ///                        },
    ///                        // Nokia:
    ///                        "token": 'f2F3dytfT9iW8LYUq796aa:APA91bG0OnzHIkQtv9Iq_z-sy93lanzHSbe53lBiwXFp1z6uY6ghn6IxgqxePZYCKr8MQ29z-rMiPWgXiB59JAD-2IO5VR7ixS0GVj1GKU-a0rvEUepRKnPHWRcB7xoph5u_bShgnNUF',
    ///                        // Small Nexus:
    ///                        // "token": 'doxTxf2VR0eGAf6RlmCDZ7:APA91bFfo8eGiOzEC_d4oyrzpYz4z6L2laIm3vJc_fWjWolvqgKh2HirX8cQgH-cv6i0IfAktSXxIjWGLvTA4fESwDnonSrf9khh3z1g0j8CgkpRT2obA_9bMOcHeiPvdiryKWXzgCFR',
    ///                        // "token": '${await myGlobalToken}',
    ///                      }),
    ///                      context);
    /// The content in localNotification will override the notification specified in onMessage
    FirebaseMessaging.onMessage.listen((remoteMsg) async {
      print('++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n'
          'onMessage');
      if (remoteMsg.notification != null) {
        print(remoteMsg.notification.title);
        print(remoteMsg.notification.body);
      }

      print('remoteMsg.data is ${remoteMsg.data}');
      // print(remoteMsg.data.isNotEmpty);

      bool localNotificationField = false;
      bool notificationOverride = false;
      bool containsEvent = false;
      bool playerIsMe = false;
      bool playingSetup = false;
      bool playingMySetup = false;
      bool resumedPlaying = false;

      if (remoteMsg.data.isNotEmpty) {
        print('remoteMsg.data.containsKey(kMsgPlaying): ${remoteMsg.data.containsKey(kMsgPlaying)}');
        // print(remoteMsg.data[kMsgPlaying] == myUid);
        print('remoteMsg.data.keys ${remoteMsg.data.keys}');

        // To override local notification:
        Map<String, dynamic> data = remoteMsg.data.cast(); //!!!!!!! :D
        Map<String, dynamic> notificationData = {};
        print('data is $data');
        localNotificationField = data.containsKey(kMsgShowLocalNotification);
        notificationOverride = data[kMsgOverride] == kMsgOverrideYes;
        print("localNotificationField is $localNotificationField");
        print("notificationOverride is $notificationOverride");

        if (localNotificationField) {
          notificationData = jsonDecode(data[kMsgShowLocalNotification]);
          print('notificationData is $notificationData');

          // Can't make it non-collapsible...
          // TODO: make non-collapsible!! :(
          await Future.delayed(Duration(seconds: 1)); // This makes it over-write the other one...
          LocalNotifications.showNotification(
            title: notificationData[kMsgNotification][kMsgTitle],
            notification: notificationData[kMsgNotification][kMsgBody],
            data: jsonEncode(notificationData[kMsgData]),
          );
        }

        containsEvent = remoteMsg.data.containsKey(kMsgEvent);
        playerIsMe = remoteMsg.data.containsKey(kMsgPlaying) && remoteMsg.data[kMsgPlaying] == myUid;
        playingSetup =
            // remoteMsg.data.containsKey(kMsgSetupSender
            // )
            //     ||
            (containsEvent && (remoteMsg.data[kMsgEvent] == kMsgEventStartedPlaying || remoteMsg.data[kMsgEvent] == kMsgEventResumedPlaying));

        // if (playingSetup
        //     && remoteMsg.data[kMsgEvent] == kMsgEventStoppedPlaying)
        //   playingSetup = false;

        playingMySetup = playingSetup && remoteMsg.data[kMsgSetupSender] == myUid;
        // Unless the event was stopped_playing:

        // if (playingMySetup
        //     && containsEvent
        //     && remoteMsg.data[kMsgEvent] == kMsgEventStoppedPlaying)
        //   playingMySetup = false;

        resumedPlaying = containsEvent && remoteMsg.data[kMsgEvent] == kMsgEventResumedPlaying;
      }

      if (!notificationOverride) {
        // If I am the one playing:
        if (playerIsMe) {
          print('remoteMsg: No notification because player is me.');
          var x = castRemoteMessageToMap(remoteMsg);
          printPrettyJson(x);
          if (testingNotifications && playingSetup) {
            LocalNotifications.showNotification(
                title: "Testing Notifications! Playing setup.",
                notification: "No notification because player is me.",
                data: jsonEncode(remoteMsg.data));
          }
        } else if (playingMySetup) {
          // If someone is playing my setup:
          print('remoteMsg: Playing my setup');
          LocalNotifications.showNotification(
              title: "Someone is playing your setup"
                  "${resumedPlaying ? " again" : ""}!",
              notification: "Someone ${resumedPlaying ? "just resumed playing" : "is playing"}"
                  " your setup no ${remoteMsg.data['i']} ${resumedPlaying ? '' : 'now, '}"
                  "in the game hub.",
              data: jsonEncode(remoteMsg.data));
          // This is taken care of from the Cloud Function:
          // } else if (playingSetup) {
          //   // If someone is playing any setup:
          //   LocalNotifications.showNotification(title: "Someone is playing your setup"
          //       "${resumedPlaying ? " again" : ""}!",
          //       notification: "Someone ${resumedPlaying ? "just resumed playing" : "is playing"}"
          //           " your setup no ${remoteMsg.data['i']} ${resumedPlaying ? '' : 'now, '}"
          //           "in the game hub.",
          //       data: jsonEncode(remoteMsg.data));
        } else {
          // If someone is playing someone else's setup, or any other message:
          if (remoteMsg.notification != null) {
            print('remoteMsg.notification is not null. Should show notification');
            LocalNotifications.showNotification(
                title: '${remoteMsg.notification.title}', notification: "${remoteMsg.notification.body ?? ''}", data: jsonEncode(remoteMsg.data));
          }
        }
      }
    }, onError: (error) {
      print('Error in onMessage: $error');
    });

    // TODO: Put navigation from remote notifications here
    FirebaseMessaging.onMessageOpenedApp.listen((remoteMsg) {
      print('Remote message opened app. Event is: $remoteMsg');
      var x = castRemoteMessageToMap(remoteMsg);
      print("remoteMsg:");
      printPrettyJson(x);

      Map<String, dynamic> msgData = remoteMsg.data.cast();
      bool containsData = !(MapEquality().equals(msgData, {}) || msgData == null);
      bool playingEvent = containsData && (msgData[kMsgEvent] == kMsgEventStartedPlaying || msgData[kMsgEvent] == kMsgEventResumedPlaying);
      bool newSetupEvent = containsData && msgData[kMsgEvent] == kMsgEventNewGameHubSetup;

      if (MyFirebase.authObject.currentUser.uid != null) {
        if (playingEvent) {
          navigateFromNotificationToFollowing(msgData: msgData);
        } else if (newSetupEvent) {
          // Todo: Only push if GameHubScreen() not already on top:
          Navigator.push(GlobalVariable.navState.currentContext, MaterialPageRoute(builder: (context) {
            return GameHubScreen();
            }, settings: RouteSettings(name: routeGameHub)));
        }
      }
    });

    // Get the token each time the application loads:
    // token =  _firebaseMessaging.getToken();
    if (token == '' || token == null) {
      // If called from main()
      myGlobalToken = _firebaseMessaging.getToken();
    } else {
      // If called from token change
      myGlobalToken = Future(() => token);
    }
    print('My device token is ${await myGlobalToken}');

    // Save the initial token to the database:
    await saveTokenToDatabase(await myGlobalToken);

    print('After saveTokenToDatabase()');

    // If you haven't yet subscribed to the topics, do so:
    DocumentSnapshot userSnap = await MyFirebase.storeObject.collection(kCollectionUserInfo).doc(myUid).get();
    Map<String, dynamic> userData = userSnap.data();
    if (!userData.containsKey(kFieldNotifications)) {
      _firebaseMessaging.subscribeToTopic(kTopicGameHubSetup);
      _firebaseMessaging.subscribeToTopic(kTopicPlayingSetup);
      _firebaseMessaging.subscribeToTopic(kTopicAllAppUpdates);

      MyFirebase.storeObject.collection(kCollectionUserInfo).doc(myUid).update({
        kFieldNotifications: [
          kTopicGameHubSetup,
          kTopicPlayingSetup,
          kTopicPlayingYourSetup,
          kTopicAllAppUpdates,
        ],
      });
    }
    if (myUid == '3lqh53p23sc93RgUBafdc4jtSYe2') {
      print("myUid == '3lqh53p23sc93RgUBafdc4jtSYe2'. Subscribing to Developer");
      _firebaseMessaging.subscribeToTopic(kTopicDeveloper);
      // MyFirebase.storeObject.collection(kCollectionUserInfo).doc(myUid).update({
      //   kFieldNotifications: [
      //     kTopicGameHubSetup,
      //     kTopicPlayingSetup,
      //     kTopicPlayingYourSetup,
      //     kTopicAllAppUpdates,
      //   ],
      // });
    }
  }
  // Any time the token refreshes, store this in the database too:
  // FirebaseMessaging.instance.onTokenRefresh.listen(saveTokenToDatabase);
  // _firebaseMessaging.onTokenRefresh.listen(saveTokenToDatabase);
  print('Starting onTokenRefresh.listen()');
  _firebaseMessaging.onTokenRefresh.listen((initializeFcm) {
    print('An event has come in in onTokenRefresh.listen()');
  });
}

Future<void> saveTokenToDatabase(String sentToken) async {
  print('Running saveTokenToDatabase()');

  String myUid = MyFirebase.authObject.currentUser.uid;
  print("My user ID in saveTokenToDatabase() is $myUid");
  DocumentSnapshot tokensSnapBefore;
  DocumentSnapshot tokensSnapAfter;

  if (myUid != null) {
    try {
      tokensSnapBefore = await MyFirebase.storeObject.collection(kCollectionUserInfo).doc(myUid).get();
    } catch (e) {
      print(e);
    }

    try {
      await MyFirebase.storeObject.collection(kCollectionUserInfo).doc(myUid).update({
        'tokens': FieldValue.arrayUnion([sentToken]),
      });
    } on Exception catch (e) {
      print(e);
    }

    // Clean up invalid tokens:
    try {
      tokensSnapAfter = await MyFirebase.storeObject.collection(kCollectionUserInfo).doc(myUid).get();
    } catch (e) {
      print(e);
    }
    Map<String, dynamic> myUserDataBefore = tokensSnapBefore.data();
    Map<String, dynamic> myUserDataAfter = tokensSnapAfter.data();
    List<dynamic> tokensBefore = myUserDataBefore.containsKey(kFieldTokens) ? myUserDataBefore[kFieldTokens] : [];
    List<dynamic> tokensAfter = myUserDataAfter.containsKey(kFieldTokens) ? myUserDataAfter[kFieldTokens] : [];
    bool tokenWasAdded = tokensAfter.length > tokensBefore.length;

    if (tokenWasAdded) {
      // if (true) {
      int i = 0;
      for (String token in tokensAfter) {
        i++;
        print('Sending message $i');
        Future<http.Response> sendMsgRes = fcmSendMsg(
            // context: context,
            jsonEncode({
          "notification": {
            "title": "You have registered a new device with Blackbox",
            // "body": "from ${myUserData[kFieldFirstName]}",
          },
          "data": {
            "click_action": "FLUTTER_NOTIFICATION_CLICK",
            // "show_local_notification": false,
          },
          "token": token,
        }));
        handleMsgResponse(sendMsgRes: sendMsgRes, token: token, uid: myUid); // Removes tokens no longer in use.

        http.Response res = await sendMsgRes;
        print('res in saveTokenToDatabase() is $res'
            '\nof type ${res.runtimeType}');
      }
    }
  }
}

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage remoteMsg) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  // FirebaseApp app = await Firebase.initializeApp();
  print('+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n'
      'onBackgroundMessage()');
  await Firebase.initializeApp();
  FirebaseAuth authObject = FirebaseAuth.instance;
  String myUid = authObject.currentUser.uid;
  if (remoteMsg.notification != null)
    print("Title: ${remoteMsg.notification.title}"
        "\nBody: ${remoteMsg.notification.body}"
        "\nData: ${remoteMsg.data}");

  //TODO Add the same conditions as for onMessage:
  if (remoteMsg.data.isNotEmpty) {
    if (remoteMsg.data.containsKey(kMsgPlaying) && remoteMsg.data[kMsgPlaying] == myUid) {
      // If I am the one playing:
      print('No local notification because player is me.');
      if (testingNotifications) {
        LocalNotifications.showNotification(
            title: "Testing Notifications!", notification: "No local notification because player is me.", data: jsonEncode(remoteMsg.data));
      }
    } else if (remoteMsg.data.containsKey(kMsgSetupSender) && remoteMsg.data[kMsgSetupSender] == myUid) {
      // If somebody is playing my setup:
      LocalNotifications.showNotification(
          title: "Someone is playing your setup!",
          notification: "Someone is playing your setup no ${remoteMsg.data['i']}.",
          data: jsonEncode(remoteMsg.data));
    } else {
      // If I am neither the player nor the sender of the setup:
      // LocalNotifications.showNotification('${remoteMsg.notification.title}', "${remoteMsg.notification.body}");
      print('A background data msg has come in. No local notification. Only maybe Cloud notification.');
    }
  }
}

