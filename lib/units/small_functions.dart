import 'package:blackbox/online_screens/game_hub_screen.dart';
import 'package:blackbox/global.dart';
import 'package:navigation_history_observer/navigation_history_observer.dart';
import 'package:blackbox/route_names.dart';
import 'package:blackbox/game_hub_updates.dart';
import 'package:provider/provider.dart';
import 'package:blackbox/my_firebase.dart';
import 'blackbox_popup.dart';
import 'package:blackbox/online_screens/follow_playing_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:blackbox/my_firebase_labels.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:pretty_json/pretty_json.dart';

String myUid = MyFirebase.authObject.currentUser.uid;

Map<String, dynamic> castRemoteMessageToMap(RemoteMessage remoteMsg, {bool verbose = true}) {
  Map<String, dynamic> map = {};
  Map<String, dynamic> data = {};

  if (remoteMsg.notification != null) {
    map.addAll({
      "notification": {
        "title": remoteMsg.notification.title,
        "body": remoteMsg.notification.body,
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
    printPrettyJson(x);
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

void tappedFollowPlaying(
    {BuildContext context,
    Map<String, dynamic> setupData,
    Map<String, dynamic> myUserData,
    DocumentSnapshot setup,
    // String myEmail,
    String me,
    /*String myUid, */ String player,
    bool fromNotification = false,
    Map<String, dynamic> msgData}) async {

  DocumentSnapshot userSnap;
  DocumentSnapshot setupSnap;

  assert (myUid != null); // If not logged in, I shouldn't be here

  if (fromNotification) {
    me = Provider.of<GameHubUpdates>(context, listen: false).myScreenName;

    try {
      userSnap = await MyFirebase.storeObject.collection(kCollectionUserInfo).doc(myUid).get();
      myUserData = userSnap.data();
      // myEmail = myUserData[kFieldEmail];
    } catch(e) {
      print('Error in tappedFollowPlaying(). e:'
          '\n$e');
    }

    try {
      setupSnap = await MyFirebase.storeObject.collection(kCollectionSetups).doc(msgData[kMsgSetupID]).get();
      setup = setupSnap;
      setupData = setupSnap.data();
    } catch (e) {
      print('Error in tappedFollowPlaying(). e:'
          '\n$e');
    }

    player = msgData[kMsgPlaying];
    print('Printing player in followtap: $player');
  }

  // print('Tapping "playing". myUid is $myUid');
  (setupData.containsKey('results') && (setupData['results'].containsKey(me) || setupData['results'].containsKey(myUid))) ||
          (setupData[kFieldSender] == MyFirebase.authObject.currentUser.email || setupData[kFieldSender] == myUid)
      // (setup.get('results') != null && (setup.get('results').containsKey(me) || setup.get('results').containsKey(myUid))) ||
      //         (setup.get(kFieldSender) == myEmail || setup.get(kFieldSender) == myUid)
      ? Navigator.push(context, MaterialPageRoute(builder: (context) {
          return FollowPlayingScreen(setup: setup, playingId: player, me: me);
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

void navigateFromNotificationToFollowing({@required Map<String, dynamic> msgData}){
  if (MyFirebase.authObject.currentUser.uid != null) {
    bool gameHubScreenOpen = NavigationHistoryObserver().history.any((route) {
      return route.settings.name == routeGameHub;
    });

    if (!gameHubScreenOpen) {
      Navigator.push(GlobalVariable.navState.currentContext, PageRouteBuilder(pageBuilder: (context, animation1, animation2) => GameHubScreen(),
      // Navigator.push(myGlobalKey.currentContext, PageRouteBuilder(pageBuilder: (context, animation1, animation2) => GameHubScreen(),
        transitionDuration: Duration(seconds: 0),
        settings: RouteSettings(name: routeGameHub),
      ));
    }

    tappedFollowPlaying(context: GlobalVariable.navState.currentContext, fromNotification: true, msgData: msgData);
    // tappedFollowPlaying(context: myGlobalKey.currentContext, fromNotification: true, msgData: remoteMsg.data.cast());
  }
}