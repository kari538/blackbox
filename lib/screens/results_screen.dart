import 'package:blackbox/play_screen_menu.dart';
import 'package:intl/intl.dart';
import 'package:blackbox/my_firebase_labels.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:blackbox/game_hub_updates.dart';
import 'package:provider/provider.dart';
import 'package:blackbox/units/small_widgets.dart';
import 'package:blackbox/board_grid.dart';
import 'package:blackbox/play.dart';
import 'package:flutter/material.dart';
import 'package:blackbox/constants.dart';
import 'package:blackbox/atom_n_beam.dart';

Timestamp? started;
Timestamp? finished;
Duration? timePlayed;
String startedString = 'N/A';
String finishedString = 'N/A';
String timePlayedString = 'N/A';

class ResultsScreen extends StatelessWidget {
  /// Constructor will give values to:
  /// startedString
  /// finishedString
  /// timePlayedString
  /// resultPlayerId = thisGame.playerUid;
  ResultsScreen(
      {required this.thisGame,
      required this.setupData,
      this.multiDisplay,
      this.altSol = false,
      /*this.beamsAndResults,*/ this.alternativeSolutions,
      /*this.playerMoves, */ this.playerMovesReview = false}) {
    // Constructor method:
    // setupData is {} if offline
    started = null;
    finished = null;
    timePlayed = null;
    startedString = 'N/A';
    finishedString = 'N/A';
    timePlayedString = 'N/A';
    // thisGame.getAtomScore(); // Moved to PlayScreen()
    String? resultPlayerId = thisGame.playerUid;
    print('resultPlayerId is $resultPlayerId');
    print(
        'setupData is $setupData and setupData.isNotEmpty is ${setupData.isNotEmpty}');
    if (thisGame.online) {
      started =
          setupData[kFieldResults][resultPlayerId][kSubFieldStartedPlaying];
      finished =
          setupData[kFieldResults][resultPlayerId][kSubFieldFinishedPlaying];
      if (finished != null) {
        finishedString =
            DateFormat('d MMM, HH:mm:ss').format(finished!.toDate());
        // It is possible that somebody updates the app between starting and finishing playing, thus getting a "finished" but not a "started" value...
        if (started != null) {
          startedString =
              DateFormat('d MMM, HH:mm:ss').format(started!.toDate());
          // timePlayed = finished.compareTo(started);
          // print("timePlayed is $timePlayed");
          // print('Type of timePlayed is ${timePlayed.runtimeType}');
          timePlayed = finished!.toDate().difference(started!.toDate());
          // timePlayed = DateTime(2021, 3, 1).difference(started.toDate()); // timePlayed is -58:22:05 when started was 3 Mar, 10:22 AM
          timePlayedString = timePlayed
              .toString()
              .substring(0, timePlayed.toString().length - 7);
          print('timePlayedString is $timePlayedString');
        }
      }
    }
  }

  final Play thisGame;
  final Map<String, dynamic> setupData;
  final List<int>? multiDisplay;
  final bool altSol;

  // final List beamsAndResults;
  final List<dynamic>? alternativeSolutions;

  // final List<dynamic>? playerMoves;
  final bool? playerMovesReview;

  //TODO: Will be called from "Player Moves" button on ResultsScreen and SentResultsScreen.
  ///Alternative\nsolutions should instead say "Player\moves".
  ///Then we go through the moves using the TestSetupsScrollWidget

  Widget getEdgeElement({required int x, required int y}) {
    // As I loop through rows and columns, I get an x and a y that need to be
    // converted into a slot number:
    int slotNo = Beam.convert(
        coordinates: Position(x, y),
        heightOfPlayArea: thisGame.heightOfPlayArea,
        widthOfPlayArea: thisGame.widthOfPlayArea)!;
    return Expanded(
      child: Container(
        child: Center(
            // If the slot has a beam, display that, otherwise display slot no:
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

  /// If called from Review moves, middle element child will be the same as in
  /// FollowPlayingScreen. Otherwise they will be as in ResultsScreen.
  Widget getMiddleElement({required int x, required int y}) {
    bool correct = false;
    bool misplaced = false;
    bool missed = false;

    // If still in play (called from Review moves):
    bool unfound = false;
    bool wronglyPlaced = false;
    bool showMarkup = false;

    // Correct atoms:
    // for (List<int> correctAtom in thisGame.correctAtoms) {
    for (Atom correctAtom in thisGame.correctAtoms) {
//      if (ListEquality().equals(Position(x, y).toList(), correctAtom)) {
      if (ListEquality().equals([x, y], correctAtom.position.toList())) {
        //correct Atom
        correct = true;
        // print('Show atom is true');
      }
    }

    // Misplaced atoms:
    if (correct == false) {
      // for (List<int> misplacedAtom in thisGame.misplacedAtoms){
      for (Atom misplacedAtom in thisGame.misplacedAtoms) {
        if (ListEquality().equals([x, y], misplacedAtom.position.toList())) {
          //misplaced Atom
          misplaced = true;
        }
      }
    }

    // Missed atoms:
    if (correct == false && misplaced == false) {
      // for (List<int> missedAtom in thisGame.missedAtoms){
      for (Atom missedAtom in thisGame.missedAtoms) {
        if (ListEquality().equals([x, y], missedAtom.position.toList())) {
          //missed Atom
          missed = true;
        }
      }
    }

    // Unfound atoms:
    if (correct == false && misplaced == false && missed == false) {
      for (Atom missedAtom in thisGame.unfoundAtoms) {
        if (ListEquality().equals([x, y], missedAtom.position.toList())) {
          //unfound Atom
          unfound = true;
        }
      }
    }

    // Not yet correctly placed atoms:
    if (correct == false &&
        misplaced == false &&
        missed == false &&
        unfound == false) {
      for (Atom notYetCorrectAtom in thisGame.notYetCorrectAtoms) {
        if (ListEquality()
            .equals([x, y], notYetCorrectAtom.position.toList())) {
          //Wrongly placed Atom
          wronglyPlaced = true;
        }
      }
    }

    // Markup:
    for (List<int> markup in thisGame.markUpList) {
      if (ListEquality().equals([x, y], markup)) {
        // markup
        showMarkup = true;
      }
    }


    return Expanded(
      child: Container(
        child: Stack(
          children: [
            Center(
              child: correct
                  ? Image(image: AssetImage('images/atom_yellow.png'))
                  : misplaced
                      ? Image(image: AssetImage('images/atom_redwcross.png'))
                      : missed
                          ? Opacity(
                              child:
                                  Image(image: AssetImage('images/atom_blue.png')),
                              opacity: 0.8)
                          : unfound
                              ? Opacity(
                                  child: Image(
                                      image: AssetImage('images/atom_blue.png')),
                                  opacity: 0.8)
                              : wronglyPlaced
                                  ? Opacity(
                                      child: Image(
                                          image:
                                              AssetImage('images/atom_yellow.png')),
                                      opacity: 0.5)
                                  : FittedBox(
                                      fit: BoxFit.contain,
                                      child: Text(
                                        '$x,$y',
                                        style: TextStyle(
                                            color: kBoardTextColor, fontSize: 15),
                                      ),
                                    ),
            ),
            showMarkup
                ? Image(image: AssetImage('images/markup.png'))
                : SizedBox()
          ],
        ),
        decoration: BoxDecoration(
            color: kBoardColor,
            border: Border.all(color: kBoardGridLineColor, width: 0.5)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // print('playerMovesReview is $playerMovesReview');
    return Scaffold(
      appBar: AppBar(
        title: Text('blackbox'),
        actions: thisGame.online
            ? [SizedBox()]
            : [
                PlayScreenMenu(thisGame, entries: [4])
              ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                            InfoText(
                                'By ${Provider.of<GameHubUpdates>(context).getScreenName(setupData[kFieldSender])}'),
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

                      // thisGame.online ? Column(
                      //   children: [
                      //     Row(
                      //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      //       children: [
                      //         // Text('online')
                      //         InfoText('Setup no ${setupData['i']}'),
                      //         // InfoText('Started: ${setupData[kFieldPlaying][playingId][kSubFieldStartedPlaying] != null ? setupData[kFieldPlaying][playingId][kSubFieldStartedPlaying].toDate() : 'N/A'}'),
                      //       ],
                      //     ),
                      //     Row(
                      //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      //       children: [
                      //         InfoText('By ${Provider.of<GameHubUpdates>(context).getScreenName(setupData[kFieldSender])}'),
                      //         // InfoText('Last move: ${setupData[kFieldPlaying][playingId][kSubFieldLatestMove] != null ? setupData[kFieldPlaying][playingId][kSubFieldLatestMove].toDate() : 'N/A'}'),
                      //       ],
                      //     ),
                    ],
                  )
                : SizedBox(/*child: Text('offline')*/),
            Expanded(
              // flex: altSol ? testing != null ? 2 : 3 : 4,
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
                          multiDisplay == null
                              ? 'Your score'
                              : playerMovesReview != true
                                  ? 'Alternative\nsolutions'
                                  : 'Player\nmoves',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 35),
                        ),
                        multiDisplay == null
                            ? Center(
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
                                            '${thisGame.beamScore}',
                                            textAlign: TextAlign.right,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : SizedBox(),
                        multiDisplay == null
                            ? Center(
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
                                          child: Text('${thisGame.atomScore} ',
                                              textAlign: TextAlign.right),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : SizedBox(),
                        multiDisplay == null
                            ? Center(
                                child: Container(
//                        color: Colors.blue,
                                  width: 200,
                                  child: Row(
                                    children: <Widget>[
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          'total:',
                                          //${(thisGame.beamScore + thisGame.atomScore) < 10 ? ' ' : ''}
                                          textAlign: TextAlign.right,
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      Expanded(
                                        child: Padding(
                                          padding: EdgeInsets.only(right: 26.0),
                                          child: Text(
                                            '${thisGame.beamScore + thisGame.atomScore}',
                                            textAlign: TextAlign.right,
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : SizedBox(),
                      ],
                    ),
                    altSol ? SizedBox(height: 30) : SizedBox(),
                    altSol
                        ? Text(
                            'Multiple solutions exist!',
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue),
                          )
                        : SizedBox(),
                  ],
                ),
              ),
            ),
            //Scaffold, Center, Column, Expanded, Padding, AspectRatio, Container, Board (returns Column)
            Expanded(
              flex: 6,
              child: Column(
                children: <Widget>[
                  multiDisplay == null
                      ? SizedBox(child: Text('The correct answer:'), height: 30)
                      : SizedBox(height: 30),
                  Expanded(
                    child: Padding(
//              child: Padding(
                      padding: const EdgeInsets.only(
                          left: 8.0, top: 8.0, right: 8.0, bottom: 10),
                      child: AspectRatio(
                        aspectRatio: (thisGame.widthOfPlayArea + 2) /
                            (thisGame.heightOfPlayArea + 2),
                        child: Container(
                          child: BoardGrid(
                              playWidth: thisGame.widthOfPlayArea,
                              playHeight: thisGame.heightOfPlayArea,
                              getEdgeTiles: getEdgeElement,
                              getMiddleTiles: getMiddleElement),
//                          child: Column(
//                            verticalDirection: VerticalDirection.up,
//                            children: boardRows(playWidth: thisGame.widthOfPlayArea, playHeight: thisGame.heightOfPlayArea),
//                          ),
                        ),
                      ),
                    ),
                  ),
                  altSol
                      ? Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: MyRaisedButton(
                            // child: ElevatedButton(
                            child: Text('View other solutions'),
                            onPressed: () async {
                              int? result = 0;
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
                                displayGame = alternativeSolutions![gameNo];
                                displayGame.edgeTileChildren =
                                    alternativeSolutions![0];
                                print(
                                    'alternativeSolutions[$gameNo] is ${alternativeSolutions![gameNo]}');
                                // Returns null if "Pop" is pressed:
                                result = await Navigator.push(context,
                                    PageRouteBuilder(
                                        pageBuilder: (context, anim1, anim2) {
                                  return ResultsScreen(
                                      thisGame: displayGame,
                                      setupData: {},
                                      multiDisplay: [
                                        gameNo,
                                        alternativeSolutions!.length - 1
                                      ]);
                                }));
                                if (result != null &&
                                    gameNo + result > 0 &&
                                    gameNo + result <=
                                        alternativeSolutions!.length - 1)
                                  gameNo += result;
                                // displayGame.correctAtoms = [];
                                // i++;
                              } while (result != null /*&& i < 100*/);
                            },
                          ))
                      : SizedBox(),
                  // testing == null ? SizedBox() : TestSetupsScrollWidget(testing: testing),
                ],
              ),
            ),
            multiDisplay == null
                ? SizedBox()
                : TestSetupsScrollWidget(indexList: multiDisplay!, playerMovesReview: playerMovesReview == true,),
          ],
        ),
      ),
    );
  }
}

class TestSetupsScrollWidget extends StatelessWidget {
  const TestSetupsScrollWidget({
    Key? key,
    required this.indexList,
    required this.playerMovesReview,
  }) : super(key: key);

  final List<int>
      indexList; // First element has the current index. Second element has the total number of indexes.
  final bool playerMovesReview;
  final int moreRowsLimitSmall = 5; // If more than 10 indexes, make ±10 buttons
  final int moreRowsLimitBig =
      10; // If more than 100 indexes, make ±100 buttons

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        playerMovesReview
            ? Text("Move ${indexList[0]} (${indexList[1]})")
            : indexList[0] == 1
              ? Text('original setup')
              : Text('alternative solution'),
        // Text("Setup ${indexList![0]} (${indexList![1]})"),
        indexList[1] > moreRowsLimitBig
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // MyRaisedButton(
                  TextButton(
                      onPressed: () {
                        Navigator.pop(context, -moreRowsLimitBig);
                        // Navigator.pop(context, -100);
                      },
                      child: Row(
                        children: [
                          Icon(Icons.arrow_back_ios),
                          Text('-${moreRowsLimitBig}'),
                        ],
                      )),
                  // MyRaisedButton(
                  // // ElevatedButton(
                  //     child: Text('Pop'),
                  //     onPressed: () {
                  //       // Navigator.popUntil(context, (route) => route.isFirst);
                  //       Navigator.pop(context, null);
                  //     }),
                  TextButton(
                      onPressed: () {
                        Navigator.pop(context, moreRowsLimitBig);
                      },
                      child: Row(
                        children: [
                          Text('+${moreRowsLimitBig}'),
                          // Text('+100 '),
                          Icon(Icons.arrow_forward_ios),
                        ],
                      )),
                ],
              )
            : SizedBox(),
        indexList[1] > moreRowsLimitSmall
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                      onPressed: () {
                        Navigator.pop(context, -moreRowsLimitSmall);
                      },
                      child: Row(
                        children: [
                          Icon(Icons.arrow_back_ios),
                          Text('-${moreRowsLimitSmall}'),
                        ],
                      )),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context, moreRowsLimitSmall);
                    },
                    child: Row(
                      children: [
                        Text('+${moreRowsLimitSmall}'),
                        Icon(Icons.arrow_forward_ios),
                      ],
                    ),
                  ),
                ],
              )
            : SizedBox(),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
                onPressed: () {
                  Navigator.pop(context, -1);
                },
                child: Icon(Icons.arrow_back_ios)),
            TextButton(
                onPressed: () {
                  Navigator.pop(context, 1);
                },
                child: Icon(Icons.arrow_forward_ios))
          ],
        ),
      ],
    );
  }
}
