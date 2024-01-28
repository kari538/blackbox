import 'package:blackbox/units/small_functions.dart';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';

// Set printPing to true to get debug prints throughout the widget
final bool printPing = false;
// final bool printPing = true;

class PingWidget extends StatefulWidget {
  const PingWidget({required this.pingStream, required this.createChild});
  // Map<String, bool> getActiveMap() {
  //   // return {};
  //   return activeMap;
  // }

  final Stream? pingStream;
  final Function createChild;

  @override
  _PingWidgetState createState() => _PingWidgetState(pingStream, createChild);
}

class _PingWidgetState extends State<PingWidget> {
  _PingWidgetState(this.pingStream, this.createChild);
  Stream? pingStream;
  final Function createChild;

  StreamSubscription? pingStreamListener;

  Map<String, bool> activeMap = {}; // {String follower: bool active}
  Map<String, dynamic> pingMap = {}; // {String follower: TimeStamp ping}
  Map<String, int> pingCountDownMap = {}; // {String follower: int countDown}
  int pingCountDownStart = 6;
  int pingExpiry = 5; // sec

  @override
  void initState() {
    getPingStream();
    super.initState();
  }

  @override
  void dispose() {
    if (pingStreamListener != null) pingStreamListener!.cancel();
    super.dispose();
  }


  void getPingStream() async {
    // print('getPingStream() in ${this.widget}');

    pingStreamListener = pingStream!.listen((event) {
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
      if (printPing) {
        print('pingMap in PingWidget, pingStreamListener is:');
        myPrettyPrint(jsonDecode(jsonEncode(pingMap, toEncodable: (object) => object.toString())));
        print('activeMap in PingWidget, pingStreamListener is');
        myPrettyPrint(jsonDecode(jsonEncode(activeMap, toEncodable: (object) => object.toString())));
      }
    });
  }

  void pingCountDown(String follower) async {
    // If a follower is removed, the countdown for that follower ends:
    while (pingCountDownMap.containsKey(follower) && this.mounted) {
      await Future.delayed(Duration(seconds: 1));
      if (pingCountDownMap.containsKey(follower) && pingCountDownMap[follower] != null) {
        // Original:
        // pingCountDownMap[follower]--;

        // From Dart developer on GitHub:
        // pingCountDownMap[follower] = pingCountDownMap[follower]! -1;

        // Monkey-patch:
        // int localPing = pingCountDownMap[follower] as int; // Unsafe, coz it may no longer be an int...
        // localPing--;
        // pingCountDownMap[follower] = localPing;

        // Should work, according to documents, but doesn't:
        // if (pingCountDownMap[follower] is int) {
        //   pingCountDownMap[follower]--;
        // }

        // The only truly null-safe way:
        int localPing = pingCountDownMap[follower] ?? 0;
        localPing--;  // This is the only way to guarantee that the operator won't be used
        // on null, since the ping can be removed async at any point in time, including
        // between when the condition is tested and when the operation is carried out!
        if (localPing >= 0 && pingCountDownMap.containsKey(follower)) pingCountDownMap[follower] = localPing;

        // The entries may no longer exist, so == true has to be added:
        if (localPing <= 0 && activeMap[follower] == true && this.mounted) {
        // if (pingCountDownMap[follower]! <= 0 && activeMap[follower] == true && this.mounted) {
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

  Widget? getChild(){
    Widget? _child;
    _child = createChild(activeMap);
    return _child;
  }

  @override
  Widget build(BuildContext context) {
    return getChild()!;
  }
}
