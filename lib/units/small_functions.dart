import 'dart:convert';
// import 'package:pretty_json/pretty_json.dart';
import 'package:blackbox/online_screens/game_hub_screen.dart';
import 'package:blackbox/global.dart';
import 'package:navigation_history_observer/navigation_history_observer.dart';
import 'package:blackbox/route_names.dart';
import 'package:blackbox/my_firebase.dart';
import 'blackbox_popup.dart';
import 'package:blackbox/online_screens/follow_playing_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:blackbox/my_firebase_labels.dart';
import 'package:firebase_messaging/firebase_messaging.dart';


Map<String, dynamic> castRemoteMessageToMap(RemoteMessage remoteMsg, {bool verbose = true}) {
  Map<String, dynamic> map = {};
  Map<String, dynamic> data = {};

  if (remoteMsg.notification != null) {
    map.addAll({
      "notification": {
        "title": remoteMsg.notification!.title,
        "body": remoteMsg.notification!.body,
      }
    });
  }

  if (remoteMsg.data.isNotEmpty) {
    data = remoteMsg.data;
  }
  map.addAll({"data": data});

  map.addAll({
    "from": remoteMsg.from,
    kMsgCollapseKey: remoteMsg.collapseKey,
    "messageId": remoteMsg.messageId,
    "senderId": remoteMsg.senderId,
    "sentTime": remoteMsg.sentTime.toString(),
  });

  if (verbose) {
    map.addAll({
      "category": remoteMsg.category,
      "messageType": remoteMsg.messageType,
      "contentAvailable": remoteMsg.contentAvailable,
      "mutableContent": remoteMsg.mutableContent,
      "threadId": remoteMsg.threadId,
      "ttl": remoteMsg.ttl,
      // "": remoteMsg.data.
      // "": remoteMsg.ttl,
      // "": remoteMsg.ttl,
      // "": remoteMsg.ttl,
    });

    print("data.keys:");
    List<String> x = List.of(remoteMsg.data.keys);
    myPrettyPrint(x);
  }

  return map;
}

// I/flutter ( 1219): {
// I/flutter ( 1219):   "title": "Cloud message: Somebody is playing!",
// I/flutter ( 1219):   "body": "Somebody just started playing setup 344 in the game hub",
// I/flutter ( 1219):   "data": {
// I/flutter ( 1219):     "setupSender": "k8nmTbf1k6QcxREdVBdydX8V9Db2",
// I/flutter ( 1219):     "earlier_results": "[]",
// I/flutter ( 1219):     "last_move": "null",
// I/flutter ( 1219):     "i": "344",
// I/flutter ( 1219):     "playing": "3lqh53p23sc93RgUBafdc4jtSYe2",
// I/flutter ( 1219):     "event": "started_playing",
// I/flutter ( 1219):     "collapse_key": "com.karolinadart.blackbox",
// I/flutter ( 1219):     "category": null,
// I/flutter ( 1219):     "from": "/topics/kTopicPlayingSetup",
// I/flutter ( 1219):     "messageId": "0:1628792508260909%37191eab37191eab",
// I/flutter ( 1219):     "senderId": null,
// I/flutter ( 1219):     "messageType": null,
// I/flutter ( 1219):     "sentTime": "2021-08-12 21:21:47.998"
// I/flutter ( 1219):   }
// I/flutter ( 1219): }

/// If from GameHubScreen(), setup, setupData and myScreenName should be provided.
/// If from Notification click, the function will find them.
void tappedFollowPlaying(
    {required BuildContext context,
    Map<String, dynamic>? setupData,
    // required Map<String, dynamic>? myUserData,
    DocumentSnapshot? setup,
    // String myEmail,
    String? myScreenName,
    /*String myUid, */
    required String player, // Can't be null or ''.
    bool fromNotification = false,
    Map<String, dynamic>? msgData}) async {
  print('Running tappedFollowPlaying()');
  // String? myScreenName;
  String? myUid;

  // I have to be logged in for any of this to happen:
  if (MyFirebase.authObject.currentUser != null) {
    myUid = MyFirebase.authObject.currentUser!.uid;
    // print('Tapping "playing". myUid is $myUid');

    if (fromNotification) {
      DocumentSnapshot setupSnap;
      try {
        setupSnap = await MyFirebase.storeObject.collection(kCollectionSetups).doc(msgData![kMsgSetupID]).get();
        setup = setupSnap;
        setupData = setupSnap.data() as Map<String, dynamic>? ?? <String, dynamic>{};
      } catch (e) {
        print('Error in tappedFollowPlaying(): $e');
      }

      myScreenName = MyFirebase.authObject.currentUser!.displayName;
      if (myScreenName == null) {
        late DocumentSnapshot userSnap;
        Map<String, dynamic>? myUserData;
        try {
          userSnap = await MyFirebase.storeObject.collection(kCollectionUserInfo).doc(myUid).get();
          myUserData = userSnap.data() as Map<String, dynamic>? ?? {};
          if (myUserData.containsKey(kFieldScreenName)) myScreenName = myUserData[kFieldScreenName];
          // myEmail = myUserData[kFieldEmail];
        } catch(e) {
          print('Error in tappedFollowPlaying(). e:'
              '\n$e');
        }

      }
      print('Printing player in followtap: $player'); // Given as required argument
    }

    print(
        "setupData!.containsKey('results') && (setupData['results'].containsKey(myScreenName)  is ${setupData!.containsKey('results') && (setupData['results'].containsKey(myScreenName))}");
    print(
        "setupData!.containsKey('results') && setupData['results'].containsKey(myUid)  is ${setupData.containsKey('results') && setupData['results'].containsKey(myUid)}");
    print(
        "setupData[kFieldSender] == MyFirebase.authObject.currentUser!.email is ${setupData[kFieldSender] == MyFirebase.authObject.currentUser!.email}");
    print("setupData[kFieldSender] == myUid is ${setupData[kFieldSender] == myUid}");

    if (setup != null) {
      (setupData.containsKey('results') && (setupData['results'].containsKey(myScreenName) || setupData['results'].containsKey(myUid))) ||
              (setupData[kFieldSender] == MyFirebase.authObject.currentUser!.email || setupData[kFieldSender] == myUid)
          // (setup.get('results') != null && (setup.get('results').containsKey(myScreenName) || setup.get('results').containsKey(myUid))) ||
          //         (setup.get(kFieldSender) == myEmail || setup.get(kFieldSender) == myUid)
          ? Navigator.push(context, MaterialPageRoute(builder: (context) {
              return FollowPlayingScreen(setup: setup!, playingId: player /*, myScreenName: myScreenName*/);
            }))
          : player == myUid
              ? BlackboxPopup(
                  title: "Nope!",
                  desc: "If you watch yourself play before finishing, you'll see the answer, which would"
                      " totally ruin the fun.",
                  context: context,
                ).show()
              : BlackboxPopup(
                  title: "Not yet!",
                  desc: "You have to play setup ${setupData["i"]} before you can watch others play it.",
                  context: context,
                ).show();
    }
  }
}

/// msgData kan be {} but not null
void navigateFromNotificationToFollowing({required Map<String, dynamic> msgData}) {
  print('Running navigateFromNotificationToFollowing()');
  if (MyFirebase.authObject.currentUser != null) {
    bool gameHubScreenOpen = NavigationHistoryObserver().history.any((route) {
      return route.settings.name == routeGameHub;
    });

    if (!gameHubScreenOpen) {
      Navigator.push(
          GlobalVariable.navState.currentContext!,
          PageRouteBuilder(
            pageBuilder: (context, animation1, animation2) => GameHubScreen(),
            // Navigator.push(myGlobalKey.currentContext, PageRouteBuilder(pageBuilder: (context, animation1, animation2) => GameHubScreen(),
            transitionDuration: Duration(seconds: 0),
            settings: RouteSettings(name: routeGameHub),
          ));
    }

    String player = msgData[kMsgPlaying] ?? ''; // player from msg or ''.
    if (player != '') {
      tappedFollowPlaying(context: GlobalVariable.navState.currentContext!, fromNotification: true, msgData: msgData, player: player);
    }
    // tappedFollowPlaying(context: myGlobalKey.currentContext, fromNotification: true, msgData: remoteMsg.data.cast());
  }
}

// From StackOverflow:
// You can make your own print. Define this method
void printLargeStrings(String text) {
  final pattern = RegExp('.{1,800}'); // 800 is the size of each chunk
  pattern.allMatches(text).forEach((match) => print(match.group(0)));
}
// Use it like
// printLargeStrings("Your very long string ...");


void myPrettyPrint(var object) {
  try {
    printLargeStrings(myPrettyJson(object));
  } catch (e) {
    printLargeStrings('Not possible to prettyPrint. Printing as String:'
        '\n$object');
    // print('Not possible to prettyPrint. Printing as String:'
    //     '\n$object');
  }
}


///
/// prettyJson
/// Return a formatted, human readable, string.
///
/// Takes a json object and optional indent size,
/// returns a formatted String
///
/// @Map<String,dynamic> json
/// @int indent
///
/// I just copy-pasted this from the discontinued 'package:pretty_json/pretty_json.dart'
String myPrettyJson(dynamic json, {int indent = 2}) {
  var spaces = ' ' * indent;
  var encoder = JsonEncoder.withIndent(spaces);
  return encoder.convert(json);
}

void printPrettyJson(dynamic json, {int indent = 2}) {
  print(myPrettyJson(json, indent: indent));
}
