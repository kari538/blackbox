import 'package:blackbox/constants.dart';
import 'package:blackbox/my_firebase_labels.dart';
import 'package:blackbox/screens/spinner_screen.dart';
import 'package:blackbox/global.dart';
import 'package:blackbox/units/blackbox_popup.dart';
import 'package:blackbox/my_firebase.dart';
import 'package:blackbox/online_button.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/material.dart';

class DeleteAccountScreen extends StatelessWidget {
  const DeleteAccountScreen({Key? key, required this.email}) : super(key: key);
  final String email;

  Future deleteAccountPress(BuildContext context,
      {required String password}) async {

    // Pop back to Welcome Screen, which will cancel all listeners:
    print('Popping screens until first');
    Navigator.popUntil(context, (route) => route.isFirst);
    // Pushing Spinner screen:
    Navigator.push(
        context,
        // MaterialPageRoute(builder: (context){
        //   return SpinnerScreen();
        // })
      PageRouteBuilder(
        pageBuilder: (context, anim1, anim2) {
          return SpinnerScreen();
        },
        transitionDuration: Duration(days: 0),
      )
    );
    print('Waiting a bit to give time for all userChange listeners to cancel...');
    await Future.delayed(Duration(milliseconds: 1000));

    String? _myUid;
    bool? loginSuccess;

    // Try to log in:
    try {
      await MyFirebase.authObject
          .signInWithEmailAndPassword(email: email, password: password);
      // print(loginResponse);
      loginSuccess = true;
    } catch (e) {
      print('Login Error!: $e');
      loginSuccess = false;
      await BlackboxPopup(
        context: GlobalVariable.navState.currentContext!,
        title: 'Login Error!',
        desc: '$e',
      ).show();
    }
    print('loginSuccess in deleteAccount is $loginSuccess');
    // print('loginResponse is $loginResponse');
    // print(
    //     'Current user in DeleteAccountScreen is ${MyFirebase.authObject.currentUser}');

    // If the login was successful:
    if (loginSuccess) {
      assert(
          MyFirebase.authObject.currentUser != null,
          'loginSuccess is true but currentUser is null!');

      _myUid = MyFirebase.authObject.currentUser?.uid;


      // Navigator.pop(context);
      // setProfileScreenState(spinner: true);
      // await Future.delayed(Duration(seconds: 1));
      bool deleteSuccess = false;
      try {
        await MyFirebase.storeObject
            .collection(kCollectionUserInfo)
            .doc(_myUid)
            .delete();
        await MyFirebase.authObject.currentUser!.delete();
        deleteSuccess = true;
        // :.(
      } catch (e) {
        print('Error deleting user: \n$e');
      }

      // Navigator.popUntil(context, (route) => route.isFirst);

      try {
        Navigator.popUntil(
          GlobalVariable.navState.currentContext!,
          (route) => route.isFirst,
        ); //Popping the Spinner screen
        // Navigator.popUntil(context, (route) => route.isFirst); //Popping the Spinner screen
      } catch (e) {
        print('Error popping the Spinner screen: \n$e');
      }

      if (deleteSuccess) {
        BlackboxPopup(
          context: GlobalVariable.navState.currentContext!,
          title: 'Complete',
          desc: 'Your blackbox account has been deleted',
        ).show();
      } else {
        BlackboxPopup(
          context: GlobalVariable.navState.currentContext!,
          title: 'Error',
          desc: 'Something went wrong deleting '
              'your blackbox account! Please contact support at '
              'karolinahagegard@gmail.com.',
        ).show();
      }
    }

    // setState(() {
    //   showSpinner = false;
    // });
  }

  @override
  Widget build(BuildContext context) {
    String password = '';

    return Scaffold(
      appBar: AppBar(title: Text('Deleting Account')),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              // mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // TextField(
                //   onChanged: (value) {
                //     // setState(() {
                //       email = value;
                //     // });
                //   },
                //   autofocus: true,
                //   decoration: InputDecoration(
                //     hintText: 'Enter your email',
                //   ),
                //   textAlign: TextAlign.center,
                //   keyboardType: TextInputType.emailAddress,
                // ),
                // SizedBox(
                //   height: 8.0,
                // ),
                Text(
                  'To delete your account, please type the password for '
                  '$email:',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22),
                ),
                SizedBox(
                  height: 20.0,
                ),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Enter your password',
                  ),
                  onChanged: (value) {
                    // setState(() {
                    password = value;
                    print('passwrod is $password');
                    // });
                  },
                  onSubmitted: (string) {
                    deleteAccountPress(context, password: password);
                  },
                  autofocus: true,
                  textAlign: TextAlign.center,
                  obscureText: true,
                ),
                SizedBox(
                  height: 24.0,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    OnlineButton(
                      text: 'Cancel',
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    OnlineButton(
                      text: 'Delete Account',
                      onPressed:
                          // password == ''
                          //     ? null
                          //     :
                          () {
                        print('Pressed Delete Account');
                        deleteAccountPress(context, password: password);
                      },
                    ),
                  ],
                ),
                SizedBox(height: 20),
                InkWell(
                  child: Text(
                    'Forgotten password?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        decoration: TextDecoration.underline,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: kHubSetupColor),
                  ),
                  onTap: () async {
                    bool clickedReset = false;
                    await BlackboxPopup(
                      context: context,
                      title: 'Reset password?',
                      desc: 'Click "Reset" to send an email with a'
                          ' reset link to the email address you provided',
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
                              await MyFirebase.authObject
                                  .sendPasswordResetEmail(email: email);
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
                                  ' and registered with us, and you are online,'
                                  ' you should receive a Reset Password email shortly.')
                          .show();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
