import 'package:blackbox/games_from_player_moves.dart';
import 'package:blackbox/my_firebase.dart';
import 'package:blackbox/units/small_functions.dart';
import 'package:blackbox/screens/results_screen.dart';
import 'package:intl/intl.dart';
import 'package:blackbox/my_firebase_labels.dart';
import 'package:blackbox/units/small_widgets.dart';
import 'package:flutter/material.dart';
import 'package:blackbox/board_grid.dart';
import 'package:blackbox/play.dart';
import 'package:blackbox/constants.dart';
import 'package:blackbox/atom_n_beam.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:blackbox/game_hub_updates.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';import 'package:provider/provider.dart';

/// Called from tapping a result or from automatically navigated from
/// FollowPlayingScreen(). When playing oneself, you instead go to the
/// ResultsScreen() in offline screens.
///
/// In both cases, setupData and resultPlayerId are both known. What
/// isn't known is multiple solutions, and for that reason, getScore()
/// needs to be run.
class SentResultsScreen extends StatefulWidget {
  SentResultsScreen({required Key key, required this.setupData, required this.resultPlayerId}) : super(key: key);
  final Map<String, dynamic> setupData;
  final String resultPlayerId;  //The ID associated with this result in the setup (whether name or code)

  @override
  _SentResultsScreenState createState() => _SentResultsScreenState(setupData, resultPlayerId);
}

class _SentResultsScreenState extends State<SentResultsScreen> {
  _SentResultsScreenState(this.setupData, this.resultPlayerId);

  final Map<String, dynamic> setupData;
  final String? resultPlayerId;  //The ID associated with this result in the setup (whether name or code)
  // FirebaseFirestore firestoreObject = FirebaseFirestore.instance;
  late Play thisGame;
  bool resultsReady = false;
  String errorMsg = '';
  // int beamScore;
  // int atomScore;
  int? totalScore;
  bool playerAtoms = false;
  bool awaitingData = false;
  Timestamp? started;
  Timestamp? finished;
  Duration? timePlayed;
  String startedString = 'N/A';
  String finishedString = 'N/A';
  String timePlayedString = 'N/A';
  bool altSol = false;
  /// First element is edgeTileChildren, other elements are Play objects:
  List<dynamic>? alternativeSolutions;
  List<dynamic>? multiDisplay;
  /// Will become true if there are moves to review:
  bool playerMovesReview = false;
  // bool playerMovesReview = true;

  bool showSpinner = true;
  int delayForSpinner = 500;  // milliseconds

  @override
  void initState() {
    super.initState();
    getThisGameData();
    // if (!(setupData[kFieldResults][resultPlayerId] is int)) {
    if (setupData[kFieldResults][resultPlayerId] is Map) {
      print('Entered finding start and finish times');
      started = setupData[kFieldResults][resultPlayerId][kSubFieldStartedPlaying];
      // started = Timestamp.fromDate(DateTime(2021, 3, 3, 22, 20));
      finished = setupData[kFieldResults][resultPlayerId][kSubFieldFinishedPlaying];
      print('Started is $started and finished is $finished');
      if (finished != null) {
        finishedString = DateFormat('d MMM, HH:mm:ss').format(finished!.toDate());
        // It is possible that somebody updates the app between starting and finishing playing, thus getting a "finished" but not a "started" value...
        if (started != null) {
          startedString = DateFormat('d MMM, HH:mm:ss').format(started!.toDate());
          // timePlayed = finished.compareTo(started);
          // print("timePlayed is $timePlayed");
          // print('Type of timePlayed is ${timePlayed.runtimeType}');
          timePlayed = finished!.toDate().difference(started!.toDate());
          // timePlayed = DateTime(2021, 3, 1).difference(started.toDate()); // timePlayed is -58:22:05 when started was 3 Mar, 10:22 AM
          timePlayedString = timePlayed.toString().substring(0, timePlayed.toString().length-7);
          print('timePlayedString is $timePlayedString');
        }
      }
    }
  }

  /// Giving thisGame values, and calculating new result and alternative solutions.
  void getThisGameData() async {
    await Future.delayed(Duration(milliseconds: delayForSpinner));  // To give spinner time to show...
    Map<String, dynamic> _setupData = widget.setupData;
    print('setupData.keys in SentResultsScreen is ${_setupData.keys}');
    print('setupData in SentResultsScreen is:');
    try {
      myPrettyPrint(_setupData);
    } catch (e) {
      print('Error in prettyJason: $e');
    }

    // if (setupData == null) {
    //   setState(() {
    //     errorMsg = 'Document contains no data';
    //     showSpinner = false;
    //   });
    // } else {
      int numberOfAtoms = (_setupData['atoms'].length / 2).toInt();
      print('number of atoms $numberOfAtoms');
      int width = _setupData['widthAndHeight'][0];
      int height = _setupData['widthAndHeight'][1];

      // Declaring thisGame and giving it values:
      thisGame = Play(numberOfAtoms: numberOfAtoms, heightOfPlayArea: height, widthOfPlayArea: width);
      thisGame.playerUid = resultPlayerId;

      if (_setupData.containsKey(kFieldShuffleA) && _setupData.containsKey(kFieldShuffleB)) {
        thisGame.beamImageIndexA = [];
        for (int i = 0; i < _setupData[kFieldShuffleA].length; i++){
          thisGame.beamImageIndexA!.add(_setupData[kFieldShuffleA][i]);
        }

        thisGame.beamImageIndexB = [];
        for (int i = 0; i < _setupData[kFieldShuffleB].length; i++){
          thisGame.beamImageIndexB!.add(_setupData[kFieldShuffleB][i]);
        }
      }

      // If a result is really old:
      if (_setupData['results']['${widget.resultPlayerId}'] is int) {
        // TODO: Instead of being so specific about when to give errorMsg, this should be the last option, after everything else failed!
        print('Player\'s result is an int');
       setState(() {
          totalScore = _setupData['results']['${widget.resultPlayerId}'];
          errorMsg = 'Detailed results data not available';
          showSpinner = false;
       });
       // Otherwise:
      } else {
       setState(() {
          // atomScore = setupData[kFieldResults][widget.resultPlayerId][kSubFieldA];
          // beamScore = setupData[kFieldResults][widget.resultPlayerId][kSubFieldB];
          // if (atomScore != null && beamScore != null) {
          //   totalScore = atomScore + beamScore;
          // }
         // TODO: Why stop spinner here?
          showSpinner = false;
       });

       // Getting setup atoms and sent beams:
        for (int i = 0; i < _setupData['atoms'].length; i += 2) {
          thisGame.atoms.add(Atom(_setupData['atoms'][i], _setupData['atoms'][i + 1]));
        }
        print('Length of sent beams: ${(_setupData['results']['${widget.resultPlayerId}']['sentBeams']).length}');
        for (int beam in _setupData['results']['${widget.resultPlayerId}']['sentBeams']) {
          var result = thisGame.sendBeam(inSlot: beam);
          // var result = thisGame.getBeamResult(beam: Beam(start: beam, widthOfPlayArea: width, heightOfPlayArea: height));
          // thisGame.setEdgeTiles(inSlot: beam, beamResult: result);
        }

        // If setup has player atoms, calculate a new result and alternative solutions:
        if (_setupData['results']['${widget.resultPlayerId}'].containsKey('playerAtoms')) {
          print('Key playerAtoms exists');
          playerAtoms = true;
          List<dynamic> sentPlayerAtoms = _setupData['results']['${widget.resultPlayerId}']['playerAtoms'];
          for (int i = 0; i < sentPlayerAtoms.length; i += 2) {
            thisGame.playerAtoms.add(Atom(sentPlayerAtoms[i].toInt(), sentPlayerAtoms[i + 1].toInt()));
          }
          print('Player atoms ${thisGame.playerAtoms}');

          //TODO: Upload the multiple solutions so they can just be downloaded again, rather than calculated anew each time:
          // bool upLoadedAltSol = setupData[kFieldResults][widget.resultPlayerId].containsKey(kSubFieldAlternativeSolutions);
          // if (upLoadedAltSol) {
          //   bool hasAltSol = setupData[kFieldResults][widget.resultPlayerId][kSubFieldAlternativeSolutions];
          //   if (hasAltSol) {
          //     // This setup states alternative solutions
          //     alternativeSolutions = alternativeSolutionsFromSetup();
          //   } else {
          //     // This setup explicitly states there are no alternative solutions
          //   }
          // }
          // To get correct, missed and misplaced atoms:
          // thisGame.rawAtomScore();  // This will overwrite atomScore. Hence the below:

          //TODO: If multiple solutions are not uploaded, this still needs to happen:
          alternativeSolutions = await thisGame.getScore();
          altSol = alternativeSolutions != null ? true : false;
          setState(() {
            print('setupData[kFieldResults][widget.resultPlayerId][kSubFieldA] is ${_setupData[kFieldResults][widget.resultPlayerId][kSubFieldA]}');
            print('setupData[kFieldResults][widget.resultPlayerId] is ${_setupData[kFieldResults][widget.resultPlayerId]}');
            print('setupData[kFieldResults] is ${_setupData[kFieldResults]}');
            thisGame.atomScore = _setupData[kFieldResults][widget.resultPlayerId][kSubFieldA] ?? thisGame.atomScore;
            thisGame.beamScore = _setupData[kFieldResults][widget.resultPlayerId][kSubFieldB] ?? thisGame.beamScore;
            totalScore = thisGame.atomScore+ thisGame.beamScore;
          });
        }

       if (_setupData['results']['${widget.resultPlayerId}'].containsKey(kFieldPlayerMoves)) {
         playerMovesReview = true;
       }

       print('Edge tile children: ${thisGame.edgeTileChildren}');
       setState(() {
         // TODO: Isn't this where spinner should stop?
//          totalScore = thisGame.atomScore + thisGame.beamScore; //no!!
//          print('Total score $totalScore');
          resultsReady = true;
//          print('Results ready $resultsReady');
       });
      }
    // }
  }

  List<dynamic> alternativeSolutionsFromSetup() {

    return [];
  }

  Widget getEdges({required int x, required int y}) {
    int slotNo = Beam.convert(coordinates: Position(x, y), heightOfPlayArea: thisGame.heightOfPlayArea, widthOfPlayArea: thisGame.widthOfPlayArea)!;
    return Expanded(
      child: Container(
        child: Center(
            child: thisGame.edgeTileChildren![slotNo - 1] ?? FittedBox(fit: BoxFit.contain, child: Text('$slotNo', style: TextStyle(color: kBoardEdgeTextColor, fontSize: 15)))),
        decoration: BoxDecoration(color: kBoardEdgeColor),
      ),
    );
  }

  Widget getMiddleElements({required int x, required int y}) {
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
        decoration: BoxDecoration(color: kBoardColor, border: Border.all(color: kBoardGridLineColor, width: 0.5)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    GameHubUpdates gameHubProviderListening = Provider.of<GameHubUpdates>(context);
    String? resultPlayerScreenName = gameHubProviderListening.userIdMap.containsKey(widget.resultPlayerId)
        ? gameHubProviderListening.userIdMap[widget.resultPlayerId]
        : widget.resultPlayerId;

    return Scaffold(
      appBar: AppBar(title: Text('blackbox')),
      body: SafeArea(
        child: ModalProgressHUD(
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
                        InfoText('By ${gameHubProviderListening.getScreenName(setupData[kFieldSender])}'),
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
                                        '${totalScore ?? '...'}',
                                        textAlign: TextAlign.right,
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ) : SizedBox(),
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
                    Row(
                      mainAxisAlignment: altSol == !playerMovesReview ? MainAxisAlignment.center : MainAxisAlignment.spaceEvenly,
                      children: [
                        altSol ?
                        Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: MyRaisedButton(
                              // child: ElevatedButton(
                              child: Text('View other solutions'),
                              onPressed: () async {
                                int? goTo = 0;  // The game to show when ResultScreen pops
                                int gameNo = 1; // The game currently being displayed
                                // int i = 0;
                                Play displayGame;

                                // Scroll through the solutions on each their screen:
                                do {
                                  displayGame = alternativeSolutions![gameNo];
                                  displayGame.edgeTileChildren = alternativeSolutions![0];  // First element is edgeTileChildren
                                  print('alternativeSolutions[$gameNo] is ${alternativeSolutions![gameNo]}');
                                  // Returns null if "Pop" is pressed:
                                  goTo = await Navigator.push(context, PageRouteBuilder(pageBuilder: (context, anim1, anim2) {
                                    return ResultsScreen(thisGame: displayGame, setupData: {}, multiDisplay: [gameNo, alternativeSolutions!.length-1]);
                                  }));
                                  if (goTo != null && gameNo + goTo > 0 && gameNo + goTo <= alternativeSolutions!.length-1) gameNo += goTo;
                                  // i++;
                                } while (goTo != null /*&& i < 100*/);
        
                              },
                            )
                        ) : SizedBox(),
                        playerMovesReview ?
                        Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: MyRaisedButton(
                              // child: ElevatedButton(
                              child: Text('Review moves'),
                              onPressed: () async {
                                int? goTo = 0;
                                int moveNo = 0;
                                // int i = 0;
                                // Play displayGame;
                                // Get player moves from results tag:
                                thisGame.playerMoves = setupData[kFieldResults]![widget.resultPlayerId]![kFieldPlayerMoves] ?? [];
                                // Overly careful - I actually shouldn't be here if there weren't any player moves...
                                print('thisGame.playerMoves in Review moves button is:');
                                myPrettyPrint(thisGame.playerMoves);
                                // print('thisGame.playerUid in Review moves button is ${thisGame.playerUid}');
                                // Play reviewGame;
                                Play reviewGame = Play(numberOfAtoms: thisGame.numberOfAtoms, widthOfPlayArea: thisGame.widthOfPlayArea, heightOfPlayArea: thisGame.heightOfPlayArea);
                                reviewGame.playerUid = thisGame.playerUid;
                                List<Play?> moveGames = [];
                                moveGames = gamesFromPlayerMoves(thisGame: thisGame);
                                // print('moveGames is $moveGames');
                                print('moveGames.length is ${moveGames.length}');
                                print('thisGame.playerMoves.length is ${thisGame.playerMoves.length}');

                                // Scroll through the moves on each their screen:
                                do {
                                  reviewGame = moveGames[moveNo] ?? Play(numberOfAtoms: thisGame.numberOfAtoms, widthOfPlayArea: thisGame.widthOfPlayArea, heightOfPlayArea: thisGame.heightOfPlayArea);
                                  print('Before pushing reviewGame, moveNo is $moveNo');
                                  // print('moveGames.length is ${moveGames.length} and moveGames[$moveNo] is ${moveGames[moveNo]}');
                                  // print('playerAtoms in reviewGame is ${reviewGame.playerAtoms}');
                                  // print('correctAtoms in reviewGame is ${reviewGame.correctAtoms}');
                                  // print('unfoundAtoms in reviewGame is ${reviewGame.unfoundAtoms}');
                                  print('The move for moveNo $moveNo is ${moveNo-1 < thisGame.playerMoves.length && moveNo-1 >= 0 ? thisGame.playerMoves[moveNo-1] : 'out of range'}');
                                  // Returns null if "Pop" is pressed:
                                  goTo = await Navigator.push(context, PageRouteBuilder(pageBuilder: (context, anim1, anim2) {
                                    return ResultsScreen(thisGame: reviewGame, setupData: {}, playerMovesReview: true, multiDisplay: [moveNo, moveGames.length-1],);
                                  }));
                                  if (goTo != null && moveNo + goTo >= 0 && moveNo + goTo < moveGames.length) moveNo += goTo;
                                  // print('thisGame.playerMoves.length is ${thisGame.playerMoves.length}');
                                  // print('moveGames.length is ${moveGames.length}');
                                  print('goTo is $goTo');
                                  print('moveNo is $moveNo');
                                  // displayGame.correctAtoms = [];
                                  // i++;
                                } while (goTo != null /*&& i < 100*/);

                              },
                            )
                        ) : SizedBox(),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
