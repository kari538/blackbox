// import 'package:blackbox/fcm.dart';
import 'package:blackbox/my_firebase.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:modal_progress_hud/modal_progress_hud.dart';

//import 'package:blackbox/online_screens/choose_board_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:blackbox/online_button.dart';
import 'file:///C:/Users/karol/AndroidStudioProjects/blackbox/lib/units/blackbox_popup.dart';
import 'game_hub_screen.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({this.fromSetup = false});

  final bool fromSetup;

  @override
  _RegistrationScreenState createState() => _RegistrationScreenState(fromSetup);
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  _RegistrationScreenState(this.fromSetup);

  final bool fromSetup;
  bool showSpinner = false;
  String email;
  String screenName;
  String password1;
  String password2 = '';
  auth.FirebaseAuth authenticator = auth.FirebaseAuth.instance;
  FirebaseFirestore database = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    print("Building RegistrationScreen with fromSetup as $fromSetup");
    return Scaffold(
      appBar: AppBar(title: Text('register')),
      body: ModalProgressHUD(
        inAsyncCall: showSpinner,
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
                    email = value;
                  });
                },
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
                  hintText: 'Enter your password',
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
                onPressed: email == null || password2 == '' || password1 != password2
                    ? null
                    : () async {
//                print(email);
//                print(password);
                  setState(() {
                          showSpinner = true;
                        });
                        try {
                          var user = await authenticator.createUserWithEmailAndPassword(email: email, password: password1);
                          if (user != null) {
                            String myUid = MyFirebase.authObject.currentUser.uid;
                            if (screenName == null || screenName == '') screenName = 'Anonymous';
//                            database.collection('userinfo').add({
//                             database.collection('userinfo').doc(myUid).set({
                            MyFirebase.storeObject.collection('userinfo').doc(myUid).set({
                              'email': email,
                              'screenName': screenName,
                            });
                            // initializeFirebaseCloudMessaging();
                            if (fromSetup) {
                              Navigator.pop(context);
                            } else {
                              Navigator.of(context).pushReplacement(MaterialPageRoute(
                                builder: (context) {
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
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
