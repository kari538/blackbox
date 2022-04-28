import 'package:flutter/material.dart';
import 'package:blackbox/online_screens/login_screen.dart';
import 'package:blackbox/online_screens/registration_screen.dart';
import 'package:blackbox/online_button.dart';

class RegistrationAndLoginScreen extends StatelessWidget {
  const RegistrationAndLoginScreen({this.withPop=false});
  final bool withPop;

  @override
  Widget build(BuildContext context) {
    print("Building RegistrationAndLoginScreen with withPop as $withPop");
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
                  return LoginScreen(withPop: withPop);
                }));
                print('After pushing LoginScreen with withPop as $withPop');
                if(withPop) {
                  print('withPop is true. Will pop RegistrationAndLoginScreen()');
                  Navigator.pop(context);
                }
              },
            ),
            OnlineButton(
              text: 'Register',
              onPressed: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return RegistrationScreen(withPop: withPop);
                }));
                if(withPop) Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
