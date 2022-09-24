import 'package:flutter/material.dart';
import 'play_screen.dart';
// import 'file:///C:/Users/karol/AndroidStudioProjects/blackbox/lib/units/play.dart';
import 'package:blackbox/play.dart';
import 'make_setup_screen.dart';
// import 'file:///C:/Users/karol/AndroidStudioProjects/blackbox/lib/units/online_button.dart';
import 'package:blackbox/online_button.dart';

class SettingsScreen extends StatefulWidget {
  SettingsScreen({required this.online});
  final bool online;
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int widthOfPlayArea = 8;
  int heightOfPlayArea = 8;
  bool showAtomsSetting = false;
  int numberOfAtoms=4;

  List<DropdownMenuItem<int>> getNumberDropdown() {
    List<DropdownMenuItem<int>> childList = [];
    for (int i = 1; i <= 12; i++) {
      childList.add(DropdownMenuItem(child: Text('$i'), value: i));
    }
    return childList;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('settings')),
      body: Center(
        child: FittedBox(
          fit: BoxFit.contain,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    'Width of playboard:      ',
                    style: TextStyle(fontSize: 20),
                  ),
                  DropdownButton<int>(
                    hint: Text('$widthOfPlayArea'),
                    items: getNumberDropdown(),
                    onChanged: (value) {
                      setState(() {
                        widthOfPlayArea = value!;
                      });
                    },
                  )
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    'Height of playboard:     ',
                    style: TextStyle(fontSize: 20),
                  ),
                  DropdownButton<int>(
                    hint: Text('$heightOfPlayArea'),
                    items: getNumberDropdown(),
                    onChanged: (value) {
                      setState(() {
                        heightOfPlayArea = value!;
                      });
                    },
                  ),
                ],
              ),
              widget.online ? SizedBox() : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    'Number of atoms:\n(for random)                  ',
                    style: TextStyle(fontSize: 20),
                  ),
                  DropdownButton<int>(
                    hint: Text('$numberOfAtoms'),
                    items: getNumberDropdown(),
                    onChanged: (value) {
                      setState(() {
                        numberOfAtoms = value!;
                      });
                    },
                  ),
                ],
              ),
              SizedBox(height: 10),
              widget.online ? SizedBox() : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    'Show atoms?\n(Test run)                      ',
                    style: TextStyle(fontSize: 20),
                  ),
                  DropdownButton<bool>(
                    hint: showAtomsSetting ? Text('Yes') : Text('No'),
                    items: [
                      DropdownMenuItem(child: Text('Yes'), value: true),
                      DropdownMenuItem(child: Text('No'), value: false),
                    ],
                    onChanged: (value) {
                      setState(() {
                        showAtomsSetting = value!;
                      });
                    },
                  ),
                ],
              ),
              SizedBox(height: 50,),
              widget.online ? SizedBox() : RaisedButton(
                child: Text('Play Random'),
                onPressed: () {
                  Play thisGame = Play(numberOfAtoms: numberOfAtoms, widthOfPlayArea: widthOfPlayArea, heightOfPlayArea: heightOfPlayArea);
                  thisGame.showAtomSetting = showAtomsSetting;
                  thisGame.getAtomsRandomly();
                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                    return PlayScreen(thisGame: thisGame);
                  }));
                },
              ),
              widget.online
                  ? OnlineButton(
                text: 'Make Setup',
                onPressed: () {
                  Play thisGame = Play(numberOfAtoms: 4, widthOfPlayArea: widthOfPlayArea, heightOfPlayArea: heightOfPlayArea);
                  thisGame.showAtomSetting = showAtomsSetting;
                  thisGame.online = true;
                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                    return MakeSetupScreen(thisGame: thisGame);
                  }));
                }
              )
                  : RaisedButton(
                child: Text('Make Setup'),
                onPressed: () {
                  Play thisGame = Play(numberOfAtoms: 4, widthOfPlayArea: widthOfPlayArea, heightOfPlayArea: heightOfPlayArea);
                  thisGame.showAtomSetting = showAtomsSetting;
                  thisGame.online = false;
                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                    return MakeSetupScreen(thisGame: thisGame);
                  }));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
