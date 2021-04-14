import 'dart:math';
import 'screens/results_screen.dart';
import 'package:flutter/cupertino.dart';
import 'alternative_solutions_play.dart';
import 'package:collection/collection.dart';
import 'atom_n_beam.dart';
import 'play.dart';
import 'package:flutter/material.dart';

int _numberOfSquares;
int _numberOfSlots;
int _numberOfAtoms;
int _totalNumberOfPossibleSetups;
int _widthOfPlayArea;
int _heightOfPlayArea;
List<List<Atom>> allUniqueSetups = [];

Future<List<List<List<int>>>> alternativeSolutions(BuildContext context, Play sentGame) async {
  AltSolPlay thisGame =
      AltSolPlay(numberOfAtoms: sentGame.numberOfAtoms, widthOfPlayArea: sentGame.widthOfPlayArea, heightOfPlayArea: sentGame.heightOfPlayArea);
  List<List<List<int>>> alternativeSolutions = [];
  _numberOfSquares = thisGame.widthOfPlayArea * thisGame.heightOfPlayArea;
  _numberOfSlots = (thisGame.widthOfPlayArea + thisGame.heightOfPlayArea) * 2;
  _numberOfAtoms = thisGame.numberOfAtoms;
  _totalNumberOfPossibleSetups = pow(_numberOfSquares, _numberOfAtoms);
  _widthOfPlayArea = thisGame.widthOfPlayArea;
  _heightOfPlayArea = thisGame.heightOfPlayArea;

  print('_totalNumberOfPossibleSetups is $_totalNumberOfPossibleSetups');
  print('Number of squares $_numberOfSquares to the power of number of atoms $_numberOfAtoms');
  allUniqueSetups = [];

  findAllUniqueSetups();

  print('allUniqueSetups after findAllUniqueSetups() is $allUniqueSetups\n');
  print('and its length (number of unique setups) is ${allUniqueSetups.length}');
  //TODO: remove! (Test for fireAllBeams with Random setup)
  // testGame.atoms = [];
  // testGame.getAtomsRandomly();

  // Display all unique setups:
  int result = 0;
  int gameNo = 0;
  int i = 0;
  do {
    AltSolPlay uniqueGame = AltSolPlay(numberOfAtoms: _numberOfAtoms, widthOfPlayArea: _widthOfPlayArea, heightOfPlayArea: _heightOfPlayArea);
    uniqueGame.atoms = allUniqueSetups[gameNo];
    // Returns null if "Pop" is pressed:
    result = await Navigator.push(context, PageRouteBuilder(pageBuilder: (context, anim1, anim2) {
      return ResultsScreen(thisGame: uniqueGame, setupData: {}, testing: [gameNo, allUniqueSetups.length]);
    }));
    if (result != null && gameNo + result >= 0 && gameNo + result < allUniqueSetups.length) gameNo += result;
  } while (result != null && i < 100);

  // Next steps:
  // for (List setup in allUniqueSetups) {
  //   AltSolPlay uniqueGame = AltSolPlay(numberOfAtoms: _numberOfAtoms, widthOfPlayArea: _widthOfPlayArea, heightOfPlayArea: _heightOfPlayArea);
  //   uniqueGame.atoms = setup;
  //   // print('Test game atoms are ${uniqueGame.atoms}');
  //   // Fire all beams and put result in beamsAndResults:
  //   // uniqueGame.beamsAndResults = fireAllBeams(uniqueGame, _numberOfSlots);
  //   // print('newGame.beamsAndResults is ${newGame.beamsAndResults}');
  //
  //   // print('thisGame.atoms are ${thisGame.atoms}');
  //
  //   ///----------------------------------------------------------
  //   // bool solutionsEquivalent = true;
  //   // int i = 0;
  //   // for (List<dynamic> bNr in uniqueGame.beamsAndResults) {
  //   //   if (!ListEquality().equals(bNr, uniqueGame.beamsAndResults[i])) {
  //   //     solutionsEquivalent = false;
  //   //   }
  //   //   i++;
  //   // }
  //   // print('Solutions are equivalent? $solutionsEquivalent!');
  //   ///----------------------------------------------------------
  // }

  return alternativeSolutions;
}

List<List<dynamic>> fireAllBeams(AltSolPlay game, int numberOfSlots) {
  for (int i = 1; i <= numberOfSlots; i++) {
    print('Slot no $i');
    dynamic result = game.getBeamResult(inSlot: i);
    game.setEdgeTiles(inSlot: i, beamResult: result);
  }
  return game.beamsAndResults;
}

///---------------------------------------------------------------------------
void findAllUniqueSetups() {
  List<Atom> testAtoms = List.filled(_numberOfAtoms, null);
  bool backtrack = false;
  Position start = Position(1, 1);

  // Loop through all atoms:
  int safetyBreak = 0;
  int breakValue = 10000;
  for (int atomNo = 0; atomNo < _numberOfAtoms && safetyBreak < breakValue; atomNo++) {
    safetyBreak++;
    print('lap $safetyBreak.');
    // List<int> newbie;
    // bool addedAtom = false;
    if (!backtrack && atomNo > 0) {
      List startList = findNewStartValue(testAtoms[atomNo - 1].position.toList(), testAtoms);
      start = Position(startList[0], startList[1]);
      print('Starting x and y loops at ${start.toList()} for atom no $atomNo');
    }
    backtrack = false; // Maybe move this to later in the loop

    for (int x = start.x; x <= _widthOfPlayArea; x++) {
      for (int y = start.y; y <= _heightOfPlayArea; y++) {
        print('Atom $atomNo at position [$x, $y]');
        // Seems the below is not needed anymore... Seems it only suggests unique atoms after my start.x start.y function
        // newbie = [x, y];
        // bool newbieUnique = true;
        // for (Atom atom in testAtoms) {
        //   // If a non-null atom is equal to newbie:
        //   if (atom != null && ListEquality().equals(newbie, atom.position.toList())) {
        //     print('newbie $x,$y equals oldie atom ${atom.position.toList()}: Not approved.');
        //     newbieUnique = false;
        //     break;
        //   }
        // }
        // if (newbieUnique) {
        // returnAtoms.add(Atom(newbie[0], newbie[1]));
        // testAtoms[atomNo] = Atom(newbie[0], newbie[1]);
        testAtoms[atomNo] = Atom(x, y);
        // addedAtom = true; // THen even this is not needed... Coz it always adds!

        // If setup is not yet full:
        if (testAtoms.contains(null)) {
          start = Position(1, 1); // For the next atom after backtrack. The backtracked atom
          break;
        }
        // }

        // Now, it's like I could turn the below into "else"...! ;D
        // If the new setup has the right number of atoms:
        if (/*newbieUnique &&*/ !testAtoms.contains(null)) {
          // No longer needed... It only suggests unique setups:
          // Check if the setup is unique or if it overlaps one that we already have:
          // bool setupUnique = isSetupUnique(testAtoms);
          // if (setupUnique) {
          /// Adding and resetting...--------------------------------------------------------------------------
          print('Adding newbie setup $testAtoms');
          // De-linking the added setup from testAtoms:
          List<Atom> _addAtoms = [];
          for (Atom atom in testAtoms) {
            _addAtoms.add(atom);
          }
          allUniqueSetups.add(_addAtoms);
          start = Position(1, 1);
          // addedAtom = true;
          // }
        }
      }
      if (/*addedAtom &&*/ testAtoms.contains(null)) break; // Is addedAtom still needed?
    }
    // x and y are over for the current atom
    // if (addedAtom) break;
    if (!testAtoms.contains(null)) {
      // If I get to this point, it means no the highest atomNo is out of options.
      // Then try moving the previous atom, or the one before that etc, unless they're all at the end:
      print('Backtracking........................................');
      backtrack = true;
      print('allUniqueSetups are $allUniqueSetups.');
      print('atomNo is $atomNo.');
      print('current setup tested is $testAtoms.');

      bool allAtomsAtEnd = true;
      for (int i = _numberOfAtoms - 2; i >= 0; i--) {
        print('Testing to find newStart of atom $i');
        // List<int> newStart = findNewStartValue(testAtoms[atomNo + 1].position.toList());
        List<int> newStart = findNewStartValue(testAtoms[i].position.toList(), testAtoms);
        // Above returns null if atom is att the end (top right)

        if (newStart != null) {
          print('Found newStart of atom $i: $newStart');
          allAtomsAtEnd = false;
          atomNo = i;
          start.x = newStart[0];
          start.y = newStart[1];
          break;
        }
      }
      if (allAtomsAtEnd) break;

      print('Before nullifying, atomNo is $atomNo and testAtoms is $testAtoms');
      for (int i = atomNo; i < _numberOfAtoms; i++) {
        testAtoms[i] = null;
      }

      print('After nullifying, testAtoms is $testAtoms.');
      print('atomNo is $atomNo and its start value is ${start.toList()}');
      atomNo--; // The loop will increment it before the next cycle, but we want THIS atomNo
    }
  }
  print('safetyBreak is $safetyBreak. For-loop breaks at $breakValue.');
  print('Main for-loop in findAllUniqueSetups() is over. testAtoms is $testAtoms. Returning nothing');
}

List<int> findNewStartValue(List<int> oldStart, List<Atom> testAtoms) {
  List<int> newStart = [];
  // De-linking...:
  for (int i = 0; i < 2; i++) {
    newStart.add(oldStart[i]);
  }

  // Try to increment y first:
  if (newStart[1] < _heightOfPlayArea) {
    newStart[1]++;
  } // Then try x:
  else if (newStart[0] < _widthOfPlayArea) {
    newStart[0]++;
    newStart[1] = 1;
  } else {
    // If none could be incremented:
    newStart = null;
  }

  // Check for clashes:
  for (int atomNo = _numberOfAtoms - 1; atomNo > 0; atomNo--) {
    if (newStart != null && testAtoms[atomNo] != null && newStart.equals(testAtoms[atomNo].position.toList())) {
      newStart = null;
      break;
    }
  }

  return newStart;
}

// bool isSetupUnique(List<Atom> _gameAtoms) {
//   bool uniqueSetup = true;
//   List<List<int>> newbieSetup = [];
//   for (Atom atom in _gameAtoms) {
//     newbieSetup.add(atom.position.toList());
//   }
//   // newbieSetup.add(newbie);
//
//   print('----------------------------\nTesting setup $newbieSetup');
//
//   // // TODO remove
//   // allUniqueSetups = [
//   //   [Atom(1,1) , Atom(2,2)],
//   //   [Atom(1,2) , Atom(2,1)],
//   // ];
//
//   print('All unique setups are: $allUniqueSetups');
//
//   for (List setup in allUniqueSetups) {
//     int atomNo = -1;
//     List<bool> identicalAtoms = List.filled(_numberOfAtoms, false);
//     bool identicalSetup = true;
//     // bool identicalAtom = false;
//     // bool identicalCoord = false;
//     for (Atom oldAtom in setup) {
//       atomNo++;
//       for (List<int> atom in newbieSetup) {
//         // if (ListEquality().equals(oldAtom.position.toList(), atom)) identicalAtom = true;
//         if (ListEquality().equals(oldAtom.position.toList(), atom)) identicalAtoms[atomNo] = true;
//         // print('After testing old atom ${oldAtom.position.toList()} to new atom $atom identicalAtoms: $identicalAtoms');
//       }
//       // If not even one oldAtom was identical to the atom, the atom was unique, and this setup was not identical to newbieSetup:
//       if (!identicalAtoms[atomNo]) {
//         identicalSetup = false;
//         // print('identical Setup is false. Breaking.');
//         break;
//       }
//     }
//     // if setup identical, unique is false
//     if (identicalSetup) {
//       // print('identical Setup is true. Breaking.');
//       uniqueSetup = false;
//       break;
//     }
//     // print('This old setup was not identical with the new one. Trying the next one if there is one.');
//   }
//   // print('Tried all old setups (or skipped them if a match was found). ');
//   print('The setup $newbieSetup is unique: $uniqueSetup!'
//       '\n----------------------------');
//   return uniqueSetup;
// }
