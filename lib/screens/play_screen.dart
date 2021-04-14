import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:blackbox/game_hub_updates.dart';
import 'package:provider/provider.dart';
import 'package:blackbox/units/small_widgets.dart';
import 'package:blackbox/token.dart';
import 'package:blackbox/my_firebase_labels.dart';
import 'package:blackbox/local_notifications.dart';
import 'package:blackbox/my_firebase_labels.dart';
import 'package:blackbox/blackbox_popup.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:blackbox/constants.dart';
import 'package:blackbox/firestore_lables.dart';
import 'package:collection/collection.dart';
import 'dart:async';
import 'package:blackbox/my_firebase.dart';
import 'package:blackbox/screens/results_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  DocumentSnapshot setup;
  final List<int> testBeams;

//  auth.User loggedInUser;
  Map<String, dynamic> setupData = {};
  Future<Timestamp> startedPlaying;
  Stream<DocumentSnapshot> thisSetupStream;
  StreamSubscription followingListener;

  // Timestamp started;
  String startedString = 'N/A';

//  StreamSubscription<auth.User> userListener;
  bool answered = false;

  @override
  void initState() {
//    getCurrentUser();
    print('PlayScreen() initState playerId is ${thisGame.playerId}');
    if (thisGame.online) {
      setupData = setup.data();
      thisSetupStream = MyFirebase.storeObject.collection('setups').doc(setup.id).snapshots();
      getFollowingStream();
      List<Atom> receivedAtoms = [];
      for (int i = 0; i < setupData['atoms'].length; i += 2) {
        receivedAtoms.add(Atom(setupData['atoms'][i], setupData['atoms'][i + 1]));
      }
      thisGame.atoms = receivedAtoms;

      // started = setupData[kFieldResults][thisGame.playerId][kSubFieldStartedPlaying];
      //   if (started != null) {
      //     startedString = DateFormat('d MMM, HH:mm:ss').format(started.toDate());
      //   }

      //If I'm already playing this game:
      if (setupData.containsKey(kFieldPlaying) && setupData[kFieldPlaying].containsKey(thisGame.playerId)) {
        startedPlaying = Future(() => setupData[kFieldPlaying][thisGame.playerId][kSubFieldStartedPlaying]); // If it's null it's null.
        if (setupData[kFieldPlaying][thisGame.playerId][kSubFieldStartedPlaying] != null) {
          startedString = DateFormat('d MMM, HH:mm:ss').format(setupData[kFieldPlaying][thisGame.playerId][kSubFieldStartedPlaying].toDate());
        }
        List<List<int>> receivedPlayingAtoms = [];
        List<dynamic> playingAtoms = setupData[kFieldPlaying][thisGame.playerId][kPlayingAtoms] ?? [];
        for (int i = 0; i < playingAtoms.length; i += 2) {
          receivedPlayingAtoms.add([playingAtoms[i], playingAtoms[i + 1]]);
        }
//        thisGame.receivedPlayingAtoms = receivedPlayerAtoms;
        thisGame.playerAtoms = receivedPlayingAtoms;
        print('receivedPlayingAtoms are $receivedPlayingAtoms');

        List<dynamic> playingBeams = setupData[kFieldPlaying][thisGame.playerId][kPlayingBeams] ?? [];
        // for (int receivedBeamNo in setupData[kPlayingField][thisGame.playerId][kPlayingBeams]) {
        for (int receivedBeamNo in playingBeams) {
          print("receivedBeamNo is $receivedBeamNo");
          dynamic result = thisGame.getBeamResult(inSlot: receivedBeamNo);
          // dynamic result = thisGame.getBeamResult(
          //   beam: Beam(start: receivedBeamNo, widthOfPlayArea: thisGame.widthOfPlayArea, heightOfPlayArea: thisGame.heightOfPlayArea),
          // );
          thisGame.setEdgeTiles(inSlot: receivedBeamNo, beamResult: result);
        }
        sendPushNotifications(kTopicResumedPlayingSetup);
      } else {
        //I'm not already playing:
        print('Creating empty "player" Map for ${thisGame.playerId}');
        // startedPlaying = FieldValue.serverTimestamp();
        // startedPlaying = startedPlaying.toDate();
        setupData.putIfAbsent('playing', () => {});
        setupData['playing'].putIfAbsent(
            '${thisGame.playerId}',
            () => {
                  'playingAtoms': [],
                  'playingBeams': [],
                  '$kSubFieldStartedPlaying': FieldValue.serverTimestamp(),
                });
        print('setupData in PlayScreen initState() is $setupData');
        sendPushNotifications(kTopicPlayingSetup);
        Future<void> uploadDoc =
            MyFirebase.storeObject.collection('setups').doc(widget.setup.id).set({'playing': setupData['playing']}, SetOptions(merge: true));
        startedPlaying = getStartedPlaying(uploadDoc);
      }

      print('Atoms are in positions:');
      for (Atom atom in thisGame.atoms) {
        print(atom.position.toList());
      }
      print('**************************');
    }
    super.initState();
  }

  Future<Timestamp> getStartedPlaying(Future<void> uploadDoc) async {
    // Wait for the playing tag to upload. Then download it again to get the "StartedPlaying" timestamp.
    await uploadDoc;
    DocumentSnapshot doc = await MyFirebase.storeObject.collection(kCollectionSetups).doc(widget.setup.id).get();
    Map<String, dynamic> docData = doc.data();
    Timestamp _startedPlaying = docData[kFieldPlaying][thisGame.playerId][kSubFieldStartedPlaying];
    // print('_startedPlaying is $_startedPlaying in getStartedPlaying()');
    if (_startedPlaying != null) {
      setState(() {
        startedString = DateFormat('d MMM, HH:mm:ss').format(_startedPlaying.toDate());
      });
    }
    return _startedPlaying;
  }

  @override
  void dispose() async {
    super.dispose();
//    userListener.cancel();
    if (thisGame.online) {
      followingListener.cancel();
      DocumentSnapshot snapshot = await MyFirebase.storeObject.collection('setups').doc(widget.setup.id).get();
      Map<String, dynamic> endSetupData = snapshot.data();

      //If the player leaves without having played, or if they're done, remove their 'playing' key:
      if (ListEquality().equals(endSetupData['playing'][thisGame.playerId]['playingAtoms'], []) &&
          ListEquality().equals(endSetupData['playing'][thisGame.playerId]['playingBeams'], [])) {
        print("endSetupData in dispose() is $endSetupData\n***************************");
        MyFirebase.storeObject.collection(kSetupCollection).doc(widget.setup.id).update({
          '$kFieldPlaying.${thisGame.playerId}': FieldValue.delete(),
        });
        //If I want to check the effect of the above:
//      DocumentSnapshot x =  await MyFirebase.storeObject.collection('setups').doc(widget.setup.id).get();
//      Map<String, dynamic> afterUploadSetupData = x.data();
//      print("afterUploadSetupData is $afterUploadSetupData");
      }
      // Remove any corrupted, half-deleted "playing" fields:
      if (endSetupData.containsKey(kFieldPlaying)) {
        for (String playingId in endSetupData['playing'].keys) {
          if (endSetupData[kFieldPlaying][playingId][kPlayingDone] == true ||
              !(endSetupData[kFieldPlaying][playingId].containsKey(kSubFieldPlayingAtoms) && endSetupData[kFieldPlaying][playingId].containsKey(kSubFieldPlayingBeams))) {
            print("endSetupData in dispose() is $endSetupData\n***************************");
            MyFirebase.storeObject.collection(kSetupCollection).doc(widget.setup.id).update({
              '$kFieldPlaying.$playingId': FieldValue.delete(),
            });
            //If I want to check the effect of the above:
            //      DocumentSnapshot x =  await MyFirebase.storeObject.collection('setups').doc(widget.setup.id).get();
            //      Map<String, dynamic> afterUploadSetupData = x.data();
            //      print("afterUploadSetupData is $afterUploadSetupData");
          }
        }
        if (endSetupData[kFieldPlaying].isEmpty) {
          //TODO: This doesn't seem to be working
          print('Deleting "playing" field.');
          MyFirebase.storeObject.collection(kSetupCollection).doc(widget.setup.id).update({
            '$kFieldPlaying': FieldValue.delete(),
          });
        }
      }
    }
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

  //TODO: Do this but from Firestore triggered Cloud Function!:

  void sendPushNotifications(String topic) async {
    http.Response res;
    String desc = '';
    String code = '';
    String jsonBody = jsonEncode({
      "notification": {
        "title": "Someone is playing!",
        "body": "Someone ${topic == kTopicPlayingSetup ? 'is playing': topic == kTopicResumedPlayingSetup ? 'resumed playing a setup': ''} now in the game hub",
      },
      "data": {
        "click_action": "FLUTTER_NOTIFICATION_CLICK",
        "playing": "${MyFirebase.authObject.currentUser.uid}",
        "setupSender": "${setup[kFieldSender]}",
      },
      "token": "${await myGlobalToken}",
      // "topic": topic,
    });
    print("jsonString is $jsonBody");
    Map<String, String> headers = {
      "content-type": "application/json"
    };
    try {
      res = await http.post(
        'https://us-central1-blackbox-6b836.cloudfunctions.net/sendMsg',
        headers: headers,
        body: jsonBody,
      );
    } catch (e) {
      print('Caught an error in sendMsg to topic $topic API call!');
      print('e is: ${e.toString()}');
// errorMsg = e.toString();
      BlackboxPopup(context: context, title: 'Error', desc: '$e').show();
      if (res != null) print('Status code in apiCall() catch is ${res.statusCode}');
    }
    if (res != null) {
      print('sendMsg to topic $topic API call response body: ${res.body}');
      print('sendMsg to topic $topic API call response code: ${res.statusCode}');
      desc = res.body;
      code = res.statusCode.toString();
    } else {
      print('sendMsg to topic $topic API call response is $res');
    }
// BlackboxPopup(context: context, title: 'Response $code', desc: '$desc').show();
    print('code is $code and desc is $desc in sendPushNotification');
  }

  void refresh() {
    setState(() {});
  }

  Future<void> onlineButtonPress() async {
//    print('setupData in OnlineButtonPress() is $setupData');

    //If I don't already have an uploaded result and I didn't already just click Final Answer:
    if (!answered && !(setupData.containsKey(kFieldResults) && setupData[kFieldResults].containsKey('${thisGame.playerId}'))) {
      answered = true;
      thisGame.getAtomScore();

      //Because Firebase can't stomach a List<List<int>>:
      //Put player atoms in array to send:
      List<int> sendPlayerAtoms = [];
      for (List<int> pAtom in thisGame.playerAtoms) {
        sendPlayerAtoms.add(pAtom[0]);
        sendPlayerAtoms.add(pAtom[1]);
      }

      //It should wait so that results are uploaded before 'done' is turned true:
      //Will create the player ID key in 'result' if it's not there (which it isn't).
      await MyFirebase.storeObject.collection(kSetupCollection).doc(widget.setup.id).update({
        '$kFieldResults.${thisGame.playerId}': {
          'A': thisGame.atomScore,
          'B': thisGame.beamScore,
          'sentBeams': thisGame.sentBeams,
          'playerAtoms': sendPlayerAtoms,
          '$kSubFieldStartedPlaying': await startedPlaying, // Might be null (if player started playing before installing this version).
          '$kSubFieldFinishedPlaying': FieldValue.serverTimestamp(),
        }
      });

      thisGame.correctAtoms = [];
      thisGame.misplacedAtoms = [];
      thisGame.missedAtoms = [];
      thisGame.atomScore = 0;
    }

    print('About to update done to true');
    //This will navigate any listener to this game to the ResultsScreen(), and must await to avoid deleting and writing at the same time:
    await MyFirebase.storeObject.collection(kSetupCollection).doc(widget.setup.id).update({
      '$kFieldPlaying.${thisGame.playerId}.$kPlayingDone': true,
    });

    MyFirebase.storeObject.collection(kSetupCollection).doc(widget.setup.id).update({
      '$kFieldPlaying.${thisGame.playerId}': FieldValue.delete(),
    });
  }

  List<Widget> followers = [];

  void getFollowingStream() async {
//  StreamSubscription<auth.User> userListener;
    followingListener = thisSetupStream.listen((event) {
      Map<String, dynamic> eventData = event.data();
      print('In getFollowingStream, eventData is $eventData');
      print('kPlayingField is $kFieldPlaying');
      print('widget.playingId is ${thisGame.playerId}');
//      List<Widget> newFollowers = followers;
      if(eventData.containsKey(kFieldPlaying) && eventData[kFieldPlaying].containsKey(thisGame.playerId) && eventData[kFieldPlaying][thisGame.playerId].containsKey(kSubFieldFollowing)){
        print('follower exists');
        followers = [];
//        bool add = false;
//        for(String follower in eventData[kPlayingField][thisGame.playerId][kFollowingField]){
//          if(follower == )
//        }
//        List<Widget> newFollowers = eventData[kPlayingField][thisGame.playerId][kFollowingField];
//        followers = eventData[kPlayingField][thisGame.playerId][kFollowingField];
//        if(ListEquality().equals(followers, newFollowers)==false){
        setState(() {
          for (String follower in eventData[kFieldPlaying][thisGame.playerId][kSubFieldFollowing]) {
            followers.add(Text('$follower', style: kConversationResultsResultsStyle));
          }
          print('New followers is $followers');
        });
//        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('blackbox')),
      body: Center(
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
                            InfoText('By ${Provider.of<GameHubUpdates>(context).getScreenName(setupData[kFieldSender])}'),
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
                                child: Column(
                                  children: followers,
                                ),
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
            //Answer button:
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.all(10),
                  child: Text(
                      'Number of atoms:   ${thisGame.playerAtoms.length == 0 ? thisGame.atoms.length : '${thisGame.atoms.length - thisGame.playerAtoms.length} (${thisGame.atoms.length})'}'),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: RaisedButton(
                    child: Text('This is my\nfinal answer'),
                    onPressed: thisGame.playerAtoms.length != thisGame.atoms.length
                        ? null
                        : () async {
                            if (thisGame.online) {
                              await onlineButtonPress(); //The "await" here should guarantee that results are uploaded before the correct answer is given...
                              DocumentSnapshot newSetup = await MyFirebase.storeObject.collection(kCollectionSetups).doc(setup.id).get();
                              setupData = newSetup.data();
                              // await Navigator.push(context, MaterialPageRoute(builder: (context) {
                              //   return ResultsScreen(thisGame: thisGame, setupData: setupData);
                              // }));
                            }
                            await Navigator.push(context, MaterialPageRoute(builder: (context) {
                              return ResultsScreen(thisGame: thisGame, setupData: setupData); // setupData might be {} (if not online)
                            }));

                            print('Called after ResultsScreen has been popped');
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
                padding: const EdgeInsets.only(left: 8.0, top: 8.0, right: 8.0, bottom: 20),
                child: AspectRatio(
                  aspectRatio: (thisGame.widthOfPlayArea + 2) / (thisGame.heightOfPlayArea + 2),
                  child: Container(
                    child:
                    PlayBoard(playWidth: thisGame.widthOfPlayArea,
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
    );
  }
}
