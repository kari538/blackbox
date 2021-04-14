import 'package:flutter/material.dart';
import 'package:blackbox/online_screens/login_screen.dart';
import 'package:blackbox/online_screens/registration_screen.dart';
import 'package:blackbox/online_button.dart';

class RegistrationAndLoginScreen extends StatelessWidget {
  const RegistrationAndLoginScreen({this.fromSetup=false});
  final bool fromSetup;

  @override
  Widget build(BuildContext context) {
    print("Building RegistrationAndLoginScreen with fromSetup as $fromSetup");
    return Scaffold(
      appBar: AppBar(title: Text('log in or register')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            OnlineButton(
              text: 'Log in',
              onPressed: () async {
                print('Pressed Log in');
                await Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return LoginScreen(fromSetup: fromSetup);
                }));
                print('After pushing LoginScreen with fromSetup as $fromSetup');
                if(fromSetup) {
                  print('fromSetup is true. Will pop context');
                  Navigator.pop(context);
                }
              },
            ),
            OnlineButton(
              text: 'Register',
              onPressed: (){
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return RegistrationScreen(fromSetup: fromSetup);
                }));
                if(fromSetup) Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
