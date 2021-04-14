import 'package:intl/intl.dart';
import 'package:blackbox/my_firebase_labels.dart';
import 'package:blackbox/units/small_widgets.dart';
import 'package:blackbox/constants.dart';
import 'dart:async';
import 'package:blackbox/board_grid.dart';
import 'package:blackbox/firestore_lables.dart';
import 'package:blackbox/game_hub_updates.dart';
import 'package:blackbox/my_firebase.dart';
import 'package:blackbox/online_screens/sent_results_screen.dart';
// import 'package:blackbox/screens/play_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../play.dart';
import '../atom_n_beam.dart';

//import 'package:firebase_auth/firebase_auth.dart' as auth;
//import 'package:provider/provider.dart';
//import 'package:blackbox/game_hub_updates.dart';

class FollowPlayingScreen extends StatefulWidget {
  FollowPlayingScreen({
    @required this.setup,
    @required this.playingId,
    @required this.me,
    /*@required this.thisGame*/
  });

//  final Play thisGame;
  final DocumentSnapshot setup;
  final String playingId;
  final String me;

  @override
  _FollowPlayingScreenState createState() => _FollowPlayingScreenState(setup, playingId);
}

class _FollowPlayingScreenState extends State<FollowPlayingScreen> {
//  final Play thisGame;
//  auth.User loggedInUser;
//  _FollowPlayingScreenState(this.thisGame);
  _FollowPlayingScreenState(this.setup, this.playingId);

  final DocumentSnapshot setup;
  final String playingId;
  Play thisGame;
  Map<String, dynamic> setupData = {};
  Stream<DocumentSnapshot> thisSetupStream;
  Timestamp started;
  Timestamp latestMove;
  String startedString = 'N/A';
  String latestMoveString = 'N/A';

//  StreamSubscription<auth.User> userListener;
  StreamSubscription playingListener;

//  StreamSubscription followingListener;

//  gameData in SentResultsScreen is {sender: 27uvauvLrQiVco8hVNLS, widthAndHeight: [8, 8], results: {Felix: {A: 5, B: 22,
//  sentBeams: [21, 18, 28, 3, 12, 6, 27, 5, 8, 25, 23, 30, 29], playerAtoms: [6, 6, 2, 2, 2, 5, 3, 6, 2, 4]},
//  Karolina: {A: 0, B: 14, sentBeams: [16, 13, 10, 9, 28, 29, 12, 32, 26], playerAtoms: [6, 6, 2, 2, 2, 5, 1, 2, 3, 6]}},
//  atoms: [6, 6, 3, 6, 2, 5, 2, 2, 1, 2], timestamp: Timestamp(seconds=1601403677, nanoseconds=830000000)}

//  gameData.keys in SentResultsScreen is (sender, widthAndHeight, results, atoms, timestamp)

  @override
  void initState() {
//    getCurrentUser();
    setupData = setup.data();
    print('setupData in FollowPlayingScreen is $setupData');
    print('setupData.keys in FollowPlayingScreen are ${setupData.keys}');
    started = setupData[kFieldPlaying][playingId][kSubFieldStartedPlaying];
    latestMove = setupData[kFieldPlaying][playingId][kSubFieldLatestMove];
    if (started != null) {
      startedString = DateFormat('d MMM, HH:mm:ss').format(started.toDate());
      if (latestMove != null) latestMoveString = DateFormat('d MMM, HH:mm:ss').format(latestMove.toDate());
    }
    thisGame = Play(numberOfAtoms: 0, widthOfPlayArea: setupData['widthAndHeight'][0], heightOfPlayArea: setupData['widthAndHeight'][1]);
    thisGame.online = true;
    uploadFollowing();
    getAtoms();
    getAndPlacePlayerAtoms(setupData);
    List<dynamic> receivedBeams = setupData[kFieldPlaying][playingId][kPlayingBeams] ?? [];
    for (int receivedBeamNo in receivedBeams) {
      sendBeam(receivedBeamNo);
    }
    thisSetupStream = MyFirebase.storeObject.collection('setups').doc(setup.id).snapshots();
    getPlayingStream();
    print('In initState: thisGame.atoms: ${thisGame.atoms}, thisGame.sentBeams: ${thisGame.sentBeams}');
//    print('Atoms are in positions:');
//    for (Atom atom in thisGame.atoms) {
//      print(atom.position.toList());
//    }
//    print('**************************');
    super.initState();
  }

  @override
  void dispose() {
//    userListener.cancel();
    playingListener.cancel();
    removeFollowing();
    super.dispose();
  }

  void uploadFollowing() async {
    List<dynamic> followers = [];
    print('setupData in uploadFollowing() is $setupData');
    print('thisGame.playerId in uploadFollowing() is ${thisGame.playerId}');
    if(setupData[kFieldPlaying][widget.playingId].containsKey(kSubFieldFollowing)){
      followers = setupData[kFieldPlaying][widget.playingId][kSubFieldFollowing];
      print('followers List is $followers');
    }
    String myName = widget.me;
    if(myName== 'Me') myName = 'Anonymous';
    followers.add(myName);
    MyFirebase.storeObject.collection(kSetupCollection).doc(widget.setup.id).update({
      '$kFieldPlaying.$playingId.$kSubFieldFollowing': followers
    });  }

  void removeFollowing() async {
    String myName = widget.me;
    if(myName== 'Me') myName = 'Anonymous';
    List<dynamic> followers = [];
    print('setupData in removeFollowing() is $setupData');
    if(setupData[kFieldPlaying][widget.playingId].containsKey(kSubFieldFollowing)){
      followers = setupData[kFieldPlaying][widget.playingId][kSubFieldFollowing];
      print('followers List is $followers');
    }
    followers.remove(myName);
    print('followers after remove(myName) is $followers');
    MyFirebase.storeObject.collection(kSetupCollection).doc(widget.setup.id).update({
      '$kFieldPlaying.$playingId.$kSubFieldFollowing': followers,
    });
  }

  void getAtoms() {
    List<Atom> receivedAtoms = [];
    for (int i = 0; i < setupData['atoms'].length; i += 2) {
      receivedAtoms.add(Atom(setupData['atoms'][i], setupData['atoms'][i + 1]));
    }
    thisGame.atoms = receivedAtoms;
  }

  void getAndPlacePlayerAtoms(Map<String, dynamic> setupData) {
    List<List<int>> receivedPlayerAtoms = [];
    if (setupData[kFieldPlaying].containsKey(playingId) && setupData[kFieldPlaying][playingId][kPlayingAtoms] != null) {
      for (int i = 0; i < setupData[kFieldPlaying][playingId][kPlayingAtoms].length; i += 2) {
        receivedPlayerAtoms
            .add([setupData[kFieldPlaying][playingId][kPlayingAtoms][i], setupData[kFieldPlaying][playingId][kPlayingAtoms][i + 1]]);
      }
    }
    thisGame.playerAtoms = receivedPlayerAtoms;
  }

  void sendBeam(int receivedBeamNo) {
    print("receivedBeamNo is $receivedBeamNo");
    dynamic result = thisGame.getBeamResult(inSlot: receivedBeamNo);
    // dynamic result = thisGame.getBeamResult(
    //   beam: Beam(start: receivedBeamNo, widthOfPlayArea: thisGame.widthOfPlayArea, heightOfPlayArea: thisGame.heightOfPlayArea),
    // );
    thisGame.setEdgeTiles(inSlot: receivedBeamNo, beamResult: result);
  }

  void getPlayingStream() {
    int showedResults = 0;
    playingListener = thisSetupStream.listen((event) {
      Map<String, dynamic> eventData;
      if (event != null) eventData = event.data();
      print('FollowingPlayingScreen listener event data: $eventData');

      //Beams:
      List<dynamic> receivedBeams = eventData[kFieldPlaying][playingId][kPlayingBeams];
      //I'm only interested in the last beam:
      int receivedBeamNo;
      if (receivedBeams != null && receivedBeams.length > 0) receivedBeamNo = receivedBeams[receivedBeams.length - 1];
      print("receivedBeamNo is $receivedBeamNo");
      if (receivedBeamNo != null && thisGame.edgeTileChildren[receivedBeamNo - 1] == null) {
        //A beam has been received and this tile does not already have a child so it's a new one
        setState(() {
          sendBeam(receivedBeamNo);
          latestMove = eventData[kFieldPlaying][playingId][kSubFieldLatestMove];
          if (latestMove != null) latestMoveString = DateFormat('d MMM, HH:mm:ss').format(latestMove.toDate());
        });
      }

      //Atoms:
      setState(() {
        getAndPlacePlayerAtoms(eventData);
        latestMove = eventData[kFieldPlaying][playingId][kSubFieldLatestMove];
        if (latestMove != null) latestMoveString = DateFormat('d MMM, HH:mm:ss').format(latestMove.toDate());
      });

      //Done:
      if (eventData[kFieldPlaying][playingId][kPlayingDone] == true) {
        //If this 'done' field doesn't yet exist, surely you'll manage...?
        if (showedResults == 0) {
//          thisGame.getAtomScore();
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) {
            return SentResultsScreen(setupData: eventData, resultPlayerId: playingId);
          }));
          showedResults++;
        }
      }
    });
  }

//  void getCurrentUser() async {
//    userListener = MyFirebase.authObject.userChanges().listen((event) {
//      loggedInUser = MyFirebase.authObject.currentUser;
////      print("Play screen getCurrentUser() event.email is ${event.email}");  //This will crash if event is null...
//    });
//
//    print('Play screen printing loggedInUser $loggedInUser');  //Should be null before it's done
////    widget.thisGame.playerId = Provider.of<GameHubUpdates>(context, listen: false).myId;
//  }

  Widget getEdges({int x, int y}) {
    int slotNo = Beam.convert(coordinates: Position(x, y), heightOfPlayArea: thisGame.heightOfPlayArea, widthOfPlayArea: thisGame.widthOfPlayArea);
    return Expanded(
      child: Container(
        child: Center(
            child: thisGame.edgeTileChildren[slotNo - 1] ??
                FittedBox(fit: BoxFit.contain, child: Text('$slotNo', style: TextStyle(color: kBoardEdgeTextColor, fontSize: 15)))),
        decoration: BoxDecoration(color: kBoardEdgeColor),
      ),
    );
  }

  Widget getMiddleElements({int x, int y}) {
    bool sent = false;
    bool hidden = false;

    for (List<int> sentAtom in thisGame.playerAtoms) {
      if (ListEquality().equals([x, y], sentAtom)) {
        //Sent Atom
        sent = true;
//        print('Show atom is true');
      }
    }
    if (sent == false) {
      for (Atom hiddenAtom in thisGame.atoms) {
        if (ListEquality().equals([x, y], hiddenAtom.position.toList())) {
          //Hidden Atom
          hidden = true;
        }
      }
    }

    return Expanded(
      child: Container(
        child: Center(
          child: sent
              ? Image(image: AssetImage('images/atom_yellow.png'))
              : hidden
                  ? Opacity(child: Image(image: AssetImage('images/atom_blue.png')), opacity: 0.8)
                  : FittedBox(
                      fit: BoxFit.contain,
                      child: Text(
                        '$x,$y',
                        style: TextStyle(color: kBoardTextColor, fontSize: 15),
                      ),
                    ),
        ),
        decoration: BoxDecoration(color: kBoardColor, border: Border.all(color: kBoardGridlineColor, width: 0.5)),
      ),
    );
  }

//  Future<void> testPlayButtonPress() async {
//    await Navigator.push(context, MaterialPageRoute(builder: (context) {
//      Play sendGame =
//          Play(numberOfAtoms: thisGame.numberOfAtoms, widthOfPlayArea: thisGame.widthOfPlayArea, heightOfPlayArea: thisGame.heightOfPlayArea);
//      sendGame.online = true;
//
//      sendGame.playerAtoms = List.generate(thisGame.playerAtoms.length, (index) => List<int>(2));
//      for (int i = 0; i < thisGame.playerAtoms.length; i++) {
//        sendGame.playerAtoms[i] = thisGame.playerAtoms[i];
//      }
////      sendGame.playerAtoms = thisGame.playerAtoms;  //When I did this, the thisGame.playerAtoms magically updated itself when sendGame.playerAtoms got updated...!!! :-O
////      sendGame.playerAtoms.add([4,4]);
//      sendGame.playerId = playingId;
//      print("sendGame.playerAtoms is ${sendGame.playerAtoms} and thisGame.playerAtoms is ${thisGame.playerAtoms}");
//      return PlayScreen(thisGame: sendGame, setup: setup, testBeams: thisGame.sentBeams, playingId: playingId);
//    }));
//  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('blackbox')),
      body: Center(
        child: Column(
          // mainAxisAlignment: MainAxisAlignment.spaceBetween,
          // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Row(
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
                    InfoText('Last move: $latestMoveString'),
                    // InfoText('Finished: $finishedString'),
                    // InfoText('Time played: $timePlayedString'), //TODO: Sort this!! (Put the timestamps into variables first)
                  ],
                ),
              ],
            ),
            // Row(
            //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //   crossAxisAlignment: CrossAxisAlignment.start,
            //   children: [
            //     Column(
            //       mainAxisAlignment: MainAxisAlignment.start,
            //       crossAxisAlignment: CrossAxisAlignment.start,
            //       children: [
            //         InfoText('Setup no ${setup['i']}'),
            //         InfoText('By ${Provider.of<GameHubUpdates>(context).getScreenName(setup[kFieldSender])}'),
            //       ],
            //     ),
            //     Column(
            //       mainAxisAlignment: MainAxisAlignment.start,
            //       crossAxisAlignment: CrossAxisAlignment.end,
            //       children: [
            //         InfoText(
            //             'Started: ${setup[kFieldPlaying][playingId][kSubFieldStartedPlaying] != null ? setup[kFieldPlaying][playingId][kSubFieldStartedPlaying].toDate() : 'N/A'}'),
            //         InfoText(
            //             'Last move: ${setup[kFieldPlaying][playingId][kSubFieldLatestMove] != null ? setup[kFieldPlaying][playingId][kSubFieldLatestMove].toDate() : 'N/A'}'),
            //       ],
            //     ),
            //   ],
            // ),
            Expanded(
              flex: 2,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text('You\'re watching ${Provider.of<GameHubUpdates>(context).getScreenName(playingId)} play',
                      textAlign: TextAlign.center, style: kConversationResultsResultsStyle),
//                  SizedBox(height: 10),
                  GestureDetector(
                    //Score count:
                    child: Center(child: Text(thisGame.beamScore.toString(), style: TextStyle(fontSize: 30))),
//                child: Center(child: Text('beam score', style: TextStyle(fontSize: 30))),
                    onTap: () {
                      setState(() {});
                      print('Setting State in secret button-------------------------------------------------------------');
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
                  child: Text('Number of atoms:   ${thisGame.atoms.length}'),
//                  child: Text('Number of atoms:   '),
                ),
//                Padding(
//                  padding: const EdgeInsets.only(right: 10),
//                  child: RaisedButton(
//                    child: Text('Test play'),
//                    onPressed:  () async {
//                      testPlayButtonPress();
//                    },
//                  ),
//                )
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
//                    PlayBoard(playWidth: thisGame.widthOfPlayArea, playHeight: thisGame.heightOfPlayArea, thisGame: thisGame, refreshParent: refresh),
                        BoardGrid(
                            playWidth: thisGame.widthOfPlayArea,
                            playHeight: thisGame.heightOfPlayArea,
                            getEdgeTiles: getEdges,
                            getMiddleTiles: getMiddleElements),
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

