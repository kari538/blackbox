import 'package:blackbox/route_names.dart';
import 'package:blackbox/fcm.dart';
import 'package:blackbox/my_firebase_labels.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:blackbox/constants.dart';
import 'package:blackbox/online_screens/game_hub_screen.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/material.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';import 'package:blackbox/online_button.dart';
import 'package:blackbox/units/blackbox_popup.dart';
import 'package:blackbox/my_firebase.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({this.withPop = false});

  final bool withPop;

  @override
  _LoginScreenState createState() => _LoginScreenState(withPop);
}

class _LoginScreenState extends State<LoginScreen> {
  _LoginScreenState(this.withPop);

  final bool withPop;
  bool showSpinner = false;
  String email = '';
  String password = '';

  Future loginPress() async {
    setState(() {
      showSpinner = true;
    });

    auth.UserCredential? loginResponse;
    String? _myUid;
    String? _myScreenName;
    bool? loginSuccess;

    // Try to log in:
    try {
      loginResponse = await MyFirebase.authObject.signInWithEmailAndPassword(email: email, password: password);
      // print(loginResponse);
      loginSuccess = true;
    } catch (e) {
      print('Login Error!: $e');
      loginSuccess = false;
      await BlackboxPopup(
        context: context,
        title: 'Login Error!',
        desc: '$e',
      ).show();
    }
    print('loginResponse is $loginResponse');
    print('Current user in LoginScreen is ${MyFirebase.authObject.currentUser}');

    // If the login was successful:
    if (loginSuccess && MyFirebase.authObject.currentUser != null) {
    // if (MyFirebase.authObject.currentUser != null) { // If from Change User, the login might have been unsuccessful even if there is a currentUser
      _myUid = MyFirebase.authObject.currentUser!.uid;
      _myScreenName = MyFirebase.authObject.currentUser!.displayName;

      // First, let's check if I have an entry in userinfo:
      DocumentSnapshot myUserInfo;
      Map<String, dynamic>? myUserData;
      try {
        myUserInfo = await MyFirebase.storeObject.collection(kCollectionUserInfo).doc(_myUid).get();
        myUserData = myUserInfo.data() as Map<String, dynamic>?;
      } catch (e) {
        print('Error checking for entry in userinfo: $e');
      }
      print('myUserData is $myUserData}');

      if (myUserData == null) {
        // I don't have an entry in userinfo. That's bad!
        print('I don\'t have an entry in userinfo! Making one.');
        myUserData = {
          'email': email,
          kFieldScreenName: _myScreenName, // It may be null, but if I didn't have any entry anyway...
          kFieldNotifications: [
            kTopicGameHubSetup,
            kTopicPlayingSetup,
            kTopicPlayingYourSetup,
            kTopicAllAppUpdates,
          ],
        };
        try {
          await MyFirebase.storeObject.collection(kCollectionUserInfo).doc(_myUid).set(myUserData);
          // If the above is successful, I need to initialize FCM again, because it doesn't
          // function properly without a userinfo entry:
          initializeFcm('');
        } catch (e) {
          print('Error making a userinfo entry: $e');
        }

      } else {
        // I already had an entry in userinfo
        // Let's check if I lack a display name in the auth object!
        if (_myScreenName == null && myUserData.containsKey(kFieldScreenName)) {
          _myScreenName = myUserData[kFieldScreenName];
          MyFirebase.authObject.currentUser!.updateDisplayName(_myScreenName);
        }
      }
      // Now, I should have an entry in userinfo, and both a screenName and
      // a display name if either existed before

      if (withPop) {
        Navigator.pop(context);
      } else {
        Navigator.of(context).pushReplacement(MaterialPageRoute(settings: RouteSettings(name: routeGameHub), builder: (context){
          return GameHubScreen();
          },
        ));
      }
    }

    setState(() {
      showSpinner = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    print("Building LoginScreen with withPop as $withPop");
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          child: Text('log in'),
          onTap: () {
            setState(() {
              print('Set state');
            });
          },
        ),
      ),
      body: ModalProgressHUD(
        inAsyncCall: showSpinner,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                // mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // SizedBox(
                  //   height: 48.0,
                  // ),
                  TextField(
                    onChanged: (value) {
                      setState(() {
                        email = value;
                      });
                    },
                    autofocus: true,
//                decoration: kTextFieldDecoration.copyWith(
                    decoration: InputDecoration(
                      hintText: 'Enter your email',
                    ),
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.emailAddress,
//                style: TextStyle(color: Colors.black),
                  ),
                  SizedBox(
                    height: 8.0,
                  ),
                  TextField(
//                decoration: kTextFieldDecoration.copyWith(
                    decoration: InputDecoration(
                      hintText: 'Enter your password',
                    ),
                    onChanged: (value) {
                      setState(() {
                        password = value;
                      });
                    },
                    onSubmitted: (string) {
                      loginPress();
                    },
                    textAlign: TextAlign.center,
                    obscureText: true,
//                style: TextStyle(color: Colors.black),
                  ),
                  SizedBox(
                    height: 24.0,
                  ),
                  OnlineButton(
                    text: 'Log in',
//                color: Colors.lightBlueAccent,
                    onPressed: email == '' || password == '' ? null : loginPress,
                  ),
                  SizedBox(height: 20),
                  InkWell(
                    child: Text(
                      'Forgotten password?',
                      textAlign: TextAlign.center,
                      style: TextStyle(decoration: TextDecoration.underline, fontSize: 14, fontWeight: FontWeight.bold, color: kHubSetupColor),
                    ),
                    onTap: () async {
                      bool clickedReset = false;
                      await BlackboxPopup(
                        context: context,
                        title: 'Reset password?',
                        desc: 'Click "Reset" to send an email with a'
                            ' reset link to the email address you just typed on this screen',
                        buttons: [
                          BlackboxPopupButton(
                              text: 'Cancel',
                              onPressed: () {
                                Navigator.pop(context);
                              }),
                          BlackboxPopupButton(
                            text: 'Reset',
                            onPressed: () async {
                              clickedReset = true;
                              print('Before change password');
                              try {
                                await MyFirebase.authObject.sendPasswordResetEmail(email: email);
                              } catch (e) {
                                print(e);
                              }
                              print('After change password');
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ).show();
                      if (clickedReset)
                        BlackboxPopup(
                                context: context,
                                title: 'Email sent',
                                desc: 'If the email address was correct'
                                    ' and registered with us, and your phone is online,'
                                    ' you should receive a Reset Password email shortly.')
                            .show();
                    },
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
