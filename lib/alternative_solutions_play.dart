// import 'package:collection/collection.dart';
// import 'atom_n_beam.dart';
// // import 'package:blackbox/atom_n_beam.dart';
//
// import 'play.dart';
// import 'package:flutter/material.dart';
//
// class AltSolPlay extends Play {
//   AltSolPlay({@required this.numberOfAtoms, @required this.widthOfPlayArea, @required this.heightOfPlayArea, this.showAtomSetting = false})
//   : super(numberOfAtoms: numberOfAtoms, widthOfPlayArea: widthOfPlayArea, heightOfPlayArea: heightOfPlayArea){
//     // alreadyTried = [];
//     // for (int atomNo = 0; atomNo < numberOfAtoms; atomNo++){
//       // alreadyTried.add([]);
//     // }
//   }
//   int numberOfAtoms;
//   bool showAtomSetting;
//   int widthOfPlayArea;
//   int heightOfPlayArea;
//
//
//   List<List<dynamic>> beamsAndResults = [];
//   // List<List<List<int>>> alreadyTried = List.filled(numberOfAtoms, []);
//   // List<List<Atom>> alreadyTried;
//
//   // @override
//   dynamic _getBeamResult({@required int inSlot}) {
//     var result = super.getBeamResult(inSlot: inSlot);
//     beamsAndResults.add([inSlot, result]);
//     print('beamsAndResults is $beamsAndResults');
//     return result;
//   }
//
//   List<List<dynamic>> fireAllBeams(/*AltSolPlay game, int numberOfSlots*/) {
//     int numberOfSlots = (widthOfPlayArea + heightOfPlayArea) * 2;
//     for (int i = 1; i <= numberOfSlots; i++) {
//       // print('Slot no $i');
//       // dynamic result = game.getBeamResult(inSlot: i);
//       dynamic result = _getBeamResult(inSlot: i);
//       // game.setEdgeTiles(inSlot: i, beamResult: result);
//       setEdgeTiles(inSlot: i, beamResult: result);
//     }
//     // return game.beamsAndResults;
//     return beamsAndResults;
//   }
//
//   @override
//   // List<AltSolPlay> getAtomScore() {
//   List<List<Atom>> getAtomScore() {
//     // Get atomScore + lists of all correct, missed and misplaced atoms:
//     super.getAtomScore();
//
//     AltSolPlay altGame;
//     AltSolPlay playerGame;
//     bool altSol = false;
//     if (atomScore > 0) {
//       // Check for alternative solutions for the player's provided answer
//       altGame = AltSolPlay(
//           numberOfAtoms: numberOfAtoms,
//           widthOfPlayArea: widthOfPlayArea,
//           heightOfPlayArea: heightOfPlayArea);
//       altGame.atoms = atoms;
//       playerGame = AltSolPlay(
//           numberOfAtoms: numberOfAtoms,
//           widthOfPlayArea: widthOfPlayArea,
//           heightOfPlayArea: heightOfPlayArea);
//       // Because playerAtoms is a List of List of int, and not a List of Atom...:
//       for (List<int> playerAtom in playerAtoms) {
//         playerGame.atoms.add(Atom(playerAtom[0], playerAtom[1]));
//       }
//
//       // print('Test game atoms are ${altGame.atoms}');
//       // Fire all beams and put result in beamsAndResults:
//       altGame.beamsAndResults = altGame.fireAllBeams();
//       print('altGame.beamsAndResults is ${altGame.beamsAndResults}');
//       playerGame.beamsAndResults = playerGame.fireAllBeams();
//       print('playerGame.beamsAndResults is ${playerGame.beamsAndResults}');
//
//       ///----------------------------------------------------------
//       bool solutionsEquivalent = true;
//       int i = 0;
//       for (List<dynamic> beamNo in altGame.beamsAndResults) {
//         if (!ListEquality().equals(beamNo, playerGame.beamsAndResults[i])) {
//           solutionsEquivalent = false;
//           break;
//         }
//         i++;
//       }
//       print('Solutions are equivalent? $solutionsEquivalent!');
//       if (solutionsEquivalent) {
//         altSol = true;
//         atomScore = 0;
//         return [altGame.atoms, playerGame.atoms];
//       }
//
//       ///----------------------------------------------------------
//
//     }
//
//     return [altGame.atoms, playerGame.atoms];
//   }
//
//
//   }