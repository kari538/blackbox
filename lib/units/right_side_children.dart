import 'package:blackbox/units/small_functions.dart';
import 'package:blackbox/online_screens/sent_results_screen.dart';
import 'package:blackbox/game_hub_updates.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import 'blackbox_popup.dart';
import 'package:blackbox/constants.dart';
import 'package:blackbox/my_firebase.dart';
import 'package:blackbox/my_firebase_labels.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart' show DocumentSnapshot;
import 'package:flutter/material.dart';


class RightSideChildren extends StatefulWidget {
  RightSideChildren({@required Key key, @required this.setup, @required this.setupData, @required this.i}): super(key: key);

  final DocumentSnapshot setup;
  final Map<String, dynamic> setupData;
  final int i;

  @override
  _RightSideChildrenState createState() => _RightSideChildrenState(setup, setupData, i);
}

class _RightSideChildrenState extends State<RightSideChildren> {
  _RightSideChildrenState(this.setup, this.currentSetupData, this.i);

  final DocumentSnapshot setup;
  Map<String, dynamic> currentSetupData = {};
  final int i;

  StreamSubscription thisSetupStream; // For adding and removing Playing and Result tags
  StreamSubscription pingStreamListener; // For determining active or not, if pings exist
  // StreamSubscription playingStream;

  Map<String, bool> activeMap = {}; // {String player: bool active}
  Map<String, int> moveCountDownMap = {}; // {String player: int countDown}
  Map<String, int> pingCountDownMap = {}; // {String player: int countDown}
  Map<String, dynamic> pingMap = {}; // {String player: TimeStamp ping}
  // Map<String, Timestamp> pingMap = {};
  int moveCountDownStart = 60;
  int pingCountDownStart = 6;
  int pingExpiry = 5; // sec
  int moveExpiry = 60; // sec
  // Future pingReady;

  @override
  void initState() {
    super.initState();
    // Make activeMap entry and a countDownMap entry for each Playing:
    if (currentSetupData.containsKey(kFieldPlaying)) {
      for (String player in currentSetupData[kFieldPlaying].keys) {
        // Would be nice, but I have no info on the Ping sub-collection yet:
        // pingMap.addAll({
        //   player: ping
        // });
        activeMap.addAll({player: isActive(player, currentSetupData, pingMap, i)});
        moveCountDownMap.addAll({player: moveCountDownStart});
        moveCountDown(player);

        pingCountDownMap.addAll({player: pingCountDownStart});
        // getPingStream();
        pingCountDown(player);
      }
      // print('actives in $i is $activeMap');
      // print('moveCountDowns in $i is $moveCountDownMap');
    }

    getPingStream();
    // pingReady
    getThisSetupStream();
  }

  @override
  void dispose() {
    if (thisSetupStream != null) thisSetupStream.cancel();
    if (pingStreamListener != null) pingStreamListener.cancel();
    // if (playingStream != null) playingStream.cancel();
    super.dispose();
  }

  void moveCountDown(String player) async {
    // If a player is removed, the countdown for that player ends:
    while (moveCountDownMap.containsKey(player) && this.mounted) {
      await Future.delayed(Duration(seconds: 1));
      if (moveCountDownMap.containsKey(player)) {
        moveCountDownMap[player]--;
        // countDown--;
        // == true has to be there, coz might have become null during countdown:
        if (moveCountDownMap[player] == 0 && activeMap[player] == true && this.mounted) {
          // if (countDown < 0 && this.mounted) {
          setState(() {
            // print('setState in RightSideChildren moveCountDown()');
            // print('Changing active to passive for $player in $i');
            activeMap[player] = false;
          });
        }
      }
    }
  }

  void pingCountDown(String player) async {
    // If a player is removed, the countdown for that player ends:
    while (pingCountDownMap.containsKey(player) && this.mounted) {
      await Future.delayed(Duration(seconds: 1));
      if (pingCountDownMap.containsKey(player)) {
        pingCountDownMap[player]--;
        // The entries may no longer exist, so == true has to be added:
        if (pingCountDownMap[player] == 0 && activeMap[player] == true && this.mounted) {
          // if (countDown < 0 && this.mounted) {
          setState(() {
            // print('setState in RightSideChildren');
            // print('Changing active to passive for $player in $i');
            activeMap[player] = false;
          });
        }
      }
    }
  }

  void getThisSetupStream() async {
    // print('getThisSetupStream() in i = $i..........');
    int j = 0; // Counting stream laps. The first lap shouldn't setState.

    thisSetupStream = MyFirebase.storeObject.collection(kCollectionSetups).doc(setup.id).snapshots().listen((event) {
      // print('A new event has come in in getThisSetupStream() setup $i'
      //     // '\nevent.data() is ${event.data()}'
      //     '');
      // Since everything that can come into this stream is probably a change in a Playing field,
      // why not just check if active has changed? And if it has, setState!

      Map<String, dynamic> newSetupData = event.data();
      Map<String, dynamic> newResultsData = newSetupData[kFieldResults];
      Map<String, dynamic> newPlayingData = newSetupData[kFieldPlaying] ?? {};
      Map<String, dynamic> oldPlayingData = currentSetupData[kFieldPlaying] ?? {};

      Map<String, bool> newActiveMap = {};
      Map<String, int> newMoveCountDownMap = {};

      // Check for changes in Playing (atom or beam):
      // No need to setState coz these changes cause the game hub screen to rebuild...
      // And if the number of tags changes, it still calls setState.
      for (String player in newPlayingData.keys) {
        // If somebody already playing:
        if (oldPlayingData.containsKey(player)) {
          // if (currentSetupData.containsKey(kFieldPlaying) && currentSetupData[kFieldPlaying].containsKey(player)) {
          bool atomChange =
          !(ListEquality().equals(newPlayingData[player][kSubFieldPlayingAtoms], currentSetupData[kFieldPlaying][player][kSubFieldPlayingAtoms]));
          bool beamChange =
          !(ListEquality().equals(newPlayingData[player][kSubFieldPlayingBeams], currentSetupData[kFieldPlaying][player][kSubFieldPlayingBeams]));
          if (atomChange) {
            // print('An atom changed in $i player $player');
            activeMap[player] = true;
            moveCountDownMap[player] = moveCountDownStart;
          }
          if (beamChange) {
            // print('A beam changed in $i player $player');
            activeMap[player] = true;
            moveCountDownMap[player] = moveCountDownStart;
          }
        }
      }

      // If there were Results before OR after the event:
      if (j > 0 && (!MapEquality().equals(newResultsData, {}) || !MapEquality().equals(currentSetupData[kFieldResults], {}))) {
        // if (j > 0 && (newResultsData != null || currentSetupData[kFieldResults] != null)) {
        // if (newResultsData != null && currentSetupData[kFieldResults] != null) {
        // print('RightSideChildren: Counting Results tags in setup $i'
        //     '\ncondition1 is ${!MapEquality().equals(newResultsData, {})}'
        //     '\ncondition2 is ${!MapEquality().equals(currentSetupData[kFieldResults], {})}'
        //     '\nnewResultsData is \n$newResultsData '
        //     '\nand currentSetupData[kFieldResults is \n${currentSetupData[kFieldResults]}'
        //     '');
        int resultLengthBefore = currentSetupData[kFieldResults] != null ? currentSetupData[kFieldResults].length : 0;
        int resultLengthAfter = newResultsData != null ? newResultsData.length : 0;
        // If the number of Results are different, setState:
        if (resultLengthAfter != resultLengthBefore) {
          // print('RightSideChildren: Results have come in (or been removed...) in setup $i');
          setState(() {
            // Setting state
            currentSetupData = newSetupData;
            activeMap = newActiveMap;
          });
        }
      }

      // If there were Playing before OR after the event:
      if (j > 0 && (!MapEquality().equals(newPlayingData, {}) || !MapEquality().equals(oldPlayingData, {}))) {
        //   print('RightSideChildren: Counting Playing tags in setup $i');
        int playingLengthBefore = oldPlayingData.length;
        int playingLengthAfter = newPlayingData.length;

        // If the number of Playing is different, setState:
        if (playingLengthAfter != playingLengthBefore) {
          // print('RightSideChildren: A player has started or stopped playing in setup $i');
          for (String player in newPlayingData.keys) {
            newActiveMap.addAll({player: activeMap[player] ?? isActive(player, newSetupData, pingMap, i)});
            // print('newActiveMap in $i is $newActiveMap');

            newMoveCountDownMap.addAll({
              player: moveCountDownMap[player] ?? moveCountDownStart,
            });

            // Start a new move countdown for new players, but not for old:
            if (!moveCountDownMap.containsKey(player)) {
              moveCountDownMap.addAll({player: moveCountDownStart});
              moveCountDown(player);
            }
          }

          setState(() {
            // Setting state
            currentSetupData = newSetupData;
            activeMap = newActiveMap;
            moveCountDownMap = newMoveCountDownMap;
          });
        }
      }
      // /// MAP EQUALITY DOES NOT WORK FOR NESTED MAPS!!!!!
      j++;
    });
  }

  void getPingStream() async {
    // print('getPingStream() in RightSideChildren()');
    pingStreamListener = MyFirebase.storeObject
        .collection(kCollectionSetups)
        .doc(setup.id)
        .collection(kSubCollectionPlayingPings)
        .doc(kSubCollectionPlayingPings)
        .snapshots()
        .listen((event) {
      // print('Event in pingStreamListener.listen() setup $i ');
      Map<String, dynamic> newPingMap = event.data() ?? {}; // Should I ever want to compare new with old...
      // pingMap = event.data();
      DateTime now = DateTime.now();
      for (String player in newPingMap.keys) {
        // Start a new ping countdown for new players, but not for old:
        if (!pingCountDownMap.containsKey(player)) {
          pingCountDownMap.addAll({player: pingCountDownStart});
          pingCountDown(player);
        }

        // for (String player in pingMap.keys) {
        // print('A new ping in $i player $player');
        if (newPingMap[player] != null) {
          // print('player is $player and newPingMap[player] is ${newPingMap[player]}\n'
          //     'newPingMap is $newPingMap');
          bool previousActive = activeMap[player] ?? false;
          DateTime lastPing = newPingMap[player].toDate();
          // DateTime lastPing = pingMap[player].toDate();
          if (lastPing.isAfter(now.subtract(Duration(seconds: pingExpiry)))) {
            pingCountDownMap.putIfAbsent(player, () => pingCountDownStart);
            pingCountDownMap[player] = pingCountDownStart;
            if (!previousActive && this.mounted)
              setState(() {
                activeMap[player] = true;
              });
          }
        }
      }

      // Remove countdowns for players that removed their tag:
      for (int i = 0; i < pingCountDownMap.length; i++) {
        String player = pingCountDownMap.keys.elementAt(i);
        if (!newPingMap.containsKey(player)) {
          pingCountDownMap.remove(player);
        }
      }
      // print('pingCountDownMap in setup $i is $pingCountDownMap');

      pingMap = newPingMap;
    });
  }

  bool isActive(String player, Map<String, dynamic> setupData, Map<String, dynamic> pingMap, int i) {
    //   print('Running isActive().'
    //       '\npingMap is $pingMap'
    //       '\nand setupData is $setupData'
    //       '');
    bool _active = false;
    if (!setupData[kFieldPlaying].containsKey(player)) return _active; // In the rest of the function, setupData[kFieldPlaying][player] will exist

    DateTime now = DateTime.now();
    bool freshPingExists = pingMap != null && pingMap[player] != null;
    DateTime lastPing = freshPingExists ? pingMap[player].toDate() : null;
    bool lastMoveExists = /*setupData[kFieldPlaying][player].containsKey(kSubFieldLastMove) &&*/ setupData[kFieldPlaying][player]
    [kSubFieldLastMove] !=
        null;
    DateTime lastMove = lastMoveExists ? setupData[kFieldPlaying][player][kSubFieldLastMove].toDate() : null;
    // If the last move is much later than the last ping, maybe the user changed to an app version that doesn't have ping or something...:
    if (lastMoveExists && freshPingExists && lastMove.isAfter(lastPing.add(Duration(seconds: pingExpiry)))) freshPingExists = false;
    bool startTimeExists = setupData[kFieldPlaying][player][kSubFieldStartedPlaying] != null;
    DateTime startTime = startTimeExists ? setupData[kFieldPlaying][player][kSubFieldStartedPlaying].toDate() : null;

    if (freshPingExists) {
      // print('lastPing of player $player in setup $i is $lastPing');
      // print('now in setup $i is $now');
      // print('lastPing.isAfter(now.subtract(Duration(minutes: 60))) ("active") is ${lastPing.isAfter(now.subtract(Duration(minutes: 60)))}');
      _active = lastPing.isAfter(now.subtract(Duration(seconds: pingExpiry)));
      return _active;
    }
    if (lastMoveExists) {
      // If their app version doesn't have a ping but has a last move:
      // if (i == 333) print('lastMoveExists for setup $i');
      // print('lastMove of player $player in setup $i is $lastMove');
      // print('now in setup $i is $now');
      // print('lastMove.isAfter(now.subtract(Duration(minutes: 60))) ("active") is ${lastMove.isAfter(now.subtract(Duration(minutes: 60)))}');

      _active = lastMove.isAfter(now.subtract(Duration(seconds: moveExpiry))); // Last move is less than 60 sec ago
      // _active = lastMove.isAfter(now.subtract(Duration(minutes: 60)));
    } else if (startTimeExists) {
      // If they have a move version app but haven't yet made a move
      // if (i == 333) print('setupData[kFieldPlaying][player][kSubFieldStartedPlaying] != null for setup $i');
      _active = startTime.isAfter(now.subtract(Duration(seconds: moveExpiry)));
    }
    // if (i == 333) print('_active is $_active for setup $i');
    return _active;
  }

  List<Widget> getChildren(
      BuildContext context,
      ) {
    final String me = Provider.of<GameHubUpdates>(context).myScreenName;
    final String myUid = MyFirebase.authObject.currentUser.uid;
    final Map userIdMap = Provider.of<GameHubUpdates>(context).userIdMap;
    // final String myEmail = Provider.of<GameHubUpdates>(context, listen: false).myEmail; // Varför ska just den här vara false?
    // final String myEmail = Provider.of<GameHubUpdates>(context, listen: false).myEmail; // Varför ska just den här vara false?

    List<Widget> resultsChildren = [Text('Results:', style: kConversationResultsResultsStyle)];
    List<Widget> scrollChildren = [];
    Widget scoreChild;
    bool hasResults = currentSetupData.containsKey(kFieldResults) ? true : false;
    bool hasPlaying = currentSetupData.containsKey(kFieldPlaying) ? true : false;

    //If this game has no result and nobody playing it right now:
    if (!hasResults && (!hasPlaying || MapEquality().equals(currentSetupData[kFieldPlaying], {}))) {
//      print("setup.data()['results'] of ${i +1} is null");
      return [SizedBox()];
      //If somebody is playing:
    } else if (currentSetupData.containsKey('playing')) {
      int j = 0;
      for (String player in currentSetupData[kFieldPlaying].keys) {
        j++;
        // if (i == 331) print('PlayingTag $j, setup $i: player $player');
        // bool active = isActive(player, currentSetupData, pingDocs, i);
        // bool active = isActive(player, currentSetupData, pingData, i);
        // isStillActive(player, active);
        // print("Adding Playing tag in $i, player $player");
        // print("currentSetupData[playing] is ${currentSetupData[kFieldPlaying]}");
        // print("activeMap is $activeMap");

        scrollChildren.add(
          PlayingTag(
            setParentState: () => setState(() {}),
            player: player,
            setup: setup,
            setupData: currentSetupData,
            active: activeMap[player],
            // myEmail: myEmail,
            myUid: myUid,
            me: me,
            i: i,
            j: j,
          ),
        );
      }
    }

    //If it also has results from before:
    if (hasResults) {
      // if (setup.get('results') != null) {
      // for (String resultPlayerId in setup.get('results').keys) {
      for (String resultPlayerId in currentSetupData['results'].keys) {
        //If the results have the standard Map structure:
        if ((currentSetupData['results'][resultPlayerId] is Map) &&
            currentSetupData['results'][resultPlayerId]['B'] != null &&
            currentSetupData['results'][resultPlayerId]['A'] != null) {
          int beamScore = currentSetupData['results'][resultPlayerId]['B'];
          int atomScore = currentSetupData['results'][resultPlayerId]['A'];
          int totalScore = beamScore + atomScore;
          scoreChild = Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: <Widget>[
              Expanded(child: Text('$totalScore', style: kConversationResultsStyle)),
              Expanded(
                  child: FittedBox(child: Text('b: $beamScore ', style: TextStyle(fontSize: 12, color: kSmallResultsColor)), fit: BoxFit.scaleDown)),
              Expanded(
                  child: FittedBox(child: Text('a: $atomScore', style: TextStyle(fontSize: 12, color: kSmallResultsColor)), fit: BoxFit.scaleDown)),
            ],
          );
          //If 'results' doesn't have the standard Map structure:
        } else {
          //Could I make this a SingeChildScrollLIst to make room for all the text in future msgs?
          scoreChild =
              SingleChildScrollView(child: Text('${currentSetupData['results'][resultPlayerId]}', style: kConversationResultsStyle, softWrap: true));
        }
        //Unless the result is an int between -10 and 0 (for passing msgs to people with the old app version):
        if (!(currentSetupData['results'][resultPlayerId] is int &&
            -10 < currentSetupData['results'][resultPlayerId] &&
            currentSetupData['results'][resultPlayerId] < 0)) {
          //If the key exists, show the value, otherwise show the playerID as it is:
          final String resultScreenName = userIdMap.containsKey(resultPlayerId)
          // ? '${Provider.of<GameHubUpdates>(parentContext).getScreenName(resultPlayerId)}'
              ? '${Provider.of<GameHubUpdates>(context).getScreenName(resultPlayerId)}'
              : '$resultPlayerId';
          scrollChildren.add(
            GestureDetector(
              child: SizedBox(
                height: 22, //For a larger click area, but doesn't work that way...
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
                currentSetupData['results'].containsKey(me) ||
                    currentSetupData['results'].containsKey(myUid) ||
                    currentSetupData[kFieldSender] == MyFirebase.authObject.currentUser.email ||
                    currentSetupData[kFieldSender] == myUid
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

    resultsChildren.add(Expanded(child: SingleChildScrollView(child: Column(children: scrollChildren), /*shrinkWrap: true,*/ reverse: false)));
    // resultsChildren.add(Expanded(child: ListView(children: scrollChildren, shrinkWrap: true, reverse: false)));
//    if(i+1 == 72 || i+1 == 62) print('resultsChildren of setup ${i+1} is $resultsChildren');
//    if(i+1 == 87) print('resultsChildren of setup ${i+1} is $resultsChildren and length is ${resultsChildren.length}');
    if (scrollChildren.length == 0) return [SizedBox()]; //This happens between -10 and 0.
    return resultsChildren;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: getChildren(context),
    );
  }
}

class PlayingTag extends StatelessWidget {
  PlayingTag(
      {@required this.setParentState,
        @required this.player,
        @required this.setup,
        @required this.setupData,
        @required this.active,
        // @required this.myEmail,
        @required this.myUid,
        @required this.me,
        @required this.i,
        @required this.j});

  final Function setParentState;
  final String player;
  final DocumentSnapshot setup;
  final Map<String, dynamic> setupData;
  final bool active;
  // final String myEmail;
  final String myUid;
  final String me;
  final int i;
  final int j;

  @override
  Widget build(BuildContext context) {
    // bool active = isActive(player, setupData, i); // People who play with the old version will be grey
    // bool active = false; // People who play with the old version will be grey
    // isStillActive(player);
    Color playingColor;
    // Note that active can be null just when Playing becomes Results:
    playingColor = active == false ? kSmallResultsColor : kPlayingTextColor;
    // print('Building PlayingTag $player in $i. active is $active');

    return GestureDetector(
        child: SizedBox(
          height: 22, //For a larger click area
          child: Row(
            children: [
              Expanded(child: Text('Playing:', style: TextStyle(color: playingColor))),
              SizedBox(width: 10),
              Expanded(child: Text('${Provider.of<GameHubUpdates>(context).getScreenName(player)}', style: TextStyle(color: playingColor))),
            ],
          ),
        ),
        onTap: (){
          tappedFollowPlaying(context: context, setupData: setupData, setup: setup, /*myEmail: myEmail,*/ me: me, /*myUid: myUid,*/ player: player);
        }
    );

  }}

void showResult({BuildContext context, Map<String, dynamic> setupData, String resultPlayerId}) {
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
