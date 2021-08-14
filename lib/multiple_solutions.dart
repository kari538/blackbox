// import 'package:blackbox/my_firebase_labels.dart';
// import 'package:modal_progress_hud/modal_progress_hud.dart';
// import 'package:blackbox/units/final_answer_press.dart';
// import 'package:wakelock/wakelock.dart';
// import 'package:intl/intl.dart';
// import 'package:blackbox/my_firebase_labels.dart';
// import 'package:blackbox/units/small_widgets.dart';
// import 'package:blackbox/constants.dart';
// import 'dart:async';
// import 'package:blackbox/board_grid.dart';
// import 'package:blackbox/firestore_lables.dart';
// import 'package:blackbox/game_hub_updates.dart';
// import 'package:blackbox/my_firebase.dart';
// import 'package:blackbox/online_screens/sent_results_screen.dart';
// // import 'package:blackbox/screens/play_screen.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../play.dart';
// import '../atom_n_beam.dart';
//
// //import 'package:firebase_auth/firebase_auth.dart' as auth;
// //import 'package:provider/provider.dart';
// //import 'package:blackbox/game_hub_updates.dart';
//
// class FollowPlayingScreen extends StatefulWidget {
//   FollowPlayingScreen({
//     @required this.setup,
//     @required this.playingId,
//     @required this.me,
//     /*@required this.thisGame*/
//   });
//
// //  final Play thisGame;
//   final DocumentSnapshot setup;
//   final String playingId;
//   final String me;
//
//   @override
//   _FollowPlayingScreenState createState() => _FollowPlayingScreenState(setup, playingId);
// }
//
// class _FollowPlayingScreenState extends State<FollowPlayingScreen> {
// //  final Play thisGame;
// //  auth.User loggedInUser;
// //  _FollowPlayingScreenState(this.thisGame);
//   _FollowPlayingScreenState(this.setup, this.playingId);
//
//   final DocumentSnapshot setup;
//   final String playingId;
//   Play thisGame;
//   Map<String, dynamic> setupData = {};
//   Stream<DocumentSnapshot> thisSetupStream;
//   Timestamp started;
//   Timestamp latestMove;
//   String startedString = 'N/A';
//   String latestMoveString = 'N/A';
//   bool showSpinner = false;
//
// //  StreamSubscription<auth.User> userListener;
//   StreamSubscription playingListener;
//
// //  StreamSubscription followingListener;
//
// //  gameData in SentResultsScreen is {sender: 27uvauvLrQiVco8hVNLS, widthAndHeight: [8, 8], results: {Felix: {A: 5, B: 22,
// //  sentBeams: [21, 18, 28, 3, 12, 6, 27, 5, 8, 25, 23, 30, 29], playerAtoms: [6, 6, 2, 2, 2, 5, 3, 6, 2, 4]},
// //  Karolina: {A: 0, B: 14, sentBeams: [16, 13, 10, 9, 28, 29, 12, 32, 26], playerAtoms: [6, 6, 2, 2, 2, 5, 1, 2, 3, 6]}},
// //  atoms: [6, 6, 3, 6, 2, 5, 2, 2, 1, 2], timestamp: Timestamp(seconds=1601403677, nanoseconds=830000000)}
//
// //  gameData.keys in SentResultsScreen is (sender, widthAndHeight, results, atoms, timestamp)
//
//   @override
//   void initState() {
//     Wakelock.enable();  // Prevents phone from sleeping for as long as this screen is open
// //    getCurrentUser();
//     setupData = setup.data();
//     print('setupData in FollowPlayingScreen is $setupData');
//     print('setupData.keys in FollowPlayingScreen are ${setupData.keys}');
//     started = setupData[kFieldPlaying][playingId][kSubFieldStartedPlaying];
//     latestMove = setupData[kFieldPlaying][playingId][kSubFieldLastMove];
//     if (started != null) {
//       startedString = DateFormat('d MMM, HH:mm:ss').format(started.toDate());
//       if (latestMove != null) latestMoveString = DateFormat('d MMM, HH:mm:ss').format(latestMove.toDate());
//     }
//     thisGame = Play(numberOfAtoms: 0, widthOfPlayArea: setupData['widthAndHeight'][0], heightOfPlayArea: setupData['widthAndHeight'][1]);
//     thisGame.online = true;
//     uploadFollowing();
//
//     if (setupData.containsKey(kFieldShuffleA) && setupData.containsKey(kFieldShuffleB)) {
//       thisGame.beamImageIndexA = [];
//       for (int i = 0; i < setupData[kFieldShuffleA].length; i++){
//         thisGame.beamImageIndexA.add(setupData[kFieldShuffleA][i]);
//       }
//
//       thisGame.beamImageIndexB = [];
//       for (int i = 0; i < setupData[kFieldShuffleB].length; i++){
//         thisGame.beamImageIndexB.add(setupData[kFieldShuffleB][i]);
//       }
//     }
//     print('In initState: beamImageIndexA is ${thisGame.beamImageIndexA} and beamImageIndexB is ${thisGame.beamImageIndexB}');
//
//     if (setupData[kFieldPlaying][playingId].containsKey(kSubFieldClearList)) {
//       List<dynamic> sentClearList = setupData[kFieldPlaying][playingId][kSubFieldClearList];
//       for (int i = 0; i < sentClearList.length; i += 2){
//         thisGame.clearList.add([sentClearList[i], sentClearList[i+1]]);
//       }
//     }
//     getAtoms();
//     getAndPlacePlayerAtoms(setupData);
//     List<dynamic> receivedBeams = setupData[kFieldPlaying][playingId][kSubFieldPlayingBeams] ?? [];
//     for (int receivedBeamNo in receivedBeams) {
//       sendBeam(receivedBeamNo);
//     }
//     thisSetupStream = MyFirebase.storeObject.collection('setups').doc(setup.id).snapshots();
//     getPlayingStream();
//     print('In initState: thisGame.atoms: ${thisGame.atoms}, thisGame.sentBeams: ${thisGame.sentBeams}');
// //    print('Atoms are in positions:');
// //    for (Atom atom in thisGame.atoms) {
// //      print(atom.position.toList());
// //    }
// //    print('**************************');
//     super.initState();
//   }
//
//   @override
//   void dispose() async {
// //    userListener.cancel();
//     playingListener.cancel();
//     super.dispose();
//     await removeFollowing();
//   }
//
//   void uploadFollowing() async {
//     List<dynamic> followers = [];
//     print('setupData in uploadFollowing() is $setupData');
//     print('thisGame.playerId in uploadFollowing() is ${thisGame.playerId}');
//     if(setupData[kFieldPlaying][widget.playingId].containsKey(kSubFieldFollowing)){
//       followers = setupData[kFieldPlaying][widget.playingId][kSubFieldFollowing];
//       print('followers List is $followers');
//     }
//     String myName = widget.me;
//     if(myName== 'Me') myName = 'Anonymous';
//     followers.add(myName);
//     MyFirebase.storeObject.collection(kCollectionSetups).doc(widget.setup.id).update({
//       '$kFieldPlaying.$playingId.$kSubFieldFollowing': followers
//     });
//   }
//
//   Future removeFollowing() async {
//     String myName = widget.me;
//     if(myName== 'Me') myName = 'Anonymous';
//     List<dynamic> followers = [];
//     print('setupData in removeFollowing() is $setupData');
//     if(setupData[kFieldPlaying][playingId].containsKey(kSubFieldFollowing)){
//       followers = setupData[kFieldPlaying][playingId][kSubFieldFollowing];
//       print('followers List is $followers');
//     }
//     followers.remove(myName);
//     print('followers after remove(myName) is $followers');
//     await MyFirebase.storeObject.collection(kCollectionSetups).doc(widget.setup.id).update({
//       '$kFieldPlaying.$playingId.$kSubFieldFollowing': followers,
//     });
//   }
//
//   void getAtoms() {
//     List<Atom> receivedAtoms = [];
//     for (int i = 0; i < setupData['atoms'].length; i += 2) {
//       receivedAtoms.add(Atom(setupData['atoms'][i], setupData['atoms'][i + 1]));
//     }
//     thisGame.atoms = receivedAtoms;
//   }
//
//   void getAndPlacePlayerAtoms(Map<String, dynamic> setupData) {
//     // List<List<int>> receivedPlayerAtoms = [];
//     List<Atom> receivedPlayerAtoms = [];
//     if (setupData[kFieldPlaying].containsKey(playingId) && setupData[kFieldPlaying][playingId][kSubFieldPlayingAtoms] != null) {
//       for (int i = 0; i < setupData[kFieldPlaying][playingId][kSubFieldPlayingAtoms].length; i += 2) {
//         receivedPlayerAtoms
//             .add(Atom(setupData[kFieldPlaying][playingId][kSubFieldPlayingAtoms][i], setupData[kFieldPlaying][playingId][kSubFieldPlayingAtoms][i + 1]));
//         // receivedPlayerAtoms
//         //     .add([setupData[kFieldPlaying][playingId][kPlayingAtoms][i], setupData[kFieldPlaying][playingId][kPlayingAtoms][i + 1]]);
//       }
//     }
//     thisGame.playerAtoms = receivedPlayerAtoms;
//   }
//
//   void sendBeam(int receivedBeamNo) {
//     print("receivedBeamNo is $receivedBeamNo");
//     dynamic result = thisGame.getBeamResult(inSlot: receivedBeamNo);
//     // dynamic result = thisGame.getBeamResult(
//     //   beam: Beam(start: receivedBeamNo, widthOfPlayArea: thisGame.widthOfPlayArea, heightOfPlayArea: thisGame.heightOfPlayArea),
//     // );
//     thisGame.setEdgeTiles(inSlot: receivedBeamNo, beamResult: result);
//   }
//
//   void getPlayingStream() {
//     int showedResults = 0;
//     playingListener = thisSetupStream.listen((event) async {
//       Map<String, dynamic> eventData;
//       if (event != null) eventData = event.data();
//       print('FollowingPlayingScreen listener event data: $eventData');
//
//       //Beams:
//       List<dynamic> receivedBeams = eventData[kFieldPlaying][playingId][kSubFieldPlayingBeams];
//       //I'm only interested in the last beam:
//       int receivedBeamNo;
//       if (receivedBeams != null && receivedBeams.length > 0) receivedBeamNo = receivedBeams[receivedBeams.length - 1];
//       print("receivedBeamNo is $receivedBeamNo");
//       if (receivedBeamNo != null && thisGame.edgeTileChildren[receivedBeamNo - 1] == null) {
//         //A beam has been received and this tile does not already have a child so it's a new one
//         setState(() {
//           sendBeam(receivedBeamNo);
//           latestMove = eventData[kFieldPlaying][playingId][kSubFieldLastMove];
//           if (latestMove != null) latestMoveString = DateFormat('d MMM, HH:mm:ss').format(latestMove.toDate());
//         });
//       }
//
//       //Atoms:
//       setState(() {
//         getAndPlacePlayerAtoms(eventData);
//         latestMove = eventData[kFieldPlaying][playingId][kSubFieldLastMove];
//         if (latestMove != null) latestMoveString = DateFormat('d MMM, HH:mm:ss').format(latestMove.toDate());
//       });
//
//       // Clear:
//       if (eventData[kFieldPlaying][playingId].containsKey(kSubFieldClearList) && eventData[kFieldPlaying][playingId][kSubFieldClearList].length != thisGame.clearList.length/2){
//         thisGame.clearList = [];
//         List<dynamic> sentClearArray = eventData[kFieldPlaying][playingId][kSubFieldClearList];
//         setState(() {
//           for (int i = 0; i < sentClearArray.length; i += 2){
//             thisGame.clearList.add([sentClearArray[i], sentClearArray[i+1]]);
//           }
//         });
//       }
//
//       //Done:
//       if (eventData[kFieldPlaying][playingId][kfidon] == true) {
//         //If this 'done' field doesn't yet exist, surely you'll manage...?
//         if (showedResults == 0) { // This is a safety since the stream might fire several times after "Done"...
//           eventData.remove(kFieldResults);
//           eventData.addAll({
//             kFieldResults: {
//               playingId: {
//                 kSubFieldStartedPlaying: eventData[kFieldPlaying][playingId][kSubFieldStartedPlaying],
//                 kSubFieldFinishedPlaying: eventData[kFieldPlaying][playingId][kSubFieldLastMove],
//                 kSubFieldPlayerAtoms: eventData[kFieldPlaying][playingId][kSubFieldPlayingAtoms],
//                 kSubFieldSentBeams: eventData[kFieldPlaying][playingId][kSubFieldPlayingBeams],
//               }
//             }
//           });
//           print('eventData before navigating to SentResultsScreen(): $eventData');
//
//           Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) {
//             return SentResultsScreen(setupData: eventData, resultPlayerId: playingId);
//           }));
//           showedResults++;
//         }
//       }
//     });
//   }
//
// //  void getCurrentUser() async {
// //    userListener = MyFirebase.authObject.userChanges().listen((event) {
// //      loggedInUser = MyFirebase.authObject.currentUser;
// ////      print("Play screen getCurrentUser() event.email is ${event.email}");  //This will crash if event is null...
// //    });
// //
// //    print('Play screen printing loggedInUser $loggedInUser');  //Should be null before it's done
// ////    widget.thisGame.playerId = Provider.of<GameHubUpdates>(context, listen: false).myId;
// //  }
//
//   Widget getEdges({int x, int y}) {
//     int slotNo = Beam.convert(coordinates: Position(x, y), heightOfPlayArea: thisGame.heightOfPlayArea, widthOfPlayArea: thisGame.widthOfPlayArea);
//     return Expanded(
//       child: Container(
//         child: Center(
//             child: thisGame.edgeTileChildren[slotNo - 1] ??
//                 FittedBox(fit: BoxFit.contain, child: Text('$slotNo', style: TextStyle(color: kBoardEdgeTextColor, fontSize: 15)))),
//         decoration: BoxDecoration(color: kBoardEdgeColor),
//       ),
//     );
//   }
//
//   Widget getMiddleElements({int x, int y}) {
//     bool sentCorrect = false;
//     bool sentWrong = false;
//     bool hidden = false;
//     // bool showClear = true;
//     bool showClear