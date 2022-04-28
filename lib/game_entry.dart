import 'units/right_side_children.dart';

import 'my_firebase_labels.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show DocumentSnapshot;
import 'constants.dart';
import 'package:provider/provider.dart';
import 'package:blackbox/game_hub_updates.dart';

class GameEntry extends StatelessWidget {
  GameEntry({
    @required this.setupData,
    @required this.setup,
    @required this.i,
    @required this.setParentState,
  });

  final DocumentSnapshot setup;
  final Map<String, dynamic> setupData;
  final int i;
  final Function setParentState;

  List<Widget> getLeftSideChildren(BuildContext context) {
    //TODO: ***Clean up getLeftSideChildren() function!
    // final String myUid = Provider.of<GameHubUpdates>(context).myUid;
    GameHubUpdates gameHubProviderListen = Provider.of<GameHubUpdates>(context);
    // final String myUid = MyFirebase.authObject.currentUser.uid;
    // print('myUid inside getLeftSideChildren() is $myUid');
    // final Map userIdMap = gameHubProviderListen.userIdMap;
    // final Map userIdMap = Provider.of<GameHubUpdates>(context).userIdMap;
    // final Map userIdMap = Provider.of<GameHubUpdates>(parentContext).providerUserIdMap;
    final String senderScreenName = gameHubProviderListen.getScreenName(setup.get(kFieldSender));
    // final String senderScreenName = userIdMap[setup.get(kFieldSender)] ?? 'Loading...';
    // final String senderScreenName = setup.get(kFieldSender) == myUid && userIdMap[setup.get(kFieldSender)] == 'Anonymous'
    //     ? "Me"
    //     : userIdMap[setup.get(kFieldSender)] ?? setup.get(kFieldSender);
    final String me = Provider.of<GameHubUpdates>(context).myScreenName;
    final List<Widget> _children = [
      Text('Setup $i', style: TextStyle(color: kHubSetupColor)),
      Text(
        'By $senderScreenName',
        style: TextStyle(color: senderScreenName == me ? Colors.pinkAccent : Colors.lightBlueAccent),
        softWrap: false,
        overflow: TextOverflow.fade,
      ),
      Text(
        '${setup.get('widthAndHeight')[0]}x${setup.get('widthAndHeight')[1]}, ${(setup.get('atoms').length / 2).toInt()} atoms',
        style: TextStyle(
          fontSize: 16,
          color: kHubSetupColor,
        ),
      ),
    ];
    return _children;
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
              children: getLeftSideChildren(context),
            ),
          ),
          Expanded(
            child: RightSideChildren(key: ValueKey(i), setup: setup, setupData: setupData, i: i),
          ),
        ],
      ),
    );
  }
}

