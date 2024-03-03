import 'package:blackbox/play_screen_menu.dart';
import 'package:blackbox/units/ping_widget.dart';
import 'package:blackbox/units/final_answer_press.dart';
import 'package:blackbox/units/fcm_send_msg.dart';
import 'package:wakelock/wakelock.dart';

// import 'package:blackbox/alternative_solutions_play.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:blackbox/game_hub_updates.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:provider/provider.dart';
import 'package:blackbox/units/small_widgets.dart';
import 'package:blackbox/my_firebase_labels.dart';
import 'dart:convert';
import 'package:blackbox/constants.dart';
import 'dart:async';
import 'package:blackbox/my_firebase.dart';
import 'package:blackbox/screens/results_screen.dart';

// import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../play_board.dart';
import '../play.dart';
import '../atom_n_beam.dart';

class PlayScreen extends StatefulWidget {
  PlayScreen(
      {required this.thisGame,
      this.setup,
      this.testBeams,
      this.sendNotification = true,
      this.rebuilding = false});

  final Play thisGame;
  final DocumentSnapshot? setup;
  final List<int>? testBeams;
  final bool sendNotification;
  final bool rebuilding; // To clear and fill with atoms and markup

  @override
  _PlayScreenState createState() => _PlayScreenState(
      thisGame, setup, testBeams, sendNotification, rebuilding);
}

class _PlayScreenState extends State<PlayScreen> {
  _PlayScreenState(this.thisGame, this.setup, this.testBeams,
      this.sendNotification, this.fromRebuild);

  final Play thisGame;
  final DocumentSnapshot? setup; // Only if online
  String? setupID; // Only if online
  final List<int>? testBeams;
  final bool sendNotification;
  final bool fromRebuild; // To clear and fill with atoms and markup
  bool toRebuild = false;
  late GameHubUpdates gameHubProvider;
  String? myUid; // Only if online
  Map<String, dynamic>? setupData = {}; // Only if online
  Future<Timestamp?>? startedPlaying; // Only if online
  Stream<DocumentSnapshot>? thisSetupStream; // Only if online
  StreamSubscription? setupListener; // Only if online
  String startedString = 'N/A'; // Only if online
  bool answered = false;

  @override
  void initState() {
    print('PlayScreen() initState playerId is ${thisGame.playerUid}');
    Wakelock
        .enable(); // Prevents phone from sleeping for as long as this screen is open

    if (MyFirebase.authObject.currentUser != null) {
      // I'm logged in
      myUid = MyFirebase.authObject.currentUser!.uid;
      thisGame.playerUid = myUid;
    }
    print(
        'PlayScreen() initState playerId a bit later is ${thisGame.playerUid}');

    if (thisGame.online) {
      updateFollowersStream();
      // If game is online, it's assumed to have a setup:
      setupData = setup!.data() as Map<String, dynamic>?;
      setupID = setup!.id;
      thisSetupStream = MyFirebase.storeObject
          .collection('setups')
          .doc(setup!.id)
          .snapshots();

      if (!fromRebuild) {
        // Todo: Insert values from step-by-step game review here:
        // Get values from setup:
        if (setupData != null &&
            setupData!.containsKey(kFieldShuffleA) &&
            setupData!.containsKey(kFieldShuffleB)) {
          thisGame.beamImageIndexA = [];
          for (int i = 0; i < setupData![kFieldShuffleA].length; i++) {
            thisGame.beamImageIndexA!.add(setupData![kFieldShuffleA][i]);
          }

          thisGame.beamImageIndexB = [];
          for (int i = 0; i < setupData![kFieldShuffleB].length; i++) {
            thisGame.beamImageIndexB!.add(setupData![kFieldShuffleB][i]);
          }
        }

        List<Atom> receivedAtoms = [];
        for (int i = 0; i < setupData!['atoms'].length; i += 2) {
          receivedAtoms
              .add(Atom(setupData!['atoms'][i], setupData!['atoms'][i + 1]));
        }
        thisGame.atoms = receivedAtoms;

        //If I'm already playing this game:
        if (setupData!.containsKey(kFieldPlaying) &&
            setupData![kFieldPlaying].containsKey(thisGame.playerUid)) {
          ping();

          // If I already have saved PlayerMoves:
          // TODO: $$$ What if I started a game without PlayerMoves, and continue with PlayerMoves...?
          if (setupData![kFieldPlaying][thisGame.playerUid].containsKey(kFieldPlayerMoves)) {
            thisGame.playerMoves = setupData![kFieldPlaying][thisGame.playerUid][kFieldPlayerMoves];
          }

          // Get the started playing string and future from setup:
          startedPlaying = Future(() => setupData![kFieldPlaying]
                  [thisGame.playerUid]
              [kSubFieldStartedPlaying]); // If it's null it's null.
          // if (startedPlaying != null) {  // Not good because Future...
          if (setupData![kFieldPlaying][thisGame.playerUid]
                  [kSubFieldStartedPlaying] !=
              null) {
            startedString = DateFormat('d MMM, HH:mm:ss').format(
                // startedPlaying!.toDate());
                setupData![kFieldPlaying][thisGame.playerUid]
                        [kSubFieldStartedPlaying]
                    .toDate());
          }

          // If game already has markUp:
          if (setupData![kFieldPlaying][thisGame.playerUid]
              .containsKey(kSubFieldMarkUpList)) {
            List<dynamic> sentClearList = setupData![kFieldPlaying]
                [thisGame.playerUid][kSubFieldMarkUpList];
            for (int i = 0; i < sentClearList.length; i += 2) {
              thisGame.markUpList.add([sentClearList[i], sentClearList[i + 1]]);
            }
          }

          // Get playingAtoms:
          List<Atom> receivedPlayingAtoms = [];
          List<dynamic> playingAtoms = setupData![kFieldPlaying]
                  [thisGame.playerUid][kSubFieldPlayingAtoms] ??
              [];
          for (int i = 0; i < playingAtoms.length; i += 2) {
            receivedPlayingAtoms
                .add(Atom(playingAtoms[i], playingAtoms[i + 1]));
          }
          thisGame.playerAtoms = receivedPlayingAtoms;
          // print('receivedPlayingAtoms are $receivedPlayingAtoms');

          // Get playingBeams:
          List<dynamic> playingBeams = setupData![kFieldPlaying]
                  [thisGame.playerUid][kSubFieldPlayingBeams] ??
              [];
          for (int receivedBeamNo in playingBeams) {
            // print("receivedBeamNo is $receivedBeamNo");
            thisGame.sendBeam(inSlot: receivedBeamNo);
            // dynamic result = thisGame.sendBeam(inSlot: receivedBeamNo);
            // thisGame.setEdgeTiles(inSlot: receivedBeamNo, beamResult: result);
          }
          if (sendNotification)
            sendPushNotifications(kTopicResumedPlayingSetup);
        } else {
          //I'm not already playing:
          // print('Creating empty "player" Map for ${thisGame.playerId}');
          setupData!.putIfAbsent('playing', () => {});
          setupData!['playing'].putIfAbsent(
              '${thisGame.playerUid}',
              () => {
                    'playingAtoms': [],
                    'playingBeams': [],
                    '$kSubFieldStartedPlaying': FieldValue.serverTimestamp(),
                  });
          // print('setupData in PlayScreen initState() is $setupData');
          if (sendNotification) sendPushNotifications(kTopicPlayingSetup);

          Future<void> uploadDoc = MyFirebase.storeObject
              .collection('setups')
              .doc(widget.setup!.id)
              .set({'playing': setupData!['playing']}, SetOptions(merge: true));
          startedPlaying = getStartedPlaying(uploadDoc);
          ping(uploadDoc: uploadDoc);
        }
      } else {
        // If from rebuild (clear all atoms etc), thisGame already has its values. Much less needed:
        ping();
        getStartedPlaying(Future(() => null));
      }
    }
    // print('Atoms are in positions:');
    // for (Atom atom in thisGame.atoms) {
    //   print(atom.position.toList());
    // }
    // print('**************************');
    super.initState();
  }

  @override
  void dispose() async {
    super.dispose();
    Wakelock.disable();

    if (thisGame.online) {
      if (setupListener != null) setupListener!.cancel();

      // If the screen is rebuilt because of clearing all atoms or similar, none of the
      // below needs to be done:
      if (!toRebuild) {
        // Get the end data:
        DocumentSnapshot? snapshot;
        Map<String, dynamic>? endSetupData;
        try {
          snapshot = await MyFirebase.storeObject
              .collection('setups')
              .doc(widget.setup!.id)
              .get();
          endSetupData = snapshot.data() as Map<String, dynamic>;
        } catch (e) {
          print('Error in ${this.runtimeType}.dispose(): $e');
        }

        if (endSetupData != null) {
          //If the player leaves without having played, remove their 'playing' key, if it still exists:
          if (endSetupData.containsKey('playing') &&
              endSetupData['playing'].containsKey(thisGame.playerUid) &&
              endSetupData['playing'][thisGame.playerUid]
                  .containsKey('playingAtoms') &&
              endSetupData['playing'][thisGame.playerUid]
                  .containsKey(kSubFieldPlayingBeams) &&
              ListEquality().equals(
                  endSetupData['playing'][thisGame.playerUid]['playingAtoms'],
                  []) &&
              ListEquality().equals(
                  endSetupData['playing'][thisGame.playerUid]['playingBeams'],
                  [])) {
            // print("endSetupData in dispose() is $endSetupData\n***************************");

            MyFirebase.storeObject
                .collection(kCollectionSetups)
                .doc(widget.setup!.id)
                .update({
              '$kFieldPlaying.${thisGame.playerUid}': FieldValue.delete(),
            });
            //If I want to check the effect of the above:
            //      DocumentSnapshot x =  await MyFirebase.storeObject.collection('setups').doc(widget.setup.id).get();
            //      Map<String, dynamic> afterUploadSetupData = x.data();
            //      print("afterUploadSetupData is $afterUploadSetupData");

            // And delete ping document in subCollection
            MyFirebase.storeObject
                .collection(kCollectionSetups)
                .doc(widget.setup!.id)
                .collection(kSubCollectionPlayingPings)
                .doc(kSubCollectionPlayingPings)
                .update({
              '${thisGame.playerUid}': FieldValue.delete(),
            });
            // MyFirebase.storeObject.collection(kCollectionSetups).doc(widget.setup.id).collection(kSubCollectionPlayingPings).doc(thisGame.playerId).delete();

            //TODO: (Can the below be put in sendPushNotification() though?)
            // This could be used to "unsend" a Playing-notification, if it is collapsible:
            String jsonString = jsonEncode({
              "data": {
                "event": "$kMsgEventStoppedPlaying",
                kMsgPlaying: "$myUid",
                "$kMsgSetupSender": "${setup![kFieldSender]}",
                "i": "${setupData!['i']}",
                kMsgSetupID: "$setupID",
                // "collapse_key": myUid + "_playing_" + setupData['i'].toString(),
              },
              // TODO: ---Change topic from Developer or my token:
              // "token": "${await myGlobalToken}", // For testing
              // "topic": kTopicDeveloper, // For testing
              "topic": kTopicPlayingSetup,
            });
            // print("jsonString is $jsonString");

            if (sendNotification) fcmSendMsg(jsonString);
            // Future<http.Response> sendMsgRes = fcmSendMsg(jsonString);
            // handleMsgResponse(sendMsgRes: sendMsgRes, token: token, uid: uid)
          }

          // Remove any corrupted, half-deleted "playing" fields:
          if (endSetupData.containsKey(kFieldPlaying)) {
            for (String playingId in endSetupData['playing'].keys) {
              if (endSetupData[kFieldPlaying][playingId]
                          [kSubFieldPlayingDone] ==
                      true ||
                  !(endSetupData[kFieldPlaying][playingId]
                          .containsKey(kSubFieldPlayingAtoms) &&
                      endSetupData[kFieldPlaying][playingId]
                          .containsKey(kSubFieldPlayingBeams))) {
                // print("endSetupData in dispose() is $endSetupData\n***************************");
                MyFirebase.storeObject
                    .collection(kCollectionSetups)
                    .doc(widget.setup!.id)
                    .update({
                  '$kFieldPlaying.$playingId': FieldValue.delete(),
                });
                // And delete ping document in subCollection
                MyFirebase.storeObject
                    .collection(kCollectionSetups)
                    .doc(widget.setup!.id)
                    .collection(kSubCollectionPlayingPings)
                    .doc(playingId)
                    .delete();
                //If I want to check the effect of the above:
                //      DocumentSnapshot x =  await MyFirebase.storeObject.collection('setups').doc(widget.setup.id).get();
                //      Map<String, dynamic> afterUploadSetupData = x.data();
                //      print("afterUploadSetupData is $afterUploadSetupData");
              }
            }

            // If I was the last person playing, delete the whole playing entry:
            if (endSetupData[kFieldPlaying].isEmpty) {
              // print('Deleting "playing" field.');
              MyFirebase.storeObject
                  .collection(kCollectionSetups)
                  .doc(widget.setup!.id)
                  .update({
                '$kFieldPlaying': FieldValue.delete(),
              });
              // And delete ping document in subCollection
              MyFirebase.storeObject
                  .collection(kCollectionSetups)
                  .doc(widget.setup!.id)
                  .collection(kSubCollectionPlayingPings)
                  .doc(thisGame.playerUid)
                  .delete();
            }
          }
        }
      }
    }
  }

  void ping({Future<void>? uploadDoc}) async {
    if (uploadDoc != null)
      await uploadDoc; // If I wasn't already playing this game, we need to wait until Playing tag has uploaded.
    // int i = 0;
    // TODO: ---Turn ping back on (if commented out):
    do {
      // print('Ping no $i');
      try {
        await MyFirebase.storeObject
            .collection(kCollectionSetups)
            .doc(setup!.id)
            .collection('PlayingPings')
            .doc('PlayingPings')
            .set({
          // await MyFirebase.storeObject.collection(kCollectionSetups).doc(setup.id).collection('PlayingPings').doc(myUid).set({
          '$myUid': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } on Exception catch (e) {
        print('Ping upload error: $e');
      }
      await Future.delayed(Duration(seconds: 4));
      // i++;
    } while (mounted);
  }

  Future<Timestamp?> getStartedPlaying(Future<void> uploadDoc) async {
    // Wait for the playing tag to upload. Then download it again to get the "StartedPlaying" timestamp.
    setState(() {
      showSpinner = true;
    });
    await uploadDoc;
    DocumentSnapshot doc;
    Timestamp? _startedPlaying;
    try {
      doc = await MyFirebase.storeObject
          .collection(kCollectionSetups)
          .doc(setup!.id)
          .get();
      Map<String, dynamic> docData = doc.data() as Map<String, dynamic>;
      _startedPlaying =
          docData[kFieldPlaying][thisGame.playerUid][kSubFieldStartedPlaying];
    } catch (e) {
      print('Error getting _startedPlaying: $e');
    }
    // print('_startedPlaying is $_startedPlaying in getStartedPlaying()');
    if (_startedPlaying != null) {
      setState(() {
        startedString =
            DateFormat('d MMM, HH:mm:ss').format(_startedPlaying!.toDate());
      });
    }

    setState(() {
      showSpinner = false;
    });
    return _startedPlaying;
  }

  void sendPushNotifications(String topic) async {
    String myUid = MyFirebase.authObject.currentUser!.uid;

    List<String> resultKeys = [];
    if (setupData!.containsKey(kFieldResults)) {
      for (String key in setupData![kFieldResults].keys) {
        resultKeys.add(key);
      }
    }
    print('resultKeys is $resultKeys');
    String jsonString = jsonEncode({
      "data": {
        "event":
            "${topic == kTopicPlayingSetup ? 'started_playing' : topic == kTopicResumedPlayingSetup ? 'resumed_playing' : ''}",
        "playing": "$myUid",
        "last_move":
            "${topic == kTopicResumedPlayingSetup ? '${setupData![kFieldPlaying][myUid][kSubFieldLastMove]}' : null}",
        "earlier_results": "$resultKeys",
        // "earlier_results": setupData[kFieldResults], // I was thinking I could send the score... to send notifications for very high or low score setups, but...
        kMsgSetupSender: "${setupData![kFieldSender]}",
        kMsgI: setupData!['i'].toString(),
        kMsgSetupID: "$setupID"
        // "collapse_key": myUid + "_playing_" + setupData['i'].toString(),
      },
      // "token": "${await myGlobalToken}", // For testing
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
    // print('thisGame.playerAtoms ${thisGame.playerAtoms}');

    toRebuild = true;
    // Navigator.pop(context);
    Navigator.pushReplacement(
        context,
        PageRouteBuilder(
            pageBuilder: (context, anim1, anim2) {
              return PlayScreen(
                thisGame: thisGame,
                setup: setup,
                testBeams: testBeams,
                sendNotification: false,
                rebuilding: true,
              );
            },
            transitionDuration: Duration(days: 0)));
  }

  List<Widget> followers = [
    Text('(none)', style: kConversationResultsResultsStyle)
  ];

  Map<String, dynamic>? setupEventData;

  void updateFollowersStream() async {
    if (thisSetupStream != null)
      setupListener = thisSetupStream!.listen((event) {
        print('getSetupStream() event in PlayScreen()');
        Map<String, dynamic>? newSetupEventData =
            event.data() as Map<String, dynamic>?;

        if (newSetupEventData != null) {
          // Check for change in followers:
          bool newFollowerExists =
              newSetupEventData.containsKey(kFieldPlaying) &&
                  newSetupEventData[kFieldPlaying]
                      .containsKey(thisGame.playerUid) &&
                  newSetupEventData[kFieldPlaying][thisGame.playerUid]
                      .containsKey(kSubFieldFollowing);
          bool oldFollowerExists = setupEventData != null &&
              setupEventData!.containsKey(kFieldPlaying) &&
              setupEventData![kFieldPlaying].containsKey(thisGame.playerUid) &&
              setupEventData![kFieldPlaying][thisGame.playerUid]
                  .containsKey(kSubFieldFollowing);

          List<dynamic>? newFollowers = newFollowerExists
              ? newSetupEventData[kFieldPlaying][thisGame.playerUid]
                  [kSubFieldFollowing]
              : [];
          List<dynamic>? oldFollowers = oldFollowerExists
              ? setupEventData![kFieldPlaying][thisGame.playerUid]
                  [kSubFieldFollowing]
              : [];
          // Map<String, dynamic> newFollowers = newFollowerExists ? newSetupEventData[kFieldPlaying][thisGame.playerId][kSubFieldFollowing] : {};
          // Map<String, dynamic> oldFollowers = oldFollowerExists ? setupEventData[kFieldPlaying][thisGame.playerId][kSubFieldFollowing] : {};

          // If either the new setupData or the old setupData contained a 'Following' tag,
          // and something is different between them, set State:
          if ((newFollowerExists || oldFollowerExists) &&
              !ListEquality().equals(newFollowers, oldFollowers)) {
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
      });
  }

  Widget getFollowers() {
    Widget _followers;
    _followers = PingWidget(
      pingStream: MyFirebase.storeObject
          .collection(kCollectionSetups)
          .doc(setup!.id)
          .collection(kSubCollectionWatchingPings)
          .doc(myUid)
          .snapshots(),
      createChild: createChild,
    );
    return _followers;
  }

  Widget createChild(activeMap) {
    // List<Widget>  createChildren(activeMap) {
    print('Running createChildren() in ${this.widget}');
    List<Widget> _children = [];

    for (String follower in activeMap.keys) {
      if (activeMap[follower])
        _children.add(Text('${gameHubProvider.getScreenName(follower)}',
            style: kConversationResultsResultsStyle));
    }
    if (_children.length == 0)
      _children = [Text('(none)', style: kConversationResultsResultsStyle)];

    return Column(
      children: _children,
    );
  }

  bool showSpinner = false;

  @override
  Widget build(BuildContext context) {
    print('Building ${this.widget}');
    gameHubProvider = Provider.of<GameHubUpdates>(context, listen: true);
    return Scaffold(
      appBar: AppBar(title: Text('blackbox'), actions: [
        PlayScreenMenu(thisGame, rebuildScreen: rebuild, setup: setup)
      ]),
      body: ModalProgressHUD(
        inAsyncCall: showSpinner,
        child: Center(
          child: Column(
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
                              InfoText('Setup no ${setupData!['i']}'),
                              InfoText(
                                  'By ${gameHubProvider.getScreenName(setupData![kFieldSender])}'),
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

              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: thisGame.online
                      ? MainAxisAlignment.spaceEvenly
                      : MainAxisAlignment.center,
                  children: [
                    thisGame.online
                        ? Column(
                            children: [
                              Text('Watching:',
                                  style: kConversationResultsResultsStyle),
                              ConstrainedBox(
                                // constraints: BoxConstraints(maxHeight: 150),
                                constraints: BoxConstraints(
                                    maxHeight:
                                        MediaQuery.of(context).size.height / 6),
                                child: SingleChildScrollView(
                                  child:
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
                      child: Center(
                          child: Text(thisGame.beamScore.toString(),
                              style: TextStyle(fontSize: 30))),
                      onTap: () {
                        setState(() {});
                        print(
                            'State reset-------------------------------------------------------------');
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
                    child: MyRaisedButton(
                      child: Text('This is my\nfinal answer', textAlign: TextAlign.center),
                      onPressed: thisGame.playerAtoms.length !=
                              thisGame.atoms.length
                          ? null
                          : () async {
                              setState(() {
                                showSpinner = true;
                              });
                              // TODO: $$$ If following moves review in Follow Playing, it has to pop when player finishes, as Playing tag will disappear.
                              thisGame.setPlayerMoves(finish: true);

                              // First element of alternativeSolutions will be the List 'edgeTileChildren' from fireAllBeams,
                              // the rest will be games, like this :
                              // return [senderGame.edgeTileChildren, senderGame, altGame];
                              // If no alternative solutions exist, alternativeSolutions is null.
                              List<dynamic>? alternativeSolutions =
                                  await finalAnswerPress(
                                      thisGame: thisGame,
                                      setupID: setupID,
                                      setupData: setupData,
                                      answered: answered,
                                      startedPlaying: startedPlaying);
                              answered = true;

                              print(
                                  '+++++++++++++++++++++++++++++++++++++++++++++++++++++\n'
                                  'Coming back from finalAnswerPress():\n'
                                  'thisGame.correctAtoms is ${thisGame.correctAtoms}\n'
                                  'setupData is $setupData\n'
                                  'setupID is $setupID');
                              bool altSol =
                                  alternativeSolutions != null ? true : false;
                              setState(() {
                                showSpinner = false;
                              });

                              if (thisGame.online) {
                                // Getting the updated setup data:
                                try {
                                  DocumentSnapshot newSetup = await MyFirebase
                                      .storeObject
                                      .collection(kCollectionSetups)
                                      .doc(setupID)
                                      .get();
                                  setupData =
                                      newSetup.data() as Map<String, dynamic>?;
                                } catch (e) {
                                  print(
                                      "Error trying to get new setup data after "
                                          "'Final answer' press: $e");
                                }
                                print(
                                    'setupData after update in "Final answer" press is $setupData');
                              }

                              await Navigator.push(context,
                                  MaterialPageRoute(builder: (context) {
                                // return ResultsScreen(thisGame: thisGame, setupData: setupData, altSol: altSol, alternativeSolutions: altGame != null ? [altGame.atoms, playerGame.atoms] : null,); // setupData might be {} (if not online)
                                return ResultsScreen(
                                    thisGame: thisGame,
                                    setupData: setupData!,
                                    altSol: altSol,
                                    alternativeSolutions:
                                        alternativeSolutions); // setupData might be {} (if not online)
                              }));

                              print(
                                  'Called after ResultsScreen has been popped');
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
                  padding: const EdgeInsets.only(
                      left: 8.0, top: 8.0, right: 8.0, bottom: 10),
                  child: AspectRatio(
                    aspectRatio: (thisGame.widthOfPlayArea + 2) /
                        (thisGame.heightOfPlayArea + 2),
                    child: Container(
                      child: PlayBoard(
                          playWidth: thisGame.widthOfPlayArea,
                          playHeight: thisGame.heightOfPlayArea,
                          thisGame: thisGame,
                          numberOfAtoms: thisGame.numberOfAtoms,
                          setup: widget.setup,
                          refreshParent: refresh),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
