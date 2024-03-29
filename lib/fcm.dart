import 'package:blackbox/global.dart';
import 'package:collection/collection.dart';
import 'online_screens/game_hub_screen.dart';
import 'package:flutter/material.dart';
import 'route_names.dart';
import 'package:navigation_history_observer/navigation_history_observer.dart';
import 'package:blackbox/units/small_functions.dart';
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

// TODO: ***Notification sound!
/// A logout event might occur while this is still initializing!
/// Have to prepare for that, so as to not get 'permission-denied' errors:
void initializeFcm(String token) async {
  print('Initializing Firebase Cloud Messaging...');

  try {
    await MyFirebase.myFutureFirebaseApp;
  } catch (e) {
    print('Error initializing Firebase App: \n$e');
  }
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  try {
    _firebaseMessaging.getInitialMessage().then((value) {
      RemoteMessage? msg = value;
      print('The message in .getInitialMessage() is ${msg != null ? 'title: ${msg.notification != null ? '${msg.notification!.title}' : ''} body: ${msg.notification != null ? '${msg.notification!.title}' : ''} data: ${msg.data}' : null}');
      if(msg != null) openAction(msg);
    });
  } catch (e) {
    print('Error in .getInitialMessage(): \n$e');
  }

  if (MyFirebase.authObject.currentUser != null) {
    // Even if I'm not logged in yet, initializeFcm() will be triggered later,
    // if I log in, from userChangesListener() in my_firebase.dart
    String? myUid = MyFirebase.authObject.currentUser?.uid;
    DocumentSnapshot? myUserInfo;

    try {
      myUserInfo = await MyFirebase.storeObject.collection(kCollectionUserInfo).doc(myUid).get();
    } catch (e) {
      print('Error finding userInfo document in initializeFcm(): $e');
    }

    print('myUserInfo.data() in initializeFcm() is:');
    // printPrettyJson(myUserInfo.data());
    myPrettyPrint(myUserInfo?.data());

    if (myUserInfo?.data() != null) {
      // I have an entry in the userinfo collection.
      // All users should have an entry there, but if they don't, one will be made
      // from LoginScreen() and initializeFcm() will be fired again.

      // An iOS thing... Makes messages show up as alerts on Apple devices,
      // even if app is in foreground:
      // _firebaseMessaging.setForegroundNotificationPresentationOptions(
      //   alert: true,
      //   badge: true,
      //   sound: true,
      // );

      try {
        // An iOS thing... but can return a Future<NotificationSettings> on Android
        _firebaseMessaging.requestPermission(
          sound: true,
          //The rest as default
        );

        // I have no idea what the below does!
        _firebaseMessaging.setAutoInitEnabled(true);
      } catch (e) {
        print('Error in _firebaseMessaging.stuff...: \n$e');
      }

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
      ///                          // kMsgOverride: kMsgOverrideYes,
      ///                        },
      ///                        // Nokia:
      ///                        "token": 'f2F3dytfT9iW8LYUq796aa:APA91bG0OnzHIkQtv9Iq_z-sy93lanzHSbe53lBiwXFp1z6uY6ghn6IxgqxePZYCKr8MQ29z-rMiPWgXiB59JAD-2IO5VR7ixS0GVj1GKU-a0rvEUepRKnPHWRcB7xoph5u_bShgnNUF',
      ///                        // Small Nexus:
      ///                        // "token": 'doxTxf2VR0eGAf6RlmCDZ7:APA91bFfo8eGiOzEC_d4oyrzpYz4z6L2laIm3vJc_fWjWolvqgKh2HirX8cQgH-cv6i0IfAktSXxIjWGLvTA4fESwDnonSrf9khh3z1g0j8CgkpRT2obA_9bMOcHeiPvdiryKWXzgCFR',
      ///                        // "token": '${await myGlobalToken}',
      ///                      }),
      ///                      context);
      /// The content in localNotification will override the notification specified in onMessage

      // If a message comes in while app in foreground:
      FirebaseMessaging.onMessage.listen((remoteMsg) async {
        // Will this give an error if I'm no longer logged in...?
        print('++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n'
            'onMessage');
        if (remoteMsg.notification != null) {
          print(remoteMsg.notification!.title);
          print(remoteMsg.notification!.body);
        }

        print('remoteMsg is:');
        try {
          myPrettyPrint(castRemoteMessageToMap(remoteMsg));
        } catch (e) {
          print('Error in myPrettyPrint');
        }
        // print('Or with built-in map cast:');
        // printPrettyJson(remoteMsg.data.cast());  //Only the data property...
        // print('remoteMsg.data is:');
        // printPrettyJson(remoteMsg.data);
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

          // To let the remote notification override local notification:
          Map<String, dynamic> data = remoteMsg.data.cast(); //!!!!!!! :D
          Map<String, dynamic>? notificationData = {};
          print('Msg data is:');
          myPrettyPrint(data);
          localNotificationField = data.containsKey(kMsgShowLocalNotification);
          notificationOverride = data[kMsgOverride] == kMsgOverrideYes;
          print("localNotificationField is $localNotificationField");
          print("notificationOverride is $notificationOverride");

          if (localNotificationField) {
            notificationData = jsonDecode(data[kMsgShowLocalNotification]);
            print('notificationData is $notificationData');

            // await Future.delayed(Duration(seconds: 1)); // This makes it over-write the other one...
            // Wait... what other one?
            LocalNotifications.showNotification(
              title: notificationData![kMsgNotification][kMsgTitle],
              notification: notificationData[kMsgNotification][kMsgBody],
              data: jsonEncode(notificationData[kMsgData]),
              category: 'GameHub',
              description: 'New game hub events',
            );
          }

          containsEvent = remoteMsg.data.containsKey(kMsgEvent);
          playerIsMe = remoteMsg.data.containsKey(kMsgPlaying) && remoteMsg.data[kMsgPlaying] == myUid;
          playingSetup =
              (containsEvent
                  && (remoteMsg.data[kMsgEvent] == kMsgEventStartedPlaying || remoteMsg.data[kMsgEvent] == kMsgEventResumedPlaying));


          playingMySetup = playingSetup && remoteMsg.data[kMsgSetupSender] == myUid;

          resumedPlaying = containsEvent && remoteMsg.data[kMsgEvent] == kMsgEventResumedPlaying;
        }

        if (!notificationOverride) {
          // If I am the one playing:
          if (playerIsMe) {
            print('remoteMsg: No notification because player is me.');
            if (testingNotifications && playingSetup) {
              LocalNotifications.showNotification(
                  title: "Testing Notifications! Playing setup.",
                  notification: "No notification because player is me.",
                  data: jsonEncode(remoteMsg.data),
                category: 'GameHub',
                description: 'New game hub events',
              );
            }
          // I'm not the one playing:
          } else if (playingMySetup) {
            // If someone is playing my setup:
            print('remoteMsg: Playing my setup');
            if (testingNotifications) {
              print('Testing notifications');
              String title = remoteMsg.notification != null && remoteMsg.notification!.title != null ? remoteMsg.notification!.title! : '';
              String body =  remoteMsg.notification != null && remoteMsg.notification!.body != null ? remoteMsg.notification!.body! : '';
              LocalNotifications.showNotification(
                  title: title,
                  notification:
                    body
                    // "${ testingNotifications ? ' Your uid is $myUid' : ''}"
                  ,
                  data: jsonEncode(remoteMsg.data),
                category: 'GameHub',
                description: 'New game hub events',
              );
            } else {
              LocalNotifications.showNotification(
                  title: "Someone is playing your setup"
                      "${resumedPlaying ? " again" : ""}!",
                  notification: "Someone ${resumedPlaying ? "just resumed playing" : "is playing"}"
                      " your setup no ${remoteMsg.data['i']} ${resumedPlaying ? '' : 'now, '}"
                      "in the game hub.",
                  data: jsonEncode(remoteMsg.data),
                category: 'GameHub',
                description: 'New game hub events',
              );
            }
          } else {
            // If someone is playing someone else's setup, or any other message:
            if (remoteMsg.notification != null) {
              print('remoteMsg.notification is not null. Should show notification');
              LocalNotifications.showNotification(
                  title: '${remoteMsg.notification!.title}', notification: "${remoteMsg.notification!.body ?? ''}", data: jsonEncode(remoteMsg.data), category: 'GameHub', description: 'New game hub events');
            }
          }
        }
      }, onError: (error) {
        print('Error in onMessage: $error');
      });

      // Fired if notification opened app from background, not from terminated:
      FirebaseMessaging.onMessageOpenedApp.listen((remoteMsg) {
        print('Remote message opened app from background - not terminated. remoteMsg is:');
        myPrettyPrint(castRemoteMessageToMap(remoteMsg));
        openAction(remoteMsg);
      });

      // Get the token each time the application loads:
      // token =  _firebaseMessaging.getToken();
      if (token == '') {
        // If called from main() or userChangesListener()
        if (MyFirebase.authObject.currentUser != null) {  // Still logged in check
          try {
            myGlobalToken = _firebaseMessaging.getToken();
          } catch (e) {
            print('Error getting firebase device token: \n$e');
          }
        }
        // Moved this to later:
        // _firebaseMessaging.onTokenRefresh.listen((newToken) {
        //   // newToken can never be null
        //   initializeFcm(newToken);
        // });
      } else {
        // If called from token change
        myGlobalToken = Future(() => token);
      }
      /// First print after 'cloud_firestore/permission-denied':
      print('My device token is ${await myGlobalToken}');

      // Save the initial token to the database:
      if (MyFirebase.authObject.currentUser != null) {
        try {
          await saveTokenToDatabase(await myGlobalToken);
        } catch (e) {
          print('Error saving token to database: \n$e');
        }
      }

      print('After saveTokenToDatabase()');

      // If you haven't yet subscribed to the topics, do so:
      DocumentSnapshot? userSnap;
      try {
        userSnap = await MyFirebase.storeObject.collection(kCollectionUserInfo).doc(myUid).get();
      } catch (e) {
        print('Error getting a userSnap: \n$e');
      }
      if (userSnap != null) {
        Map<String, dynamic> userData = userSnap.data() as Map<String, dynamic>? ?? {};
        if (!userData.containsKey(kFieldNotifications)) {
          _firebaseMessaging.subscribeToTopic(kTopicGameHubSetup);
          _firebaseMessaging.subscribeToTopic(kTopicPlayingSetup);
          _firebaseMessaging.subscribeToTopic(kTopicAllAppUpdates);

          try {
            MyFirebase.storeObject.collection(kCollectionUserInfo).doc(myUid).update({
              kFieldNotifications: [
                kTopicGameHubSetup,
                kTopicPlayingSetup,
                kTopicPlayingYourSetup,
                kTopicAllAppUpdates,
              ],
            });
          } catch (e) {
            print('Error updating notification topics in userinfo: \n$e');
          }
        }

        // Subscribe Karolina to Developer topic:
        print("myUid is: $myUid.");
        if (myUid == '3lqh53p23sc93RgUBafdc4jtSYe2' || myUid == 'bVsFYm2KuTQH5G2bWOfKI45IBlS2') {
          print("myUid == $myUid. Subscribing to Developer");
          try {
            _firebaseMessaging.subscribeToTopic(kTopicDeveloper);
            MyFirebase.storeObject.collection(kCollectionUserInfo).doc(myUid).update({
              kFieldNotifications: FieldValue.arrayUnion([
                kTopicDeveloper,
              ]),
            });
          } catch (e) {
            print('Error subscribing Karolina to Developer topic: \n$e');
          }
        }
      }

      // Any time the token refreshes, store this in the database too:
      if (MyFirebase.authObject.currentUser != null) {
        print('Starting onTokenRefresh.listen(). myUid is ${MyFirebase.authObject.currentUser?.uid}.');
        // FirebaseMessaging.instance.onTokenRefresh.listen(saveTokenToDatabase);
        // _firebaseMessaging.onTokenRefresh.listen(saveTokenToDatabase);
        // _firebaseMessaging.onTokenRefresh.listen((initializeFcm) {
        _firebaseMessaging.onTokenRefresh.listen((newToken) {
          // newToken can never be null
          print('An event has come in in onTokenRefresh.listen().'
              '\nThe event is $newToken');
          // saveTokenToDatabase(newToken); // This will happen below anyway:
          initializeFcm(newToken);
        });
      }
    }
  }
}

Future<void> saveTokenToDatabase(String? sentToken) async {
  print('Running saveTokenToDatabase()');

  String? myUid = MyFirebase.authObject.currentUser?.uid; // Might have logged out...
  print("My user ID in saveTokenToDatabase() is $myUid");
  DocumentSnapshot? tokensSnapBefore;
  DocumentSnapshot? tokensSnapAfter;

  if (myUid != null) {
    try {
      tokensSnapBefore = await MyFirebase.storeObject.collection(kCollectionUserInfo).doc(myUid).get();
    } catch (e) {
      print('Error getting tokens snap: \n$e');
    }

    try {
      await MyFirebase.storeObject.collection(kCollectionUserInfo).doc(myUid).update({
        'tokens': FieldValue.arrayUnion([sentToken]),
      });
    } on Exception catch (e) {
      print('Error saving token to database in saveTokenToDatabase(): \n$e');
    }

    // Clean up invalid tokens:
    try {
      tokensSnapAfter = await MyFirebase.storeObject.collection(kCollectionUserInfo).doc(myUid).get();
    } catch (e) {
      print('Error getting tokensSnapAfter: \n$e');
    }
    Map<String, dynamic>? myUserDataBefore = tokensSnapBefore?.data() as Map<String, dynamic>?;
    Map<String, dynamic>? myUserDataAfter = tokensSnapAfter?.data() as Map<String, dynamic>?;
    List<dynamic>? tokensBefore = [];
    List<dynamic>? tokensAfter = [];

    if (myUserDataBefore != null) {
      tokensBefore = myUserDataBefore.containsKey(kFieldTokens) ? myUserDataBefore[kFieldTokens] : [];
    }
    if (myUserDataAfter != null) {
      tokensAfter = myUserDataAfter.containsKey(kFieldTokens) ? myUserDataAfter[kFieldTokens] : [];
    }
    
    bool tokenWasAdded = tokensAfter!.length > tokensBefore!.length;

    // Send a notification if a new device was added (or app reinstalled) to clear invalid tokens:
    if (tokenWasAdded) {
      // if (true) {
      int i = 0;
      for (String token in tokensAfter) {
        i++;
        print('Sending message $i');
        Future<http.Response> sendMsgRes = fcmSendMsg(
            // context: context,
            jsonEncode({
          // "notification": {
          //   "title": "You have registered a new device with Blackbox",
          //   // "body": "from ${myUserData[kFieldFirstName]}",
          // },
          "data": {
            "click_action": "FLUTTER_NOTIFICATION_CLICK",
            "$kMsgEvent": "$kMsgEventAddedToken"
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
  String myUid = authObject.currentUser!.uid;
  // if (remoteMsg.notification != null) {
  //   print("Title: ${remoteMsg.notification!.title}"
  //       "\nBody: ${remoteMsg.notification!.body}"
  //       "\nData:");
  //   printPrettyJson(remoteMsg.data);
  // }
  myPrettyPrint(castRemoteMessageToMap(remoteMsg));

  //TODO: ***Add the same conditions as for onMessage:
  // On second thought... Let's just not show any local notifications if
  // app is in background! That only means the user gets two notifications,
  // and if they tap the local one, they won't be properly navigated...
  // if (remoteMsg.data.isNotEmpty) {
  //   if (remoteMsg.data.containsKey(kMsgPlaying) && remoteMsg.data[kMsgPlaying] == myUid) {
  //     // If I am the one playing:
  //     print('No local notification because player is me.');
  //     if (testingNotifications) {
  //       LocalNotifications.showNotification(
  //           title: "Testing Notifications!", notification: "No local notification because player is me.", data: jsonEncode(remoteMsg.data), category: 'GameHub', description: 'New game hub events');
  //     }
  //   } else if (remoteMsg.data.containsKey(kMsgSetupSender) && remoteMsg.data[kMsgSetupSender] == myUid) {
  //     // If somebody is playing my setup:
  //     if (testingNotifications) {
  //       print('Testing notifications');
  //       String title = remoteMsg.notification != null && remoteMsg.notification!.title != null ? remoteMsg.notification!.title! : '';
  //       String body =  remoteMsg.notification != null && remoteMsg.notification!.body != null ? remoteMsg.notification!.body! : '';
  //       LocalNotifications.showNotification(
  //           title: title,
  //           notification: body
  //           // "${ testingNotifications ? ' Your uid is $myUid' : ''}"
  //           ,
  //           data: jsonEncode(remoteMsg.data),
  //         category: 'GameHub',
  //         description: 'New game hub events',
  //       );
  //     } else {
  //       print('Not testing notifications');
  //       LocalNotifications.showNotification(
  //           title: "Someone is playing your setup!",
  //           notification: "Someone is playing your setup no ${remoteMsg.data['i']}."
  //           // "${ testingNotifications ? ' Your uid is $myUid' : ''}"
  //           ,
  //           data: jsonEncode(remoteMsg.data),
  //         category: 'GameHub',
  //         description: 'New game hub events',
  //       );
  //     }
  //   } else {
  //     // If I am neither the player nor the sender of the setup:
  //     // LocalNotifications.showNotification('${remoteMsg.notification.title}', "${remoteMsg.notification.body}");
  //     print('A background data msg has come in. No local notification. Only maybe Cloud notification.');
  //   }
  // }
}

//TODO: If the player has removed their playing tag before you click the notification, it shouldn't take you to FollowPlayingScreen....
/// Called when user opens a remote notification.
/// Should only be called after await myFutureFirebaseApp.
void openAction(RemoteMessage remoteMsg) {
  Map<String, dynamic> msgData = remoteMsg.data.cast(); // returns {} if message has no data field
  bool containsData = !MapEquality().equals(msgData, {});
  bool playingEvent = containsData && (msgData[kMsgEvent] == kMsgEventStartedPlaying || msgData[kMsgEvent] == kMsgEventResumedPlaying);
  bool newSetupEvent = containsData && msgData[kMsgEvent] == kMsgEventNewGameHubSetup;

  if (MyFirebase.authObject.currentUser != null) {
    if (playingEvent) {
      navigateFromNotificationToFollowing(msgData: msgData);
    } else if (newSetupEvent) {
      Route topRoute = NavigationHistoryObserver().top!;
      if (topRoute.settings.name != routeGameHub) {
        Navigator.push(GlobalVariable.navState.currentContext!, MaterialPageRoute(settings: RouteSettings(name: routeGameHub), builder: (context){
          return GameHubScreen();
        }));
      }
    }
  }
}

//TODO: What if I listen to onSelectNotification from inside
// firebaseMessagingBackgroundHandler()...? Will that mean I can get the
// data from the local notification in there? Which I don't get in getInitialMessage()...?