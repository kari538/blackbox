import 'package:blackbox/units/small_functions.dart';
import 'package:blackbox/atom_n_beam.dart';
import 'package:blackbox/my_firebase_labels.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:blackbox/my_firebase.dart';
import 'package:blackbox/play.dart';

Future<List<dynamic>?> finalAnswerPress({required Play thisGame, required String? setupID, required Map<String, dynamic>? setupData, required bool answered, required Future<Timestamp?>? startedPlaying}) async {
  // TODO: ***Put heavy calculation in isolate so the below is not needed
  await Future.delayed(Duration(milliseconds: 200));  // For the spinner to start
  print('Answered in finalAnswerPress() is $answered');
  print('thisGame.online in finalAnswerPress() is ${thisGame.online}');

  thisGame.correctAtoms = [];
  thisGame.misplacedAtoms = [];
  thisGame.missedAtoms = [];
  thisGame.atomScore = 0;
  // First returned element will be the List 'edgeTileChildren' from fireAllBeams.
  // The second will be the game with the original setup.
  // The rest will be alternative games.
  // Like this: return [senderGame.edgeTileChildren, senderGame, altGame];
  List<dynamic>? alternativeSolutions = await thisGame.getScore();

  if (thisGame.online) {
    await onlineButtonPress(thisGame, setupID, setupData, answered, startedPlaying);
    //The "await" here should guarantee that results are uploaded before the correct
    // answer is given to the player...
  }
  return alternativeSolutions;
}

Future<void> onlineButtonPress(Play thisGame, String? setupID, Map<String, dynamic>? setupData, bool answered, Future<Timestamp?>? startedPlaying) async {
   print('setupData in OnlineButtonPress() is:');
   myPrettyPrint(setupData);

  //If I didn't already click Final Answer this round, and I don't already have an uploaded result from before:
  // if (!answered && !(setupData?[kFieldResults]?.containsKey('${thisGame.playerUid}'))) {
  if (!answered && !(setupData!.containsKey(kFieldResults) && setupData[kFieldResults].containsKey('${thisGame.playerUid}'))) {
    // answered = true;
    // thisGame.getAtomScore();

    //Because Firebase can't stomach a List<List<int>>:
    //Put player atoms in array to send:
    List<int?> sendPlayerAtoms = [];
    // for (List<int> pAtom in thisGame.playerAtoms) {
    for (Atom pAtom in thisGame.playerAtoms) {
      sendPlayerAtoms.add(pAtom.position.x);
      sendPlayerAtoms.add(pAtom.position.y);
      // sendPlayerAtoms.add(pAtom[0]);
      // sendPlayerAtoms.add(pAtom[1]);
    }

    //Will create the player ID key in 'result' if it's not there (which it isn't).
    //It should wait so that results are uploaded before 'done' is turned true:
    await MyFirebase.storeObject.collection(kCollectionSetups).doc(setupID).update({
      '$kFieldResults.${thisGame.playerUid}': {
        'A': thisGame.atomScore,
        'B': thisGame.beamScore,
        'sentBeams': thisGame.sentBeams,
        'playerAtoms': sendPlayerAtoms,
        '$kFieldPlayerMoves': thisGame.playerMoves,
        '$kSubFieldStartedPlaying': await startedPlaying, // Might be null (if player started playing before installing this version).
        '$kSubFieldFinishedPlaying': FieldValue.serverTimestamp(),
      }
    });
  }

  // print('About to update done to true');
  //This will navigate any listener to this game to the ResultsScreen(), and must await to avoid deleting and writing at the same time:
  await MyFirebase.storeObject.collection(kCollectionSetups).doc(setupID).update({
    '$kFieldPlaying.${thisGame.playerUid}.$kSubFieldPlayingDone': true,
  });
  // print('Done updating done to true');
  await Future.delayed(Duration(seconds: 6)); // To give the above plenty of time to complete before the below happens
  MyFirebase.storeObject.collection(kCollectionSetups).doc(setupID).update({
    '$kFieldPlaying.${thisGame.playerUid}': FieldValue.delete(),
  });
}
