// import 'package:blackbox/atom_n_beam.dart';

import 'play.dart';
import 'package:flutter/material.dart';

class AltSolPlay extends Play {
  AltSolPlay({@required this.numberOfAtoms, @required this.widthOfPlayArea, @required this.heightOfPlayArea, this.showAtomSetting = false})
  : super(numberOfAtoms: numberOfAtoms, widthOfPlayArea: widthOfPlayArea, heightOfPlayArea: heightOfPlayArea){
    // alreadyTried = [];
    // for (int atomNo = 0; atomNo < numberOfAtoms; atomNo++){
      // alreadyTried.add([]);
    // }
  }
  int numberOfAtoms;
  bool showAtomSetting;
  int widthOfPlayArea;
  int heightOfPlayArea;

  List<List<dynamic>> beamsAndResults = [];
  // List<List<List<int>>> alreadyTried = List.filled(numberOfAtoms, []);
  // List<List<Atom>> alreadyTried;

  @override
  dynamic getBeamResult({@required int inSlot}) {
    var result = super.getBeamResult(inSlot: inSlot);
    beamsAndResults.add([inSlot, result]);
    print('beamsAndResults is $beamsAndResults');
    return result;
  }


}