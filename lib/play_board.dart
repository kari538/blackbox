//import 'package:blackbox/play_screen.dart';
import 'package:blackbox/firestore_lables.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'atom_n_beam.dart';
import 'constants.dart';
import 'package:collection/collection.dart';
import 'my_firebase_labels.dart';
import 'play.dart';
import 'board_grid.dart';
import 'my_firebase.dart';

class PlayBoard extends StatefulWidget {
  PlayBoard({this.playWidth, this.playHeight, this.numberOfAtoms, this.thisGame, this.setup, this.refreshParent});

  final int playWidth;
  final int playHeight;
  final int numberOfAtoms;
  final Play thisGame;
  final Function refreshParent;
  final DocumentSnapshot setup;

  @override
  _PlayBoardState createState() => _PlayBoardState(playWidth, playHeight, numberOfAtoms, thisGame, setup, refreshParent);
}

class _PlayBoardState extends State<PlayBoard> {
  _PlayBoardState(this.playWidth, this.playHeight, this.numberOfAtoms, this.thisGame, this.setup, this.refreshParent);

  //Since it gets thisGame, it doesn't actually need the other stuff!... It's the same info twice!
  final int playWidth;
  final int playHeight;
  final int numberOfAtoms;
  final Play thisGame;
  final Function refreshParent;
  final DocumentSnapshot setup;


//  Widget getMiddleElements({int x, int y, bool showAtom = false}) {
  Widget getMiddleElements({int x, int y}) {
    bool showAtom = false;
    bool showClear = false;
//    bool receivedAtom = false;
    if (thisGame.showAtomSetting) {
      for (Atom atom in thisGame.atoms) {
        if (ListEquality().equals([x, y], atom.position.toList())) {
          showAtom = true;
        }
      }
    }
    for(Atom playerAtom in thisGame.playerAtoms){
    // for(List<int> playerAtom in thisGame.playerAtoms){
//    for(List<int> playerAtom in thisGame.receivedPlayingAtoms){
      if(ListEquality().equals([x,y], playerAtom.position.toList())){
        showAtom = true;
//        receivedAtom = true;
      }
    }

    for (List<int> clear in thisGame.clearList){
      if (ListEquality().equals([x, y], clear)) showClear = true;
    }

    return PlayBoardTile(position: Position(x, y), showAtom: showAtom, showClear: showClear, /*receivedAtom: receivedAtom,*/ thisGame: thisGame, setup: setup, refreshParent: refreshParent);
//    return PlayBoardTile(x, y);
  }

//  Widget getEdges(int row, int element) {
  Widget getEdges({int x, int y}) {
//    int slotNo = myBeam.convert({'x': element, 'y': row});
    int slotNo = Beam.convert(coordinates: Position(x, y), heightOfPlayArea: thisGame.heightOfPlayArea, widthOfPlayArea: thisGame.widthOfPlayArea);
    return Expanded(
      child: GestureDetector(
        child: Container(
          child: Center(child: thisGame.edgeTileChildren[slotNo - 1] ?? FittedBox(
        fit: BoxFit.contain, child: Text('$slotNo', style: TextStyle(color: kBoardEdgeTextColor, fontSize: 15)))),
          decoration: BoxDecoration(color: kBoardEdgeColor),
        ),
        onTap: thisGame.edgeTileChildren[slotNo - 1] != null ? null : () async {
                dynamic result = thisGame.getBeamResult(inSlot: slotNo);
                // dynamic result = thisGame.getBeamResult(
                //   beam: Beam(start: slotNo, widthOfPlayArea: thisGame.widthOfPlayArea, heightOfPlayArea: thisGame.heightOfPlayArea),
                // );
                thisGame.setEdgeTiles(inSlot: slotNo, beamResult: result);
                setState(() {});
                refreshParent();
                if(thisGame.online){
                  MyFirebase.storeObject.collection(kSetupCollection).doc(setup.id).update({
                    'playing.${thisGame.playerId}.playingBeams': thisGame.sentBeams,
                    'playing.${thisGame.playerId}.$kSubFieldLatestMove': FieldValue.serverTimestamp(),
                    } //The dots take me down in the nested map.
                  );
//                DocumentSnapshot x = await  MyFirebase.storeObject.collection('setups').doc(setup.id).get();
//                Map<String, dynamic> updatedAtomSetup = x.data();
                  print('************************\nEdge element pressed. The sent beam is $slotNo\n************************');
                }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BoardGrid(playWidth: thisGame.widthOfPlayArea, playHeight: thisGame.heightOfPlayArea, getEdgeTiles: getEdges, getMiddleTiles: getMiddleElements);
  }
}

//-----------------------------------------------------------------------------------------------------
//TODO: Make Stateless:
//PlayBoardTile Stateful Widget:
class PlayBoardTile extends StatefulWidget {
  PlayBoardTile({this.position, this.showAtom, @required this.showClear, /*this.receivedAtom,*/ @required this.thisGame, this.setup, this.refreshParent});

  final Position position;
  final bool showAtom;
  final bool showClear;
//  final bool receivedAtom;
  final Play thisGame;
  final DocumentSnapshot setup;
  final Function refreshParent;

  @override
  _PlayBoardTileState createState() => _PlayBoardTileState(position, showAtom, showClear, thisGame, setup);
}

class _PlayBoardTileState extends State<PlayBoardTile> {
  _PlayBoardTileState(this.position, this.showAtom, this.showClear, this.thisGame, this.setup){
    thisAtomCoordinates=position.toList();
//    if(receivedAtom){
//      thisGame.playerAtoms.add(thisAtomCoordinates);
//    }
  }

  bool showAtom;
  bool showClear;
//  bool receivedAtom;
  final Position position;
  final Play thisGame;
  final DocumentSnapshot setup;
  List<int> thisAtomCoordinates;

  @override
  Widget build(BuildContext context) {
//    print('Building tile ${position.toList()} with showAtom as $showAtom');
    return Expanded(
      child: GestureDetector(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
              child: Center(
                child: showAtom ? Image(image: AssetImage('images/atom_yellow.png')) : FittedBox(
                    fit: BoxFit.contain, child: Text('${position.x},${position.y}', style: TextStyle(color: kBoardTextColor, fontSize: 15))),
              ),
              decoration: BoxDecoration(color: kBoardColor, border: Border.all(color: kBoardGridlineColor, width: 0.5)),
            ),
              showClear
                  ? Image(image: AssetImage('images/clear.png'))
                  : SizedBox()
            ],
          ),
          onTap: () async {
//            print('Button ${position.toList()} was pressed');
            if(showAtom==false){
              //This box didn't have an atom before
              setState(() {
                showAtom = true;
              });
              print('Adding ${position.toList()}');
              thisGame.playerAtoms.add(Atom(thisAtomCoordinates[0], thisAtomCoordinates[1]));
              print('Player atoms list in PlayBoard is ${thisGame.playerAtoms}');
            } else {
              //This box had an atom before
              setState(() {
                showAtom = false;
              });
              print('Removing $thisAtomCoordinates');
              //This worked so wonderfully, but if atoms were sent rather than added from here, they will not be removed... unless I add them from here as well!
//              thisGame.playerAtoms.remove(thisAtomCoordinates);
              int removeIndex;
              int i = 0;
              // for(List<int> playerAtom in thisGame.playerAtoms){
              for(Atom playerAtom in thisGame.playerAtoms){
                if(ListEquality().equals(thisAtomCoordinates, playerAtom.position.toList())){
                  removeIndex = i;
                }
                i++;
              }
              if(removeIndex!=null) thisGame.playerAtoms.removeAt(removeIndex);
              print('Player atoms list is ${thisGame.playerAtoms}');
            }
            if(thisGame.online){
              //Because Firebase can't stomach a List<List<int>>:
              //Put player atoms in array to send:
              List<int> playingAtomsArray = [];
              print("thisGame.playerAtoms are ${thisGame.playerAtoms}");
              // for (List<int> pAtom in thisGame.playerAtoms) {
              for (Atom pAtom in thisGame.playerAtoms) {
                playingAtomsArray.add(pAtom.position.x);
                playingAtomsArray.add(pAtom.position.y);
                // playingAtomsArray.add(pAtom[0]);
                // playingAtomsArray.add(pAtom[1]);
              }
              print("playingAtomsArray is $playingAtomsArray\n+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++");
              MyFirebase.storeObject.collection('setups').doc(setup.id).update({
                'playing.${thisGame.playerId}.playingAtoms': playingAtomsArray,
                'playing.${thisGame.playerId}.$kSubFieldLatestMove': FieldValue.serverTimestamp(),
              } //The dots should take me down in the nested map...
              );
              DocumentSnapshot y = await  MyFirebase.storeObject.collection('setups').doc(setup.id).get();
              Map<String, dynamic> updatedAtomSetup = y.data();
              print('************************\nMiddle element pressed. updatedAtomSetup is $updatedAtomSetup\n************************');
            }
            //Toggling showAtom below meant that atoms would be added several times if a person clicked quickly, especially if their network was slow.
//            setState(() {
//              showAtom = showAtom ? false : true;
//            });
            widget.refreshParent();
          },
        onLongPress: () async {
          print('long press');

          if (thisGame.online){
            if (!showClear) thisGame.clearList.add(thisAtomCoordinates);
            else {
              int removeIndex;
              for (int i=0; i < thisGame.clearList.length; i++){
                if (ListEquality().equals(thisAtomCoordinates, thisGame.clearList[i])) {
                  removeIndex = i;
                  break;
                }
              }
              if (removeIndex != null) thisGame.clearList.removeAt(removeIndex);
            }
            List<int> clearArray = [];
            for (List<int> clear in thisGame.clearList){
              clearArray.add(clear[0]);
              clearArray.add(clear[1]);
            }
            await MyFirebase.storeObject.collection(kCollectionSetups).doc(setup.id).update({
              'playing.${thisGame.playerId}.$kSubFieldClearList': clearArray,
            });
          }

          setState(() {
            showClear = !showClear;
          });
        },
      ),
    );
  }
}
//-----------------------------------------------------------------------------------------------------

//Old version between the pluses, to copy-paste into the state:
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//  List<Widget> boardRows({int playWidth, int playHeight}) {
//    int numberOfRows = playHeight + 2;
//    int numberOfElements = playWidth + 2;
//    List<Widget> boardRows = []; //List of Rows
////    List<List<Widget>> allElements = List<List<Widget>>(numberOfRows); //2D List of row elements, which are Widgets
//    List<List<Widget>> allElements = List.generate(numberOfRows, (int i) => List<Widget>(numberOfElements), growable: false);
//
//    for (int row = 0; row < numberOfRows; row++) {
////      print('row is $row');
////      allElements[row] = List<Widget>(numberOfElements);
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
////              showAtom = true;
////              showAtom = false; //Why would I want it to show the secret setup??
//              showAtom = thisGame.showAtomSetting;
////              print('Show atom is true');
//            }
//          }
////          if (showAtom) print('Getting element $element,$row with showAtom as $showAtom');
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
//    return Column(
//      verticalDirection: VerticalDirection.up,
//      children: boardRows(playWidth: playWidth, playHeight: playHeight),
//    );
//  }
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
