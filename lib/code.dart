import 'atom_n_beam.dart';
import 'play.dart';
//import 'package:flutter/material.dart';

void main() {
  print('starting...');
  Play thisGame = Play(numberOfAtoms: 4, widthOfPlayArea: 8, heightOfPlayArea: 8);
  print('thisGame is $thisGame');
  thisGame.getAtomsRandomly();
  print('Atoms are in positions:');
  for(Atom atom in thisGame.atoms){
    print(atom.position.toList());
  }
  print('**************************');

  Beam beamA = Beam(start: 10, widthOfPlayArea: thisGame.widthOfPlayArea, heightOfPlayArea: thisGame.heightOfPlayArea);
  print('Beam A starts in position ${beamA.position.toList()} with direction ${beamA.direction.toList()}');

//  dynamic result = thisGame.getBeamResult(beam: beamA, heightOfPlayArea: thisGame.heightOfPlayArea, widthOfPlayArea: thisGame.widthOfPlayArea);
//   dynamic result = thisGame.getBeamResult(beam: beamA);
  thisGame.sendBeam(inSlot: beamA.start);
  // dynamic result = thisGame.sendBeam(inSlot: beamA.start);
  // print('result is $result');

  int q = (3/2).truncate();  //1.5 is 1 or 2?
  print('q is $q');
}

//  List<Atom> atoms = [
//    Atom(3, 3),
//    Atom(3, 5),
//    Atom(6, 8),
//    Atom(3, 6),
//  ];
