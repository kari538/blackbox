import 'package:blackbox/route_names.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:blackbox/fcm.dart';
import 'package:blackbox/my_firebase.dart';
import 'package:blackbox/my_firebase_labels.dart';
import 'package:flutter/material.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';import 'package:blackbox/online_button.dart';
import 'package:blackbox/units/blackbox_popup.dart';
import 'game_hub_screen.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({this.withPop = false});

  final bool withPop;

  @override
  _RegistrationScreenState createState() => _RegistrationScreenState(withPop);
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  _RegistrationScreenState(this.withPop);

  final bool withPop;
  bool showSpinner = false;
  String? email;
  String? screenName;
  String? password1;
  String password2 = '';
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future registerPress() async {
//  print(email);
//                print(password);
    setState(() {
      showSpinner = true;
    });
    try {
      var user = await MyFirebase.authObject.createUserWithEmailAndPassword(email: email!, password: password1!);
      if (user != null) {
        MyFirebase.authObject.currentUser!.updateDisplayName(screenName);
        String myUid = MyFirebase.authObject.currentUser!.uid;
        if (screenName == null || screenName == '') screenName = 'Anonymous';
//                            database.collection('userinfo').add({
//                             database.collection('userinfo').doc(myUid).set({
        MyFirebase.storeObject.collection('userinfo').doc(myUid).set({
          'email': email,
          'screenName': screenName,
          kFieldNotifications: [
            kTopicGameHubSetup,
            kTopicPlayingSetup,
            kTopicPlayingYourSetup,
            kTopicAllAppUpdates,
          ],
        });
        _firebaseMessaging.subscribeToTopic(kTopicGameHubSetup);
        _firebaseMessaging.subscribeToTopic(kTopicPlayingSetup);
        _firebaseMessaging.subscribeToTopic(kTopicAllAppUpdates);
        // initializeFirebaseCloudMessaging();
        if (withPop) {
          Navigator.pop(context);
        } else {
          Navigator.of(context).pushReplacement(MaterialPageRoute(settings: RouteSettings(name: routeGameHub), builder: (context){
                    return GameHubScreen();
            },
          ));
        }
      }
    } catch (e) {
      print('Error caught authenticating! e is: $e');
      BlackboxPopup(
        context: context,
        title: "Registration Error",
        desc: '$e',
      ).show();
    }
    setState(() {
      showSpinner = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    print("Building RegistrationScreen with withPop as $withPop");
    return Scaffold(
      appBar: AppBar(title: Text('register')),
      body: ModalProgressHUD(
        inAsyncCall: showSpinner,
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  TextField(
//                decoration: kTextFieldDecoration.copyWith(
                    decoration: InputDecoration(
                      hintText: 'Enter your email',
                    ),
                    onChanged: (value) {
                      setState(() {
                        email = value.toLowerCase();
                      });
                    },
                    autofocus: true,
//                style: TextStyle(color: Colors.black),
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  SizedBox(
                    height: 8.0,
                  ),
                  TextField(
//                decoration: kTextFieldDecoration.copyWith(
                    decoration: InputDecoration(
                      hintText: 'Enter your desired screen name',
                    ),
                    onChanged: (value) {
                      setState(() {
                        screenName = value;
                      });
                    },
//                style: TextStyle(color: Colors.black),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(
                    height: 8.0,
                  ),
                  TextField(
//                decoration: kTextFieldDecoration.copyWith(
                    decoration: InputDecoration(
                      hintText: 'Choose a password',
                    ),
                    onChanged: (value) {
                      setState(() {
                        password1 = value;
                      });
                    },
//                style: TextStyle(color: Colors.black),
                    textAlign: TextAlign.center,
                    obscureText: true,
                  ),
                  SizedBox(
                    height: 8.0,
                  ),
                  TextField(
//                decoration: kTextFieldDecoration.copyWith(
                    decoration: InputDecoration(
                      hintText: 'Repeat your password',
                    ),
                    onChanged: (value) {
                      setState(() {
                        password2 = value;
                      });
                    },
                    onSubmitted: (string){
                      registerPress();
                    },
//                style: TextStyle(color: Colors.black),
                    textAlign: TextAlign.center,
                    obscureText: true,
                  ),
                  password2 != ''
                      ? password1 == password2
                          //If passwords match:
                          ? Text('Passwords match', style: TextStyle(fontSize: 12, color: Colors.tealAccent))
                          //If passwords don't match:
                          : Text('Passwords don\'t match', style: TextStyle(fontSize: 12, color: Colors.red))
                      : SizedBox(),
                  SizedBox(
                    height: 24.0,
                  ),
                  OnlineButton(
                    text: 'Register',
//              onPressed: null,
                    onPressed: email == null || password2 == '' || password1 != password2 ? null : registerPress,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
