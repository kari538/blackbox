import 'play.dart';
import 'screens/results_screen.dart';
import 'my_firebase_labels.dart';
// import 'package:blackbox/firestore_lables.dart';
import 'package:blackbox/my_firebase.dart';
import 'package:collection/collection.dart';
import 'online_screens/follow_playing_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'constants.dart';
import 'package:blackbox/online_screens/sent_results_screen.dart';
import 'file:///C:/Users/karol/AndroidStudioProjects/blackbox/lib/units/blackbox_popup.dart';
import 'package:provider/provider.dart';
import 'package:blackbox/game_hub_updates.dart';

class GameEntry extends StatelessWidget {
  GameEntry(
      {
//        @required this.setupData,
      @required this.setup,
      @required this.i,
      @required this.context});

  final DocumentSnapshot setup;

//  final Map<String, dynamic> setupData;
  final int i;
  final BuildContext context;

  List<Widget> getLeftSideChildren() {
    // final String myId = Provider.of<GameHubUpdates>(context).myId;
    final String myId = MyFirebase.authObject.currentUser.uid;
    // print('myId inside getLeftSideChildren() is $myId');
    final Map userIdMap = Provider.of<GameHubUpdates>(context).providerUserIdMap;
    //TODO: Make the below print out "Anonymous" instead of "null" if the kFieldSender doesn't exist in the userIdMap:
    final String senderScreenName =
        setup.data()[kFieldSender] == myId && userIdMap[setup.data()[kFieldSender]] == 'Anonymous' ? "Me" : userIdMap[setup.data()[kFieldSender]] ?? setup.data()[kFieldSender];
    final String me = Provider.of<GameHubUpdates>(context).myScreenName;
    final List<Widget> children = [
      Text('Setup $i', style: TextStyle(color: kHubSetupColor)),
      // Row(
      //   children: [
      //     RichText(
      //       text: TextSpan(
      //         text: 'By $senderScreenName',
      //         style: TextStyle(color: senderScreenName == me ? Colors.pinkAccent : Colors.lightBlueAccent, fontSize: 18),
      //       ),
      //       maxLines: 1,
      //       overflow: TextOverflow.visible,
      //     ),
      //   ],
      // ),

      Text(
        'By $senderScreenName',
        style: TextStyle(color: senderScreenName == me ? Colors.pinkAccent : Colors.lightBlueAccent),
        softWrap: false,
        overflow: TextOverflow.fade,
      ),
      Text(
        '${setup.data()['widthAndHeight'][0]}x${setup.data()['widthAndHeight'][1]}, ${(setup.data()['atoms'].length / 2).toInt()} atoms',
        style: TextStyle(
          fontSize: 16,
          color: kHubSetupColor,
        ),
      ),
    ];
    return children;
  }

  List<Widget> getResultsChildren() {
    final String me = Provider
        .of<GameHubUpdates>(context)
        .myScreenName;
    final String myId = MyFirebase.authObject.currentUser.uid;
    // final String myId = Provider
    //     .of<GameHubUpdates>(context, listen: false)
    //     .myId;
    final Map userIdMap = Provider
        .of<GameHubUpdates>(context)
        .providerUserIdMap;
    final String myEmail = Provider
        .of<GameHubUpdates>(context, listen: false)
        .myEmail;

    List<Widget> resultsChildren = [Text('Results:', style: kConversationResultsResultsStyle)];
    List<Widget> scrollChildren = [];
    Widget scoreChild;
    //If this game has no result and nobody playing it right now:
    if (setup.data()['results'] == null &&
        (MapEquality().equals(setup.data()['playing'], {}) || !setup.data().containsKey('playing'))) { //Why doesn't it complain that ['results'] was called on null?...
//      print("setup.data()['results'] of ${i +1} is null");
      return [SizedBox()];
      //If somebody is playing:
    } else if (setup.data().containsKey('playing')) {
      for (String player in setup.data()['playing'].keys) {
//        print('Player in Game Entry is $player');
//          resultsChildren.add(
        bool active = false;  // People who play with the old version will be grey
        DateTime now = DateTime.now();
        // if (setup.data()[kFieldPlaying][player].containsKey(kSubFieldLatestMove)) {
        if (setup.data()[kFieldPlaying][player][kSubFieldLatestMove] != null) {
          DateTime lastMove = setup.data()[kFieldPlaying][player][kSubFieldLatestMove].toDate();
          active = lastMove.isAfter(now.subtract(Duration(minutes: 1)));
        } else if (setup.data()[kFieldPlaying][player][kSubFieldStartedPlaying] != null) {
          // If they have a new version app but haven't yet made a move
          DateTime started = setup.data()[kFieldPlaying][player][kSubFieldStartedPlaying].toDate();
          active = started.isAfter(now.subtract(Duration(minutes: 1)));
        }
        Color playingColor = active ? kPlayingTextColor : kSmallResultsColor;

        scrollChildren.add(
          GestureDetector(
              child: SizedBox(
                height: 22, //For a larger click area
                child: Row(
                  children: [
                    Expanded(child: Text('Playing:', style: TextStyle(color: playingColor))),
                    SizedBox(width: 10),
                    Expanded(
                        child: Text('${Provider.of<GameHubUpdates>(context).getScreenName(player)}', style: TextStyle(color: playingColor))),
                  ],
                ),
              ),
              onTap: () {
                print('Tapping "playing". myId is $myId');
                (setup.data()['results'] != null &&
                    (setup.data()['results'].containsKey(me) || setup.data()['results'].containsKey(myId))) ||
                    (setup.data()[kFieldSender] == myEmail ||
                        setup.data()[kFieldSender] == myId)
                    ? Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return FollowPlayingScreen(setup: setup, playingId: player, me: me);
                }))
                    : player == myId
                    ? BlackboxPopup(
                  title: "Nope!",
                  desc: "If you watch yourself play before finishing, you'll see the answer, which would"
                      " totally ruin the fun.",
                  context: context,
                ).show()
                    : BlackboxPopup(
                  title: "Not yet!",
                  desc: "You have to play this setup before you can watch others play it.",
                  context: context,
                ).show();
              }
          ),
        );
      }
    }

    //If it also has results from before:
    if (setup.data()['results'] != null) {
      for (String resultPlayerId in setup.data()['results'].keys) {
        //If the results have the standard Map structure:
        if ((setup.data()['results'][resultPlayerId] is Map) && setup.data()['results'][resultPlayerId]['B'] != null &&
            setup.data()['results'][resultPlayerId]['A'] != null) {
          int beamScore = setup.data()['results'][resultPlayerId]['B'];
          int atomScore = setup.data()['results'][resultPlayerId]['A'];
          int totalScore = beamScore + atomScore;
          scoreChild = Row(
            children: <Widget>[
              Expanded(child: Text('$totalScore', style: kConversationResultsStyle)),
              Expanded(child: Text('b: $beamScore', style: TextStyle(fontSize: 12, color: kSmallResultsColor))),
              Expanded(child: Text('a: $atomScore', style: TextStyle(fontSize: 12, color: kSmallResultsColor))),
            ],
          );
          //If 'results' doesn't have the standard Map structure:
        } else {
          //Could I make this a SingeChildScrollLIst to make room for all the text in future msgs?
          scoreChild =
              SingleChildScrollView(child: Text('${setup.data()['results'][resultPlayerId]}', style: kConversationResultsStyle, softWrap: true));
        }
        //Unless the result is an int between -10 and 0 (for passing msgs to people with the old app version):
        if (!(setup.data()['results'][resultPlayerId] is int && -10 < setup.data()['results'][resultPlayerId] &&
            setup.data()['results'][resultPlayerId] < 0)) {
          //If the key exists, show the value, otherwise show the playerID as it is:
          final String resultScreenName = userIdMap.containsKey(resultPlayerId)
              ? '${Provider.of<GameHubUpdates>(context).getScreenName(resultPlayerId)}'
              : '$resultPlayerId';
          scrollChildren.add(
            GestureDetector(
              child: SizedBox(
                height: 22, //For a larger click area
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        '$resultScreenName:',
                        style: resultScreenName == me ? kConversationResultsStyle.copyWith(color: Colors.pinkAccent) : kConversationResultsStyle,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(child: scoreChild),
                  ],
                ),
              ),
              onTap: () {
                setup.data()['results'].containsKey(me) || setup.data()['results'].containsKey(myId) || setup.data()[kFieldSender] == myEmail ||
                    setup.data()[kFieldSender] == myId
                //If I either played or made this setup
                    ? showResult(context: context, setupData: setup.data(), resultPlayerId: resultPlayerId)
                    : BlackboxPopup(
                  title: "Not yet!",
                  desc: "You have to play this setup before you can see the results of others.",
                  context: context,
                ).show();
              },
            ),
          );
        }
      }
    }

    resultsChildren.add(Expanded(child: ListView(children: scrollChildren, shrinkWrap: true, reverse: false)));
//    if(i+1 == 72 || i+1 == 62) print('resultsChildren of setup ${i+1} is $resultsChildren');
//    if(i+1 == 87) print('resultsChildren of setup ${i+1} is $resultsChildren and length is ${resultsChildren.length}');
    if (scrollChildren.length == 0) return [SizedBox()]; //This happens between -10 and 0.
    return resultsChildren;
  }

  @override
  Widget build(BuildContext context) {
//    print("Building game entry ${i + 1}");
    return Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.black), color: kBoardColor),
      height: 100,
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: getLeftSideChildren(),
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: getResultsChildren(),
            ),
          ),
        ],
      ),
    );
  }
}


void showResult({BuildContext context, Map<String, dynamic> setupData, String resultPlayerId}) {
  // Play thisGame = Play(numberOfAtoms: numberOfAtoms, widthOfPlayArea: widthOfPlayArea, heightOfPlayArea: heightOfPlayArea);
  //
  // Navigator.push(
  //   context,
  //   MaterialPageRoute(builder: (context) {
  //     return ResultsScreen(
  //       thisGame: thisGame,
  //       setupData: setupData,
  //       resultPlayerId: '$resultPlayerId',
  //     );
  //   }),
  // );
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) {
      return SentResultsScreen(
        setupData: setupData,
        resultPlayerId: '$resultPlayerId',
      );
    }),
  );
}