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

  @override
  void initState() {
    super.initState();
    getGameData();
    started = setupData[kFieldResults][resultPlayerId][kSubFieldStartedPlaying];
    // started = Timestamp.fromDate(DateTime(2021, 3, 3, 22, 20));
    finished = setupData[kFieldResults][resultPlayerId][kSubFieldFinishedPlaying];
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

  void getGameData() {
    Map<String, dynamic> gameData = widget.setupData;
    print('gameData in SentResultsScreen is $gameData');
    print('gameData.keys in SentResultsScreen is ${gameData.keys}');

    if (gameData == null) {
      setState(() {
        errorMsg = 'Document contains no data';
      });
    } else {
      print('Game data $gameData');
      int numberOfAtoms = (gameData['atoms'].length / 2).toInt();
      print('number of atoms $numberOfAtoms');
      int width = gameData['widthAndHeight'][0];
      int height = gameData['widthAndHeight'][1];
      thisGame = Play(numberOfAtoms: numberOfAtoms, heightOfPlayArea: height, widthOfPlayArea: width);
      if (gameData['results']['${widget.resultPlayerId}'] is int) {
        print('Player\'s result is an int');
//        setState(() {
          totalScore = gameData['results']['${widget.resultPlayerId}'];
          errorMsg = 'Detailed results data not available';
//        });
      } else {
//        setState(() { //Do I really have to set State? It's called from initState and is no longer async...
          atomScore = gameData[kFieldResults][widget.resultPlayerId][kAaResultsField];
          beamScore = gameData[kFieldResults][widget.resultPlayerId][kBbResultsField];
          totalScore = atomScore + beamScore;
//        });
        for (int i = 0; i < gameData['atoms'].length; i += 2) {
          thisGame.atoms.add(Atom(gameData['atoms'][i], gameData['atoms'][i + 1]));
        }
        print('Length of sent beams: ${(gameData['results']['${widget.resultPlayerId}']['sentBeams']).length}');
        for (int beam in gameData['results']['${widget.resultPlayerId}']['sentBeams']) {
          var result = thisGame.getBeamResult(inSlot: beam);
          // var result = thisGame.getBeamResult(beam: Beam(start: beam, widthOfPlayArea: width, heightOfPlayArea: height));
          thisGame.setEdgeTiles(inSlot: beam, beamResult: result);
        }
        if (gameData['results']['${widget.resultPlayerId}'].containsKey('playerAtoms')) {
          print('Key playerAtoms exists');
          playerAtoms = true;
          List<dynamic> sentPlayerAtoms = gameData['results']['${widget.resultPlayerId}']['playerAtoms'];
          for (int i = 0; i < sentPlayerAtoms.length; i += 2) {
            thisGame.playerAtoms.add([sentPlayerAtoms[i].toInt(), sentPlayerAtoms[i + 1].toInt()]);
          }
          print('Player atoms ${thisGame.playerAtoms}');
          thisGame.getAtomScore();  //Gets correct and incorrect atoms
        }

        print('Edge tile children: ${thisGame.edgeTileChildren}');
//        setState(() {
//          totalScore = thisGame.atomScore + thisGame.beamScore; //no!!
//          print('Total score $totalScore');
          resultsReady = true;
//          print('Results ready $resultsReady');
//        });
      }
    }
  }

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
      for (List<int> correctAtom in thisGame.correctAtoms) {
        if (ListEquality().equals([x, y], correctAtom)) {
          //correct Atom
          correct = true;
          print('Show atom is true');
        }
      }
      if (correct == false) {
        for (List<int> misplacedAtom in thisGame.misplacedAtoms) {
          if (ListEquality().equals([x, y], misplacedAtom)) {
            //misplaced Atom
            misplaced = true;
          }
        }
      }
      if (correct == false && misplaced == false) {
        for (List<int> missedAtom in thisGame.missedAtoms) {
          if (ListEquality().equals(Position(x, y).toList(), missedAtom)) {
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
    String resultPlayerScreenName = Provider
        .of<GameHubUpdates>(context)
        .providerUserIdMap
        .containsKey(widget.resultPlayerId)
        ? Provider
        .of<GameHubUpdates>(context)
        .providerUserIdMap[widget.resultPlayerId]
        : widget.resultPlayerId;
    return Scaffold(
      appBar: AppBar(title: Text('blackbox')),
      body: Column(
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
                  InfoText('Time played: $timePlayedString'), //TODO: Sort this!! (Put the timestamps into variables first)
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
            flex: 4,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  resultPlayerScreenName == 'Me'
                      ? 'My score'
                      : '$resultPlayerScreenName\'s score',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 35),
                ),
                Center(
                  child: Container(
                       // color: Colors.blue,
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
//                                  resultsReady ? '${thisGame.beamScore}' : '?', //no!
                                '${beamScore ?? '?'}',
                                textAlign: TextAlign.right,
                              ),
                            )),
                      ],
                    ),
                  ),
                ),
                Center(
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
//                              child: Text(resultsReady ? '${thisGame.atomScore}' : '?', textAlign: TextAlign.right),  //no!
                            child: Text('${atomScore ?? '?'}', textAlign: TextAlign.right),  //no!

                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Center(
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
//                                  resultsReady ? '${thisGame.beamScore + thisGame.atomScore}' : '?',
//                                  resultsReady ? '$totalScore' : '?',
//                                totalScore == null ? '?' : totalScore.toString(),
                              '${totalScore ?? '?'}',
                              textAlign: TextAlign.right,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 6,
            child: Column(
              children: <Widget>[
                SizedBox(
                    child: resultsReady ? playerAtoms ? Text('Answer:') : FittedBox(
                        fit: BoxFit.contain, child: Text('Player atom info not available. Beams played:')) : null,
                    height: 30),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
