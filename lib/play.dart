import 'package:blackbox/my_firebase.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'my_firebase_labels.dart';
import 'package:blackbox/units/small_functions.dart';

import 'atom_n_beam.dart';
import 'package:collection/collection.dart';
import 'dart:math';
import 'package:flutter/material.dart';
//import 'package:meta/meta.dart';

///-----------------------------------------------
///-----------------------------------------------
///-----------------------------------------------
class Play {
  Play(
      {required this.numberOfAtoms,
      required this.widthOfPlayArea,
      required this.heightOfPlayArea,
      this.showAtomSetting = false}) {
    edgeTileChildren =
        List<Widget?>.filled((heightOfPlayArea + widthOfPlayArea) * 2, null);
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
    beamImageIndexA!.shuffle();
    beamImageIndexB = List.generate(beamImagesB.length, (index) => index);
    beamImageIndexB!.shuffle();
  }

  int numberOfAtoms;
  bool showAtomSetting;
  int widthOfPlayArea;
  int heightOfPlayArea;
  List<Atom> atoms = [];
  List<Atom> playerAtoms = [];
  List<Atom> correctAtoms = [];
  List<Atom> misplacedAtoms = [];
  /// If still in play:
  List<Atom> notYetCorrectAtoms = [];
  List<Atom> missedAtoms = [];
  /// If still in play:
  List<Atom> unfoundAtoms = [];
  List<List<int>> markUpList =
      []; // I was lazy... This should better be a List<Position> but...
  int beamCount = 0;
  int beamScore = 0;
  int atomScore = 0;
  List<int> sentBeams = [];
  List<Widget?> edgeTileChildren = [];
  List<int?>? beamImageIndexA;
  List<int?>? beamImageIndexB;
  late List<Widget> beamImagesA;
  late List<Widget> beamImagesB;
  bool online = false;
  String playerScreenName = 'Screen name';
  String? playerUid;
  Map<String, dynamic>? setupData;
  List<List<dynamic>> beamsAndResults = [];

  // Player moves can be:
  // send beam, place atom, remove atom, place markup, remove markup, finish
  /// 'beam ##', '+atom (#,#)', '-atom (#,#)', '+markup (#,#)', '-markup (#,#)', 'finish'
  List<dynamic> playerMoves = [];
  // List<Map<String, dynamic>> playerMoves = [];
  // List<String> playerMoves = [];

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
  /// Takes the inSlot as argument and returns the beam result.
  /// Also adds the beam to sentBeams and to beamsAndResults.
  /// Also sets edgeTileChildren.
  void sendBeam({required int inSlot}) {
  // dynamic sendBeam({required int inSlot}) {
    Beam beam = Beam(
        start: inSlot,
        widthOfPlayArea: widthOfPlayArea,
        heightOfPlayArea: heightOfPlayArea);

    dynamic beamResult() {
      dynamic _result = 'no _result was found';
      // Add the sent beam to sentBeams:
      sentBeams.add(beam.start);
      // Let the beam travel through the black box:
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
              if (ListEquality()
                  .equals(searchPosition, atom.position.toList())) {
                // print('Sensed an atom nearby');
                //If the atom that the probe found is in the projected position:
                if (ListEquality()
                    .equals(searchPosition, beam.projectedPosition.toList())) {
                  _result = 'hit';
                  // print('_result is hit');
                  return _result;
                  //If the atom that the probe found is NOT in the projected position:
                } else {
                  //Is the beam still in its starting position?:
                  if (Beam.convert(
                          coordinates: beam.position,
                          heightOfPlayArea: heightOfPlayArea,
                          widthOfPlayArea: widthOfPlayArea) ==
                      beam.start) {
                    //Check if there is ANOTHER atom in the projected position:
                    for (Atom atom in atoms) {
                      if (ListEquality().equals(beam.projectedPosition.toList(),
                          atom.position.toList())) {
                        _result = 'hit';
                        return _result;
                      }
                    }
                    //There is no atom in the projected position and the beam is still in its starting position:
                    _result = 'reflection';
                    // print('_result is reflection');
                    return _result;
                  }
                  //change direction
                  beam.direction.xDir =
                      beam.direction.xDir - (atom.position.x - beam.position.x);
                  beam.direction.yDir =
                      beam.direction.yDir - (atom.position.y - beam.position.y);
                  // print('New beam direction is ${beam.direction.toList()}');
                  /* stråle (5, 6) kula (4, 7)
                  stråle.dir = (0, 1)
                  ska bli (1, 0)
                  kula - stråle.pos = (-1, 1)
                  ny dir = stråle.dir - (kula - stråle.pos)
        */
                }
//            return _result = 'near hit';
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
      } while (beam.position.x > 0 &&
          beam.position.x < widthOfPlayArea + 1 &&
          beam.position.y > 0 &&
          beam.position.y < heightOfPlayArea + 1);

      // The beam has come out without a hit or reflection.
      _result = Beam.convert(
          coordinates: beam.position,
          heightOfPlayArea: heightOfPlayArea,
          widthOfPlayArea: widthOfPlayArea);
      if (_result == beam.start) _result = 'reflection';
      // print('_result is $_result');
      return _result;
    }

    var result = beamResult();
    // beamsAndResults.add([beam.start, result]);
    // print('beamsAndResults is $beamsAndResults');
    beamsAndResults.add([inSlot, result]);
    // print('beamsAndResults is $beamsAndResults');
    setEdgeTiles(inSlot: inSlot, beamResult: result);
    // return result;
  }

  /// Puts the correct beam result widget in edgeTileChildren.
  /// Also increases beamCount and beamScore.
  void setEdgeTiles({int? inSlot, dynamic beamResult}) {
    if (beamResult == 'hit') {
      edgeTileChildren![inSlot! - 1] =
          Image(image: AssetImage('images/beams/beam_hit.png'));
      beamScore++;
    } else if (beamResult == 'reflection') {
      edgeTileChildren![inSlot! - 1] =
          Image(image: AssetImage('images/beams/beam_reflection.png'));
      beamScore++;
    }

    // Not hit or reflection:
    else {
      if (beamCount >= beamImagesA.length + beamImagesB.length) beamCount = 0;

      // If still on A list:
      if (beamCount < beamImagesA.length) {
        int index = beamImageIndexA![beamCount]!;
        // If the sender has sent a beam which the receiver doesn't have:
        if (index >= beamImagesA.length) {
          edgeTileChildren[inSlot! - 1] =
              Image(image: AssetImage('images/beams/beam_doesnt_exist.png'));
          edgeTileChildren[beamResult - 1] =
              Image(image: AssetImage('images/beams/beam_doesnt_exist.png'));
        } else {
          edgeTileChildren[inSlot! - 1] = beamImagesA[index];
          edgeTileChildren[beamResult - 1] = beamImagesA[index];
          // edgeTileChildren[inSlot - 1] = beamImagesA[beamCount];
          // edgeTileChildren[beamResult - 1] = beamImagesA[beamCount];
        }
      } else {
        // Else use B list:
        int index = beamImageIndexB![beamCount - beamImagesA.length]!;

        // If the sender has sent a beam which the receiver doesn't have:
        if (index >= beamImagesB.length) {
          edgeTileChildren[inSlot! - 1] =
              Image(image: AssetImage('images/beams/beam_doesnt_exist.png'));
          edgeTileChildren[beamResult - 1] =
              Image(image: AssetImage('images/beams/beam_doesnt_exist.png'));
        } else {
          edgeTileChildren[inSlot! - 1] = beamImagesB[index];
          edgeTileChildren[beamResult - 1] = beamImagesB[index];
          // edgeTileChildren[inSlot - 1] = beamImagesB[beamCount - beamImagesA.length];
          // edgeTileChildren[beamResult - 1] = beamImagesB[beamCount - beamImagesA.length];
        }
      }
      beamScore += 2;
      beamCount++;
    }
  }

  // Player moves can be:
  // send beam,
  // place atom,
  // remove atom,
  // place markup,
  // remove markup,
  // 'fill w atoms'
  // 'clear all atoms'
  // 'fill with markup'
  // 'clear all markup'
  // finish
  /// Arguments will be formatted to:
  /// 'beam ##',
  /// '+atom [#,#]',
  /// '-atom [#,#]',
  /// '+markup [#,#]',
  /// '-markup [#,#]',
  /// -markup ';
  /// 'fill_w_atoms';
  /// 'clear_all_atoms';
  /// 'fill_w_markup';
  /// 'clear_all_markup'
  /// 'finish'
  /// One argument will have a value, others be null.
  void setPlayerMoves(
      {int? beam,
        Position? addedAtom,
        Position? removedAtom,
        Position? addedMarkup,
        Position? removedMarkup,
        bool? fillWithAtoms,
        bool? clearAllAtoms,
        bool? fillWithMarkup,
        bool? clearAllMarkup,
        bool? finish,
        DocumentSnapshot<Object?>? setup,
      }) {
      // {String? beam,
      //   String? addedAtom,
      //   String? removedAtom,
      //   String? addedMarkup,
      //   String? removedMarkup,
      //   String? finish}) {

    late dynamic move;
    // late Map<String, dynamic> move;
    // late String move;
    if (beam != null) {
      move = {kPlayerMoveBeam : beam};
      // move = kPlayerMoveBeam + '${beam}';
    } else if (addedAtom != null) {
      move = {kPlayerMoveAddAtom: addedAtom.toList()};
      // move = kPlayerMoveAddAtom + '${addedAtom.toList()}';
    } else if (removedAtom != null) {
      move = {kPlayerMoveRemoveAtom: removedAtom.toList()};
      // move = kPlayerMoveRemoveAtom + '${removedAtom.toList()}';
    } else if (addedMarkup != null) {
      move = {kPlayerMoveAddMarkup: addedMarkup.toList()};
      // move = kPlayerMoveAddMarkup + '${addedMarkup.toList()}';
    } else if (removedMarkup != null) {
      move = {kPlayerMoveRemoveMarkup: removedMarkup.toList()};
      // move = kPlayerMoveRemoveMarkup + '${removedMarkup.toList()}';
    } else if (fillWithAtoms != null) {
      move = kPlayerMoveFillWithAtoms;
      // move = kPlayerMoveFillWithAtoms;
    } else if (clearAllAtoms != null) {
      move = kPlayerMoveClearAllAtoms;
      // move = kPlayerMoveClearAllAtoms;
    } else if (fillWithMarkup != null) {
      move = kPlayerMoveFillWithMarkup;
      // move = kPlayerMoveFillWithMarkup;
    } else if (clearAllMarkup != null) {
      move = kPlayerMoveClearAllMarkup;
      // move = kPlayerMoveClearAllMarkup;
    } else if (finish != null) {
      move = kPlayerMoveFinish;
      // move = kPlayerMoveFinish;
    }

    playerMoves.add(
      move
      // '${beam ?? addedAtom ?? removedAtom ?? addedMarkup ?? removedMarkup ?? finish}',
    );
    print('playerMoves is:');
    myPrettyPrint(playerMoves);

    //The below is only for testing:
    if (setup != null) {
      downLoadPlayerMoves(setup);
    }
  }

  Future<List<dynamic>?> downLoadPlayerMoves(DocumentSnapshot<Object?> setup) async {
  // void downLoadPlayerMoves(DocumentSnapshot<Object?> setup) async {
    await Future.delayed(Duration(milliseconds: 500));
    DocumentSnapshot _setup = await MyFirebase.storeObject.collection(kCollectionSetups).doc(setup.id).get();
    Map<String, dynamic>? _setupData = _setup.data() as Map<String, dynamic>?;
    List<dynamic>? _onlineMoves = _setupData?[kFieldPlaying]?[MyFirebase.authObject.currentUser?.uid]?[kFieldPlayerMoves];
    print('Online playerMoves is:');
    myPrettyPrint(_onlineMoves);
    return _onlineMoves;
  }

  /// Gives values to correctAtoms, misplacedAtoms, missedAtoms and 
  /// atomScore = misplacedAtoms.length * 5, by simply comparing player's
  /// answer with setup.
  void rawAtomScore() {
    correctAtoms = [];
    misplacedAtoms = [];
    missedAtoms = [];

    //Correct and misplaced atoms:
    for (Atom pAtom in playerAtoms) {
      bool correct = false;
      for (Atom atom in atoms) {
        if (ListEquality()
            .equals(pAtom.position.toList(), atom.position.toList())) {
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
    for (Atom atom in atoms) {
      bool missed = true;
      // for(List<int> pAtom in playerAtoms){
      for (Atom pAtom in playerAtoms) {
        if (ListEquality()
            .equals(pAtom.position.toList(), atom.position.toList())) {
          missed = false;
        }
      }
      if (missed) missedAtoms.add(atom);
    }

    // Now I have my 3 Lists of atom types:
    print('Correct atoms: $correctAtoms\n'
        'Misplaced atoms: $misplacedAtoms\n'
        'Missed atoms: $missedAtoms');

    // atomScore = (atoms.length - correctAtoms.length) * 5;
    atomScore = misplacedAtoms.length * 5;
  }

  /// If exact alternative solution is found:
  /// print('Returning senderGame and playerGame which are equivalent.');
  ///
  /// return [senderGame.edgeTileChildren, senderGame, playerGame];
  ///
  /// If alternative solution found with some atom(s) wrong:
  ///         return [
  ///           senderGame.edgeTileChildren,
  ///           senderGame,
  ///           /*playerGame,*/
  ///           altGame
  ///         ];
  ///
  /// Otherwise returning null.
  Future<List<dynamic>?> getScore() async {
  // List<List<Atom>> getScore() {
    beamsAndResults = [];
    rawAtomScore();
    // bool equalSol = false;
    
    // If raw atom score is 0, look no further! Everybody happy.
    // But if it's higher:
    if (atomScore > 0) {
      // Check if the player's provided answer is an alternative solution
      Play senderGame;
      Play playerGame;
      Play altGame;
      senderGame = Play(
          numberOfAtoms: numberOfAtoms,
          widthOfPlayArea: widthOfPlayArea,
          heightOfPlayArea: heightOfPlayArea);
      senderGame.atoms = atoms;
      senderGame.beamImagesA = senderGame.beamImagesA;
      senderGame.beamImagesB = senderGame.beamImagesB;
      senderGame.beamImageIndexA = beamImageIndexA;
      senderGame.beamImageIndexB = beamImageIndexB;
      playerGame = Play(
          numberOfAtoms: numberOfAtoms,
          widthOfPlayArea: widthOfPlayArea,
          heightOfPlayArea: heightOfPlayArea);
      playerGame.atoms = playerAtoms;
      playerGame.beamImageIndexA = beamImageIndexA;
      playerGame.beamImageIndexB = beamImageIndexB;
      // print('senderGame atoms are ${senderGame.atoms}');

      // print('Before running areSolutionsEquivalent(), senderGame.missedAtoms is: length ${senderGame.missedAtoms.length},  ${senderGame.missedAtoms}');
      print(
          'Before running areSolutionsEquivalent(), senderGame.beamsAndResults is: length ${senderGame.beamsAndResults.length},  ${senderGame.beamsAndResults}');
      bool solutionsEquivalent = areSolutionsEquivalent(senderGame, playerGame);
      print('Original player solution is equivalent? $solutionsEquivalent!');
      // print('After running areSolutionsEquivalent(), senderGame.missedAtoms is: length ${senderGame.missedAtoms.length}, ${senderGame.missedAtoms}');
      print(
          'After running areSolutionsEquivalent(), senderGame.beamsAndResults is: length ${senderGame.beamsAndResults.length}, ${senderGame.beamsAndResults}');
      if (solutionsEquivalent) {
        // equalSol = true;
        atomScore = 0;
        // return [senderGame.atoms, playerGame.atoms];
        // print('Before returning, beamsAndResults is ${senderGame.beamsAndResults}');
        print(
            'Before running senderGame.setEdgeTiles(), senderGame.sentBeams is ${senderGame.sentBeams}');

        // TODO: (Will try to comment this out, since I put setEdgeTiles inside sendBeam:)
        // for (List<dynamic> bnr in senderGame.beamsAndResults) {
        //   senderGame.setEdgeTiles(inSlot: bnr[0], beamResult: bnr[1]);
        // }
        print(
            'After running senderGame.setEdgeTiles(), senderGame.sentBeams is ${senderGame.sentBeams}');
        // print('Before returning, edgeTileChildren is ${senderGame.edgeTileChildren}');
        senderGame.correctAtoms = senderGame.atoms;
        playerGame.correctAtoms = playerGame.atoms;
        print('Returning senderGame and playerGame which are equivalent.');
        return [senderGame.edgeTileChildren, senderGame, playerGame];
      }

      senderGame.beamsAndResults = [];
      // Not sure what this does with edgeTileChildren:
      // edgeTileChildren =
      //   List<Widget?>.filled((heightOfPlayArea + widthOfPlayArea) * 2, null);
      print('Solutions were not exactly equivalent');

      // If there was no alternative solution that's exactly correct, there might be one that's more correct than the raw score.
      // Loop through all red atoms and try to swap them for a blue atom. If it can be swapped, that red atom does not give penalty
      // and will be added to correctAtoms in altGame.

      // Start with the senderGame, try and turn it into the playerGame by taking a blueAtom from the original answer
      // and putting it in the place of a redAtom, and so long as the beam output stays the same as it was for the
      // original senderGame, it's ok! The moment the beam output changes from the original, that atom swap must be reversed.

      altGame = Play(
          numberOfAtoms: numberOfAtoms,
          widthOfPlayArea: widthOfPlayArea,
          heightOfPlayArea: heightOfPlayArea);
      // De-link:
      // for (Atom atom in playerAtoms){
      //   altGame.atoms.add(atom);  // Will this work, really...?
      // }
      for (Atom atom in atoms) {
        altGame.atoms.add(atom); // Sender atoms being placed as altGame.atoms
      }
      for (Atom missedAtom in missedAtoms) {
        altGame.missedAtoms.add(
            missedAtom); // Original missed atoms being placed as altGame.missedAtoms
      }
      for (Atom misplacedAtom in misplacedAtoms) {
        altGame.misplacedAtoms.add(
            misplacedAtom); // Original misplaced atoms being placed as altGame.misplacedAtoms
      }
      // print ('altGame.atoms before trying swapping is ${altGame.atoms}');
      // for (Atom redAtom in playerGame.misplacedAtoms){
      //   for (Atom blueAtom in playerGame.missedAtoms){

      bool alternativeFound = false;
      // for (int twice = 0; twice < 2; twice++) {
      //   print('twice is $twice');
      print(
          'Before the swap-loops.\n-------------------------------------------------------------------------------------------------------------------');
      print(
          'altGame.misplacedAtoms is: length ${altGame.misplacedAtoms.length}, ${altGame.misplacedAtoms}');
      print(
          'altGame.missedAtoms is: length ${altGame.missedAtoms.length}, ${altGame.missedAtoms}');
      print(
          'altGame.atoms is: length ${altGame.atoms.length}, ${altGame.atoms}');
      int red = -1;
      int blue = -1;
      bool swapMade = false;
      // For each red atom:
      // for (Atom redAtom in misplacedAtoms){
      for (Atom redAtom in altGame.misplacedAtoms) {
        red++;
        blue = -1;
        print('Trying redAtom $red: ${redAtom.position.toList()}');
        // For each blue atom:
        for (Atom blueAtom in altGame.missedAtoms) {
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
          int? replaceIndex;
          for (Atom atom in altGame.atoms) {
            // If the atom in altGame.atoms is the same as the blueAtom we're on, that's the atom to be replaced:
            if (atom.position.toList().equals(blueAtom.position.toList()))
              replaceIndex = i;
            i++;
          }
          if (replaceIndex != null) {
            print(
                'Replacing atom ${altGame.atoms[replaceIndex]} at $replaceIndex in altGame.atoms with the redAtom $redAtom');
            print('altGame.atoms before swapping is ${altGame.atoms}');
            altGame.atoms[replaceIndex] =
                redAtom; // Replacing the missed atom with a misplaced atom,
            // so that the redAtom will come out as correct. The missedAtom will have to be removed later,
            // because I'm looping through them. (Can't change a list while looping it)
            print(
                'altGame.atoms after swapping is ${altGame.atoms}.\nReplace index is $replaceIndex and blue is $blue.');
            print(
                'altGame.missedAtoms is - length ${altGame.missedAtoms.length}, ${altGame.missedAtoms}.');
            // break;
            // fireAllBeams(altGame);
            // bool swapSuccessful = areSolutionsEquivalent(altGame, playerGame);
            // print('Before running areSolutionsEquivalent(), senderGame.missedAtoms is: length ${senderGame.missedAtoms.length},  ${senderGame.missedAtoms}');
            // print('Before running areSolutionsEquivalent(), senderGame.beamsAndResults is: length ${senderGame.beamsAndResults.length},  ${senderGame.beamsAndResults}');
            // print('Before running areSolutionsEquivalent(), altGame.missedAtoms is: length ${altGame.missedAtoms.length},  ${altGame.missedAtoms}');
            // print('Before running areSolutionsEquivalent(), altGame.beamsAndResults is: length ${altGame.beamsAndResults.length},  ${altGame.beamsAndResults}');
            bool swapSuccessful = areSolutionsEquivalent(altGame, senderGame);
            print(
                'Was the swap successful? $swapSuccessful. redAtom is $redAtom, red is $red, blueAtom is $blueAtom, blue is $blue and replaceIndex is $replaceIndex');
            // print('After running areSolutionsEquivalent(), senderGame.missedAtoms is: length ${senderGame.missedAtoms.length}, ${senderGame.missedAtoms}');
            // print('After running areSolutionsEquivalent(), senderGame.beamsAndResults is: length ${senderGame.beamsAndResults.length}, ${senderGame.beamsAndResults}');
            print(
                'After running areSolutionsEquivalent(), altGame.missedAtoms is: length ${altGame.missedAtoms.length},  ${altGame.missedAtoms}');
            // print('After running areSolutionsEquivalent(), altGame.beamsAndResults is: length ${altGame.beamsAndResults.length},  ${altGame.beamsAndResults}');
            if (!swapSuccessful) {
              print(
                  '********************************************************************************************************');
              print('altGame.beamsAndResults is ${altGame.beamsAndResults}');
              print(
                  'senderGame.beamsAndResults is ${senderGame.beamsAndResults}');
              if (altGame.beamsAndResults.toString().length > 500) {
                print(
                    'altGame.beamsAndResults is ${altGame.beamsAndResults.toString().substring(500)}');
              }
              if (senderGame.beamsAndResults.toString().length > 500) {
                print(
                    'senderGame.beamsAndResults is ${senderGame.beamsAndResults.toString().substring(500)}');
              }
              print(
                  '********************************************************************************************************');
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
          print(
              'Alternative not found. redAtom is ${redAtom.position.toList()} and blueAtom is $blueAtom');
          print(
              'alternativeFound is $alternativeFound. altGame.atoms is length ${altGame.atoms.length}, ${altGame.atoms}');
          // break;
        }
        print('red is $red');
        print('blue is $blue');
        print('alternativeFound is $alternativeFound');
        if (swapMade) {
          print(
              'swapMade is $swapMade. Removing altGame.missedAtom ${altGame.missedAtoms[blue]} at index $blue');
          print('that is ${altGame.missedAtoms[blue]}');
          print(
              'altGame.missedAtoms before removing is length ${altGame.missedAtoms.length}, ${altGame.missedAtoms}');
          altGame.missedAtoms.removeAt(blue);
          print(
              'altGame.missedAtoms after removing is length ${altGame.missedAtoms.length}, ${altGame.missedAtoms}');
          blue = -1;
          swapMade = false;
        }
      }
      if (alternativeFound) {
        altGame.playerAtoms = playerAtoms;
        altGame.beamsAndResults = [];
        altGame.rawAtomScore();
        print(
            'altGame.atoms.length is ${altGame.atoms.length} and altGame.correctAtoms.length is ${altGame.correctAtoms.length}');
        print(
            'altGame.misplacedAtoms.length is ${altGame.misplacedAtoms.length}');
        // if (altGame.atomScore <= 5) break;  // Otherwise run the whole swap-loops thing again, but only one more time.
        // break;  // Use above (to make algorithm more secure...?)
      }
      // }  // End of twice loop

      // Seems this could now be combined with the above if()...
      if (alternativeFound) {
        atomScore = altGame.atomScore;
        // return [senderGame.atoms, altGame.atoms];
        // return [altGame.edgeTileChildren, senderGame.atoms, altGame.atoms];
        // print('Before returning, beamsAndResults is ${senderGame.beamsAndResults}');
        for (List<dynamic> bna in senderGame.beamsAndResults) {
          senderGame.setEdgeTiles(inSlot: bna[0], beamResult: bna[1]);
        }
        print(
            'Before returning, edgeTileChildren is ${senderGame.edgeTileChildren}');
        senderGame.correctAtoms = senderGame.atoms;
        return [
          senderGame.edgeTileChildren,
          senderGame,
          /*playerGame,*/
          altGame
        ];
      }
    }

    // return [playerGame.atoms, senderGame.atoms];
    print('Returning null from getScore()');
    return null;
  }

  // static List<List<dynamic>> fireAllBeams(/*AltSolPlay game, int numberOfSlots*/) {
  static void fireAllBeams(
    Play tempGame,
    /*int numberOfSlots*/
  ) {
    print('Running fireAllBeams()');
    tempGame.sentBeams = [];
    // Play tempGame = Play(numberOfAtoms: numberOfAtoms, widthOfPlayArea: widthOfPlayArea, heightOfPlayArea: heightOfPlayArea);
    // tempGame.atoms = atoms;
    // int numberOfSlots = (widthOfPlayArea + heightOfPlayArea) * 2;
    int numberOfSlots =
        (tempGame.widthOfPlayArea + tempGame.heightOfPlayArea) * 2;
    for (int i = 1; i <= numberOfSlots; i++) {
      // print('Slot no $i');
      // dynamic result = game.getBeamResult(inSlot: i);
      // dynamic result = tempGame.getBeamResult(inSlot: i);
      tempGame.sendBeam(inSlot: i);
      // game.setEdgeTiles(inSlot: i, beamResult: result);
      // tempGame.setEdgeTiles(inSlot: i, beamResult: result);
    }
    // return beamsAndResults;
    // return tempGame.beamsAndResults;
  }

  /// Fires all beams for both games. Returns true if beam results are identical,
  /// otherwise returns false.
  static bool areSolutionsEquivalent(Play _game1, Play _game2) {
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
    print(
        '_game1.beamsAndResults.length == _game2.beamsAndResults.length is ${_game1.beamsAndResults.length == _game2.beamsAndResults.length}'
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
