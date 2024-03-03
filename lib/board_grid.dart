import 'package:flutter/material.dart';
// import '../constants.dart';
import 'constants.dart';

class BoardGrid extends StatelessWidget {
  BoardGrid({required this.playWidth, required this.playHeight, required this.getEdgeTiles, required this.getMiddleTiles});
  final int playWidth;
  final int playHeight;
  final Widget Function({required int x, required int y}) getEdgeTiles;
  final Widget Function({required int x, required int y}) getMiddleTiles;
  // final Widget Function({int x, int y}) getEdgeTiles;
  // final Widget Function({int? x, int? y}) getMiddleTiles;

  List<Widget> getBoardRows({required int playWidth, required int playHeight}) {
    int numberOfRows = playHeight + 2;
    int numberOfElements = playWidth + 2;
    List<Widget> boardRows = []; //List of Rows
//    List<List<Widget>> allElements = List<List<Widget>>(numberOfRows); //2D List of row elements, which are Widgets
    List<List<Widget>> allElements = List.generate(numberOfRows, (int i) => List.filled(numberOfElements, SizedBox(), growable: false));

    for (int row = 0; row < numberOfRows; row++) {
//      print('row is $row');
      for (int element = 0; element < numberOfElements; element++) {
//        print('element is $element');
        //Corners:
        if (element == 0 && (row == 0 || row == numberOfRows - 1) || element == numberOfElements - 1 && (row == 0 || row == numberOfRows - 1)) {
          allElements[row][element] = getCorners();
//          allElements[row][element] = cornerTile();
          //Other edges:
        } else if (row == 0 || row == numberOfRows - 1 || element == 0 || element == numberOfElements - 1) {
//          allElements[row][element] = edgeTiles(x: element, y: row, heightOfPlayArea: playHeight, widthOfPlayArea: playWidth);
          allElements[row][element] = getEdgeTiles(x: element, y: row);
        } else {
//          allElements[row][element] = getMiddleElements(x: element, y: row, showAtom: showAtom);
          allElements[row][element] = getMiddleTiles(x: element, y: row);
        }
      }
//      print('Adding Row of allElements to boardRows');
      boardRows.add(
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            // children: allElements[row],
            children: allElements[row],
          ),
        ),
      );
//      print('boardRows: $boardRows');
    }
    return boardRows;
  }

  Widget getCorners() {
    return Expanded(
        child: Container(
          color: kBoardEdgeColor,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      verticalDirection: VerticalDirection.up,
      children: getBoardRows(playWidth: playWidth, playHeight: playHeight),
    );
  }
}