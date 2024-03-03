import 'my_firebase.dart';
import 'my_firebase_labels.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'play.dart';

/// Updates this player's MarkupList and PlayerMoves.
Future uploadMarkup (Play thisGame, DocumentSnapshot setup) async {
  List<int> markUpArray = [];
  for (List<int> markUp in thisGame.markUpList){
    markUpArray.add(markUp[0]);
    markUpArray.add(markUp[1]);
  }
  MyFirebase.storeObject.collection(kCollectionSetups).doc(setup.id).update({
    'playing.${thisGame.playerUid}.$kSubFieldMarkUpList': markUpArray,
    'playing.${thisGame.playerUid}.$kFieldPlayerMoves': thisGame.playerMoves,
  }); //The dots take me down in the nested map.
}