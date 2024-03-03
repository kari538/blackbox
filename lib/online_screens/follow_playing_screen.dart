import 'package:blackbox/units/small_functions.dart';
import 'package:blackbox/units/ping_widget.dart';
import 'package:blackbox/my_firebase_labels.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:wakelock/wakelock.dart';
import 'package:intl/intl.dart';
import 'package:blackbox/units/small_widgets.dart';
import 'package:blackbox/constants.dart';
import 'dart:async';
import 'package:blackbox/board_grid.dart';
import 'package:blackbox/game_hub_updates.dart';
import 'package:blackbox/my_firebase.dart';
import 'package:blackbox/online_screens/sent_results_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../play.dart';
import '../atom_n_beam.dart';

class FollowPlayingScreen extends StatefulWidget {
  FollowPlayingScreen({
    required this.setup,
    required this.playingId,
    // required this.myScreenName,
    /*@required this.thisGame*/
  });

//  final Play thisGame;
  final DocumentSnapshot setup;
  final String playingId;

  // final String? myScreenName;

  @override
  _FollowPlayingScreenState createState() =>
      _FollowPlayingScreenState(setup, playingId);
}

class _FollowPlayingScreenState extends State<FollowPlayingScreen> {
//  final Play thisGame;
//  auth.User loggedInUser;
//  _FollowPlayingScreenState(this.thisGame);
  _FollowPlayingScreenState(this.setup, this.playingId);

  final DocumentSnapshot? setup;
  final String playingId;
  String? myUid = MyFirebase.authObject.currentUser?.uid;
  late Play thisGame;
  Map<String, dynamic> setupData = {};
  late Stream<DocumentSnapshot> thisSetupStream;
  Timestamp? started;
  Timestamp? lastMove;
  String startedString = 'N/A';
  String lastMoveString = 'N/A';
  bool showSpinner = true;
  Future? refreshed;
  late GameHubUpdates gameHubProvider;
  Stream? otherWatchersStream;
  late StreamSubscription playingListener;
  bool? playingOnlineStatus;
  late PingWidget invisiblePingWidget;

//  StreamSubscription followingListener;

//  gameData in SentResultsScreen is {sender: 27uvauvLrQiVco8hVNLS, widthAndHeight: [8, 8], results: {Felix: {A: 5, B: 22,
//  sentBeams: [21, 18, 28, 3, 12, 6, 27, 5, 8, 25, 23, 30, 29], playerAtoms: [6, 6, 2, 2, 2, 5, 3, 6, 2, 4]},
//  Karolina: {A: 0, B: 14, sentBeams: [16, 13, 10, 9, 28, 29, 12, 32, 26], playerAtoms: [6, 6, 2, 2, 2, 5, 1, 2, 3, 6]}},
//  atoms: [6, 6, 3, 6, 2, 5, 2, 2, 1, 2], timestamp: Timestamp(seconds=1601403677, nanoseconds=830000000)}

//  gameData.keys in SentResultsScreen is (sender, widthAndHeight, results, atoms, timestamp)

  @override
  void initState() {
    Wakelock
        .enable(); // Prevents phone from sleeping for as long as this screen is open
//    getCurrentUser();
    invisiblePingWidget = PingWidget(
      pingStream: MyFirebase.storeObject
          .collection(kCollectionSetups)
          .doc(setup!.id)
          .collection(kSubCollectionPlayingPings)
          .doc(kSubCollectionPlayingPings)
          .snapshots(),
      createChild: createPingChildAndGetOnlineStatus,
    );
    setupData = setup!.data() as Map<String,
        dynamic>; // This may not be up to date, but some things can
    // still be done since they never change
    print('setupData.keys in FollowPlayingScreen initState() are:');
    myPrettyPrint(setupData.keys);
    // printPrettyJson(setupData.keys);
    print('setupData in FollowPlayingScreen initState() is:');
    myPrettyPrint(setupData);
    thisGame = Play(
        numberOfAtoms: 0,
        widthOfPlayArea: setupData['widthAndHeight'][0],
        heightOfPlayArea: setupData['widthAndHeight'][1]);
    thisGame.online = true;

    refreshed = refreshSetupData();
    getMoveTimeStamps(refreshed);
    uploadFollowing(refreshed);

    thisSetupStream = MyFirebase.storeObject
        .collection(kCollectionSetups)
        .doc(setup!.id)
        .snapshots();
    otherWatchersStream = MyFirebase.storeObject
        .collection(kCollectionSetups)
        .doc(setup!.id)
        .collection(kSubCollectionWatchingPings)
        .doc(playingId)
        .snapshots();
    getPlayingStream();

    ping();
    super.initState();
  }

  @override
  void dispose() async {
//    userListener.cancel();
    Wakelock.disable();
    playingListener.cancel();
    super.dispose();
    await removeFollowing(refreshed);
  }

  Future refreshSetupData() async {
    DocumentSnapshot? newSetup;
    try {
      newSetup = await MyFirebase.storeObject
          .collection(kCollectionSetups)
          .doc(setup!.id)
          .get();
    } catch (e) {
      print('Error in refreshSetupData(): $e');
    }
    if (newSetup != null) setupData = newSetup.data() as Map<String, dynamic>;
    // If the newSetup was null, we will just continue with the old setupData.

    if (setupData.containsKey(kFieldShuffleA) &&
        setupData.containsKey(kFieldShuffleB)) {
      thisGame.beamImageIndexA = [];
      for (int i = 0; i < setupData[kFieldShuffleA].length; i++) {
        thisGame.beamImageIndexA!.add(setupData[kFieldShuffleA][i]);
      }

      thisGame.beamImageIndexB = [];
      for (int i = 0; i < setupData[kFieldShuffleB].length; i++) {
        thisGame.beamImageIndexB!.add(setupData[kFieldShuffleB][i]);
      }
    }

    if (setupData[kFieldPlaying][playingId].containsKey(kSubFieldMarkUpList)) {
      List<dynamic> sentMarkUpList =
          setupData[kFieldPlaying][playingId][kSubFieldMarkUpList];
      for (int i = 0; i < sentMarkUpList.length; i += 2) {
        thisGame.markUpList.add([sentMarkUpList[i], sentMarkUpList[i + 1]]);
      }
    }
    getAtoms();
    getAndPlacePlayerAtoms(setupData);
    List<dynamic> receivedBeams =
        setupData[kFieldPlaying][playingId][kSubFieldPlayingBeams] ?? [];
    for (int receivedBeamNo in receivedBeams) {
      sentBeam(receivedBeamNo);
    }

    print(
        'In refreshSetupData(): thisGame.atoms: ${thisGame.atoms}, thisGame.sentBeams: ${thisGame.sentBeams}');
//    print('Atoms are in positions:');
//    for (Atom atom in thisGame.atoms) {
//      print(atom.position.toList());
//    }
//    print('**************************');
    if (this.mounted)
      setState(() {
        showSpinner = false;
      });
    return;
  }

  void delayedSetState() async {
    await Future.delayed(Duration(milliseconds: 200));
    if (this.mounted) setState(() {});
  }

  void getMoveTimeStamps(Future? refreshed) async {
    await refreshed;
    // if (setupData[kFieldPlaying][playingId] == null)
    started = setupData[kFieldPlaying][playingId][kSubFieldStartedPlaying];
    lastMove = setupData[kFieldPlaying][playingId][kSubFieldLastMove];
    if (started != null)
      startedString = DateFormat('d MMM, HH:mm:ss').format(started!.toDate());
    if (lastMove != null)
      lastMoveString = DateFormat('d MMM, HH:mm:ss').format(lastMove!.toDate());
  }

// TODO: ---Turn ping back on (if commented out):
  void ping() async {
    // int i = 0;
    do {
      // print('Ping no $i');
      try {
        await MyFirebase.storeObject
            .collection(kCollectionSetups)
            .doc(setup!.id)
            .collection(kSubCollectionWatchingPings)
            .doc(playingId)
            .set({
          // await MyFirebase.storeObject.collection(kCollectionSetups).doc(setup.id).collection('PlayingPings').doc(myUid).set({
          '$myUid': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } on Exception catch (e) {
        print('Watching Ping upload error: $e');
      }
      await Future.delayed(Duration(seconds: 4));
      // i++;
    } while (this.mounted);
  }

  void uploadFollowing(Future? refreshed) async {
    print('thisGame.playerId in uploadFollowing() is ${thisGame.playerUid}');
    print('setupData keys in uploadFollowing() is ${setupData.keys}');
    print('setupData in uploadFollowing() is:');
    myPrettyPrint(setupData);

    await refreshed;
    List<dynamic>? followers = []; // Must be dynamic because Firebase...
    if (setupData[kFieldPlaying][widget.playingId]
        .containsKey(kSubFieldFollowing)) {
      followers =
          setupData[kFieldPlaying][widget.playingId][kSubFieldFollowing];
      print('followers List is:');
      myPrettyPrint(followers);
    }
    followers!.add(myUid);
    // String myName = widget.me;
    // if(myName== 'Me') myName = 'Anonymous';
    // followers.add(myName);
    try {
      /* Future<void> uploadDoc = */ MyFirebase.storeObject
          .collection(kCollectionSetups)
          .doc(widget.setup.id)
          .update({
        // Future<void> uploadDoc = MyFirebase.storeObject.collection(kCollectionSetups).doc(widget.setup.id).update({
        '$kFieldPlaying.$playingId.$kSubFieldFollowing': followers
      });
    } catch (e) {
      print('Error updating followers: \n$e');
    }
    // ping(uploadDoc: uploadDoc);
  }

  Future removeFollowing(Future? refreshed) async {
    await refreshed;
    // String myName = widget.me;
    // if(myName== 'Me') myName = 'Anonymous';
    List<dynamic>? followers = [];
    print('setupData in removeFollowing() is $setupData');
    if (setupData[kFieldPlaying][playingId].containsKey(kSubFieldFollowing)) {
      followers = setupData[kFieldPlaying][playingId][kSubFieldFollowing];
      print('followers List is $followers');
    }
    followers!.remove(myUid);
    // followers.remove(myName);
    print('followers after remove(myUid) is $followers');
    // print('followers after remove(myName) is $followers');
    try {
      await MyFirebase.storeObject
          .collection(kCollectionSetups)
          .doc(widget.setup.id)
          .update({
        '$kFieldPlaying.$playingId.$kSubFieldFollowing': followers,
      });
    } catch (e) {
      print('Error updating followers...: \n$e');
    }
  }

  // TODO: Atoms belonging to the original setup should always be called 'setupAtoms', except in Play where they are called 'atoms'.
  void getAtoms() {
    List<Atom> receivedSetupAtoms = [];
    for (int i = 0; i < setupData['atoms'].length; i += 2) {
      receivedSetupAtoms.add(Atom(setupData['atoms'][i], setupData['atoms'][i + 1]));
    }
    thisGame.atoms = receivedSetupAtoms;
  }

  void getAndPlacePlayerAtoms(Map<String, dynamic> setupData) {
    // List<List<int>> receivedPlayerAtoms = [];
    List<Atom> receivedPlayerAtoms = [];
    // If the game (still) contains a playing tag, and the followed player's ID is there
    // and they have places atoms:
    if (setupData[kFieldPlaying]?[playingId]?[kSubFieldPlayingAtoms] != null) {
      // if (setupData[kFieldPlaying].containsKey(playingId) && setupData[kFieldPlaying][playingId][kSubFieldPlayingAtoms] != null) {
      for (int i = 0;
          i < setupData[kFieldPlaying][playingId][kSubFieldPlayingAtoms].length;
          i += 2) {
        receivedPlayerAtoms.add(
          Atom(
              setupData[kFieldPlaying][playingId][kSubFieldPlayingAtoms][i],
              setupData[kFieldPlaying][playingId][kSubFieldPlayingAtoms][i + 1],
          ),
        );
        // receivedPlayerAtoms
        //     .add([setupData[kFieldPlaying][playingId][kPlayingAtoms][i], setupData[kFieldPlaying][playingId][kPlayingAtoms][i + 1]]);
      }
    }
    thisGame.playerAtoms = receivedPlayerAtoms;
  }

  void sentBeam(int receivedBeamNo) {
    print("receivedBeamNo is $receivedBeamNo");
    thisGame.sendBeam(inSlot: receivedBeamNo);
    // dynamic result = thisGame.sendBeam(inSlot: receivedBeamNo);
    // thisGame.setEdgeTiles(inSlot: receivedBeamNo, beamResult: result);
  }

  void getPlayingStream() {
    int showedResults = 0;
    playingListener = thisSetupStream.listen((event) async {
      Map<String, dynamic> eventData;
      eventData = event.data() as Map<String, dynamic>;
      print('FollowingPlayingScreen getPlayingStream() event data:');
      myPrettyPrint(eventData);

      //Beams:
      List<dynamic>? receivedBeams =
          eventData[kFieldPlaying][playingId][kSubFieldPlayingBeams];
      //I'm only interested in the last beam:
      int? receivedBeamNo;
      if (receivedBeams != null && receivedBeams.length > 0)
        receivedBeamNo = receivedBeams[receivedBeams.length - 1];
      print("receivedBeamNo is $receivedBeamNo");
      if (receivedBeamNo != null &&
          thisGame.edgeTileChildren![receivedBeamNo - 1] == null) {
        //A beam has been received and this tile does not already have a child so it's a new one
        setState(() {
          sentBeam(receivedBeamNo!);
          lastMove = eventData[kFieldPlaying][playingId][kSubFieldLastMove];
          if (lastMove != null)
            lastMoveString =
                DateFormat('d MMM, HH:mm:ss').format(lastMove!.toDate());
        });
      }

      //Atoms:
      setState(() {
        getAndPlacePlayerAtoms(eventData);
        lastMove = eventData[kFieldPlaying][playingId][kSubFieldLastMove];
        if (lastMove != null)
          lastMoveString =
              DateFormat('d MMM, HH:mm:ss').format(lastMove!.toDate());
      });

      // Mark up:
      if (eventData[kFieldPlaying][playingId]
              .containsKey(kSubFieldMarkUpList) &&
          eventData[kFieldPlaying][playingId][kSubFieldMarkUpList].length !=
              thisGame.markUpList.length / 2) {
        thisGame.markUpList = [];
        List<dynamic>? sentMarkUpArray =
            eventData[kFieldPlaying][playingId][kSubFieldMarkUpList];
        setState(() {
          for (int i = 0; i < sentMarkUpArray!.length; i += 2) {
            thisGame.markUpList
                .add([sentMarkUpArray[i], sentMarkUpArray[i + 1]]);
          }
        });
      }

      //Done:
      if (eventData[kFieldPlaying][playingId][kSubFieldPlayingDone] == true) {
        //If this 'done' field doesn't yet exist, surely you'll manage...?
        if (showedResults == 0) {
          // This is a safety since the stream might fire several times after "Done"...
          eventData.remove(kFieldResults);
          eventData.addAll({
            kFieldResults: {
              playingId: {
                kSubFieldStartedPlaying: eventData[kFieldPlaying][playingId]
                    [kSubFieldStartedPlaying],
                kSubFieldFinishedPlaying: eventData[kFieldPlaying][playingId]
                    [kSubFieldLastMove],
                kSubFieldPlayerAtoms: eventData[kFieldPlaying][playingId]
                    [kSubFieldPlayingAtoms],
                kSubFieldSentBeams: eventData[kFieldPlaying][playingId]
                    [kSubFieldPlayingBeams],
              }
            }
          });
          print(
              'eventData before navigating to SentResultsScreen(): $eventData');

          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) {
            return SentResultsScreen(
                key: ValueKey(eventData),
                setupData: eventData,
                resultPlayerId: playingId);
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

  Widget getEdgeElement({required int x, required int y}) {
    int slotNo = Beam.convert(
        coordinates: Position(x, y),
        heightOfPlayArea: thisGame.heightOfPlayArea,
        widthOfPlayArea: thisGame.widthOfPlayArea)!;
    return Expanded(
      child: Container(
        child: Center(
            child: thisGame.edgeTileChildren![slotNo - 1] ??
                FittedBox(
                    fit: BoxFit.contain,
                    child: Text('$slotNo',
                        style: TextStyle(
                            color: kBoardEdgeTextColor, fontSize: 15)))),
        decoration: BoxDecoration(color: kBoardEdgeColor),
      ),
    );
  }

  /// Unfound setupAtoms are blue transparent, player atoms correctly placed are
  /// yellow solid, and player atoms wrongly placed are yellow transparent.
  Widget getMiddleElement({required int x, required int y}) {
    bool correctlyPlaced = false;
    bool wronglyPlaced = false;
    bool unfound = false;
    // bool hasMarkup = true;
    bool hasMarkup = false;

    // Loop through player atoms:
    // for (List<int> playerAtom in thisGame.playerAtoms) {
    // xxx
    for (Atom playerAtom in thisGame.playerAtoms) {
      if (ListEquality().equals([x, y], playerAtom.position.toList())) {
        //Sent Atom
        // This atom is correctly placed:
        for (Atom setupAtom in thisGame.atoms) {
          if (ListEquality().equals([x, y], setupAtom.position.toList())) {
            correctlyPlaced = true;
          }
        }
        //        print('Show atom is true');
        // This atom is wrongly placed:
        if (!correctlyPlaced) {
          wronglyPlaced = true;
        }
      }
    }
    // If no player atom is placed on this square:
    if (correctlyPlaced == false && wronglyPlaced == false) {
      for (Atom setupAtom in thisGame.atoms) {
        if (ListEquality().equals([x, y], setupAtom.position.toList())) {
          //Hidden Atom
          unfound = true;
        }
      }
    }

    for (List<int?>? markup in thisGame.markUpList) {
      if (ListEquality().equals([x, y], markup)) hasMarkup = true;
    }

    return Expanded(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            child: Center(
              child: correctlyPlaced
                  ? Image(image: AssetImage('images/atom_yellow.png'))
                  : wronglyPlaced
                      ? Opacity(
                          child: Image(
                              image: AssetImage('images/atom_yellow.png')),
                          opacity: 0.5)
                      : unfound
                          // ? Image(image: AssetImage('images/atom_yellow_transp.png'))
                          ? Opacity(
                              child: Image(
                                  image: AssetImage('images/atom_blue.png')),
                              opacity: 0.8)
                          : FittedBox(
                              fit: BoxFit.contain,
                              child: Text(
                                '$x,$y',
                                style: TextStyle(
                                    color: kBoardTextColor, fontSize: 15),
                              ),
                            ),
            ),
            decoration: BoxDecoration(
                color: kBoardColor,
                border: Border.all(color: kBoardGridLineColor, width: 0.5)),
          ),
          hasMarkup
              ? Image(image: AssetImage('images/markup.png'))
              : SizedBox(),
        ],
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

  /// Checks if the followed player is online (playingOnlineStatus is true or false)
  /// and returns an empty SizedBox().
  Widget createPingChildAndGetOnlineStatus(Map<String, bool> activeMap) {
    Widget widget = SizedBox();
    // Widget widget = OnlineStatusWidget(online: activeMap[playingId] == true);
    // List<Widget> list = [];
    playingOnlineStatus = activeMap[playingId];
    delayedSetState();
    return widget;
  }

  // void getOnlineStatus() {
  //   // String getOnlineStatus() {
  //   print('Running getOnlineStatus()');
  //
  //   // bool online = invisiblePingWidget.online;
  //   // playingOnlineStatus = '...';
  //   // String _status = '...';
  //   // Map<String, bool> activeMap = invisiblePingWidget.getActiveMap();
  //   // Map<String, bool> activeMap = PingWidget(
  //   //   pingStream: MyFirebase.storeObject.collection(kCollectionSetups).doc(setup.id).collection(kSubCollectionPlayingPings).doc(kSubCollectionPlayingPings).snapshots(),
  //   //   createChildren: (activeMap) {
  //   //     setState(() {
  //   //       playingOnlineStatus = activeMap[playingId];
  //   //       // _status = activeMap[playingId];
  //   //       print('Online status is $playingOnlineStatus');
  //   //       // print('Online status is $_status');
  //   //     });
  //   //     return [];
  //   //   },
  //   // ).getActiveMap();
  //   // playingOnlineStatus = activeMap[playingId];
  //   // print('activeMap is $activeMap');
  //   // print('Online status is $playingOnlineStatus');
  //
  //   // get(
  //   //   pingStream: MyFirebase.storeObject.collection(kCollectionSetups).doc(setup.id).collection(kSubCollectionPlayingPings).doc(kSubCollectionPlayingPings).snapshots(),
  //   //   createChildren: (activeMap) {
  //   //     setState(() {
  //   //       playingOnlineStatus = activeMap[playingId];
  //   //       // _status = activeMap[playingId];
  //   //       print('Online status is $playingOnlineStatus');
  //   //       // print('Online status is $_status');
  //   //     });
  //   //     return [];
  //   //   },
  //   // );
  //   // print(x);
  //   // print('Length of $x is ${x.}')
  //   // return playingOnlineStatus.toString();
  // }

  // Widget invisiblePingWidget() {
  //   return PingWidget(
  //     pingStream: MyFirebase.storeObject.collection(kCollectionSetups).doc(setup.id).collection(kSubCollectionPlayingPings).doc(kSubCollectionPlayingPings).snapshots(),
  //     createChildren: (activeMap) {
  //       setState(() {
  //         playingOnlineStatus = activeMap[playingId];
  //         // _status = activeMap[playingId];
  //         print('Online status is $playingOnlineStatus');
  //       });
  //       return [];
  //     },
  //   );
  // }

  Widget otherWatchersChild(Map<String, bool> activeMap) {
    // List<Widget> otherWatchersChildren(Map<String, bool> activeMap) {
    List<Widget> _watchChildren = [InfoText('Also watching:')];

    for (String follower in activeMap.keys) {
      if (activeMap[follower]! && follower != myUid)
        _watchChildren.add(Text(
          // child: Text(
          '${gameHubProvider.getScreenName(follower)}',
          style: TextStyle(
            fontSize: 14,
            color: Colors.tealAccent,
          ),
        ));
    }

    if (_watchChildren.length == 1) _watchChildren = [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _watchChildren,
    );
  }

  @override
  Widget build(BuildContext context) {
    gameHubProvider = Provider.of<GameHubUpdates>(context);
    // getOnlineStatus();
    return Scaffold(
      appBar: AppBar(title: Text('blackbox')),
      body: ModalProgressHUD(
        inAsyncCall: showSpinner,
        child: Center(
          child: Column(
            // mainAxisAlignment: MainAxisAlignment.spaceBetween,
            // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              invisiblePingWidget,
              // invisiblePingWidget(),
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
                        InfoText(
                            'By ${Provider.of<GameHubUpdates>(context).getScreenName(setupData[kFieldSender])}'),
                        PingWidget(
                            pingStream: otherWatchersStream,
                            createChild: otherWatchersChild),
                      ],
                    ),
                  ),
                  //Right info texts:
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      InfoText('Started: $startedString'),
                      InfoText('Last move: $lastMoveString'),
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
                    RichText(
                      text: TextSpan(
                          text:
                              'You\'re watching ${gameHubProvider.getScreenName(playingId)} play',
                          style: kConversationResultsResultsStyle.copyWith(
                              fontSize: 18),
                          children: [
                            playingOnlineStatus == true
                                ? TextSpan(text: '\nstatus: ', children: [
                                    TextSpan(
                                        text: 'online',
                                        style: kConversationResultsResultsStyle
                                            .copyWith(color: Colors.tealAccent))
                                  ])
                                : playingOnlineStatus == false
                                    ? TextSpan(text: '\nstatus: ', children: [
                                        TextSpan(
                                            text: 'offline',
                                            style:
                                                kConversationResultsResultsStyle
                                                    .copyWith(
                                                        color: Colors.red))
                                      ])
                                    : TextSpan(text: '')
                          ]),
                      textAlign: TextAlign.center,
                    ),
                    // Text(
                    //     'You\'re watching ${gameHubProvider.getScreenName(playingId)} play'
                    //     '${playingOnlineStatus == null ? '' : playingOnlineStatus ? '\nstatus: online' : '\nstatus: offline'}',
                    //     // '${gameHubProvider.getScreenName(playingId)} is ${getOnlineStatus()}',
                    //     textAlign: TextAlign.center,
                    //     style: kConversationResultsResultsStyle),
//                  SizedBox(height: 10),
                    GestureDetector(
                      //Score count:
                      child: Center(
                          child: Text(thisGame.beamScore.toString(),
                              style: TextStyle(fontSize: 30))),
//                child: Center(child: Text('beam score', style: TextStyle(fontSize: 30))),
                      onTap: () {
                        setState(() {});
                        print(
                            'Setting State in secret button-------------------------------------------------------------');
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
//                  child: Text('Number of atoms:   '),
                  ),
//                Padding(
//                  padding: const EdgeInsets.only(right: 10),
//                  child: MyRaizedButton(
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
                  padding: const EdgeInsets.only(
                      left: 8.0, top: 8.0, right: 8.0, bottom: 20),
                  child: AspectRatio(
                    aspectRatio: (thisGame.widthOfPlayArea + 2) /
                        (thisGame.heightOfPlayArea + 2),
                    child: Container(
                      child:
//                    PlayBoard(playWidth: thisGame.widthOfPlayArea, playHeight: thisGame.heightOfPlayArea, thisGame: thisGame, refreshParent: refresh),
                          BoardGrid(
                              playWidth: thisGame.widthOfPlayArea,
                              playHeight: thisGame.heightOfPlayArea,
                              getEdgeTiles: getEdgeElement,
                              getMiddleTiles: getMiddleElement),
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

// class OnlineStatusWidget extends StatelessWidget {
//   const OnlineStatusWidget({@required this.online});
//
//   final bool online;
//
//   @override
//   Widget build(BuildContext context) {
//     print('Building OnlineStatusWidget with online as $online');
//     return SizedBox();
//   }
// }
