import 'package:blackbox/play_screen_menu.dart';
import 'package:blackbox/units/ping_widget.dart';
import 'package:blackbox/units/final_answer_press.dart';
import 'package:blackbox/units/fcm_send_msg.dart';
import 'package:wakelock/wakelock.dart';
// import 'package:blackbox/alternative_solutions_play.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:blackbox/game_hub_updates.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:provider/provider.dart';
import 'package:blackbox/units/small_widgets.dart';
import 'package:blackbox/my_firebase_labels.dart';
import 'dart:convert';
import 'package:blackbox/constants.dart';
import 'package:collection/collection.dart';
import 'dart:async';
import 'package:blackbox/my_firebase.dart';
import 'package:blackbox/screens/results_screen.dart';

// import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../play_board.dart';
import '../play.dart';
import '../atom_n_beam.dart';
//import 'package:firebase_auth/firebase_auth.dart' as auth;

//import 'package:provider/provider.dart';
//import 'package:blackbox/game_hub_updates.dart';

class PlayScreen extends StatefulWidget {
  PlayScreen({@required this.thisGame, this.setup, this.testBeams,
//    this.playingId //For testPlayButtonPress() in FollowPlayingScreen()
  });

  final Play thisGame;
  final DocumentSnapshot setup;
  final List<int> testBeams;
//  final String playingId;

  @override
  _PlayScreenState createState() => _PlayScreenState(thisGame, setup, testBeams);
}

class _PlayScreenState extends State<PlayScreen> {
  _PlayScreenState(this.thisGame, this.setup, this.testBeams);

  final Play thisGame;
  final DocumentSnapshot setup;
  String setupID;
  final List<int> testBeams;
  GameHubUpdates gameHubProvider;
  String myUid;
  Map<String, dynamic> setupData = {};
  Future<Timestamp> startedPlaying;
  Stream<DocumentSnapshot> thisSetupStream;
  StreamSubscription setupListener;

  // Timestamp started;
  String startedString = 'N/A';

//  StreamSubscription<auth.User> userListener;
  bool answered = false;

  @override
  void initState() {
//    getCurrentUser();
    print('PlayScreen() initState playerId is ${thisGame.playerId}');
    Wakelock.enable(); // Prevents phone from sleeping for as long as this screen is open
    // gameHubProvider = Provider.of<GameHubUpdates>(context, listen: false);

    if (MyFirebase.authObject.currentUser != null) {
      myUid = MyFirebase.authObject.currentUser.uid;
      thisGame.playerId = myUid;
    }
    print('PlayScreen() initState playerId a bit later is ${thisGame.playerId}');

    if (thisGame.online) {
      setupData = setup.data();
      setupID = setup.id;
      thisSetupStream = MyFirebase.storeObject.collection('setups').doc(setup.id).snapshots();
      getSetupStream();

      if (setupData != null && setupData.containsKey(kFieldShuffleA) && setupData.containsKey(kFieldShuffleB)) {
        thisGame.beamImageIndexA = [];
        for (int i = 0; i < setupData[kFieldShuffleA].length; i++) {
          thisGame.beamImageIndexA.add(setupData[kFieldShuffleA][i]);
        }

        thisGame.beamImageIndexB = [];
        for (int i = 0; i < setupData[kFieldShuffleB].length; i++) {
          thisGame.beamImageIndexB.add(setupData[kFieldShuffleB][i]);
        }
      }

      List<Atom> receivedAtoms = [];
      for (int i = 0; i < setupData['atoms'].length; i += 2) {
        receivedAtoms.add(Atom(setupData['atoms'][i], setupData['atoms'][i + 1]));
      }
      thisGame.atoms = receivedAtoms;

      //If I'm already playing this game:
      if (setupData.containsKey(kFieldPlaying) && setupData[kFieldPlaying].containsKey(thisGame.playerId)) {
        ping();
        startedPlaying = Future(() => setupData[kFieldPlaying][thisGame.playerId][kSubFieldStartedPlaying]); // If it's null it's null.
        if (setupData[kFieldPlaying][thisGame.playerId][kSubFieldStartedPlaying] != null) {
          startedString = DateFormat('d MMM, HH:mm:ss').format(setupData[kFieldPlaying][thisGame.playerId][kSubFieldStartedPlaying].toDate());
        }

        if (setupData[kFieldPlaying][thisGame.playerId].containsKey(kSubFieldMarkUpList)) {
          List<dynamic> sentClearList = setupData[kFieldPlaying][thisGame.playerId][kSubFieldMarkUpList];
          for (int i = 0; i < sentClearList.length; i += 2) {
            thisGame.markUpList.add([sentClearList[i], sentClearList[i + 1]]);
          }
        }

        List<Atom> receivedPlayingAtoms = [];
        List<dynamic> playingAtoms = setupData[kFieldPlaying][thisGame.playerId][kSubFieldPlayingAtoms] ?? [];
        for (int i = 0; i < playingAtoms.length; i += 2) {
          receivedPlayingAtoms.add(Atom(playingAtoms[i], playingAtoms[i + 1]));
        }

        thisGame.playerAtoms = receivedPlayingAtoms;
        // print('receivedPlayingAtoms are $receivedPlayingAtoms');

        List<dynamic> playingBeams = setupData[kFieldPlaying][thisGame.playerId][kSubFieldPlayingBeams] ?? [];
        for (int receivedBeamNo in playingBeams) {
          // print("receivedBeamNo is $receivedBeamNo");
          dynamic result = thisGame.getBeamResult(inSlot: receivedBeamNo);
          thisGame.setEdgeTiles(inSlot: receivedBeamNo, beamResult: result);
        }
        sendPushNotifications(kTopicResumedPlayingSetup);
      } else {
        //I'm not already playing:
        // print('Creating empty "player" Map for ${thisGame.playerId}');
        // startedPlaying = FieldValue.serverTimestamp();
        // startedPlaying = startedPlaying.toDate();
        setupData.putIfAbsent('playing', () => {});
        setupData['playing'].putIfAbsent(
            // '$myUid',
            '${thisGame.playerId}',
            () => {
                  'playingAtoms': [],
                  'playingBeams': [],
                  '$kSubFieldStartedPlaying': FieldValue.serverTimestamp(),
                });
        // print('setupData in PlayScreen initState() is $setupData');
        sendPushNotifications(kTopicPlayingSetup);
        Future<void> uploadDoc =
            MyFirebase.storeObject.collection('setups').doc(widget.setup.id).set({'playing': setupData['playing']}, SetOptions(merge: true));
        startedPlaying = getStartedPlaying(uploadDoc);
        ping(uploadDoc: uploadDoc);
      }

      // print('Atoms are in positions:');
      // for (Atom atom in thisGame.atoms) {
      //   print(atom.position.toList());
      // }
      // print('**************************');
    }
    super.initState();
  }

  @override
  void dispose() async {
    super.dispose();
//    userListener.cancel();
    Wakelock.disable();
    if (thisGame.online) {
      setupListener.cancel();
      DocumentSnapshot snapshot = await MyFirebase.storeObject.collection('setups').doc(widget.setup.id).get();
      Map<String, dynamic> endSetupData = snapshot.data();

      //If the player leaves without having played, remove their 'playing' key, if it still exists:
      if (endSetupData.containsKey('playing') &&
          endSetupData['playing'].containsKey(thisGame.playerId) &&
          endSetupData['playing'][thisGame.playerId].containsKey('playingAtoms') &&
          endSetupData['playing'][thisGame.playerId].containsKey(kSubFieldPlayingBeams) &&
          ListEquality().equals(endSetupData['playing'][thisGame.playerId]['playingAtoms'], []) &&
          ListEquality().equals(endSetupData['playing'][thisGame.playerId]['playingBeams'], [])) {
        // print("endSetupData in dispose() is $endSetupData\n***************************");
        String myUid = MyFirebase.authObject.currentUser.uid;

        MyFirebase.storeObject.collection(kCollectionSetups).doc(widget.setup.id).update({
          '$kFieldPlaying.${thisGame.playerId}': FieldValue.delete(),
        });
        //If I want to check the effect of the above:
//      DocumentSnapshot x =  await MyFirebase.storeObject.collection('setups').doc(widget.setup.id).get();
//      Map<String, dynamic> afterUploadSetupData = x.data();
//      print("afterUploadSetupData is $afterUploadSetupData");

        // Delete ping document in subCollection
        MyFirebase.storeObject
            .collection(kCollectionSetups)
            .doc(widget.setup.id)
            .collection(kSubCollectionPlayingPings)
            .doc(kSubCollectionPlayingPings)
            .update({
          '$myUid': FieldValue.delete(),
        });
        // MyFirebase.storeObject.collection(kCollectionSetups).doc(widget.setup.id).collection(kSubCollectionPlayingPings).doc(thisGame.playerId).delete();

        // TODO: ---Change topic:
        // This could be used to "unsend" a Playing-notification, if it is collapsible:
        String jsonString = jsonEncode({
          "data": {
            "event": "$kMsgEventStoppedPlaying",
            kMsgPlaying: "$myUid",
            "$kMsgSetupSender": "${setup[kFieldSender]}",
            "i": "${setupData['i']}",
            kMsgSetupID: "$setupID",
            // "collapse_key": myUid + "_playing_" + setupData['i'].toString(),
          },
          // "token": "${await myGlobalToken}",
          "topic": kTopicPlayingSetup,
          // "topic": kTopicDeveloper, // For testing
        });
        // print("jsonString is $jsonString");

        fcmSendMsg(jsonString);
        // Future<http.Response> sendMsgRes = fcmSendMsg(jsonString);
        // handleMsgResponse(sendMsgRes: sendMsgRes, token: token, uid: uid)
      }
      // Remove any corrupted, half-deleted "playing" fields:
      if (endSetupData.containsKey(kFieldPlaying)) {
        for (String playingId in endSetupData['playing'].keys) {
          if (endSetupData[kFieldPlaying][playingId][kSubFieldPlayingDone] == true ||
              !(endSetupData[kFieldPlaying][playingId].containsKey(kSubFieldPlayingAtoms) &&
                  endSetupData[kFieldPlaying][playingId].containsKey(kSubFieldPlayingBeams))) {
            // print("endSetupData in dispose() is $endSetupData\n***************************");
            MyFirebase.storeObject.collection(kCollectionSetups).doc(widget.setup.id).update({
              '$kFieldPlaying.$playingId': FieldValue.delete(),
            });
            // Delete ping document in subCollection
            MyFirebase.storeObject.collection(kCollectionSetups).doc(widget.setup.id).collection(kSubCollectionPlayingPings).doc(playingId).delete();
            //If I want to check the effect of the above:
            //      DocumentSnapshot x =  await MyFirebase.storeObject.collection('setups').doc(widget.setup.id).get();
            //      Map<String, dynamic> afterUploadSetupData = x.data();
            //      print("afterUploadSetupData is $afterUploadSetupData");
          }
        }
        if (endSetupData[kFieldPlaying].isEmpty) {
          // print('Deleting "playing" field.');
          MyFirebase.storeObject.collection(kCollectionSetups).doc(widget.setup.id).update({
            '$kFieldPlaying': FieldValue.delete(),
          });
          // Delete ping document in subCollection
          MyFirebase.storeObject
              .collection(kCollectionSetups)
              .doc(widget.setup.id)
              .collection(kSubCollectionPlayingPings)
              .doc(thisGame.playerId)
              .delete();
        }
      }
    }
  }

  void ping({Future<void> uploadDoc}) async {
    if (uploadDoc != null) await uploadDoc; // If I wasn't already playing this game, we need to wait until Playing tag has uploaded.
    // int i = 0;
    // TODO: ---Turn ping back on (if commented out):
    do {
      // print('Ping no $i');
      try {
        await MyFirebase.storeObject.collection(kCollectionSetups).doc(setup.id).collection('PlayingPings').doc('PlayingPings').set({
          // await MyFirebase.storeObject.collection(kCollectionSetups).doc(setup.id).collection('PlayingPings').doc(myUid).set({
          '$myUid': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } on Exception catch (e) {
        print('Ping upload error: $e');
      }
      // await MyFirebase.storeObject.collection(kCollectionSetups).doc(setup.id).update({
      //    '$kFieldPlaying.${thisGame.playerId}.$kSubFieldPing': FieldValue.serverTimestamp(),
      //  });
      await Future.delayed(Duration(seconds: 4));
      // i++;
    } while (this.mounted);
  }

  Future<Timestamp> getStartedPlaying(Future<void> uploadDoc) async {
    // Wait for the playing tag to upload. Then download it again to get the "StartedPlaying" timestamp.
    setState(() {
      showSpinner = true;
    });
    await uploadDoc;
    DocumentSnapshot doc;
    Timestamp _startedPlaying;
    try {
      doc = await MyFirebase.storeObject.collection(kCollectionSetups).doc(setup.id).get();
      Map<String, dynamic> docData = doc.data();
      _startedPlaying = docData[kFieldPlaying][thisGame.playerId][kSubFieldStartedPlaying];
    } catch (e) {
      print('Error getting _startedPlaying: $e');
    }
    // print('_startedPlaying is $_startedPlaying in getStartedPlaying()');
    if (_startedPlaying != null) {
      setState(() {
        startedString = DateFormat('d MMM, HH:mm:ss').format(_startedPlaying.toDate());
      });
    }

    setState(() {
      showSpinner = false;
    });
    return _startedPlaying;
  }

//  void getCurrentUser(){
//    loggedInUser = MyFirebase.authObject.currentUser;
//    userListener = MyFirebase.authObject.userChanges().listen((event) {
//      loggedInUser = event;
////      print("Play screen getCurrentUser() event.email is ${event.email}");  //This will crash if event is null...
//    });
//    print('Play screen printing loggedInUser $loggedInUser'); //Should be null before it's done
////    widget.thisGame.playerId = Provider.of<GameHubUpdates>(context, listen: false).myId;
//  }

  void sendPushNotifications(String topic) async {
    String myUid = MyFirebase.authObject.currentUser.uid;

    List<String> resultKeys = [];
    if (setupData.containsKey(kFieldResults)) {
      for (String key in setupData[kFieldResults].keys) {
        resultKeys.add(key);
      }
    }
    print('resultKeys is $resultKeys');
    String jsonString = jsonEncode({
      "data": {
        "event": "${topic == kTopicPlayingSetup ? 'started_playing' : topic == kTopicResumedPlayingSetup ? 'resumed_playing' : ''}",
        "playing": "$myUid",
        "last_move": "${topic == kTopicResumedPlayingSetup ? '${setupData[kFieldPlaying][myUid][kSubFieldLastMove]}' : null}",
        "earlier_results": "$resultKeys",
        // "earlier_results": setupData[kFieldResults], // I was thinking I could send the score... to send notifications for very high or low score setups, but...
        kMsgSetupSender: "${setupData[kFieldSender]}",
        kMsgI: setupData['i'].toString(),
        kMsgSetupID: "$setupID"
        // "collapse_key": myUid + "_playing_" + setupData['i'].toString(),
      },
      // "token": "${await myGlobalToken}",
      "topic": topic,
    });
    // String jsonString = jsonEncode({
    //   "notification": {
    //     "title": "Someone is playing!",
    //     "body": "Someone ${topic == kTopicPlayingSetup ? 'is playing': topic == kTopicResumedPlayingSetup ? 'just resumed playing': ''} setup no ${setupData['i']}nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn.",
    //   },
    //   "data": {
    //     "click_action": "FLUTTER_NOTIFICATION_CLICK",
    //     "playing": "$myUid",
    //     "setupSender": "${setup[kFieldSender]}",
    //     "i": setupData['i'].toString(),
    //     // "collapse_key": myUid + "_playing_" + setupData['i'].toString(),
    //   },
    //   // "token": "${await myGlobalToken}",
    //   // "topic": topic,
    //   "topic": kTopicDeveloper,  // For testing
    // });
    // print("jsonString is $jsonString");

    fcmSendMsg(jsonString, context);
//     print('API address is ${kApiCloudFunctionsLink + kApiSendMsg}');
//     Map<String, String> headers = {
//       kApiContentType: kApiApplicationJson
//     };
//     try {
//       res = await http.post(
//         // 'https://us-central1-blackbox-6b836.cloudfunctions.net/sendMsg',
//         kApiCloudFunctionsLink + kApiSendMsg,
//         headers: headers,
//         body: jsonString,
//       );
//     } catch (e) {
//       print('Caught an error in sendMsg to topic $topic API call!');
//       print('e is: ${e.toString()}');
// // errorMsg = e.toString();
//       BlackboxPopup(context: context, title: 'Error', desc: '$e').show();
//       if (res != null) print('Status code in apiCall() catch is ${res.statusCode}');
//     }
//     if (res != null) {
//       print('sendMsg to topic $topic API call response body: ${res.body}');
//       print('sendMsg to topic $topic API call response code: ${res.statusCode}');
//       desc = res.body;
//       code = res.statusCode.toString();
//     } else {
//       print('sendMsg to topic $topic API call response is $res');
//     }
// // BlackboxPopup(context: context, title: 'Response $code', desc: '$desc').show();
//     print('code is $code and desc is $desc in sendPushNotification');
  }

  void refresh() {
    setState(() {});
  }

  void rebuild() {
    print('Running rebuild() in ${widget.runtimeType}');
    // print('thisGame.markUpList ${thisGame.markUpList}');
    // Navigator.pop(context);
    Navigator.pushReplacement(context, PageRouteBuilder(pageBuilder: (context, anim1, anim2) {
      return PlayScreen(thisGame: thisGame, setup: setup, testBeams: testBeams);
    }, transitionDuration: Duration(days: 0)));
  }

//   Future<void> onlineButtonPress() async {
// //    print('setupData in OnlineButtonPress() is $setupData');
//
//     //If I didn't already click Final Answer this round, and I don't already have an uploaded result from before:
//     if (!answered && !(setupData.containsKey(kFieldResults) && setupData[kFieldResults].containsKey('${thisGame.playerId}'))) {
//       answered = true;
//       // thisGame.getAtomScore();
//
//       //Because Firebase can't stomach a List<List<int>>:
//       //Put player atoms in array to send:
//       List<int> sendPlayerAtoms = [];
//       // for (List<int> pAtom in thisGame.playerAtoms) {
//       for (Atom pAtom in thisGame.playerAtoms) {
//         sendPlayerAtoms.add(pAtom.position.x);
//         sendPlayerAtoms.add(pAtom.position.y);
//         // sendPlayerAtoms.add(pAtom[0]);
//         // sendPlayerAtoms.add(pAtom[1]);
//       }
//
//       //It should wait so that results are uploaded before 'done' is turned true:
//       //Will create the player ID key in 'result' if it's not there (which it isn't).
//       await MyFirebase.storeObject.collection(kSetupCollection).doc(widget.setup.id).update({
//         '$kFieldResults.${thisGame.playerId}': {
//           'A': thisGame.atomScore,
//           'B': thisGame.beamScore,
//           'sentBeams': thisGame.sentBeams,
//           'playerAtoms': sendPlayerAtoms,
//           '$kSubFieldStartedPlaying': await startedPlaying, // Might be null (if player started playing before installing this version).
//           '$kSubFieldFinishedPlaying': FieldValue.serverTimestamp(),
//         }
//       });
//
//       // thisGame.correctAtoms = [];
//       // thisGame.misplacedAtoms = [];
//       // thisGame.missedAtoms = [];
//       // thisGame.atomScore = 0;
//     }
//
//     // print('About to update done to true');
//     //This will navigate any listener to this game to the ResultsScreen(), and must await to avoid deleting and writing at the same time:
//     await MyFirebase.storeObject.collection(kSetupCollection).doc(widget.setup.id).update({
//       '$kFieldPlaying.${thisGame.playerId}.$kPlayingDone': true,
//     });
//     // print('Done updating done to true');
//     await Future.delayed(Duration(seconds: 6)); // To give the above plenty of time to complete before the below happens
//     MyFirebase.storeObject.collection(kSetupCollection).doc(widget.setup.id).update({
//       '$kFieldPlaying.${thisGame.playerId}': FieldValue.delete(),
//     });
//   }

  List<Widget> followers = [Text('(none)', style: kConversationResultsResultsStyle)];

  Map<String, dynamic> setupEventData;

  void getSetupStream() async {
    setupListener = thisSetupStream.listen((event) {
      print('getSetupStream() event in PlayScreen()');
      if (event != null) {
        Map<String, dynamic> newSetupEventData = event.data();

        if (newSetupEventData != null) {
          bool newFollowerExists = newSetupEventData.containsKey(kFieldPlaying) &&
              newSetupEventData[kFieldPlaying].containsKey(thisGame.playerId) &&
              newSetupEventData[kFieldPlaying][thisGame.playerId].containsKey(kSubFieldFollowing);
          bool oldFollowerExists = setupEventData.containsKey(kFieldPlaying) &&
              setupEventData[kFieldPlaying].containsKey(thisGame.playerId) &&
              setupEventData[kFieldPlaying][thisGame.playerId].containsKey(kSubFieldFollowing);

          List<dynamic> newFollowers = newFollowerExists ? newSetupEventData[kFieldPlaying][thisGame.playerId][kSubFieldFollowing] : [];
          List<dynamic> oldFollowers = oldFollowerExists ? setupEventData[kFieldPlaying][thisGame.playerId][kSubFieldFollowing] : [];
          // Map<String, dynamic> newFollowers = newFollowerExists ? newSetupEventData[kFieldPlaying][thisGame.playerId][kSubFieldFollowing] : {};
          // Map<String, dynamic> oldFollowers = oldFollowerExists ? setupEventData[kFieldPlaying][thisGame.playerId][kSubFieldFollowing] : {};

          // If either the new setupData or the old setupData contained a 'Following' tag,
          // and something is different between them, set State:
          if (((newFollowerExists) || (oldFollowerExists)) && (!ListEquality().equals(newFollowers, oldFollowers))) {
            // if (((newFollowerExists) || (oldFollowerExists)) && (!MapEquality().equals(newFollowers, oldFollowers))) {
            print('A change in followers detected in ${this.widget}');
            setState(() {
              setupEventData = newSetupEventData;
            });
          } else {
            // Otherwise, just update setupEventData:
            print('No change in followers in ${this.widget}');
            setupEventData = newSetupEventData;
          }
        }
      }
    });
  }

  Widget getFollowers() {
  // List<Widget> getFollowers() {
    Widget _followers;
    // List<Widget> _followers = [];
    _followers =
      PingWidget(
        pingStream: MyFirebase.storeObject.collection(kCollectionSetups).doc(setup.id).collection(kSubCollectionWatchingPings).doc(myUid).snapshots(),
        // pingStream: MyFirebase.storeObject.collection(kCollectionSetups).doc(setup.id).collection(kSubCollectionPlayingPings).doc(kSubCollectionPlayingPings).snapshots(),
        createChild: createChild,
      );
    // _followers = [
    //   PingWidget(
    //     pingStream: MyFirebase.storeObject.collection(kCollectionSetups).doc(setup.id).collection(kSubCollectionWatchingPings).doc(myUid).snapshots(),
    //     // pingStream: MyFirebase.storeObject.collection(kCollectionSetups).doc(setup.id).collection(kSubCollectionPlayingPings).doc(kSubCollectionPlayingPings).snapshots(),
    //     createChildren: createChildren,
    //   ),
    // ];

    return _followers;
  }

  Widget  createChild(activeMap) {
  // List<Widget>  createChildren(activeMap) {
    print('Running createChildren() in ${this.widget}');
    List<Widget> _children = [];

    for (String follower in activeMap.keys) {
      if (activeMap[follower]) _children.add(Text('${gameHubProvider.getScreenName(follower)}', style: kConversationResultsResultsStyle));
    }
    if (_children.length == 0) _children = [Text('(none)', style: kConversationResultsResultsStyle)];

    return Column(
      children: _children,
    );
  }

  // List<Widget> getFollowers() {
  //   List<Widget> _followers = [];
  //   // followers = [];
  //
  //   if (setupEventData != null &&
  //       setupEventData.containsKey(kFieldPlaying) &&
  //       setupEventData[kFieldPlaying].containsKey(thisGame.playerId) &&
  //       setupEventData[kFieldPlaying][thisGame.playerId].containsKey(kSubFieldFollowing)) {
  //     // print('follower exists');
  //
  //     for (String follower in setupEventData[kFieldPlaying][thisGame.playerId][kSubFieldFollowing]) {
  //       _followers.add(Text('${gameHubProvider.getScreenName(follower)}', style: kConversationResultsResultsStyle));
  //       // No longer gives listen error, as it did when it was inside the setupStream:
  //       // _followers.add(Text('${Provider.of<GameHubUpdates>(context).getScreenName(follower)}', style: kConversationResultsResultsStyle));
  //     }
  //     // print('New _followers is $_followers');
  //   }
  //   if (_followers.length == 0) _followers = [Text('(none)', style: kConversationResultsResultsStyle)];
  //   return _followers;
  // }

  bool showSpinner = false;

  @override
  Widget build(BuildContext context) {
    print('Building ${this.widget}');
    gameHubProvider = Provider.of<GameHubUpdates>(context, listen: true);
    // getSetupStream();  // This doesn't give an error.... but it really should,
    // coz getSetupStream() sets state!...
    return Scaffold(
      appBar: AppBar(title: Text('blackbox'), actions: [PlayScreenMenu(thisGame, rebuildPlayScreen: rebuild)]),
      body: ModalProgressHUD(
        inAsyncCall: showSpinner,
        child: Center(
          child: Column(
            // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              thisGame.online
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        //Left info texts:
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Text('online')
                              InfoText('Setup no ${setupData['i']}'),
                              InfoText('By ${gameHubProvider.getScreenName(setupData[kFieldSender])}'),
                              // InfoText('By ${Provider.of<GameHubUpdates>(context).getScreenName(setupData[kFieldSender])}'),
                            ],
                          ),
                        ),
                        //Right info texts:
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            InfoText('Started: $startedString'),
                          ],
                        ),
                      ],
                    )
                  : SizedBox(),

              // thisGame.online ? Align(
              //   alignment: Alignment.centerLeft,
              //   child: Column(
              //     crossAxisAlignment: CrossAxisAlignment.start,
              //     children: [
              //       InfoText('Setup no ${setupData['i']}'),
              //       InfoText('By ${Provider.of<GameHubUpdates>(context).getScreenName(setupData[kFieldSender])}'),
              //     ],
              //   ),
              // ) : SizedBox(/*child: Text('xxxxxxxxxxx')*/),

              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: thisGame.online ? MainAxisAlignment.spaceEvenly : MainAxisAlignment.center,
                  children: [
                    thisGame.online
                        ? Column(
                      children: [
                        Text('Watching:', style: kConversationResultsResultsStyle),
                        ConstrainedBox(
                          // constraints: BoxConstraints(maxHeight: 150),
                          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height / 6),
                          child: SingleChildScrollView(
                            child:
                            // Column(
                            //         children:
                                    getFollowers(),
                                    // For some STUPID reason, the below does not update when
                                    // Provider.of<GameHubUpdates>(context, listen: true) updates...
                                    // Even though it contained the same:
                                    // children: followers,
                                    // Hence getFollowers(), because then it updates... *facepalm*
                                  // ),
                                ),
                        ),
                      ],
                    )
                        : SizedBox(),

                    // Score count:
                    GestureDetector(
                      child: Center(child: Text(thisGame.beamScore.toString(), style: TextStyle(fontSize: 30))),
                      onTap: () {
                        setState(() {});
                        print('State reset-------------------------------------------------------------');
                      },
                    ),
                  ],
                ),
              ),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Container(
                      alignment: Alignment.centerLeft,
                      // color: Colors.purple,
                      child: Padding(
                        padding: EdgeInsets.all(10),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Number of atoms:   ${thisGame.playerAtoms.length == 0 ? thisGame.atoms.length : '${thisGame.atoms.length - thisGame.playerAtoms.length} (${thisGame.atoms.length})'}',
                            textAlign: TextAlign.left,
                          ),
                        ),
                      ),
                    ),
                  ),
                  //Answer button:
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: RaisedButton(
                      child: Text('This is my\nfinal answer'),
                      onPressed: thisGame.playerAtoms.length != thisGame.atoms.length
                          ? null
                          : () async {
                              setState(() {
                                showSpinner = true;
                              });
                              // First element of alternativeSolutions will be the List 'edgeTileChildren' from fireAllBeams,
                              // the rest will be alternative games, like this :
                              // return [senderGame.edgeTileChildren, senderGame, /*playerGame,*/ altGame];
                              List<dynamic> alternativeSolutions = await finalAnswerPress(
                                  thisGame: thisGame, setupID: setupID, setupData: setupData, answered: answered, startedPlaying: startedPlaying);
                              answered = true;

                              print('+++++++++++++++++++++++++++++++++++++++++++++++++++++\n'
                                  'Coming back from finalAnswerPress():\n'
                                  'thisGame.correctAtoms is ${thisGame.correctAtoms}\n'
                                  'setupData is $setupData\n'
                                  'setupID is $setupID');
                              bool altSol = alternativeSolutions != null ? true : false;
                              setState(() {
                                showSpinner = false;
                              });

                              if (thisGame.online) {
                                // await onlineButtonPress(thisGame, setupID, setupData, answered, startedPlaying); //The "await" here should guarantee that results are uploaded before the correct answer is given...
                                try {
                                  DocumentSnapshot newSetup = await MyFirebase.storeObject.collection(kCollectionSetups).doc(setupID).get();
                                  setupData = newSetup.data();
                                } catch (e) {
                                  print("Error trying to upload setup data after 'Final answer' press: $e");
                                }
                                print('setupData after upload in "Final answer" press is $setupData');
                              }

                              await Navigator.push(context, MaterialPageRoute(builder: (context) {
                                // return ResultsScreen(thisGame: thisGame, setupData: setupData, altSol: altSol, alternativeSolutions: altGame != null ? [altGame.atoms, playerGame.atoms] : null,); // setupData might be {} (if not online)
                                return ResultsScreen(
                                    thisGame: thisGame,
                                    setupData: setupData,
                                    altSol: altSol,
                                    alternativeSolutions: alternativeSolutions); // setupData might be {} (if not online)
                              }));

                              print('Called after ResultsScreen has been popped');
                              // This is now done in rawAtomScore():
                              thisGame.correctAtoms = [];
                              thisGame.misplacedAtoms = [];
                              thisGame.missedAtoms = [];
                              thisGame.atomScore = 0;
                            },
                    ),
                  )
                ],
              ),
              //Play board:
              Expanded(
                flex: 3,
                //Scaffold, Center, Column, Expanded, Padding, AspectRatio, Container, Board (returns Column)
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0, top: 8.0, right: 8.0, bottom: 10),
                  child: AspectRatio(
                    aspectRatio: (thisGame.widthOfPlayArea + 2) / (thisGame.heightOfPlayArea + 2),
                    child: Container(
                      child: PlayBoard(
                          playWidth: thisGame.widthOfPlayArea,
                          playHeight: thisGame.heightOfPlayArea,
                          thisGame: thisGame,
                          setup: widget.setup,
                          refreshParent: refresh),
                    ),
                  ),
                ),
              ),
//            Image(image: AssetImage('images/ball.png'))
            ],
          ),
        ),
      ),
    );
  }
}
