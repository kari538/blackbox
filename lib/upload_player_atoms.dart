import 'package:cloud_firestore/cloud_firestore.dart';
import 'my_firebase_labels.dart';
import 'my_firebase.dart';
import 'play.dart';
import 'atom_n_beam.dart';

/// Updates this player's playingAtoms, PlayerMoves and LastMove timestamp.
Future uploadPlayerAtoms(Play thisGame, DocumentSnapshot setup) async {
  //Because Firebase can't stomach a List<List<int>>...,
  //put player atoms in array to send:
  List<int> playingAtomsArray = [];
  // print("thisGame.playerAtoms are ${thisGame.playerAtoms}");
  for (Atom pAtom in thisGame.playerAtoms) {
    playingAtomsArray.add(pAtom.position.x);
    playingAtomsArray.add(pAtom.position.y);
    // playingAtomsArray.add(pAtom[0]);
    // playingAtomsArray.add(pAtom[1]);
  }
  print('Before updating playingAtoms, the last element is ${thisGame.playerMoves.last} '
      'of type ${thisGame.playerMoves.last.runtimeType}');
  // print("playingAtomsArray is $playingAtomsArray\n+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++");
  MyFirebase.storeObject.collection('setups').doc(setup.id).update({
    'playing.${thisGame.playerUid}.playingAtoms': playingAtomsArray,
    'playing.${thisGame.playerUid}.$kFieldPlayerMoves': thisGame.playerMoves,
    'playing.${thisGame.playerUid}.$kSubFieldLastMove': FieldValue.serverTimestamp(),
  } //The dots should take me down in the nested map...
  );
  // DocumentSnapshot y = await  MyFirebase.storeObject.collection('setups').doc(setup.id).get();
  // Map<String, dynamic> updatedAtomSetup = y.data();
  // print('************************\nMiddle element pressed. updatedAtomSetup is $updatedAtomSetup\n************************');
}