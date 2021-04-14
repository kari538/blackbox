import 'package:blackbox/units/fcm_send_msg.dart';
import 'package:blackbox/scratches/temp_firebase_operations.dart';
//import 'package:blackbox/constants.dart';
import 'package:blackbox/my_firebase.dart';
import 'package:blackbox/my_firebase_labels.dart';
import 'package:blackbox/online_screens/choose_board_screen.dart';
import 'package:blackbox/play.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
//import 'package:blackbox/atom_n_beam.dart';
import 'package:blackbox/screens/play_screen.dart';
import 'package:blackbox/game_entry.dart';
import 'package:collection/collection.dart';
import 'package:provider/provider.dart';
import 'package:blackbox/game_hub_updates.dart';
import 'package:blackbox/game_hub_menu.dart';
import 'dart:async';

class GameHubScreen extends StatefulWidget {
  @override
  _GameHubScreenState createState() => _GameHubScreenState();
}

class _GameHubScreenState extends State<GameHubScreen> {
  StreamSubscription<auth.User> currentUserListener;
  auth.User loggedInUser;
  Future<String> futurePlayerId;
  Map<String, String> userIdMap;
  int del = 0;
  List<Widget> gameList = [
  Container(
        decoration: BoxDecoration(border: Border.all(color: Colors.white)),
        height: 100,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text('No connection with database'),
          ],
        ))
  ];

  @override
  void initState() {
    super.initState();
    getCurrentUser();
    futurePlayerId = getPayerId();
    getUserIdMap();
//    getSubCollection();
    addScreenName();
  }

  @override
  void dispose() {
    print('Popping game hub screen');
    print("Cancelling the listener");
    currentUserListener.cancel();
    super.dispose();
  }

  void addScreenName() async {
//    String myUid = MyFirebase.authObject.currentUser.uid;
//    MyFirebase.authObject.currentUser.updateProfile(displayName: 'Mirabella');
    print("MyFirebase.authObject.app is ${MyFirebase.authObject.app}");
    var userChanges = MyFirebase.authObject.userChanges();
    print("userChanges is $userChanges");
  }

  //Works!
//  void getSubCollection() async {
//    DocumentSnapshot test = await MyFirebase.storeObject.collection('setups').doc('073v8NgDjhSsVqrFdT3X').collection('subcollection').doc('zfdzmig6BlAJFugdCG4k').get();
//    print("test['testing'] is ${test['testing']}");
//  }

  void getCurrentUser() async {
    print('Getting me');
    print('My displayName is ${MyFirebase.authObject.currentUser.displayName}');
    String myScreenName = 'Loading...';

    currentUserListener = MyFirebase.authObject.userChanges().listen((event) async {
      loggedInUser = MyFirebase.authObject.currentUser;
      print("getCurrentUser() event is null? ${event == null}");
//      print("getCurrentUser() loggedInUser is $loggedInUser");
      if (loggedInUser != null && context != null) {
//        Provider.of<GameHubUpdates>(context, listen: false).updateMyEmail(loggedInUser.email);
        Provider.of<GameHubUpdates>(this.context, listen: false).updateMyEmail(loggedInUser.email);
//    print('Game hub screen printing user email: ${loggedInUser.email}');
        await for (QuerySnapshot loggedInUserInfo
            in MyFirebase.storeObject.collection('userinfo').where('email', isEqualTo: loggedInUser.email).snapshots()) {
          print('A new snapshot has come in from current user document');
          //Stream of QuerySnapshots which sends a new Snapshot every time the 'userinfo' collection is changed for loggedInUser.
          //Returns an empty list if there is no such entry in the 'userinfo' collection.
          if (ListEquality().equals(loggedInUserInfo.docs, [])) {
            //My entry in 'userinfo' doesn't exist:
            myScreenName = 'Me'; //I don't have an entry in the 'userinfo' but I know I'm me.
            print('me is $myScreenName');
            Provider.of<GameHubUpdates>(context, listen: false).updateMyScreenName(myScreenName);
          } else if (loggedInUserInfo.docs[0].data()['screenName'] == null || loggedInUserInfo.docs[0].data()['screenName'] == 'Anonymous') {
            myScreenName = 'Me'; //I don't have a screenName in the 'userinfo' but I know I'm me.
            print('me is $myScreenName');
            Provider.of<GameHubUpdates>(context, listen: false).updateMyScreenName(myScreenName);
          } else {
            //If a userinfo entry with that email exists and has a screenName:
            myScreenName = loggedInUserInfo.docs[0].data()['screenName']; // I put [0] because I know there is only one document with that email.
            print('me is $myScreenName');
            Provider.of<GameHubUpdates>(context, listen: false).updateMyScreenName(myScreenName);
          }
        }
      } else {
//        print('else-if loggedInUser is null');
        myScreenName = 'Me'; //While we wait for that loggedInUser to get a value...
//        print('me is $myScreenName');
        if (context != null) {
//          print('Running Provider in else-if');
          Provider.of<GameHubUpdates>(this.context, listen: false).updateMyScreenName(myScreenName);
          print("Done running Provider in else-if");
        }
      }
    }, onError: (e) {
      print("currentUserListener error $e");
    });
  }

//   Future<String> getPayerId() async {
//     print('Getting my user ID');
//     String _myId;
//     bool triedEnough = false;
//     Future.delayed(Duration(seconds: 5), () {
//       triedEnough = true;
//       print("triedEnough inside Future.delayed is $triedEnough");
//     });
// //    futureLoggedInUser = firebaseAuthObject.currentUser();
// //    loggedInUser = await futureLoggedInUser;
//     loggedInUser = MyFirebase.authObject.currentUser;
//     print("loggedInUser is $loggedInUser");
    //I need the below while loop so that this method doesn't return the Future 'null'!... It HAS to wait until I have an actual value:
//     while (loggedInUser == null && triedEnough == false && this.mounted) {
//       print('Inside while');
//       loggedInUser = MyFirebase.authObject.currentUser;
// //      playerIdListener = MyFirebase.authObject.userChanges().listen((event) async {
// //        print('Inside playerIdListener');
// //        loggedInUser = MyFirebase.authObject.currentUser;
// //        print("getPayerIdAndMap() event is null? ${event == null}");
// //      }, onError: (e) {
// //        print("playerIdListener error $e");
// //      });
//       await Future.delayed(Duration(milliseconds: 500)); //So that we don't loop through too quickly...
//     }
//     print("triedEnough is $triedEnough");
//     print("Before await userinfo with my email in getPlayerId()");
//     QuerySnapshot loggedInUserInfo = await MyFirebase.storeObject
//         .collection('userinfo')
//         .where('email', isEqualTo: loggedInUser.email)
//         .get(); //No stream needed, coz the document no. is not supposed to change
//     print("After await userinfo with my email in getPlayerId()");
//
//     if (ListEquality().equals(loggedInUserInfo.docs, [])) {
//       //I don't have an entry in 'userinfo', which shouldn't ever happen:
//       print("I don't have an entry in 'userinfo', which shouldn't ever happen!!");
//       _myId = 'myself';
//     } else {
//       _myId = loggedInUserInfo.docs[0].id;
//     }
//     print("My player ID is '$_myId'");
//     Provider.of<GameHubUpdates>(context, listen: false).updateMyId(_myId);
//     print("Returning futurePlayerId: $_myId");
//     return _myId;
//
//     //------------------------
// //    print("Getting user ID map");
// //    Map<String, String> map = {};
// //    await for (QuerySnapshot users in firestoreObject.collection('userinfo').snapshots()) {
// //      print('A new snapshot has come in in getUserIdMap()');
// //      for (DocumentSnapshot user in users.docs) {
// ////        print('user id is ${user.id}');
// ////        print('user screenName is ${user.data()['screenName']}');
// //        String screenName = user.id == _myId && user.data()['screenName'] == 'Anonymous' ? 'Me' : user.data()['screenName'];
// //        map.addAll({user.id: screenName});
// //      }
// //      print(map);
// //      Provider.of<GameHubUpdates>(context, listen: false).updateUserIdMap(map);
// ////      if (this.mounted)
// ////        print('Setting state of $this');
// ////        setState(() {
// ////          userIdMap = map;
// ////        });
// //    }
// //
//     //------------------------
//     //This was useless, as it returns a user ID that the app can never access, except for the logged in user!!...:
// //    String userID = loggedInUser.uid;
// //    return userID;
//   }

  Future<String> getPayerId() async {
    String _myUid;
//     bool triedEnough = false;
//     Future.delayed(Duration(seconds: 5), () {
//       triedEnough = true;
//       print("triedEnough inside Future.delayed is $triedEnough");
//     });
//
//     while (loggedInUser == null && triedEnough == false && this.mounted) {
//       print('Inside while');
//       loggedInUser = MyFirebase.authObject.currentUser;
// //      playerIdListener = MyFirebase.authObject.userChanges().listen((event) async {
// //        print('Inside playerIdListener');
// //        loggedInUser = MyFirebase.authObject.currentUser;
// //        print("getPayerIdAndMap() event is null? ${event == null}");
// //      }, onError: (e) {
// //        print("playerIdListener error $e");
// //      });
//       await Future.delayed(Duration(milliseconds: 500)); //So that we don't loop through too quickly...
//     }

    _myUid = MyFirebase.authObject.currentUser.uid;
    print('My playerID inside getPayerId() is $_myUid');
    // Provider.of<GameHubUpdates>(context, listen: false).updateMyId(_myUid);
    return _myUid;
  }

    void getUserIdMap() async {
    print("Getting user ID map");
    Map<String, String> map = {};
    await for (QuerySnapshot users in MyFirebase.storeObject.collection(kCollectionUserInfo).snapshots()) {
      print('A new snapshot has come in in getUserIdMap()');
      for (DocumentSnapshot user in users.docs) {
//        String screenName = user.id == Provider.of<GameHubUpdates>(context).myId && user.data()['screenName'] == 'Anonymous' ? 'Me' : user.data()['screenName'];
        String screenName = user.id == await futurePlayerId && user.data()['screenName'] == 'Anonymous' ? 'Me' : user.data()['screenName'];
        map.addAll({user.id: screenName});
      }
      print(map.values);
      Provider.of<GameHubUpdates>(context, listen: false).updateUserIdMap(map);
//      if (this.mounted)
//        print('Setting state of $this');
//        setState(() {
//          userIdMap = map;
//        });
    }
  }

  @override
  Widget build(BuildContext context) {
    print('Building game hub screen');
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
            child: Text('the game hub'),
//              child: Text('${Provider.of<GameHubUpdates>(context).providerUserIdMap.values}'),
            onTap: () async {
              tempFirebaseOperations();
              // fcmSendMsg(context);
//                print("Setting game hub state with map: ${await futureUserIdMap}");
//               print("Setting game hub state");
//               setState(() {});
            }),
        actions: [GameHubMenu(context)],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              //Every time something happens in the 'setups' collection, every list item created by this Stream will be rebuilt
              stream: MyFirebase.storeObject.collection('setups').orderBy('timestamp', descending: true).snapshots(),
              builder: (context, setupsSnapshot) {
                if (setupsSnapshot.hasData) {  //I think I can remove this... because a snapshot in a stream (a QuerySnapshot) ALWAYS has data...?
//                  print('The first document ID is ${setupsSnapshot.data.docs[0].id}');
                  gameList = [];
                  int i = 0;
                  int j = 0;
                  for (DocumentSnapshot setup in setupsSnapshot.data.docs) {
                    i = setup.data()['i'];
                    j++;
                    // j = i;
                    //Temporary code for adding 'timestamp' field where missing:
//                    print('timestamp is ${setup.data()['timestamp'].toDate()}');
//                    print(i);
//                    //January 1, 2001 at 12:00:00 AM UTC+3
//                    if (setup.data()['timestamp'] == null) {
//                      print(i);
//                      print(DateTime(2001));
//
//                      //Adds a new field to the document, but overwrites any old field with the same name (key), i.e. 'results':
//                      firestoreObject.collection('setups').doc(setup.id).set({
//                        'timestamp': DateTime(2001),
//
//                      }, merge: true);
//                    }
//                  if(setup.data()['sender'] == 'marshallmusyimi@gmail.com') {
//                    print('Sender: ${setup.data()['sender']}, timestamp: ${setup.data()['timestamp'].toDate()}');
//                  }
//                  print('Sender: ${setup.data()['sender']}, timestamp: ${setup.data()['timestamp'].toDate()}');
//                    if(setup.data()['timestamp'])
                    gameList.add(GestureDetector(
                      child: GameEntry(
                        setup: setup,
                        i: i ?? j,
                        context: context,
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
                            numberOfAtoms: (setup.data()['atoms'].length / 2).toInt(),
                            heightOfPlayArea: setup.data()['widthAndHeight'][1],
                            widthOfPlayArea: setup.data()['widthAndHeight'][0]);
                        thisGame.setupData = setup.data();
                        thisGame.online = true;
                        thisGame.playerId = await futurePlayerId;
                        Navigator.push(context, MaterialPageRoute(builder: (context) {
                          return PlayScreen(thisGame: thisGame, setup: setup);
                        }));
                      },
                    ));
                  }
                } else {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }
                return ListView.builder(
                  reverse: true,
                  itemCount: gameList.length,
                  itemBuilder: (context, index) {
                    return gameList[index];
                  },
                );
                // return ListView(
                //   reverse: true,
                //   children: <Widget>[
                //     Column(
                //       children: gameList,
                //     ),
                //   ],
                // );
              },
            ),
          ),
          BottomAppBar(
            color: Colors.pink.shade600,
            elevation: 5,
            child: GestureDetector(
              child: Container(
//              child: Center(child: Text('Add', style: TextStyle(color: kBoardColor, fontWeight: FontWeight.bold))),
                child: Center(child: Text('Add', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
//              height: 50,
                height: 40,
                width: double.infinity,
              ),
              onTap: (){
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return ChooseBoardScreen();
                }));
              },
            ),
          ),
        ],
      ),
      //      persistentFooterButtons: [
//        GestureDetector(
//          child: Container(
//            height: 80,
//            decoration: BoxDecoration(
//              color: Colors.blue
//            ),
//          ),
//          onTap: () {},
//        )
//      ],
//      persistentFooterButtons: [RaisedButton(child: Text('Add'), onPressed: (){}, padding: EdgeInsets.all(0),)],
//      bottomNavigationBar: GestureDetector(child: Container(height: 100,), onTap: (){},),
//      floatingActionButton: Padding(
//        padding: const EdgeInsets.only(bottom: 70),
//        child: FloatingActionButton(
//
//          onPressed: () {},
//          child: Icon(Icons.add),
//          mini: true,
//        ),
//      ),

    );
  }
}

