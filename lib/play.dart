import 'atom_n_beam.dart';
import 'package:collection/collection.dart';
import 'dart:math';
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
    beamImagesA = [
      Image(image: AssetImage('images/beams/beam_plane.png')),
      Image(image: AssetImage('images/beams/beam_violet.png')),
      Image(image: AssetImage('images/beams/beam_pink.png')),
      Image(image: AssetImage('images/beams/beam_purple.png')),
      Image(image: AssetImage('images/beams/beam_indigo.png')),
      Image(image: AssetImage('images/beams/beam_blue.png')),
      Image(image: AssetImage('images/beams/beam_aqua.png')),
      Image(image: AssetImage('images/beams/beam_current.png')),
      Image(image: AssetImage('images/beams/beam_lines.png')),
      Image(image: AssetImage('images/beams/beam_pear.png')),
      Image(image: AssetImage('images/beams/beam_lamp.png')),
      Image(image: AssetImage('images/beams/beam_orange.png')),
      Image(image: AssetImage('images/beams/beam_orange_2.png')),
      Image(image: AssetImage('images/beams/beam_red.png')),
      Image(image: AssetImage('images/beams/beam_note.png')),
      Image(image: AssetImage('images/beams/beam_rose.png')),
      Image(image: AssetImage('images/beams/beam_brown.png')),
      Image(image: AssetImage('images/beams/beam_grey.png')),
      Image(image: AssetImage('images/beams/beam_white.png')),
      // Image(image: AssetImage('images/beams/beam_reflection.png')),
    ];
    beamImagesB = [
      Image(image: AssetImage('images/beams/beam_magenta.png')),
      Image(image: AssetImage('images/beams/beam_yellow.png')),
      Image(image: AssetImage('images/beams/beam_egg.png')),
      Image(image: AssetImage('images/beams/beam_green.png')),
    ];
    beamImageIndexA = List.generate(beamImagesA.length, (index) => index);
    beamImageIndexA.shuffle();
    beamImageIndexB = List.generate(beamImagesB.length, (index) => index);
    beamImageIndexB.shuffle();
    // beamImagesA.shuffle();
    // beamImagesB.shuffle();
  }

  int numberOfAtoms;
  bool showAtomSetting;
  int widthOfPlayArea;
  int heightOfPlayArea;
  List<Atom> atoms = [];
//  List<List<int>> receivedPlayingAtoms = [];
  List<Atom> playerAtoms = [];
  List<Atom> correctAtoms = [];
  List<Atom> misplacedAtoms = [];
  List<Atom> missedAtoms = [];
  List<List<int>> markUpList = [];
  // List<List<int>> playerAtoms = [];
  // List<List<int>> correctAtoms = [];
  // List<List<int>> misplacedAtoms = [];
  // List<List<int>> missedAtoms = [];
  int beamCount = 0;
  int beamScore = 0;
  int atomScore = 0;
  List<int> sentBeams = [];
  List<Widget> edgeTileChildren;
  List<int> beamImageIndexA;
  List<int> beamImageIndexB;
  List<Widget> beamImagesA;
  List<Widget> beamImagesB;
  bool online = false;
  String playerScreenName = 'Screen name';
  String playerId;
  Map<String, dynamic> setupData;
  List<List<dynamic>> beamsAndResults = [];

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
      // print('result is $result');
      return result;

    }
    var result = beamResult();
    // beamsAndResults.add([beam.start, result]);
    // print('beamsAndResults is $beamsAndResults');
    beamsAndResults.add([inSlot, result]);
    // print('beamsAndResults is $beamsAndResults');
    return result;
  }

  void setEdgeTiles({int inSlot, dynamic beamResult}) {
    if (beamResult == 'hit') {
      edgeTileChildren[inSlot - 1] = Image(image: AssetImage('images/beams/beam_hit.png'));
      beamScore++;
    } else if (beamResult == 'reflection') {
      edgeTileChildren[inSlot - 1] = Image(image: AssetImage('images/beams/beam_reflection.png'));
      beamScore++;
    }

    // Not hit or reflection:
    else {
      if (beamCount >= beamImagesA.length + beamImagesB.length) beamCount = 0;

      // If still on A list:
      if (beamCount < beamImagesA.length) {
        int index = beamImageIndexA[beamCount];
        // If the sender has sent a beam which the receiver doesn't have:
        if (index >= beamImagesA.length) {
          edgeTileChildren[inSlot - 1] = Image(image: AssetImage('images/beams/beam_doesnt_exist.png'));
          edgeTileChildren[beamResult - 1] = Image(image: AssetImage('images/beams/beam_doesnt_exist.png'));
        } else {
          edgeTileChildren[inSlot - 1] = beamImagesA[index];
          edgeTileChildren[beamResult - 1] = beamImagesA[index];
          // edgeTileChildren[inSlot - 1] = beamImagesA[beamCount];
          // edgeTileChildren[beamResult - 1] = beamImagesA[beamCount];
        }

      } else {
        // Else use B list:
        int index = beamImageIndexB[beamCount - beamImagesA.length];

        // If the sender has sent a beam which the receiver doesn't have:
        if (index >= beamImagesB.length) {
          edgeTileChildren[inSlot - 1] = Image(image: AssetImage('images/beams/beam_doesnt_exist.png'));
          edgeTileChildren[beamResult - 1] = Image(image: AssetImage('images/beams/beam_doesnt_exist.png'));
        } else {
          edgeTileChildren[inSlot - 1] = beamImagesB[index];
          edgeTileChildren[beamResult - 1] = beamImagesB[index];
          // edgeTileChildren[inSlot - 1] = beamImagesB[beamCount - beamImagesA.length];
          // edgeTileChildren[beamResult - 1] = beamImagesB[beamCount - beamImagesA.length];
        }
      }
      beamScore += 2;
      beamCount++;
    }
  }

  void rawAtomScore(){
    correctAtoms = [];
    misplacedAtoms = [];
    missedAtoms = [];

    //Correct and misplaced atoms:
    for (Atom pAtom in playerAtoms) {
      bool correct = false;
      for (Atom atom in atoms) {
        if (ListEquality().equals(pAtom.position.toList(), atom.position.toList())) {
          correctAtoms.add(pAtom);
          correct = true;
          break;
        }
      }
      // If none of the sender atoms match the specific player atom:
      if (correct == false) {
        misplacedAtoms.add(pAtom);
      }
    }

    //Missed atoms:
    for(Atom atom in atoms){
      bool missed = true;
      // for(List<int> pAtom in playerAtoms){
      for(Atom pAtom in playerAtoms){
        if (ListEquality().equals(pAtom.position.toList(), atom.position.toList())) {
          missed = false;
        }
      }
      if(missed) missedAtoms.add(atom);
    }

    // Now I have my 3 Lists of atom types:
    print('Correct atoms: $correctAtoms\n'
        'Misplaced atoms: $misplacedAtoms\n'
        'Missed atoms: $missedAtoms');

    // atomScore = (atoms.length - correctAtoms.length) * 5;
    atomScore = misplacedAtoms.length * 5;
  }

  // List<List<Atom>> getScore() {
  Future<List<dynamic>> getScore() async {
    beamsAndResults = [];
    rawAtomScore();
    // bool equalSol = false;
    if (atomScore > 0) {
      // Check if the player's provided answer is an alternative solution
      Play senderGame;
      Play playerGame;
      Play altGame;
      senderGame = Play(numberOfAtoms: numberOfAtoms, widthOfPlayArea: widthOfPlayArea, heightOfPlayArea: heightOfPlayArea);
      senderGame.atoms = atoms;
      playerGame = Play(numberOfAtoms: numberOfAtoms, widthOfPlayArea: widthOfPlayArea, heightOfPlayArea: heightOfPlayArea);
      playerGame.atoms = playerAtoms;
      // print('senderGame atoms are ${senderGame.atoms}');

      // print('Before running areSolutionsEquivalent(), senderGame.missedAtoms is: length ${senderGame.missedAtoms.length},  ${senderGame.missedAtoms}');
      print('Before running areSolutionsEquivalent(), senderGame.beamsAndResults is: length ${senderGame.beamsAndResults.length},  ${senderGame.beamsAndResults}');
      bool solutionsEquivalent = areSolutionsEquivalent(senderGame, playerGame);
      print('Original solutions are equivalent? $solutionsEquivalent!');
      // print('After running areSolutionsEquivalent(), senderGame.missedAtoms is: length ${senderGame.missedAtoms.length}, ${senderGame.missedAtoms}');
      print('After running areSolutionsEquivalent(), senderGame.beamsAndResults is: length ${senderGame.beamsAndResults.length}, ${senderGame.beamsAndResults}');
      if (solutionsEquivalent) {
        // equalSol = true;
        atomScore = 0;
        // return [senderGame.atoms, playerGame.atoms];
        // print('Before returning, beamsAndResults is ${senderGame.beamsAndResults}');
        print('Before running senderGame.setEdgeTiles(), senderGame.sentBeams is ${senderGame.sentBeams}');

        for (List<dynamic> bnr in senderGame.beamsAndResults) {
          senderGame.setEdgeTiles(inSlot: bnr[0], beamResult: bnr[1]);
        }
        print('After running senderGame.setEdgeTiles(), senderGame.sentBeams is ${senderGame.sentBeams}');
        // print('Before returning, edgeTileChildren is ${senderGame.edgeTileChildren}');
        senderGame.correctAtoms = senderGame.atoms;
        playerGame.correctAtoms = playerGame.atoms;
        print('Returning senderGame and playerGame which are equivalent.');
        return [senderGame.edgeTileChildren, senderGame, playerGame];
      }

      senderGame.beamsAndResults = [];
      print('Solutions were not exactly equivalent');

      // If there was no alternative solution that's exactly correct, there might be one that's more correct than the raw score.
      // Loop through all red atoms and try to swap them for a blue atom. If it can be swapped, that red atom does not give penalty
      // and will be added to correctAtoms in altGame.

      // Start with the senderGame, try and turn it into the playerGame by taking a blueAtom from the original answer
      // and putting it in the place of a redAtom, and so long as the beam output stays the same as it was for the
      // original senderGame, it's ok! The moment the beam output changes from the original, that atom swap must be reversed.

      altGame = Play(numberOfAtoms: numberOfAtoms, widthOfPlayArea: widthOfPlayArea, heightOfPlayArea: heightOfPlayArea);
      // De-link:
      // for (Atom atom in playerAtoms){
      //   altGame.atoms.add(atom);  // Will this work, really...?
      // }
      for (Atom atom in atoms){
        altGame.atoms.add(atom);  // Sender atoms being placed as altGame.atoms
      }
      for (Atom missedAtom in missedAtoms){
        altGame.missedAtoms.add(missedAtom);  // Original missed atoms being placed as altGame.missedAtoms
      }
      for (Atom misplacedAtom in misplacedAtoms){
        altGame.misplacedAtoms.add(misplacedAtom);  // Original misplaced atoms being placed as altGame.misplacedAtoms
      }
      // print ('altGame.atoms before trying swapping is ${altGame.atoms}');
      // for (Atom redAtom in playerGame.misplacedAtoms){
      //   for (Atom blueAtom in playerGame.missedAtoms){

      bool alternativeFound = false;
      // for (int twice = 0; twice < 2; twice++) {
      //   print('twice is $twice');
        print('Before the swap-loops.\n-------------------------------------------------------------------------------------------------------------------');
        print('altGame.misplacedAtoms is: length ${altGame.misplacedAtoms.length}, ${altGame.misplacedAtoms}');
        print('altGame.missedAtoms is: length ${altGame.missedAtoms.length}, ${altGame.missedAtoms}');
        print('altGame.atoms is: length ${altGame.atoms.length}, ${altGame.atoms}');
        int red = -1;
        int blue = -1;
        bool swapMade = false;
        // For each red atom:
        // for (Atom redAtom in misplacedAtoms){
        for (Atom redAtom in altGame.misplacedAtoms){
          red++;
          blue = -1;
          print('Trying redAtom $red: ${redAtom.position.toList()}');
          // For each blue atom:
          for (Atom blueAtom in altGame.missedAtoms){
            blue++;
            print('Trying blueAtom $blue: ${blueAtom.position.toList()}');
            print('altGame.missedAtoms is: ${altGame.missedAtoms}');
            print('altGame.misplacedAtoms is: ${altGame.misplacedAtoms}');
            print('altGame.atoms is: ${altGame.atoms}');

            // Swap and see if it gives a better result:
            // If the swap results gives the same allBeamOutput as the senderGame allBeamOutput,
            // the redAtom will be an atom in an alternative solution, altGame.
            // If not, the blueAtom will be an atom in altGame.
            // Then the player score will be calculated on the altGame.
            // Return senderGame and altGame.

            // Find the index of the missed atom from missedAtoms that is supposed to be deleted from the correct altGame.atoms in altGame.atoms:
            int i = 0;
            int replaceIndex;
            for (Atom atom in altGame.atoms){
              // If the atom in altGame.atoms is the same as the blueAtom we're on, that's the atom to be replaced:
              if (atom.position.toList().equals(blueAtom.position.toList())) replaceIndex = i;
              i++;
            }
            if (replaceIndex != null) {
              print('Replacing atom ${altGame.atoms[replaceIndex]} at $replaceIndex in altGame.atoms with the redAtom $redAtom');
              print('altGame.atoms before swapping is ${altGame.atoms}');
              altGame.atoms[replaceIndex] = redAtom; // Replacing the missed atom with a misplaced atom,
              // so that the redAtom will come out as correct. The missedAtom will have to be removed later,
              // because I'm looping through them. (Can't change a list while looping it)
              print ('altGame.atoms after swapping is ${altGame.atoms}.\nReplace index is $replaceIndex and blue is $blue.');
              print ('altGame.missedAtoms is - length ${altGame.missedAtoms.length}, ${altGame.missedAtoms}.');
              // break;
              // fireAllBeams(altGame);
              // bool swapSuccessful = areSolutionsEquivalent(altGame, playerGame);
              // print('Before running areSolutionsEquivalent(), senderGame.missedAtoms is: length ${senderGame.missedAtoms.length},  ${senderGame.missedAtoms}');
              // print('Before running areSolutionsEquivalent(), senderGame.beamsAndResults is: length ${senderGame.beamsAndResults.length},  ${senderGame.beamsAndResults}');
              // print('Before running areSolutionsEquivalent(), altGame.missedAtoms is: length ${altGame.missedAtoms.length},  ${altGame.missedAtoms}');
              // print('Before running areSolutionsEquivalent(), altGame.beamsAndResults is: length ${altGame.beamsAndResults.length},  ${altGame.beamsAndResults}');
              bool swapSuccessful = areSolutionsEquivalent(altGame, senderGame);
              print('Was the swap successful? $swapSuccessful. redAtom is $redAtom, red is $red, blueAtom is $blueAtom, blue is $blue and replaceIndex is $replaceIndex');
              // print('After running areSolutionsEquivalent(), senderGame.missedAtoms is: length ${senderGame.missedAtoms.length}, ${senderGame.missedAtoms}');
              // print('After running areSolutionsEquivalent(), senderGame.beamsAndResults is: length ${senderGame.beamsAndResults.length}, ${senderGame.beamsAndResults}');
              print('After running areSolutionsEquivalent(), altGame.missedAtoms is: length ${altGame.missedAtoms.length},  ${altGame.missedAtoms}');
              // print('After running areSolutionsEquivalent(), altGame.beamsAndResults is: length ${altGame.beamsAndResults.length},  ${altGame.beamsAndResults}');
              if (!swapSuccessful){
                print('********************************************************************************************************');
                print('altGame.beamsAndResults is ${altGame.beamsAndResults}');
                print('senderGame.beamsAndResults is ${senderGame.beamsAndResults}');
                if (altGame.beamsAndResults.toString().length > 500) {
                  print('altGame.beamsAndResults is ${altGame.beamsAndResults.toString().substring(500)}');
                }
                if (senderGame.beamsAndResults.toString().length > 500) {
                  print('senderGame.beamsAndResults is ${senderGame.beamsAndResults.toString().substring(500)}');
                }
                print('********************************************************************************************************');
                // print('playerGame.beamsAndResults is ${playerGame.beamsAndResults}');
              }
              if (swapSuccessful) {
                alternativeFound = true;
                swapMade = true;
                print('Alternative solution with better score found. Breaking');
                break;
              } else {
                // If the swap changes the beam output, the atom will again be the blueAtom and not the redAtom:
                altGame.atoms[replaceIndex] = blueAtom;
              }
            }
            print('Alternative not found. redAtom is ${redAtom.position.toList()} and blueAtom is $blueAtom');
            print('alternativeFound is $alternativeFound. altGame.atoms is length ${altGame.atoms.length}, ${altGame.atoms}');
            // break;
          }
          print('red is $red');
          print('blue is $blue');
          print('alternativeFound is $alternativeFound');
          if (swapMade){
            print('swapMade is $swapMade. Removing altGame.missedAtom ${altGame.missedAtoms[blue]} at index $blue');
            print('that is ${altGame.missedAtoms[blue]}');
            print('altGame.missedAtoms before removing is length ${altGame.missedAtoms.length}, ${altGame.missedAtoms}');
            altGame.missedAtoms.removeAt(blue);
            print('altGame.missedAtoms after removing is length ${altGame.missedAtoms.length}, ${altGame.missedAtoms}');
            blue = -1;
            swapMade = false;
          }
        }
        if (alternativeFound) {
          altGame.playerAtoms = playerAtoms;
          altGame.beamsAndResults = [];
          altGame.rawAtomScore();
          print('altGame.atoms.length is ${altGame.atoms.length} and altGame.correctAtoms.length is ${altGame.correctAtoms.length}');
          print('altGame.misplacedAtoms.length is ${altGame.misplacedAtoms.length}');
          // if (altGame.atomScore <= 5) break;  // Otherwise run the whole swap-loops thing again, but only one more time.
          // break;  // Use above (to make algorithm more secure...?)
        }
      // }  // End of twice loop

      if (alternativeFound) {
        atomScore = altGame.atomScore;
        // return [senderGame.atoms, altGame.atoms];
        // return [altGame.edgeTileChildren, senderGame.atoms, altGame.atoms];
        // print('Before returning, beamsAndResults is ${senderGame.beamsAndResults}');
        for (List<dynamic> bna in senderGame.beamsAndResults) {
          senderGame.setEdgeTiles(inSlot: bna[0], beamResult: bna[1]);
        }
        print('Before returning, edgeTileChildren is ${senderGame.edgeTileChildren}');
        senderGame.correctAtoms = senderGame.atoms;
        return [senderGame.edgeTileChildren, senderGame, /*playerGame,*/ altGame];
      }
    }

    // return [playerGame.atoms, senderGame.atoms];
    print('Returning null from getScore()');
    return null;
  }

  // static List<List<dynamic>> fireAllBeams(/*AltSolPlay game, int numberOfSlots*/) {
  static void fireAllBeams(Play tempGame, /*int numberOfSlots*/) {
    print('Running fireAllBeams()');
    tempGame.sentBeams = [];
    // Play tempGame = Play(numberOfAtoms: numberOfAtoms, widthOfPlayArea: widthOfPlayArea, heightOfPlayArea: heightOfPlayArea);
    // tempGame.atoms = atoms;
    // int numberOfSlots = (widthOfPlayArea + heightOfPlayArea) * 2;
    int numberOfSlots = (tempGame.widthOfPlayArea + tempGame.heightOfPlayArea) * 2;
    for (int i = 1; i <= numberOfSlots; i++) {
      // print('Slot no $i');
      // dynamic result = game.getBeamResult(inSlot: i);
      // dynamic result = tempGame.getBeamResult(inSlot: i);
      tempGame.getBeamResult(inSlot: i);
      // game.setEdgeTiles(inSlot: i, beamResult: result);
      // tempGame.setEdgeTiles(inSlot: i, beamResult: result);
    }
    // return beamsAndResults;
    // return tempGame.beamsAndResults;
  }

  ///----------------------------------------------------------
  static bool areSolutionsEquivalent(Play _game1, Play _game2){
    print('Running areSolutionsEquivalent()');
    _game1.beamsAndResults = [];
    _game2.beamsAndResults = [];
    // Fire all beams and put result in beamsAndResults:
    // senderGame.beamsAndResults = senderGame.fireAllBeams();
    fireAllBeams(_game1);
    // print('_game1.edgeTileChildren in areSolutionsEquivalent() is ${_game1.edgeTileChildren}');
    // print('senderGame.beamsAndResults is ${_game1.beamsAndResults}');
    // print('senderGame.atomScore is ${_game1.atomScore}');
    // print('senderGame.beamScore is ${_game1.beamScore}');
    // playerGame.beamsAndResults = playerGame.fireAllBeams();
    fireAllBeams(_game2);
    // print('playerGame.beamsAndResults is ${_game2.beamsAndResults}');
    // print('playerGame.atomScore is ${_game2.atomScore}');
    // print('playerGame.beamScore is ${_game2.beamScore}');
    // assert (_game1.beamsAndResults.length == _game2.beamsAndResults.length);
    print ('_game1.beamsAndResults.length == _game2.beamsAndResults.length is ${_game1.beamsAndResults.length == _game2.beamsAndResults.length}'
        ' and length is ${_game2.beamsAndResults.length}');
    bool _solutionsEquivalent = true;
    int i = 0;
    for (List<dynamic> beamNo in _game1.beamsAndResults) {
      if (!ListEquality().equals(beamNo, _game2.beamsAndResults[i])) {
        _solutionsEquivalent = false;
        break;
      }
      i++;
    }
    return _solutionsEquivalent;
  }
///----------------------------------------------------------
}
