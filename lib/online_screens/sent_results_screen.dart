import 'package:blackbox/screens/results_screen.dart';
import 'package:intl/intl.dart';
import 'package:blackbox/my_firebase_labels.dart';
import 'package:blackbox/units/small_widgets.dart';
import 'package:blackbox/firestore_lables.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:blackbox/board_grid.dart';
import 'package:blackbox/play.dart';
import 'package:blackbox/constants.dart';
import 'package:blackbox/atom_n_beam.dart';
import 'package:collection/collection.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:blackbox/game_hub_updates.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:provider/provider.dart';

class SentResultsScreen extends StatefulWidget {
  SentResultsScreen({@required this.setupData, @required this.resultPlayerId});
  //TODO: Change to "setupData" in all places, unless of strong reasons against!
  final Map<String, dynamic> setupData;
  final String resultPlayerId;  //The ID associated with this result in the setup (whether name or code)

  @override
  _SentResultsScreenState createState() => _SentResultsScreenState(setupData, resultPlayerId);
}

class _SentResultsScreenState extends State<SentResultsScreen> {
  _SentResultsScreenState(this.setupData, this.resultPlayerId);
  final Map<String, dynamic> setupData;
  final String resultPlayerId;  //The ID associated with this result in the setup (whether name or code)
  FirebaseFirestore firestoreObject = FirebaseFirestore.instance;
  Play thisGame;
  bool resultsReady = false;
  String errorMsg = '';
  int beamScore;
  int atomScore;
  int totalScore;
  bool playerAtoms = false;
  bool awaitingData = false;
  Timestamp started;
  Timestamp finished;
  Duration timePlayed;
  String startedString = 'N/A';
  String finishedString = 'N/A';
  String timePlayedString = 'N/A';
  bool altSol = false;
  List<dynamic> alternativeSolutions;
  List<dynamic> multiDisplay;
  bool showSpinner = true;

  @override
  void initState() {
    super.initState();
    getGameData();
    // if (!(setupData[kFieldResults][resultPlayerId] is int)) {
    if (setupData[kFieldResults][resultPlayerId] is Map) {
      print('Entered finding start and finish times');
      started = setupData[kFieldResults][resultPlayerId][kSubFieldStartedPlaying];
      // started = Timestamp.fromDate(DateTime(2021, 3, 3, 22, 20));
      finished = setupData[kFieldResults][resultPlayerId][kSubFieldFinishedPlaying];
      print('Started is $started and finished is $finished');
      if (finished != null) {
        finishedString = DateFormat('d MMM, HH:mm:ss').format(finished.toDate());
        // It is possible that somebody updates the app between starting and finishing playing, thus getting a "finished" but not a "started" value...
        if (started != null) {
          startedString = DateFormat('d MMM, HH:mm:ss').format(started.toDate());
          // timePlayed = finished.compareTo(started);
          // print("timePlayed is $timePlayed");
          // print('Type of timePlayed is ${timePlayed.runtimeType}');
          timePlayed = finished.toDate().difference(started.toDate());
          // timePlayed = DateTime(2021, 3, 1).difference(started.toDate()); // timePlayed is -58:22:05 when started was 3 Mar, 10:22 AM
          timePlayedString = timePlayed.toString().substring(0, timePlayed.toString().length-7);
          print('timePlayedString is $timePlayedString');
        }
      }
    }
  }

  void getGameData() async {
    await Future.delayed(Duration(milliseconds: 500));  // TODO check... Does this make the spinner show?
    Map<String, dynamic> setupData = widget.setupData;
    print('setupData in SentResultsScreen is $setupData');
    print('setupData.keys in SentResultsScreen is ${setupData.keys}');

    if (setupData == null) {
      setState(() {
        errorMsg = 'Document contains no data';
        showSpinner = false;
      });
    } else {
      int numberOfAtoms = (setupData['atoms'].length / 2).toInt();
      print('number of atoms $numberOfAtoms');
      int width = setupData['widthAndHeight'][0];
      int height = setupData['widthAndHeight'][1];
      thisGame = Play(numberOfAtoms: numberOfAtoms, heightOfPlayArea: height, widthOfPlayArea: width);

      if (setupData.containsKey(kFieldShuffleA) && setupData.containsKey(kFieldShuffleB)) {
        thisGame.beamImageIndexA = [];
        for (int i = 0; i < setupData[kFieldShuffleA].length; i++){
          thisGame.beamImageIndexA.add(setupData[kFieldShuffleA][i]);
        }

        thisGame.beamImageIndexB = [];
        for (int i = 0; i < setupData[kFieldShuffleB].length; i++){
          thisGame.beamImageIndexB.add(setupData[kFieldShuffleB][i]);
        }
      }

      if (setupData['results']['${widget.resultPlayerId}'] is int) {
        print('Player\'s result is an int');
       setState(() {
          totalScore = setupData['results']['${widget.resultPlayerId}'];
          errorMsg = 'Detailed results data not available';
          showSpinner = false;
       });
      } else {
       setState(() { //Do I really have to set State? It's called from initState and is no longer async...
          atomScore = setupData[kFieldResults][widget.resultPlayerId][kAaResultsField];
          beamScore = setupData[kFieldResults][widget.resultPlayerId][kBbResultsField];
          if (atomScore != null && beamScore != null) {
            totalScore = atomScore + beamScore;
          }
          showSpinner = false;
       });
        for (int i = 0; i < setupData['atoms'].length; i += 2) {
          thisGame.atoms.add(Atom(setupData['atoms'][i], setupData['atoms'][i + 1]));
        }
        print('Length of sent beams: ${(setupData['results']['${widget.resultPlayerId}']['sentBeams']).length}');
        for (int beam in setupData['results']['${widget.resultPlayerId}']['sentBeams']) {
          var result = thisGame.getBeamResult(inSlot: beam);
          // var result = thisGame.getBeamResult(beam: Beam(start: beam, widthOfPlayArea: width, heightOfPlayArea: height));
          thisGame.setEdgeTiles(inSlot: beam, beamResult: result);
        }
        if (setupData['results']['${widget.resultPlayerId}'].containsKey('playerAtoms')) {
          print('Key playerAtoms exists');
          playerAtoms = true;
          List<dynamic> sentPlayerAtoms = setupData['results']['${widget.resultPlayerId}']['playerAtoms'];
          for (int i = 0; i < sentPlayerAtoms.length; i += 2) {
            thisGame.playerAtoms.add(Atom(sentPlayerAtoms[i].toInt(), sentPlayerAtoms[i + 1].toInt()));
          }
          print('Player atoms ${thisGame.playerAtoms}');
          alternativeSolutions = await thisGame.getScore();
          altSol = alternativeSolutions != null ? true : false;
          setState(() {
            atomScore = thisGame.atomScore;
            beamScore = thisGame.beamScore;
            totalScore = atomScore + beamScore;
          });
          // TODO Navigate to Playing data and not Results data, if following somebody who already has an uploaded result.
        }

        print('Edge tile children: ${thisGame.edgeTileChildren}');
       setState(() {
//          totalScore = thisGame.atomScore + thisGame.beamScore; //no!!
//          print('Total score $totalScore');
          resultsReady = true;
//          print('Results ready $resultsReady');
       });
      }
    }
  }

  // TODO: Move the get() functions below to some common place
  Widget getEdges({int x, int y}) {
    int slotNo = Beam.convert(coordinates: Position(x, y), heightOfPlayArea: thisGame.heightOfPlayArea, widthOfPlayArea: thisGame.widthOfPlayArea);
    return Expanded(
      child: Container(
        child: Center(
            child: thisGame.edgeTileChildren[slotNo - 1] ?? FittedBox(fit: BoxFit.contain, child: Text('$slotNo', style: TextStyle(color: kBoardEdgeTextColor, fontSize: 15)))),
        decoration: BoxDecoration(color: kBoardEdgeColor),
      ),
    );
  }

  Widget getMiddleElements({int x, int y}) {
    bool correct = false;
    bool misplaced = false;
    bool missed = false;

    if (playerAtoms == false) {
      //I don't have info of player atoms but will show hidden atoms as blue
      for (Atom atom in thisGame.atoms) {
        if (ListEquality().equals([x, y], atom.position.toList())) {
          missed = true;
          print('Show atom is true');
        }
      }
    } else {
      // for (List<int> correctAtom in thisGame.correctAtoms) {
      for (Atom correctAtom in thisGame.correctAtoms) {
        if (ListEquality().equals([x, y], correctAtom.position.toList())) {
          //correct Atom
          correct = true;
          print('Show atom is true');
        }
      }
      if (correct == false) {
        // for (List<int> misplacedAtom in thisGame.misplacedAtoms) {
        for (Atom misplacedAtom in thisGame.misplacedAtoms) {
          // if (ListEquality().equals([x, y], misplacedAtom)) {
          if (ListEquality().equals([x, y], misplacedAtom.position.toList())) {
            //misplaced Atom
            misplaced = true;
          }
        }
      }
      if (correct == false && misplaced == false) {
        // for (List<int> missedAtom in thisGame.missedAtoms) {
        for (Atom missedAtom in thisGame.missedAtoms) {
          if (ListEquality().equals(Position(x, y).toList(), missedAtom.position.toList())) {
            //missed Atom
            missed = true;
          }
        }
      }
    }

    return Expanded(
      child: Container(
        child: Center(
          child: correct
              ? Image(image: AssetImage('images/atom_yellow.png'))
              : misplaced
                  ? Image(image: AssetImage('images/atom_redwcross.png'))
                  : missed
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

  @override
  Widget build(BuildContext context) {
    String resultPlayerScreenName = Provider.of<GameHubUpdates>(context).providerUserIdMap.containsKey(widget.resultPlayerId)
        ? Provider.of<GameHubUpdates>(context).providerUserIdMap[widget.resultPlayerId]
        : widget.resultPlayerId;

    return Scaffold(
      appBar: AppBar(title: Text('blackbox')),
      body: ModalProgressHUD(
        inAsyncCall: showSpinner,
        child: Column(
          // mainAxisAlignment: MainAxisAlignment.spaceBetween,
          // crossAxisAlignment: CrossAxisAlignment.start,
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
                    InfoText('Finished: $finishedString'),
                    InfoText('Time played: $timePlayedString'),
                  ],
                ),
              ],
            ),
            // Align(
            //   alignment: Alignment.centerLeft,
            //   child: Column(
            //     crossAxisAlignment: CrossAxisAlignment.start,
            //     children: [
            //       InfoText('Setup no ${widget.setupData['i']}'),
            //       InfoText('By ${Provider.of<GameHubUpdates>(context).getScreenName(widget.setupData[kFieldSender])}'),
            //     ],
            //   ),
            // ),
            Expanded(
              // flex: 4,
              flex: altSol
                  ? 3
                  : multiDisplay != null
                  ? 3
                  : 4,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          // resultPlayerScreenName == 'Me'
                          //     ? 'My score'
                          //     : '$resultPlayerScreenName\'s score',
                          // textAlign: TextAlign.center,
                          // style: TextStyle(fontSize: 35),
                          multiDisplay == null
                              // ? 'Your score'
                              ? resultPlayerScreenName == 'Me'
                              ? 'My score'
                              : '$resultPlayerScreenName\'s score'
                              : 'Alternative\nsolutions',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 35),
                        ),
                        multiDisplay == null ? Center(
                          child: Container(
//                        color: Colors.blue,
                            width: 200,
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                    flex: 2,
                                    child: Text(
                                      'beam score:',
                                      textAlign: TextAlign.right,
                                    )),
                                Expanded(
                                  flex: 1,
                                  child: Padding(
                                    padding: EdgeInsets.only(right: 26.0),
                                    child: Text(
                                      resultsReady ? '${thisGame.beamScore}' : '...',
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ) : SizedBox(),
                        multiDisplay == null ? Center(
                          child: Container(
//                        color: Colors.blue,
                            width: 200,
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    'atom penalty:',
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(right: 26.0),
                                    child: Text(
                                        resultsReady ? '${thisGame.atomScore} ' : '...',
                                        textAlign: TextAlign.right,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ) : SizedBox(),
                        multiDisplay == null ? Center(
                          child: Container(
//                        color: Colors.blue,
                            width: 200,
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    'total:', //${(thisGame.beamScore + thisGame.atomScore) < 10 ? ' ' : ''}
                                    textAlign: TextAlign.right,
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(right: 26.0),
                                    child: Text(
                                      // '${thisGame.beamScore + thisGame.atomScore}',
                                      '$totalScore',
                                      textAlign: TextAlign.right,
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ) : SizedBox(),

//                       Center(
//                         child: Container(
//                              // color: Colors.blue,
//                           width: 200,
//                           child: Row(
//                             children: <Widget>[
//                               Expanded(
//                                   flex: 2,
//                                   child: Text(
//                                     'beam score:',
//                                     textAlign: TextAlign.right,
//                                   )),
//                               Expanded(
//                                   flex: 1,
//                                   child: Padding(
//                                     padding: EdgeInsets.only(right: 26.0),
//                                     child: Text(
// //                                  resultsReady ? '${thisGame.beamScore}' : '?', //no!
//                                       '${beamScore ?? '?'}',
//                                       textAlign: TextAlign.right,
//                                     ),
//                                   )),
//                             ],
//                           ),
//                         ),
//                       ),
//                       Center(
//                         child: Container(
// //                        color: Colors.blue,
//                           width: 200,
//                           child: Row(
//                             children: <Widget>[
//                               Expanded(
//                                 flex: 2,
//                                 child: Text(
//                                   'atom penalty:',
//                                   textAlign: TextAlign.right,
//                                 ),
//                               ),
//                               Expanded(
//                                 child: Padding(
//                                   padding: EdgeInsets.only(right: 26.0),
// //                              child: Text(resultsReady ? '${thisGame.atomScore}' : '?', textAlign: TextAlign.right),  //no!
//                                   child: Text('${atomScore ?? '?'}', textAlign: TextAlign.right),  //no!
//
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                       Center(
//                         child: Container(
// //                        color: Colors.blue,
//                           width: 200,
//                           child: Row(
//                             children: <Widget>[
//                               Expanded(
//                                 flex: 2,
//                                 child: Text(
//                                   'total:', //${(thisGame.beamScore + thisGame.atomScore) < 10 ? ' ' : ''}
//                                   textAlign: TextAlign.right,
//                                   style: TextStyle(fontWeight: FontWeight.bold),
//                                 ),
//                               ),
//                               Expanded(
//                                 child: Padding(
//                                   padding: EdgeInsets.only(right: 26.0),
//                                   child: Text(
// //                                  resultsReady ? '${thisGame.beamScore + thisGame.atomScore}' : '?',
// //                                  resultsReady ? '$totalScore' : '?',
// //                                totalScore == null ? '?' : totalScore.toString(),
//                                     '${totalScore ?? '?'}',
//                                     textAlign: TextAlign.right,
//                                     style: TextStyle(fontWeight: FontWeight.bold),
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
                      ],
                    ),
                    altSol ? SizedBox(height: 30) : SizedBox(),
                    altSol
                        ? Text(
                      'Multiple solutions exist!',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue),
                    )
                        : SizedBox(),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 6,
              child: Column(
                children: <Widget>[
                  multiDisplay == null ? SizedBox(
                      child: resultsReady ? playerAtoms ? Text('Answer:') : FittedBox(
                          fit: BoxFit.contain, child: Text('Player atom info not available. Beams played:')) : null,
                      height: 30) : SizedBox(height: 30),
                  // multiDisplay == null ? SizedBox(child: Text('The correct answer:'), height: 30) : SizedBox(height: 30),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8.0, top: 8.0, right: 8.0, bottom: 20),
                      child: awaitingData
                          ? Center(child: CircularProgressIndicator())
                          : resultsReady
                          ? AspectRatio(
                              aspectRatio: (thisGame.widthOfPlayArea + 2) / (thisGame.heightOfPlayArea + 2),
                                child: Container(
                                  child: BoardGrid(
                              playWidth: thisGame.widthOfPlayArea,
                              playHeight: thisGame.heightOfPlayArea,
                              getEdgeTiles: getEdges,
                              getMiddleTiles: getMiddleElements,
                          ),
                        ),
                      )
                          : SizedBox(child: Text('$errorMsg', style: TextStyle(color: Colors.red), textAlign: TextAlign.center)),
                    ),
                  ),
                  altSol ?
                  Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: ElevatedButton(
                        child: Text('View other solutions'),
                        onPressed: () async {
                          int result = 0;
                          int gameNo = 1;
                          // int i = 0;
                          Play displayGame;
                          // displayGame.edgeTileChildren = alternativeSolutions[0];
                          // Play displayGame = Play(numberOfAtoms: thisGame.numberOfAtoms, widthOfPlayArea: thisGame.widthOfPlayArea, heightOfPlayArea: thisGame.heightOfPlayArea);
                          // displayGame.atoms = thisGame.atoms;
                          // displayGame.showAtomSetting= true;  // Not working... Atoms don't show up
                          // displayGame.fireAllBeams();
                          // Play.fireAllBeams(displayGame);  // This is only done once...
                          do {
                            // uniqueGame.atoms = allUniqueSetups[gameNo];
                            // displayGame.correctAtoms = alternativeSolutions[gameNo];
                            //
                            // for (Atom atom in alternativeSolutions[gameNo]) {
                            //   displayGame.correctAtoms.add(atom.position.toList());
                            // }
                            displayGame = alternativeSolutions[gameNo];
                            displayGame.edgeTileChildren = alternativeSolutions[0];
                            print('alternativeSolutions[$gameNo] is ${alternativeSolutions[gameNo]}');
                            // Returns null if "Pop" is pressed:
                            result = await Navigator.push(context, PageRouteBuilder(pageBuilder: (context, anim1, anim2) {
                              return ResultsScreen(thisGame: displayGame, setupData: {}, multiDisplay: [gameNo, alternativeSolutions.length-1]);
                            }));
                            if (result != null && gameNo + result > 0 && gameNo + result <= alternativeSolutions.length-1) gameNo += result;
                            // displayGame.correctAtoms = [];
                            // i++;
                          } while (result != null /*&& i < 100*/);

                        },
                      )
                  ) : SizedBox(),

                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
