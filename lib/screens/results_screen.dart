import 'package:intl/intl.dart';
import 'package:blackbox/my_firebase_labels.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:blackbox/game_hub_updates.dart';
import 'package:provider/provider.dart';
import 'package:blackbox/units/small_widgets.dart';
import 'package:blackbox/board_grid.dart';
import 'package:blackbox/play.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:blackbox/constants.dart';
import 'package:blackbox/atom_n_beam.dart';
import 'package:collection/collection.dart';

Timestamp started;
Timestamp finished;
Duration timePlayed;
String startedString = 'N/A';
String finishedString = 'N/A';
String timePlayedString = 'N/A';

class ResultsScreen extends StatelessWidget {
  ResultsScreen({@required this.thisGame, @required this.setupData, this.testing}) {
    // setupData is {} if offline
    started = null;
    finished = null;
    timePlayed = null;
    startedString = 'N/A';
    finishedString = 'N/A';
    timePlayedString = 'N/A';
    thisGame.getAtomScore();
    String resultPlayerId = thisGame.playerId;
    print('resultPlayerId is $resultPlayerId');
    print('setupData is $setupData and setupData.isNotEmpty is ${setupData.isNotEmpty}');
    if (thisGame.online) {
      started = setupData[kFieldResults][resultPlayerId][kSubFieldStartedPlaying];
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
          timePlayedString = timePlayed.toString().substring(0, timePlayed.toString().length - 7);
          print('timePlayedString is $timePlayedString');
        }
      }
    }
  }

  final List<int> testing;
  final Play thisGame;
  final Map<String, dynamic> setupData;

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
    bool correct = false;
    bool misplaced = false;
    bool missed = false;

    for (List<int> correctAtom in thisGame.correctAtoms) {
//      if (ListEquality().equals(Position(x, y).toList(), correctAtom)) {
      if (ListEquality().equals([x, y], correctAtom)) {
        //correct Atom
        correct = true;
        print('Show atom is true');
      }
    }
    if (correct==false) {
      for (List<int> misplacedAtom in thisGame.misplacedAtoms){
        if (ListEquality().equals([x, y], misplacedAtom)) {
          //misplaced Atom
          misplaced = true;
        }
      }
    }
    if (correct==false && misplaced==false) {
      for (List<int> missedAtom in thisGame.missedAtoms){
        if (ListEquality().equals([x, y], missedAtom)) {
          //missed Atom
          missed = true;
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
    return Scaffold(
      appBar: AppBar(title: Text('blackbox')),
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
                flex: testing == null ? 4 : 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      'Your score',
                      style: TextStyle(fontSize: 35),
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
                                child: Text('${thisGame.atomScore} ', textAlign: TextAlign.right),
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
                                  '${thisGame.beamScore + thisGame.atomScore}',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                )),
            //Scaffold, Center, Column, Expanded, Padding, AspectRatio, Container, Board (returns Column)
            Expanded(
              flex: 6,
              child: Column(
                children: <Widget>[
                  SizedBox(child: Text('The correct answer:'), height: 30),
                  Expanded(
                    child: Padding(
//              child: Padding(
                      padding: const EdgeInsets.only(left: 8.0, top: 8.0, right: 8.0, bottom: 20),
                      child: AspectRatio(
                        aspectRatio: (thisGame.widthOfPlayArea + 2) / (thisGame.heightOfPlayArea + 2),
                        child: Container(
                          child: BoardGrid(
                              playWidth: thisGame.widthOfPlayArea,
                              playHeight: thisGame.heightOfPlayArea,
                              getEdgeTiles: getEdges,
                              getMiddleTiles: getMiddleElements),
//                          child: Column(
//                            verticalDirection: VerticalDirection.up,
//                            children: boardRows(playWidth: thisGame.widthOfPlayArea, playHeight: thisGame.heightOfPlayArea),
//                          ),
                        ),
                      ),
                    ),
                  ),
                  testing == null ? SizedBox() : Column(
                    children: [
                      Text("Setup ${testing[0]} (${testing[1]})"),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                              onPressed: () {
                                Navigator.pop(context, -100);
                              },
                              child: Row(
                                children: [
                                  Icon(Icons.arrow_back_ios),
                                  Text('-100'),
                                ],
                              )),
                          ElevatedButton(
                              child: Text('Pop'),
                              onPressed: () {
                                // Navigator.popUntil(context, (route) => route.isFirst);
                                Navigator.pop(context, null);
                              }),
                          TextButton(
                              onPressed: () {
                                Navigator.pop(context, 100);
                              },
                              child: Row(
                                children: [
                                  Text('+100'),
                                  Icon(Icons.arrow_forward_ios),
                                ],
                              )),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                              onPressed: () {
                                Navigator.pop(context, -10);
                              },
                              child: Row(
                                children: [
                                  Icon(Icons.arrow_back_ios),
                                  Text('-10'),
                                ],
                              )),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context, 10);
                            },
                            child: Row(
                              children: [
                                Text('+10'),
                                Icon(Icons.arrow_forward_ios),
                              ],
                            ),
                          ),
                        ],
                      ),
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
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//Old version:
//********************************************************************************************************************
//class ResultsScreen extends StatelessWidget {
//  ResultsScreen({@required this.thisGame});
//
//  final Play thisGame;
//
//  Widget getCorners() {
////    return Expanded(child: Container(decoration: BoxDecoration(color: Colors.pink, border: Border.all(color: Colors.white)),));
//    return Expanded(
//        child: Container(
//          color: kBoardEdgeColor,
//        ));
//  }
//
//  Widget getEdges({int x, int y, @required int heightOfPlayArea, @required int widthOfPlayArea}) {
////    int slotNo = myBeam.convert({'x': element, 'y': row});
//    int slotNo = Beam.convert(coordinates: Position(x, y), heightOfPlayArea: heightOfPlayArea, widthOfPlayArea: widthOfPlayArea);
//    return Expanded(
//      child: Container(
//        child: Center(child: thisGame.edgeTileChildren[slotNo-1] ?? Text('$slotNo', style: TextStyle(color: kBoardEdgeTextColor))),
//        decoration: BoxDecoration(color: kBoardEdgeColor),
//      ),
//    );
//  }
//
//  Widget getMiddleElements({int x, int y, bool showAtom}) {
//    return Expanded(
//      child: Container(
//        child: Center(
//          child: showAtom ? Image(image: AssetImage('images/atom_yellow.png')) : Text('$x,$y', style: TextStyle(color: kBoardTextColor)),
//        ),
//        decoration: BoxDecoration(color: kBoardColor, border: Border.all(color: kBoardGridlineColor, width: 0.5)),
//      ),
//    );
//  }
//
//
//
//
//  List<Widget> boardRows({int playWidth, int playHeight}) {
//    int numberOfRows = playHeight + 2;
//    int numberOfElements = playWidth + 2;
//    List<Widget> boardRows = []; //List of Rows
//    List<List<Widget>> allElements = List<List<Widget>>(numberOfRows); //2D List of row elements (Widgets)
//
//    for (int row = 0; row < numberOfRows; row++) {
////      print('row is $row');
//      allElements[row] = List<Widget>(numberOfElements);
//      for (int element = 0; element < numberOfElements; element++) {
////        print('element is $element');
//        //Corners:
//        if (element == 0 && (row == 0 || row == numberOfRows - 1) || element == numberOfElements - 1 && (row == 0 || row == numberOfRows - 1)) {
//          allElements[row][element] = getCorners();
//          //Other edges:
//        } else if (row == 0 || row == numberOfRows - 1 || element == 0 || element == numberOfElements - 1) {
//          allElements[row][element] = getEdges(x: element, y: row, heightOfPlayArea: thisGame.heightOfPlayArea, widthOfPlayArea: thisGame.widthOfPlayArea);
//        } else {
//          //Middle rows, middle elements:
//          bool showAtom = false;
//          for (Atom atom in thisGame.atoms) {
//            if (ListEquality().equals(Position(element, row).toList(), atom.position.toList())) {
//              showAtom = true;
////              showAtom = false; //Why would I want it to show the secret setup??
////              print('Show atom is true');
//            }
//          }
//          if (showAtom) print('Getting element $element,$row with showAtom as $showAtom');
//          allElements[row][element] = getMiddleElements(x: element, y: row, showAtom: showAtom);
//        }
//      }
////      print('Adding Row of allElements to boardRows');
//      boardRows.add(
//        Expanded(
//          child: Row(
//            crossAxisAlignment: CrossAxisAlignment.stretch,
//            children: allElements[row],
//          ),
//        ),
//      );
////      print('boardRows: $boardRows');
//    }
//    return boardRows;
//  }
//
//  @override
//  Widget build(BuildContext context) {
//    return Scaffold(
//      appBar: AppBar(title: Text('blackbox')),
//      body: Center(
////          child: Container(
////            child: Text('Oh, just shoot all the beams until you know!...'),
////          ),
//        child: Column(
//          mainAxisAlignment: MainAxisAlignment.spaceBetween,
//          children: <Widget>[
//            SizedBox(),
//            Text('Your score: ${thisGame.score}'),
//            Column(
//              children: <Widget>[
//                Text('The correct answer:'),
//                Padding(
//                  padding: const EdgeInsets.only(left: 8.0, top: 8.0, right: 8.0, bottom: 20),
//                  child: AspectRatio(
//                    aspectRatio: 1,
//                    child: Container(
//                      child: Column(
//                        verticalDirection: VerticalDirection.up,
//                        children: boardRows(playWidth: thisGame.widthOfPlayArea, playHeight: thisGame.heightOfPlayArea),
//                      ),
//                    ),
//                  ),
//                ),
//              ],
//            ),
//          ],
//        ),
//      ),
//    );
//  }
//}
//***********************************************************************************************
