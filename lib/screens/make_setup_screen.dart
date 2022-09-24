import 'package:blackbox/route_names.dart';
import 'package:blackbox/play_screen_menu.dart';
import 'package:blackbox/board_grid.dart';
//import 'package:blackbox/my_firebase.dart';
//import 'package:blackbox/online_screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:blackbox/play.dart';
import 'package:blackbox/atom_n_beam.dart';
import 'package:blackbox/constants.dart';
import 'play_screen.dart';
//import 'package:cloud_firestore/cloud_firestore.dart';
//import 'package:firebase_auth/firebase_auth.dart' as auth;
//import 'package:blackbox/online_screens/game_hub_screen.dart';
//import 'package:blackbox/online_button.dart';
//import 'package:collection/collection.dart';
//import 'package:blackbox/blackbox_popup.dart';
//import 'package:provider/provider.dart';
//import 'package:blackbox/game_hub_updates.dart';
//import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:blackbox/online_screens/reg_n_login_screen.dart';
import 'package:blackbox/upload_setup_button.dart';

class MakeSetupScreen extends StatefulWidget {
  MakeSetupScreen({required this.thisGame});
  final Play thisGame;

  @override
  _MakeSetupScreenState createState() => _MakeSetupScreenState();
}

class _MakeSetupScreenState extends State<MakeSetupScreen> {

  void refresh() {
    setState(() {});
  }

  Widget getEdges({required int x, required int y}) {
//    int slotNo = myBeam.convert({'x': element, 'y': row});
    int slotNo = Beam.convert(coordinates: Position(x, y), heightOfPlayArea: widget.thisGame.heightOfPlayArea, widthOfPlayArea: widget.thisGame.widthOfPlayArea)!;
    return Expanded(
      child: Container(
        child: Center(child: widget.thisGame.edgeTileChildren![slotNo - 1] ?? FittedBox(
            fit: BoxFit.contain, child: Text('$slotNo', style: TextStyle(color: kBoardEdgeTextColor, fontSize: 15)))),
        decoration: BoxDecoration(color: kBoardEdgeColor),
      ),
    );
  }

  Widget getMiddleElements({required int x, required int y}) {
//    return Expanded(child: Container(decoration: BoxDecoration(border: Border.all(color: kBoardGridlineColor))));
    return PlayBoardTile(position: Position(x, y), showAtom: false, thisGame: widget.thisGame, refreshParent: refresh);
//    return PlayBoardTile(x, y);
  }

  Widget onlineSetupMenu(BuildContext context) {
    return PopupMenuButton(
      itemBuilder: (context){
        return [
          PopupMenuItem(
            child: Text('Change user'),
            value: () async {
//              print('Inside value of Change User. About to push RegistrationAndLoginScreen()');
              await Navigator.push(context, MaterialPageRoute(settings: RouteSettings(name: routeRegLogin), builder: (context) {
                return RegistrationAndLoginScreen(withPop: true);
              }));
            },
          ),
        ];
      },
      onSelected: (Function value) => value(),
//      onSelected: (Function value){
//        value();
//      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text('blackbox'),
          actions: widget.thisGame.online ? [onlineSetupMenu(context)] : [PlayScreenMenu(widget.thisGame, entries: [4],)]),
      // appBar: AppBar(title: Text('blackbox'), actions: [popupMenu(context)]),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            SizedBox(),
            Expanded(flex: 2, child: Center(child: Text('Make your setup!', style: TextStyle(fontSize: 30)))),
            //Scaffold, Center, Column, Expanded, Padding, AspectRatio, Container, Board (returns Column)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.all(10),
                  child: Text('Number of atoms:   ${widget.thisGame.atoms.length}'),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: widget.thisGame.online ? UploadSetupButton(widget: widget, /*currentUser: loggedInUser.email,*/) : PlayButton(widget: widget),
                ),
              ],
            ),
            Expanded(flex: 3,
              child: Padding(
                padding: EdgeInsets.only(left: 8, top: 8, right: 8, bottom: 20),
                child: AspectRatio(
                  aspectRatio: (widget.thisGame.widthOfPlayArea+2)/(widget.thisGame.heightOfPlayArea+2),
                  child: Container(
                    child: BoardGrid(getEdgeTiles: getEdges, getMiddleTiles: getMiddleElements, playHeight: widget.thisGame.heightOfPlayArea, playWidth: widget.thisGame.widthOfPlayArea),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PlayButton extends StatelessWidget {
  const PlayButton({
    required this.widget,
  });

  final MakeSetupScreen widget;

  @override
  Widget build(BuildContext context) {
    return RaisedButton(
      child: Text('Play'),
      onPressed: widget.thisGame.atoms.length != widget.thisGame.atoms.length ? null : () {
//                      Navigator.push(context, MaterialPageRoute(builder: (context) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) {
          return PlayScreen(thisGame: widget.thisGame);
        },));
//                      Navigator.pop(context);
      },
    );
  }
}



//-----------------------------------------------------------------------------------------------------
//PlayBoardTile Stateful Widget:
class PlayBoardTile extends StatefulWidget {
  PlayBoardTile({this.position, this.showAtom, required this.thisGame, this.refreshParent});

  final Position? position;
  final bool? showAtom;
  final Play thisGame;
  final Function? refreshParent;

  @override
  _PlayBoardTileState createState() => _PlayBoardTileState(position!, showAtom, thisGame);
}

class _PlayBoardTileState extends State<PlayBoardTile> {
  _PlayBoardTileState(this.position, this.showAtom, this.thisGame){
    thisAtom=Atom(position.x, position.y);
  }

  bool? showAtom;
  final Position position;
  final Play thisGame;
  late Atom thisAtom;

  @override
  Widget build(BuildContext context) {
//    print('Building tile ${position.toList()} with showAtom as $showAtom');
    return Expanded(
      child: GestureDetector(
          child: Container(
            child: Center(
              child: showAtom! ? Image(image: AssetImage('images/atom_yellow.png')) : FittedBox(
                  fit: BoxFit.contain, child: Text('${position.x},${position.y}', style: TextStyle(color: kBoardTextColor, fontSize: 15))),
            ),
            decoration: BoxDecoration(color: kBoardColor, border: Border.all(color: kBoardGridLineColor, width: 0.5)),
          ),
          onTap: () {
            if(showAtom!){
              print('Removing ${position.toList()}');
//              thisGame.playerAtoms.remove(position.toList());
              thisGame.atoms.remove(thisAtom);
              print('Atoms list is ${thisGame.atoms}');
            } else {
              print('Adding ${position.toList()}');
//              thisGame.playerAtoms.add(position.toList());
              thisGame.atoms.add(thisAtom);
              print('Atoms list is ${thisGame.atoms}');
            }
//              print('Button ${position.toList()} was pressed');
            setState(() {
              showAtom = showAtom! ? false : true;
            });
            widget.refreshParent!();
          }),
    );
  }
}