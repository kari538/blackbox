import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
// import 'file:///C:/Users/karol/AndroidStudioProjects/blackbox/lib/units/play.dart';
import 'package:blackbox/play.dart';
import 'package:blackbox/screens/settings_screen.dart';
import 'package:blackbox/screens/make_setup_screen.dart';
// import 'file:///C:/Users/karol/AndroidStudioProjects/blackbox/lib/units/online_button.dart';
import 'package:blackbox/online_button.dart';

class ChooseBoardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('blackbox')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            OnlineButton(
              text: 'Standard board',
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  Play thisGame = Play(numberOfAtoms: 4, heightOfPlayArea: 8, widthOfPlayArea: 8);
                  thisGame.online = true;
                  return MakeSetupScreen(thisGame: thisGame);
                }));
              },
            ),
            OnlineButton(
              text: 'Custom board',
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return SettingsScreen(online: true);
                }));
              },
            ),
          ],
        ),
      ),
    );
  }
}
