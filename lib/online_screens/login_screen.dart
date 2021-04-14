// import 'package:blackbox/fcm.dart';
import 'package:blackbox/online_screens/game_hub_screen.dart';
import 'package:flutter/material.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:blackbox/online_button.dart';
import 'package:blackbox/blackbox_popup.dart';
import 'package:blackbox/my_firebase.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({this.fromSetup=false});
  final bool fromSetup;
  @override
  _LoginScreenState createState() => _LoginScreenState(fromSetup);
}

class _LoginScreenState extends State<LoginScreen> {
  _LoginScreenState(this.fromSetup);
  final bool fromSetup;
  bool showSpinner = false;
  String email;
  String password;


  @override
  Widget build(BuildContext context) {
    print("Building LoginScreen with fromSetup as $fromSetup");
    return Scaffold(
      appBar: AppBar(title: Text('log in')),
      body: ModalProgressHUD(
        inAsyncCall: showSpinner,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SizedBox(
                height: 48.0,
              ),
              TextField(
                onChanged: (value) {
                  email = value;
                },
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
                  password = value;
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
                onPressed: () async {
                  setState(() {
                    showSpinner = true;
                  });
                  try {
                    var loginResponse = await MyFirebase.authObject.signInWithEmailAndPassword(email: email, password: password);
//                    print(loginResponse);
                    print('Current user in LoginScreen is ${MyFirebase.authObject.currentUser}');
                    // initializeFirebaseCloudMessaging();
                    if (loginResponse != null) {
                      if(fromSetup){
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
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
