import 'package:blackbox/units/small_functions.dart';
import 'package:blackbox/scratches/temp_firebase_operations.dart';
import 'package:blackbox/my_firebase.dart';
import 'package:blackbox/my_firebase_labels.dart';
import 'package:blackbox/online_screens/choose_board_screen.dart';
import 'package:blackbox/play.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:blackbox/screens/play_screen.dart';
import 'package:blackbox/game_entry.dart';
import 'package:provider/provider.dart';
import 'package:blackbox/game_hub_updates.dart';
import 'package:blackbox/game_hub_menu.dart';
import 'dart:async';

class GameHubScreen extends StatefulWidget {
  @override
  _GameHubScreenState createState() => _GameHubScreenState();
}

class _GameHubScreenState extends State<GameHubScreen> {
  late StreamSubscription<auth.User?> currentUserListener;
  late StreamSubscription<QuerySnapshot> setupStreamListener;

  // auth.User loggedInUser;
  String? myUid = MyFirebase.authObject.currentUser != null
      ? MyFirebase.authObject.currentUser!.uid
      : null;
  int delayToShowSpinner = 200; // milliseconds

  // Map<String, String> userIdMap;
  int del = 0; // Used for delete-script
  late GameHubUpdates providerNoListen;

  // TODO: (Maybe take back a 'No connection with database' option...:)
  List<Widget> gameList = [
    // Container(
    //     decoration: BoxDecoration(border: Border.all(color: Colors.white)),
    //     height: 100,
    //     child: Column(
    //       mainAxisAlignment: MainAxisAlignment.center,
    //       crossAxisAlignment: CrossAxisAlignment.stretch,
    //       children: <Widget>[
    //         Text('No connection with database'),
    //       ],
    //     ))
  ];

  @override
  void initState() {
    super.initState();
    providerNoListen = Provider.of<GameHubUpdates>(context, listen: false);
    // providerNoListen = Provider.of<GameHubUpdates>(this.context, listen: false);
    getMyInfo();
    getSetupStream();
    // futurePlayerId = getPlayerId();
    getUserIdMap();
//     addScreenName();
  }

  @override
  void dispose() {
    print('Popping game hub screen');
    print("Cancelling the user listener");
    currentUserListener.cancel();
    print("Cancelling the setup stream listener");
    setupStreamListener.cancel();
    // userSnapshotStream.
    super.dispose();
  }

  void getMyInfo() async {
    print('Getting my info');
    print(
        'My displayName is ${MyFirebase.authObject.currentUser!.displayName}');
    print('My user ID is ${MyFirebase.authObject.currentUser!.uid}');

    String? myScreenName = 'Loading...';

    await Future.delayed(Duration(
        milliseconds:
            delayToShowSpinner)); // To give the spinner time to start...

    // On changing user:
    currentUserListener =
        MyFirebase.authObject.userChanges().listen((event) async {
      if (event != null) {
        // New values:
        myUid = MyFirebase.authObject.currentUser!.uid;
        print("currentUserListener event is null? ${event == null}");
        //      print("currentUserListener loggedInUser is $loggedInUser");
        if (MyFirebase.authObject.currentUser != null && context != null) {
          //    print('Game hub screen printing user email: ${loggedInUser.email}');

          // When anything changes in the current user's userinfo:
          await for (DocumentSnapshot loggedInUserInfo in MyFirebase.storeObject
              .collection('userinfo')
              .doc(myUid)
              .snapshots()) {
            print('A new snapshot has come in from current user document');
            //Stream of QuerySnapshots which sends a new Snapshot every time the 'userinfo' collection is changed for loggedInUser.
            //Returns an empty list if there is no such entry in the 'userinfo' collection.

            // Since this is just a Stream, and not a StreamSubscription, the only way
            // to cancel it seems to be to break when screen has popped:
            print('mounted is ${mounted}');
            if (!mounted) {
              print('mounted in getMyInfo() is not true. Breaking!');
              break;
            }

            Map<String, dynamic>? loggedInUserInfoData =
                loggedInUserInfo.data() as Map<String, dynamic>?;
            if (!loggedInUserInfo.exists ||
                !loggedInUserInfoData!.containsKey(kFieldScreenName) ||
                loggedInUserInfo.get(kFieldScreenName) == 'Anonymous' ||
                loggedInUserInfo.get(kFieldScreenName) == '' ||
                loggedInUserInfo.get(kFieldScreenName) == null) {
              //My entry in 'userinfo' doesn't exist (which should never happen)
              // or it has no screenName or the screenName is 'Anonymous':
              myScreenName =
                  'Me'; //I don't have a screenName but I know I'm me.
              print('aaa myScreenName is $myScreenName');
              providerNoListen.updateMyScreenName(myScreenName);
            } else {
              //If a userinfo entry with that uid exists and has a screenName:
              myScreenName = loggedInUserInfo.get(kFieldScreenName);
              print('bbb myScreenName is $myScreenName');
              providerNoListen.updateMyScreenName(myScreenName);
            }
          }
        } else {
          // User or context is null
          //        print('else-if loggedInUser is null');
          myScreenName =
              'Me'; //While we wait for that loggedInUser to get a value...
          print(
              'User or context is null. myScreenName is $myScreenName, while we wait...');
          if (context != null) {
            //          print('Running Provider in else-if');
            providerNoListen.updateMyScreenName(myScreenName);
            // print("Done running Provider in else-if");
          }
        }
      }
    }, onError: (e) {
      print("currentUserListener error in ${this.widget}: $e");
    });
  }

  void getUserIdMap() async {
    print("Getting user ID map");

    await Future.delayed(Duration(
        milliseconds:
            delayToShowSpinner)); // To give the spinner time to start...

    Stream userSnapshotStream =
        MyFirebase.storeObject.collection(kCollectionUserInfo).snapshots();
    Map<String, String?> map = {};
    await for (QuerySnapshot users in userSnapshotStream) {
      print(
          'A new "collection userinfo" snapshot has come in in getUserIdMap()');

      // Since this is just a Stream, and not a StreamSubscription, the only way
      // to cancel it seems to be to break when screen has popped:
      print('mounted is ${mounted}');
      if (!mounted) {
        print('mounted is not true. Breaking!');
        break;
      }
      for (DocumentSnapshot user in users.docs) {
        Map<String, dynamic> userData = user.data() as Map<String, dynamic>;
        String? screenName;
        if (userData.containsKey(kFieldScreenName) &&
            userData[kFieldScreenName] != '' &&
            userData[kFieldScreenName] != null) {
          screenName = userData[kFieldScreenName];
        } else
          screenName = user.id == myUid ? 'Me' : 'Anonymous';
        map.addAll({user.id: screenName});
      }
      print(map.values);

      providerNoListen.updateUserIdMap(map);
      print('userIdMap in getUserIdMap is:');
      myPrettyPrint(providerNoListen.userIdMap);
    }
  }

  void getSetupStream() async {
    //Every time something (IMPORTANT??) happens in the 'setups' collection, every list item created by this Stream will be rebuilt

    await Future.delayed(Duration(
        milliseconds:
            delayToShowSpinner)); // To give the spinner time to start...

    setupStreamListener = MyFirebase.storeObject
        .collection('setups')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((event) {
      print('New snapshot in game hub getSetupStream()');
      gameList = [];
      List<Widget> _newGameList = [];
      int? i;
      // int j = 0;

      for (DocumentSnapshot setup in event.docs) {
        if (setup.data() != null) {
          Map<String, dynamic> setupData = setup.data() as Map<String, dynamic>;
          if (setupData.containsKey('i')) {
            i = setupData['i'];
          }
          // j++;
          if (i != null) {
            // The Cloud Function "i" has finished, giving the game a number.
            // Before this, the game shouldn't show up.
            _newGameList.add(GestureDetector(
              child: GameEntry(
                setup: setup,
                setupData: setupData,
                // setupData: setup.data(),
                i: i,
                setParentState: () {
                  setState(() {});
                },
              ),
              onTap: () async {
                ///Run this to delete results by clicking:
                //                        del++;
                //                        print('Delete all results for entry no. $i?');
                //                        if(del==2){
                //                          firestoreObject.collection('setups').doc(setup.id).updateData(
                //                              {'results': FieldValue.delete()}
                //                          ).whenComplete(() {
                //                            print('Field deleted');
                //                          });
                //                          del=0;
                //                        }
                ///Run this to change sender from email to playerId by clicking:
                //                        QuerySnapshot userInfos = await firestoreObject.collection('userinfo').get();  //No stream needed, coz the document no is not supposed to change
                //                        String senderId;
                //                        for(var user in userInfos.docs) {
                //                          if(setup.data()['sender']== user['email']){
                //                            senderId = user.id;
                //                            print('senderId is $senderId');
                //                          }
                //
                //                        }
                //                          firestoreObject.collection('setups'
                //                              ).doc(setup.id).updateData(
                //                              {'sender': senderId}
                //                          ).whenComplete(() {
                //                            print('Field deleted');
                //                          });
                //                          del=0;
                ///---------

                Play thisGame = Play(
                    numberOfAtoms: (setup.get('atoms').length / 2).toInt(),
                    widthOfPlayArea: setup.get('widthAndHeight')[0],
                    heightOfPlayArea: setup.get('widthAndHeight')[1]);
                thisGame.setupData = setupData;
                // thisGame.setupData = setup.data();
                thisGame.online = true;
                thisGame.playerUid = myUid;
                // thisGame.playerId = await futurePlayerId;
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return PlayScreen(thisGame: thisGame, setup: setup);
                }));
              },
            ));
          }
        }
      }

      setState(() {
        gameList = _newGameList;
      });

      // } else {
      //   return Center(
      //     child: CircularProgressIndicator(),
      //   );
      // }
    });
    // builder: (context, setupsSnapshot) {
  }

  @override
  Widget build(BuildContext context) {
    print('Building game hub screen');
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: GestureDetector(
              child: Text('the game hub'),
              onTap: () async {
                setState(() {
                  print('Setting game hub state');
                });
                tempFirebaseOperations(); //Keep this uncommented to avoid lint
                print("Setting game hub state");
                setState(() {});
              }),
          actions: [GameHubMenu(context)],
        ),
        body: Column(
          children: <Widget>[
            Expanded(
              child: ListEquality().equals(gameList, [])
                  ? Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      reverse: true,
                      itemCount: gameList.length,
                      itemBuilder: (context, index) {
                        return gameList[index];
                      },
                    ),
            ),
            MaterialButton(
              child: Container(
                height: 40,
                width: double.infinity,
                child: Center(
                    child: Text('Add',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium!
                            .copyWith(fontWeight: FontWeight.bold))),
              ),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return ChooseBoardScreen();
                }));
              },
              // BottomAppBar(
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(),
              padding: EdgeInsets.all(0),
              color: Colors.pink.shade600,
              elevation: 0,
            ),
          ],
        ),
      ),
    );
  }
}
