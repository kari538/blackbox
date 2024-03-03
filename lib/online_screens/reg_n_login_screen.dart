import 'package:blackbox/online_screens/game_hub_screen.dart';
import 'package:blackbox/route_names.dart';
// import 'package:blackbox/my_firebase.dart';
import 'package:flutter/material.dart';
import 'package:blackbox/online_screens/login_screen.dart';
import 'package:blackbox/online_screens/registration_screen.dart';
import 'package:blackbox/online_button.dart';

class RegistrationAndLoginScreen extends StatelessWidget {
  const RegistrationAndLoginScreen({this.withPop = false});

  final bool withPop;

  @override
  Widget build(BuildContext context) {
    print("Building RegistrationAndLoginScreen with withPop as $withPop");
    bool? loginSuccess;

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
                loginSuccess = await Navigator.push(context,
                    MaterialPageRoute(builder: (context) {
                  return LoginScreen();
                  // return LoginScreen(withPop: withPop);
                }));
                print(
                    'After popping LoginScreen with withPop as $withPop and loginSuccess as $loginSuccess');
                if (loginSuccess == true) {
                  if (withPop) {
                    print(
                        'loginSuccess and withPop are true. Will pop RegistrationAndLoginScreen()');
                    Navigator.pop(context);
                  } else {
                    print(
                        'loginSuccess is true and withPop is false. Will push replacement GameHubScreen()');
                    Navigator.of(context).pushReplacement(MaterialPageRoute(
                      settings: RouteSettings(name: routeGameHub),
                      builder: (context) {
                        return GameHubScreen();
                      },
                    ));
                  }
                }
                // print('After popping LoginScreen with withPop as $withPop');
                // if (withPop) {
                //   print(
                //       'withPop is true. Will pop RegistrationAndLoginScreen()');
                //   Navigator.pop(context);
                // } else {
                //   bool loggedIn = MyFirebase.authObject.currentUser != null;
                //   if (loggedIn) {
                //     print(
                //         'loggedIn is true. Will pop RegistrationAndLoginScreen()');
                //     // Navigator.pop(thisContext);
                //   }
                // }
              },
            ),
            OnlineButton(
                text: 'Register',
                onPressed: () async {
                  loginSuccess = await Navigator.push(context,
                      MaterialPageRoute(builder: (context) {
                    return RegistrationScreen();
                    // return RegistrationScreen(withPop: withPop);
                  }));
                  print(
                      'After popping RegistrationScreen with withPop as $withPop and loginSuccess as $loginSuccess');
                  if (loginSuccess == true) {
                    if (withPop) {
                      print(
                          'loginSuccess and withPop are true. Will pop RegistrationAndLoginScreen()');
                      Navigator.pop(context);
                    } else {
                      print(
                          'loginSuccess is true and withPop is false. Will push replacement GameHubScreen()');
                      Navigator.of(context).pushReplacement(MaterialPageRoute(
                        settings: RouteSettings(name: routeGameHub),
                        builder: (context) {
                          return GameHubScreen();
                        },
                      ));
                    }
                  }
                }),
          ],
        ),
      ),
    );
  }
}
