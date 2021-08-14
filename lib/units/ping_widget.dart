import 'dart:convert';

import 'package:pretty_json/pretty_json.dart';
import 'package:provider/provider.dart';
import 'package:blackbox/game_hub_updates.dart';
import 'package:blackbox/constants.dart';
// import 'package:blackbox/my_firebase_labels.dart';
// import 'package:blackbox/my_firebase.dart';
import 'dart:async';
import 'package:flutter/material.dart';


// Monkey-patch gone horribly wrong:
// Map<String, bool> activeMap = {}; // {String follower: bool active}

class PingWidget extends StatefulWidget {
  const PingWidget({@required this.pingStream, @required this.createChild});
  // Map<String, bool> getActiveMap() {
  //   // return {};
  //   return activeMap;
  // }

  final Stream pingStream;
  final Function createChild;

  @override
  _PingWidgetState createState() => _PingWidgetState(pingStream, createChild);
}

class _PingWidgetState extends State<PingWidget> {
  _PingWidgetState(this.pingStream, this.createChild);
  Stream pingStream;
  final Function createChild;

  StreamSubscription pingStreamListener;

  Map<String, bool> activeMap = {}; // {String follower: bool active}
  Map<String, dynamic> pingMap = {}; // {String follower: TimeStamp ping}
  Map<String, int> pingCountDownMap = {}; // {String follower: int countDown}
  int pingCountDownStart = 6;
  int pingExpiry = 5; // sec
  GameHubUpdates gameHubProvider;

  @override
  void initState() {
    getPingStream();
    super.initState();
  }

  @override
  void dispose() {
    if (pingStreamListener != null) pingStreamListener.cancel();
    super.dispose();
  }


  void getPingStream() async {
    // print('getPingStream() in ${this.widget}');

    pingStreamListener = pingStream.listen((event) {
      // pingStreamListener = MyFirebase.storeObject.collection(kCollectionSetups).doc(setup.id).collection(kSubCollectionPlayingPings).doc(kSubCollectionPlayingPings).snapshots().listen((event) {
      // print('Event in pingStreamListener in ${this.widget}');
      Map<String, dynamic> newPingMap = event.data() ?? {}; // Should I ever want to compare new with old...
      // pingMap = event.data();
      DateTime now = DateTime.now();

      for (String follower in newPingMap.keys) {
        // Start a new ping countdown for new followers, but not for old:
        if (!pingCountDownMap.containsKey(follower)) {
          pingCountDownMap.addAll({follower: pingCountDownStart});
          pingCountDown(follower);
        }

        if (newPingMap[follower] != null) {
          // For every other event, the value will be null
          // print('follower is $follower and newPingMap[follower] is ${newPingMap[follower]}\n'
          //     'newPingMap is $newPingMap');
          bool previousActive = activeMap[follower] ?? false;
          DateTime lastPing = newPingMap[follower].toDate();

          if (lastPing.isAfter(now.subtract(Duration(seconds: pingExpiry)))) {
            pingCountDownMap.putIfAbsent(follower, () => pingCountDownStart);
            pingCountDownMap[follower] = pingCountDownStart;
            // moveCountDownMap[follower] = moveCountDownStart;

            if (!previousActive && this.mounted)
              setState(() {
                activeMap[follower] = true;
              });
          }
        }
      }

      // Remove countdowns for followers that removed their tag:
      for (int i = 0; i < pingCountDownMap.length; i++) {
        String follower = pingCountDownMap.keys.elementAt(i);
        if (!newPingMap.containsKey(follower)) {
          pingCountDownMap.remove(follower);
        }
      }

      pingMap = newPingMap;
      print('pingMap in PingWidget, pingStreamListener is:');
      printPrettyJson(jsonDecode(jsonEncode(pingMap, toEncodable: (object) => object.toString())));
      print('activeMap in PingWidget, pingStreamListener is');
      printPrettyJson(jsonDecode(jsonEncode(activeMap, toEncodable: (object) => object.toString())));
    });
  }

  void pingCountDown(String follower) async {
    // If a follower is removed, the countdown for that follower ends:
    while (pingCountDownMap.containsKey(follower) && this.mounted) {
      await Future.delayed(Duration(seconds: 1));
      if (pingCountDownMap.containsKey(follower)) {
        pingCountDownMap[follower]--;
        // The entries may no longer exist, so == true has to be added:
        if (pingCountDownMap[follower] <= 0 && activeMap[follower] == true && this.mounted) {
          setState(() {
            // print('setState in ${this.widget} pingCountDown()');
            // print('Changing active to passive for $follower in ${this.widget} pingCountDown()');
            activeMap[follower] = false;
          });
          // print('activeMap in PingWidget pingCountDown() is $activeMap');
        }
      }
    }
  }

  Widget getChild(){
  // List<Widget> getChild(){
    Widget _child;
    // List<Widget> _children = [];

    _child = createChild(activeMap);

    // _children = createChildren(pingMap);
    // for (String follower in pingMap.keys) {
    //   _children.add(Text('${gameHubProvider.getScreenName(follower)}'));
    // }
    //
    // if (_children.length == 0) _children = [Text('(none)', style: kConversationResultsResultsStyle)];
    return _child;
  }

  @override
  Widget build(BuildContext context) {
    // gameHubProvider = Provider.of<GameHubUpdates>(context);
    return getChild();
    // return Column(
    //   children: getChild(),
    // );
  }
}
