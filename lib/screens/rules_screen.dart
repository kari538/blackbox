import 'package:flutter/material.dart';

class RulesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('rules')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: SingleChildScrollView(
                  child: Column(
                    children: <Widget>[
                      Text(
                        "Blackbox️ is a classic puzzle and logic game, invented in the 1970s by a man call Eric Solomon. "
                            "The idea is that you have a black box inside which there are 4 atoms "
                            "hidden in secret locations, and you want to find out where they are.\n\n"
                            " You can't look into the box, but you can shoot \"light beams\" into it. The light beams will interact "
                            "with the atoms, and so by observing what happens "
                            "to the light beams, you will eventually be able to work out where the atoms are!\n\n"
                            "The light beams interact with the atoms according to the following rules, to be applied in this order "
                            "(see example image):\n\n",
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(flex: 1, child: Center(child: Text("1) "))),
                          Expanded(
                            flex: 5,
                            child: Container(
                              child: Center(
                                child: Text(
                                  "When a beam reaches a square directly in front of an atom, it gets sucked into the atom and it's a hit.\n",
                                  softWrap: true,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(flex: 1, child: Center(child: Text("2) "))),
                          Expanded(
                            flex: 5,
                            child: Center(
                              child: Container(
                                child: Text(
                                  "When a beam reaches a square diagonal from an atom, it is \"deflected\", changing direction 90 degrees "
                                      "away from where it almost hit the atom. (If there is an atom straight ahead AND one diagonally from "
                                      "the beam position, the atom straight ahead \"wins\" and it's a hit.)\n",
                                  softWrap: true,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(flex: 1, child: Container(child: Center(child: Text("3) ")))),
                          Expanded(
                            flex: 5,
                            child: Container(
                              child: Center(
                                child: Text(
                                  "When a beam reaches a square diagonal with TWO atoms, it makes a u-turn and comes back to where it started. "
                                      "It's a reflection.\n",
                                  softWrap: true,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(flex: 1, child: Center(child: Text("4) "))),
                          Expanded(
                            flex: 5,
                            child: Container(
                              child: Center(
                                child: Text(
                                  "If there is an atom diagonal from the starting point where you are trying to shoot a beam, the beam can't get in and "
                                      "it's also a reflection.\n\n",

                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text("The outcome of the beams are shown with these symbols:\n"),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text('Hit:  '),
                          Image(image: AssetImage('images/beams/beam_hit.png'), height: 25),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text('Reflection:  '),
                          Image(
                            image: AssetImage('images/beams/beam_reflection.png'),
                            height: 25,
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text('Beam out:  '),
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: Image(
                              image: AssetImage('images/beams/beam_blue.png'),
                              height: 25,
                            ),
                          ),
                          Text(','),
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: Image(
                              image: AssetImage('images/beams/beam_violet.png'),
                              height: 25,
                            ),
                          ),
                          Text(','),
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: Image(
                              image: AssetImage('images/beams/beam_green.png'),
                              height: 25,
                            ),
                          ),
                          Text('...'),
                        ],
                      ),
                      Text('\nIn the example image below, most but not all beams have been marked for you. Can you work out how'
                          ' the remaining beams traveled?\n\n'
                          ''
                          'Under the "Settings" button, you also have an option to "Show atoms". If you choose that, you can see '
                          'the atoms as you play, just to understand how it works, before you play for real.\n\n'
                          'When you play a game, and you think you have figured out where the atoms are, click \"This is my final answer\" '
                          'to see how well you did. Each beam mark gives you one score, and you get 5 penalty scores for every atom that you '
                          'got wrong. The goal is, of course, to get as low a score as possible.\n\n'
                          'Happy puzzling! ☺')
                    ],
                  ),
                ),
              ),
//              child: Padding(
//                padding: const EdgeInsets.all(20.0),
//                child: Scrollable(
//                  viewportBuilder: (context, ViewportOffset x){
//                    return Text(
//                      "The idea is that you have a black box inside which there are 4 atoms hidden in secret locations. You can't look into "
//                          "the box, but you can shoot \"light beams\" into it. The light beams will interact with the atoms, and so by observing what happens "
//                          "to the light beams, you will eventually be able to work out where the atoms are!\n\n"
//                          "The light beams interact with the atoms according to the following rules, to be applied in this order (see example below):\n"
//                          "1) When a beam reaches a square directly in front of an atom, it gets sucked into the atom and it's a hit.\n"
//                          "2) When a beam reaches a square diagonal from an atom, it is \"deflected\", changing direction 90 degrees away from the atom.\n"
//                          "3) When a beam reaches a square diagonal with TWO atoms, it makes a u-turn and comes back to where it started. It's a reflection.\n"
//                          "4) If there is an atom diagonal from the starting point where you are trying to shoot a beam, the beam can't get in and it's also a reflection.'),",
//                    );
//                  },
////                  child: Text(
////                    "The idea is that you have a black box inside which there are 4 atoms hidden in secret locations. You can't look into "
////                    "the box, but you can shoot \"light beams\" into it. The light beams will interact with the atoms, and so by observing what happens "
////                    "to the light beams, you will eventually be able to work out where the atoms are!\n\n"
////                    "The light beams interact with the atoms according to the following rules, to be applied in this order (see example below):\n"
////                    "1) When a beam reaches a square directly in front of an atom, it gets sucked into the atom and it's a hit.\n"
////                    "2) When a beam reaches a square diagonal from an atom, it is \"deflected\", changing direction 90 degrees away from the atom.\n"
////                    "3) When a beam reaches a square diagonal with TWO atoms, it makes a u-turn and comes back to where it started. It's a reflection.\n"
////                    "4) If there is an atom diagonal from the starting point where you are trying to shoot a beam, the beam can't get in and it's also a reflection.'),",
////                  ),
//                ),
//              ),
            ),
            Expanded(
              child: Image(image: AssetImage('images/rules_example.png')),
            )
          ],
        ),
      ),
    );
  }
}