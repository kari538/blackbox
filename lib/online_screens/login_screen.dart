// import 'package:blackbox/fcm.dart';
import 'package:blackbox/constants.dart';
import 'package:blackbox/online_screens/game_hub_screen.dart';
import 'package:flutter/material.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:blackbox/online_button.dart';
import 'package:blackbox/units/blackbox_popup.dart';
import 'package:blackbox/my_firebase.dart';
class LoginScreen extends StatefulWidget {
  const LoginScreen({this.fromSetup = false});

  final bool fromSetup;

  @override
  _LoginScreenState createState() => _LoginScreenState(fromSetup);
}

class _LoginScreenState extends State<LoginScreen> {
  _LoginScreenState(this.fromSetup);

  final bool fromSetup;
  bool showSpinner = false;
  String email = '';
  String password = '';

  Future loginPress() async {
    setState(() {
      showSpinner = true;
    });
    try {
      var loginResponse = await MyFirebase.authObject.signInWithEmailAndPassword(email: email, password: password);
//                    print(loginResponse);
      print('Current user in LoginScreen is ${MyFirebase.authObject.currentUser}');
      // initializeFirebaseCloudMessaging();
      if (loginResponse != null) {
        if (fromSetup) {
          Navigator.pop(context);
        } else {
          Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (context) {
//                          return OnlineWelcomeScreen();
              return GameHubScreen();
            },
          ));
        }
      }
    } catch (e) {
      print('Error caught! $e');
      BlackboxPopup(
        context: context,
        title: 'Login Error!',
        desc: '$e',
      ).show();
    }
    setState(() {
      showSpinner = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    print("Building LoginScreen with fromSetup as $fromSetup");
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          child: Text('log in'),
          onTap: (){
            setState(() {
              email = 'karolinahagegard@gmail.com';
              password = '123456';
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
