// import 'flutter';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:blackbox/my_firebase.dart';
import 'package:blackbox/my_firebase_labels.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:blackbox/constants.dart';
import 'package:blackbox/game_hub_menu.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool allGameHub = true;
  bool newSetup = true;
  bool playing = true;
  bool playingYourSetup = true;
  bool allAppUpdates = true;
  bool majorAppUpdates = true;
  bool inactive = true;
  bool appInactive = true;
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  String myUid = MyFirebase.authObject.currentUser!.uid;
  bool showSpinner = true;

  @override
  void initState() {
    super.initState();
    // List<dynamic> list = ['hej', 'hej,hej'];
    // list.contains(element)
    getSettings();
  }

  Future getSettings() async {
    DocumentSnapshot userSnap = await MyFirebase.storeObject.collection(kCollectionUserInfo).doc(myUid).get();
    Map <String, dynamic> myUserData = userSnap.data() as Map<String, dynamic>;
    if (myUserData.containsKey(kFieldNotifications)) {
      if (!myUserData[kFieldNotifications].contains(kTopicGameHubSetup)) {
        newSetup = false;
      }
      if (!myUserData[kFieldNotifications].contains(kTopicPlayingSetup)) {
        playing = false;
      }
      if (!myUserData[kFieldNotifications].contains(kTopicPlayingYourSetup)) {
        playingYourSetup = false;
      }
      if (!(newSetup && playing && playingYourSetup)) {
        allGameHub = false;
        inactive = false;
      }
      if (!myUserData[kFieldNotifications].contains(kTopicAllAppUpdates)) {
        allAppUpdates = false;
        appInactive = false;
      }
      if (!myUserData[kFieldNotifications].contains(kTopicMajorAppUpdates) && !myUserData[kFieldNotifications].contains(kTopicAllAppUpdates)) {
        majorAppUpdates = false;
        appInactive = false;
      }

    } else {
      // If there is no Notifications field in the userinfo:
      _firebaseMessaging.subscribeToTopic(kTopicGameHubSetup);
      _firebaseMessaging.subscribeToTopic(kTopicPlayingSetup);
      _firebaseMessaging.subscribeToTopic(kTopicAllAppUpdates);
      MyFirebase.storeObject.collection(kCollectionUserInfo).doc(myUid).update({
        kFieldNotifications: [
          kTopicGameHubSetup,
          kTopicPlayingSetup,
          kTopicPlayingYourSetup,
          kTopicAllAppUpdates,
        ],
      });
    }
    setState(() {
      showSpinner = false;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Settings'), actions: [GameHubMenu(context)]),
      body: ModalProgressHUD(
        inAsyncCall: showSpinner,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HeadLine('Game Notifications'),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Category('All Game Hub Notifications')),
                    Switch(
                        value: allGameHub,
                        onChanged: (value) {
                          setState(() {
                            allGameHub = !allGameHub;
                            inactive = allGameHub;
                          });
                          if (allGameHub) {
                            print('Subscribing to topic GameHubSetup and PlayingSetup.\n'
                                'Adding ${[
                              kTopicGameHubSetup,
                              kTopicPlayingSetup,
                              kTopicPlayingYourSetup]} to userinfo');
                            _firebaseMessaging.subscribeToTopic(kTopicGameHubSetup);
                            _firebaseMessaging.subscribeToTopic(kTopicPlayingSetup);
                            MyFirebase.storeObject.collection(kCollectionUserInfo).doc(myUid).update({
                              kFieldNotifications: FieldValue.arrayUnion([
                                kTopicGameHubSetup,
                                kTopicPlayingSetup,
                                kTopicPlayingYourSetup],
                              ),
                            });
                          } else print('No action');
                        }),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SubCategory('New game hub setup', inactive),
                    Switch(
                        value: newSetup,
                        onChanged: inactive
                            ? null
                            : (value) {
                                setState(() {
                                  newSetup = !newSetup;
                                });
                                if (newSetup) {
                                  print('Subscribing to topic GameHubSetup.\n'
                                      'Adding ${[
                                    kTopicGameHubSetup]} to userinfo');
                                  _firebaseMessaging.subscribeToTopic(kTopicGameHubSetup);
                                  MyFirebase.storeObject.collection(kCollectionUserInfo).doc(myUid).update({
                                    kFieldNotifications: FieldValue.arrayUnion(
                                      [kTopicGameHubSetup],
                                    ),
                                  });
                                } else {
                                  print('Unsubscribing to topic GameHubSetup.\n'
                                      'Removing ${[
                                    kTopicGameHubSetup]} from userinfo');
                                  _firebaseMessaging.unsubscribeFromTopic(kTopicGameHubSetup);
                                  MyFirebase.storeObject.collection(kCollectionUserInfo).doc(myUid).update({
                                    kFieldNotifications: FieldValue.arrayRemove(
                                      [kTopicGameHubSetup],
                                    ),
                                  });                              }
                              }),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SubCategory('Somebody playing', inactive),
                    Switch(
                        value: playing,
                        onChanged: inactive
                            ? null
                            : (value) {
                                setState(() {
                                  playing = !playing;
                                });
                                if (playing) {
                                  print('Subscribing to topic $kTopicPlayingSetup.\n'
                                      'Adding ${[
                                    kTopicPlayingSetup]} to userinfo');
                                  _firebaseMessaging.subscribeToTopic(kTopicPlayingSetup);
                                  MyFirebase.storeObject.collection(kCollectionUserInfo).doc(myUid).update({
                                    kFieldNotifications: FieldValue.arrayUnion(
                                      [kTopicPlayingSetup],
                                    ),
                                  });
                                } else {
                                  print('Unsubscribing from topic $kTopicPlayingSetup.\n'
                                      'Removing ${[
                                    kTopicPlayingSetup]} from userinfo');
                                  _firebaseMessaging.unsubscribeFromTopic(kTopicGameHubSetup);
                                  MyFirebase.storeObject.collection(kCollectionUserInfo).doc(myUid).update({
                                    kFieldNotifications: FieldValue.arrayRemove(
                                      [kTopicPlayingSetup],
                                    ),
                                  });                              }
                              }),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: SubCategory('Somebody playing my setup', inactive)),
                    Switch(
                        value: playingYourSetup,
                        onChanged: inactive
                            ? null
                            : (value) {
                                setState(() {
                                  playingYourSetup = !playingYourSetup;
                                });
                                if (playingYourSetup) {
                                  print('Adding ${[kTopicPlayingSetup]} to userinfo');
                                  MyFirebase.storeObject.collection(kCollectionUserInfo).doc(myUid).update({
                                    kFieldNotifications: FieldValue.arrayUnion(
                                      [kTopicPlayingYourSetup],
                                    ),
                                  });
                                } else {
                                  print('Removing ${[kTopicPlayingSetup]} from userinfo');
                                  MyFirebase.storeObject.collection(kCollectionUserInfo).doc(myUid).update({
                                    kFieldNotifications: FieldValue.arrayRemove(
                                      [kTopicPlayingYourSetup],
                                    ),
                                  });                              }
                              }),
                  ],
                ),
                FittedBox(child: HeadLine('App Updates Notifications')),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Category('All App Updates')),
                    Switch(
                        value: allAppUpdates,
                        onChanged: (value) {
                          setState(() {
                            allAppUpdates = !allAppUpdates;
                          });
                          if (allAppUpdates) {
                            appInactive = true;
                            print('Subscribing to topic $kTopicAllAppUpdates.\n'
                                'Adding ${[
                              kTopicAllAppUpdates]} to userinfo.\n'
                                'Unsubscribing from topic $kTopicMajorAppUpdates.\n'
                                'Removing ${[
                              kTopicMajorAppUpdates]} to userinfo.');
                            _firebaseMessaging.subscribeToTopic(kTopicAllAppUpdates);
                            _firebaseMessaging.unsubscribeFromTopic(kTopicMajorAppUpdates);
                            MyFirebase.storeObject.collection(kCollectionUserInfo).doc(myUid).update({
                              kFieldNotifications: FieldValue.arrayUnion(
                                [kTopicAllAppUpdates],
                              ),
                            });
                            MyFirebase.storeObject.collection(kCollectionUserInfo).doc(myUid).update({
                              kFieldNotifications: FieldValue.arrayRemove(
                                [kTopicMajorAppUpdates],
                              ),
                            });
                          } else {
                            appInactive = false;
                            print('Unsubscribing from topic $kTopicAllAppUpdates.\n'
                                'Removing ${[
                              kTopicAllAppUpdates]} from userinfo');
                            _firebaseMessaging.unsubscribeFromTopic(kTopicAllAppUpdates);
                            MyFirebase.storeObject.collection(kCollectionUserInfo).doc(myUid).update({
                              kFieldNotifications: FieldValue.arrayRemove(
                                [kTopicAllAppUpdates],
                              ),
                            });
                            if (majorAppUpdates) {
                              print('Subscribing to topic $kTopicMajorAppUpdates.\n'
                                  'Adding ${[
                                kTopicMajorAppUpdates]} to userinfo.\n');
                              _firebaseMessaging.subscribeToTopic(kTopicMajorAppUpdates);
                              MyFirebase.storeObject.collection(kCollectionUserInfo).doc(myUid).update({
                                kFieldNotifications: FieldValue.arrayUnion(
                                  [kTopicMajorAppUpdates],
                                ),
                              });
                            }
                          }
                        }),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: SubCategory('Major App Updates', appInactive)),
                    Switch(
                        value: majorAppUpdates,
                        onChanged: appInactive ? null : (value) {
                          setState(() {
                            majorAppUpdates = !majorAppUpdates;
                          });
                          if (majorAppUpdates) {
                            print('Subscribing to topic $kTopicMajorAppUpdates.\n'
                                'Adding ${[
                              kTopicMajorAppUpdates]} to userinfo');
                            _firebaseMessaging.subscribeToTopic(kTopicMajorAppUpdates);
                            MyFirebase.storeObject.collection(kCollectionUserInfo).doc(myUid).update({
                              kFieldNotifications: FieldValue.arrayUnion(
                                [kTopicMajorAppUpdates],
                              ),
                            });
                          } else {
                            print('Unsubscribing from topic $kTopicMajorAppUpdates.\n'
                                'Removing ${[
                              kTopicMajorAppUpdates]} from userinfo');
                            _firebaseMessaging.unsubscribeFromTopic(kTopicMajorAppUpdates);
                            MyFirebase.storeObject.collection(kCollectionUserInfo).doc(myUid).update({
                              kFieldNotifications: FieldValue.arrayRemove(
                                [kTopicMajorAppUpdates],
                              ),
                            });                              }
                        }),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HeadLine extends Text {
  HeadLine(this.text) : super(text);

  final String text;
  final TextStyle style = TextStyle(fontFamily: 'Pacifico', fontSize: 25);
}

class Category extends Text {
  Category(this.text) : super(text);

  final String text;
  final TextStyle style = TextStyle(
      // fontFamily: 'Pacifico',
      fontSize: 18);
}

class SubCategory extends Text {
  SubCategory(this.text, this.inactive) : super(text);

  final String text;
  final bool inactive;

  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 10),
      child: Text(
        text,
        style: TextStyle(
          // fontFamily: 'Pacifico',
          fontSize: 16,
          color: inactive ? kHubSetupColor : Colors.white,
          // color: Colors.pinkAccent,
        ),
      ),
    );
  }
}
