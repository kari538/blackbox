//import 'package:flutter/cupertino.dart';
import 'atom_n_beam.dart';
import 'package:collection/collection.dart';
import 'dart:math';

//import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
//import 'package:meta/meta.dart';

///-----------------------------------------------
///-----------------------------------------------
///-----------------------------------------------
class Play {
//  Play(this.atoms);
//  Play({@required this.numberOfAtoms=4, @required this.heightOfPlayArea=8, @required this.widthOfPlayArea=8}){
  Play({@required this.numberOfAtoms, @required this.widthOfPlayArea, @required this.heightOfPlayArea, this.showAtomSetting = false}) {
//    edgeTileNumbers = List<int>((heightOfPlayArea + widthOfPlayArea) * 2);
    edgeTileChildren = List<Widget>.filled((heightOfPlayArea + widthOfPlayArea) * 2, null);
    beamImages = [
      Image(image: AssetImage('images/beam_blue.png')),
      Image(image: AssetImage('images/beam_green.png')),
      Image(image: AssetImage('images/beam_pink.png')),
      Image(image: AssetImage('images/beam_grey.png')),
      Image(image: AssetImage('images/beam_orange.png')),
      Image(image: AssetImage('images/beam_aqua.png')),
      Image(image: AssetImage('images/beam_purple.png')),
      Image(image: AssetImage('images/beam_red.png')),
      Image(image: AssetImage('images/beam_rose.png')),
      Image(image: AssetImage('images/beam_violet.png')),
      Image(image: AssetImage('images/beam_white.png')),
      Image(image: AssetImage('images/beam_brown.png')),
    ];
    beamImages.shuffle();
  }

  int numberOfAtoms;
  bool showAtomSetting;
  int widthOfPlayArea;
  int heightOfPlayArea;
  List<Atom> atoms = [];
//  List<List<int>> receivedPlayingAtoms = [];
  List<List<int>> playerAtoms = [];
  List<List<int>> correctAtoms = [];
  List<List<int>> misplacedAtoms = [];
  List<List<int>> missedAtoms = [];
  int beamCount = 0;
  int beamScore = 0;
  int atomScore = 0;
  List<int> sentBeams = [];
  List<Widget> edgeTileChildren;
  List<Widget> beamImages;
  bool online = false;
  String playerScreenName = 'Screen name';
  String playerId;
  Map<String, dynamic> setupData;

  void getAtomsRandomly() {
    print('Getting atoms randomly');
    Random coord = Random();
    int i = 0;
    do {
      List<int> newbie = [
        coord.nextInt(widthOfPlayArea) + 1,
        coord.nextInt(heightOfPlayArea) + 1,
      ];
//      print('atoms is $atoms');
      bool newbieApproved = true;
      for (Atom atom in atoms) {
        if (ListEquality().equals(newbie, atom.position.toList())) {
//          print('newbie equals an oldie atom: Not approved');
          newbieApproved = false;
        }
      }
      if (newbieApproved) {
        atoms.add(Atom(newbie[0], newbie[1]));
//        print('Adding atom');
      }
      i++;
//      print('Running while, atoms.length is ${atoms.length} and i is $i');
    } while (atoms.length < numberOfAtoms && i < 100);
//    return atoms;
  }

//  dynamic getBeamResult({@required Beam beam, @required int widthOfPlayArea, @required int heightOfPlayArea}) {
//   dynamic getBeamResult({@required Beam beam}) {
  dynamic getBeamResult({@required int inSlot}) {
    Beam beam = Beam(start: inSlot, widthOfPlayArea: widthOfPlayArea, heightOfPlayArea: heightOfPlayArea);
    dynamic beamResult(){
      dynamic result = 'no result was found';
      sentBeams.add(beam.start);
      do {
        // print('--------------------------');
        beam.projectedPosition.x = beam.position.x + beam.direction.xDir;
        beam.projectedPosition.y = beam.position.y + beam.direction.yDir;
//      print('Beam position is ${beam_1.position} and atom position is ${balls.position}\n'
//      print('${[position.x, position.y]}==${[ball_1.position.x, ball_1.position.y]}');
//      if([position.x, position.y]==[ball_1.position.x, ball_1.position.y]){ //dnw
        for (int x = -1; x <= 1; x++) {
          int searchPosX = beam.position.x + x;
          for (int y = -1; y <= 1; y++) {
            int searchPosY = beam.position.y + y;
            List<int> searchPosition = [searchPosX, searchPosY];
            for (Atom atom in atoms) {
//            if (MapEquality().equals(searchPosition, atom.position)) {
              //If the probe finds an atom nearby:
              if (ListEquality().equals(searchPosition, atom.position.toList())) {
                // print('Sensed an atom nearby');
                //If the atom that the probe found is in the projected position:
                if (ListEquality().equals(searchPosition, beam.projectedPosition.toList())) {
                  result = 'hit';
                  // print('result is hit');
                  return result;
                  //If the atom that the probe found is NOT in the projected position:
                } else {
                  //Is the beam still in its starting position?:
                  if (Beam.convert(coordinates: beam.position, heightOfPlayArea: heightOfPlayArea, widthOfPlayArea: widthOfPlayArea) == beam.start) {
                    //Check if there is ANOTHER atom in the projected position:
                    for (Atom atom in atoms) {
                      if (ListEquality().equals(beam.projectedPosition.toList(), atom.position.toList())) {
                        result = 'hit';
                        return result;
                      }
                    }
                    //There is no atom in the projected position and the beam is still in its starting position:
                    result = 'reflection';
                    // print('result is reflection');
                    return result;
                  }
                  //change direction
                  beam.direction.xDir = beam.direction.xDir - (atom.position.x - beam.position.x);
                  beam.direction.yDir = beam.direction.yDir - (atom.position.y - beam.position.y);
                  // print('New beam direction is ${beam.direction.toList()}');
                  /* stråle (5, 6) kula (4, 7)
                  stråle.dir = (0, 1)
                  ska bli (1, 0)
                  kula - stråle.pos = (-1, 1)
                  ny dir = stråle.dir - (kula - stråle.pos)
        */
                }
//            return result = 'near hit';
              }
            }
          }
        }

        ///Attempts at vector addition...
//      beam_1.position += beam_1.beam_1.direction;
//      print('hi ${beam_1.position + beam_1.direction}');
//      beam_1.position.addAll(beam_1.direction);
        beam.position.x += beam.direction.xDir;
        beam.position.y += beam.direction.yDir;

        // print('New beam position is ${beam.position.toList()}');
      } while (beam.position.x > 0 && beam.position.x < widthOfPlayArea + 1 && beam.position.y > 0 && beam.position.y < heightOfPlayArea + 1);
      result = Beam.convert(coordinates: beam.position, heightOfPlayArea: heightOfPlayArea, widthOfPlayArea: widthOfPlayArea);
      if (result == beam.start) result = 'reflection';
      print('result is $result');
      return result;

    }
    var result = beamResult();
    // beamsAndResults.add([beam.start, result]);
    // print('beamsAndResults is $beamsAndResults');
    return result;
  }

  void setEdgeTiles({int inSlot, dynamic beamResult}) {
    if (beamResult == 'hit') {
      edgeTileChildren[inSlot - 1] = Image(image: AssetImage('images/beam_hit.png'));
      beamScore++;
    } else if (beamResult == 'reflection') {
      edgeTileChildren[inSlot - 1] = Image(image: AssetImage('images/beam_reflection.png'));
      beamScore++;
    } else {
      if (beamCount >= beamImages.length) beamCount = 0;
      edgeTileChildren[inSlot - 1] = beamImages[beamCount];
      edgeTileChildren[beamResult - 1] = beamImages[beamCount];
      beamScore += 2;
      beamCount++;
    }
  }

  void getAtomScore() {
//    int correctAtoms = 0;
    //Correct and misplaced atoms:
    for (List<int> pAtom in playerAtoms) {
      bool correct = false;
      for (Atom atom in atoms) {
//        if(ListEquality().equals(pAtom, atom.position.toList())) correctAtoms++;
        if (ListEquality().equals(pAtom, atom.position.toList())) {
          correctAtoms.add(pAtom);
          correct = true;
        }
      }
      if (correct == false) {
        misplacedAtoms.add(pAtom);
      }
    }

    //Missed atoms:
    for(Atom atom in atoms){
      bool missed = true;
      for(List<int> pAtom in playerAtoms){
        if (ListEquality().equals(pAtom, atom.position.toList())) {
          missed = false;
        }
      }
      if(missed) missedAtoms.add(atom.position.toList());
    }
    print('Correct atoms: $correctAtoms\n'
        'Misplaced atoms: $misplacedAtoms\n'
        'Missed atoms: $missedAtoms');

//    atomScore = (atoms.length - correctAtoms) *5;
    atomScore = (atoms.length - correctAtoms.length) * 5;
  }
}
