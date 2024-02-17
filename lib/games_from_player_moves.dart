import 'package:collection/src/equality.dart';
import 'package:blackbox/atom_n_beam.dart';
import 'package:blackbox/my_firebase_labels.dart';
import 'package:blackbox/play.dart';
import 'package:flutter/cupertino.dart';

/// Takes thisGame as argument, and returns a list of games for each move.
/// Games should have correctAtoms, unfoundAtoms and wronglyPlacedAtoms,
/// except if the game is already finished, in which case the last game
/// should have correctAtoms, missedAtoms and misplacedAtoms.
/// All games should also have edgeTileChildren.
List<Play?> gamesFromPlayerMoves({required Play thisGame}) {
  List<dynamic> moves = thisGame.playerMoves;
  /// A game for each move, plus the 0th move and the result(?)
  List<Play?> moveGames = List.filled(moves.length + 1, null, growable: false);
  Play accumulatingGame = Play(numberOfAtoms: thisGame.numberOfAtoms, widthOfPlayArea: thisGame.widthOfPlayArea, heightOfPlayArea: thisGame.heightOfPlayArea);
  accumulatingGame.playerUid = thisGame.playerUid;
  accumulatingGame.atoms = thisGame.atoms;
  accumulatingGame.unfoundAtoms = thisGame.atoms; // They're all unfound at first!

  int i = 0;
  makeAddGame(accumulatingGame: accumulatingGame, moveGames: moveGames, i: i);

  // Loop through all the moves and play the game:
  i = 1;
  for (dynamic move in moves) {
    // move can be a Map<String, List> or a String.
    // The Map contains a key with the moveAction and a list of coordinates.
    // The String contains only a moveAction, such as fill with atoms, or finish.
    String? moveAction;

    // If it's a Map:
    if (move is Map) {
      moveAction = move.keys.first as String;
    // If it's a String:
    } else if (move is String) {
      moveAction = move;
    }

    if (moveAction == kPlayerMoveBeam) {
      // Sent a beam
      Map<String, dynamic> moveMap = move as Map<String, dynamic>;  // Cast
      int inSlot = moveMap.values.first as int;
      dynamic result = accumulatingGame.sendBeam(inSlot: inSlot);
      accumulatingGame.setEdgeTiles(inSlot: inSlot, beamResult: result);
      makeAddGame(accumulatingGame: accumulatingGame, moveGames: moveGames, i: i);
      print('Correct atoms of moveGames[$i]? is ${moveGames[i]?.correctAtoms} and of moveGames[0]? is ${moveGames[0]?.correctAtoms}');

      // print('moveGames.edgeTileChildren.length are:');
      // for (Play game in moveGames) {
      //   myPrettyPrint(game.edgeTileChildren?.length);
      // }
      // print('addGame.correctAtoms of lap $i is ${addGame.correctAtoms}');

    } else if (moveAction == kPlayerMoveAddAtom) {
      // Added an atom
      Map<String, dynamic> moveMap = move as Map<String, dynamic>;  // Cast
      List<dynamic> coordinates = moveMap.values.first as List<dynamic>;
      accumulatingGame.playerAtoms.add(Atom(coordinates[0], coordinates[1]));
      // Ok, now I've added the player atom. But I also need to decide if
      // it's correct or wrongly placed!... And who's gonna decide the
      // unfound ones...?
      updateCorrectAtoms(accumulatingGame: accumulatingGame, thisGame: thisGame);
      // bool correctlyPlaced = false;
      //
      // // Loop through all player atoms and setup atoms:
      // for (Atom playerAtom in thisGame.playerAtoms) {
      //     for (Atom setupAtom in thisGame.atoms) {
      //       // This atom is correctly placed:
      //       if (ListEquality().equals(playerAtom.position.toList(), setupAtom.position.toList())) {
      //         correctlyPlaced = true;
      //         accumulatingGame.correctAtoms.add(playerAtom);
      //         break;
      //       }
      //     }
      //
      //     // This atom is wrongly placed:
      //     if (!correctlyPlaced) {
      //       accumulatingGame.notYetCorrectlyPlacedAtoms.add(playerAtom);
      //     }
      //
      // }

      makeAddGame(accumulatingGame: accumulatingGame, moveGames: moveGames, i: i);
      print('Correct atoms of moveGames[$i]? is ${moveGames[i]?.correctAtoms} and of moveGames[0]? is ${moveGames[0]?.correctAtoms}');

    } else if (moveAction == kPlayerMoveRemoveAtom) {
      // Removed an atom
      Map<String, dynamic> moveMap = move as Map<String, dynamic>;  // Cast
      List<dynamic> coordinates = moveMap.values.first as List<dynamic>;
      int? removeIndex;
      int _i = 0;
      for (Atom playerAtom in accumulatingGame.playerAtoms) {
        if (ListEquality().equals(coordinates, playerAtom.position.toList())) {
          removeIndex = _i;
        }
        _i++;
      }
      if (removeIndex != null) {
        accumulatingGame.playerAtoms.removeAt(removeIndex);
      }

      updateCorrectAtoms(accumulatingGame: accumulatingGame, thisGame: thisGame);

      makeAddGame(accumulatingGame: accumulatingGame, moveGames: moveGames, i: i);
      print('Correct atoms of moveGames[$i]? is ${moveGames[i]?.correctAtoms} and of moveGames[0]? is ${moveGames[0]?.correctAtoms}');

    } else if (moveAction == kPlayerMoveAddMarkup) {
      // Added markup
      Map<String, dynamic> moveMap = move as Map<String, dynamic>;  // Cast
      List<dynamic> coordinates = moveMap.values.first as List<dynamic>;
      List<int> markupCoordinates = [];
      for (dynamic coord in coordinates) {
        if (coord is int) {
          markupCoordinates.add(coord);
        }
      }
      accumulatingGame.markUpList.add(markupCoordinates);
      makeAddGame(accumulatingGame: accumulatingGame, moveGames: moveGames, i: i);
      print('Correct atoms of moveGames[$i]? is ${moveGames[i]?.correctAtoms} and of moveGames[0]? is ${moveGames[0]?.correctAtoms}');
      print('markUpList of moveGames[$i]? is ${moveGames[i]?.markUpList} and of moveGames[0]? is ${moveGames[0]?.markUpList}');

    } else if (moveAction == kPlayerMoveRemoveMarkup) {
      // Removed a markup
      Map<String, dynamic> moveMap = move as Map<String, dynamic>;  // Cast
      List<dynamic> coordinates = moveMap.values.first as List<dynamic>;
      List<int> markupCoordinates = [];
      for (dynamic coord in coordinates) {
        if (coord is int) {
          markupCoordinates.add(coord);
        }
      }
      int? removeIndex;
      int _i = 0;
      for (List<int> markup in accumulatingGame.markUpList) {
        if (ListEquality().equals(markupCoordinates, markup)) {
          removeIndex = _i;
        }
        _i++;
      }
      if (removeIndex != null)
        accumulatingGame.markUpList.removeAt(removeIndex);

      makeAddGame(accumulatingGame: accumulatingGame, moveGames: moveGames, i: i);
      print('Correct atoms of moveGames[$i]? is ${moveGames[i]?.correctAtoms} and of moveGames[0]? is ${moveGames[0]?.correctAtoms}');
      print('markUpList of moveGames[$i]? is ${moveGames[i]?.markUpList} and of moveGames[0]? is ${moveGames[0]?.markUpList}');

    } else if (moveAction == kPlayerMoveClearAllAtoms) {
      // Cleared all atoms:
      accumulatingGame.playerAtoms = [];
      accumulatingGame.correctAtoms = [];
      accumulatingGame.notYetCorrectAtoms = [];
      accumulatingGame.misplacedAtoms = [];
      accumulatingGame.unfoundAtoms = thisGame.atoms;

      updateCorrectAtoms(accumulatingGame: accumulatingGame, thisGame: thisGame);

      makeAddGame(accumulatingGame: accumulatingGame, moveGames: moveGames, i: i);
      print('Correct atoms of moveGames[$i]? is ${moveGames[i]?.correctAtoms} and of moveGames[0]? is ${moveGames[0]?.correctAtoms}');

    } else if (moveAction == kPlayerMoveClearAllMarkup) {
      // Cleared all markup:
      accumulatingGame.markUpList = [];
      
      makeAddGame(accumulatingGame: accumulatingGame, moveGames: moveGames, i: i);
      print('Correct atoms of moveGames[$i]? is ${moveGames[i]?.correctAtoms} and of moveGames[0]? is ${moveGames[0]?.correctAtoms}');

    } else if (moveAction == kPlayerMoveFillWithAtoms) {
      // Filled with atoms:
      print('Filled with atoms+++++');
      accumulatingGame.playerAtoms = [];
      for (int x = 1; x <= accumulatingGame.widthOfPlayArea; x++) {
        for (int y = 1; y <= accumulatingGame.heightOfPlayArea; y++) {
          accumulatingGame.playerAtoms.add(Atom(x, y));
        }
      }

      print('accumulatingGame.playerAtoms.length is ${accumulatingGame.playerAtoms.length}');
      updateCorrectAtoms(accumulatingGame: accumulatingGame, thisGame: thisGame);

      makeAddGame(accumulatingGame: accumulatingGame, moveGames: moveGames, i: i);
      print('Correct atoms of moveGames[$i]? is ${moveGames[i]?.correctAtoms} and of moveGames[0]? is ${moveGames[0]?.correctAtoms}');

    } else if (moveAction == kPlayerMoveFillWithMarkup) {
      // Filled with markup:
      accumulatingGame.markUpList = [];
      for (int x = 1; x <= accumulatingGame.widthOfPlayArea; x++) {
        for (int y = 1; y <= accumulatingGame.heightOfPlayArea; y++) {
          accumulatingGame.markUpList.add([x, y]);
        }
      }

      makeAddGame(accumulatingGame: accumulatingGame, moveGames: moveGames, i: i);
      print('Correct atoms of moveGames[$i]? is ${moveGames[i]?.correctAtoms} and of moveGames[0]? is ${moveGames[0]?.correctAtoms}');

    } else if (moveAction == kPlayerMoveFinish) {
      // Finished:
      for (Atom notYetAtom in accumulatingGame.notYetCorrectAtoms) {
        accumulatingGame.misplacedAtoms.add(notYetAtom);
      }
      accumulatingGame.notYetCorrectAtoms = [];

      makeAddGame(accumulatingGame: accumulatingGame, moveGames: moveGames, i: i);
      print('Correct atoms of moveGames[$i]? is ${moveGames[i]?.correctAtoms} and of moveGames[0]? is ${moveGames[0]?.correctAtoms}');
    }
    // else if (moveAction == )

    i++;
  }
  print('After all of that, correct atoms of moveGames[0]? is ${moveGames[0]?.correctAtoms}');
  return moveGames;
}

/// Will update moveGames\[i\] with:
/// playerUid
/// correctAtoms
/// unfoundAtoms
/// notYetCorrectlyPlacedAtoms
/// missedAtoms
/// misplacedAtoms
/// markUpList
/// edgeTileChildren
void makeAddGame({required Play accumulatingGame, required List<Play?> moveGames, required int i}) {
  Play _tempGame = Play(numberOfAtoms: accumulatingGame.numberOfAtoms, widthOfPlayArea: accumulatingGame.widthOfPlayArea, heightOfPlayArea: accumulatingGame.heightOfPlayArea);
  _tempGame.playerUid = accumulatingGame.playerUid;
  for (Atom correctAtom in accumulatingGame.correctAtoms) {
    _tempGame.correctAtoms.add(correctAtom);
  }
  for (Atom unfoundAtom in accumulatingGame.unfoundAtoms) {
    _tempGame.unfoundAtoms.add(unfoundAtom);
  }
  for (Atom wronglyPlacedAtom in accumulatingGame.notYetCorrectAtoms) {
    _tempGame.notYetCorrectAtoms.add(wronglyPlacedAtom);
  }
  for (Atom missedAtom in accumulatingGame.missedAtoms) {
    _tempGame.missedAtoms.add(missedAtom);
  }
  for (Atom misplacedAtom in accumulatingGame.misplacedAtoms) {
    _tempGame.misplacedAtoms.add(misplacedAtom);
  }
  for (List<int> markup in accumulatingGame.markUpList) {
    _tempGame.markUpList.add(markup);
  }
  for (int j=0; j < accumulatingGame.edgeTileChildren.length; j++) {
    _tempGame.edgeTileChildren[j] = accumulatingGame.edgeTileChildren[j];
  }

  moveGames[i] = _tempGame;
}



/// Will update accumulatingGame with correctAtoms and notYetCorrectAtoms by
/// comparing accumulatingGame.playerAtoms with thisGame.atoms
void updateCorrectAtoms({required Play thisGame, required Play accumulatingGame}) {
  accumulatingGame.correctAtoms = [];
  accumulatingGame.notYetCorrectAtoms = [];

  // Loop through all player atoms and setup atoms:
  for (Atom playerAtom in accumulatingGame.playerAtoms) {
    bool correctlyPlaced = false;
    for (Atom setupAtom in thisGame.atoms) {
      print('playerAtom is ${playerAtom.position.toList()} and '
          'setupAtom is ${setupAtom.position.toList()}');

      // This atom is correctly placed:
      if (ListEquality().equals(playerAtom.position.toList(), setupAtom.position.toList())) {
        correctlyPlaced = true;
        accumulatingGame.correctAtoms.add(playerAtom);
        break;
        // TODO: $$$ Remove this as an unfound atom! (Not necessary coz correct ends up on top)
      }
    }
    print('After break');
    print('correctlyPlaced is $correctlyPlaced');

    // This atom is wrongly placed:
    if (!correctlyPlaced) {
      print('Adding notYetCorrectAtom ${playerAtom.position.toList()}');
      accumulatingGame.notYetCorrectAtoms.add(playerAtom);
    }
  }
  print('notYetCorrectAtoms is ${accumulatingGame.notYetCorrectAtoms}');
}