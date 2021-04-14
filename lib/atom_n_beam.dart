//import 'package:flutter/cupertino.dart';
//import 'package:flutter/material.dart';
//import 'dart:ui';
import 'package:meta/meta.dart';

class Atom {
  Atom(this._x, this._y) {
    void getPosition() {
      //
      position = Position(_x, _y);
//      position = {'x': _x, 'y': _y};
    }
    getPosition();
  }
  int _x;
  int _y;
//  List<int> position;
  Position position;
//  Map<String, int> position;
  String toString(){
    return '[$_x,$_y]';
  }
}

class Beam {
  ///A beam has a position, (x, y), and a direction, (xDir, yDir) where 1 means a positive direction along the respective axis, 0 means no direction along that axis, and -1 is a negative direction along that axis.
  Beam({@required this.start, @required int widthOfPlayArea, @required int heightOfPlayArea}) {
    //Bottom edge:
    if (1 <= start && start <= widthOfPlayArea) {
      _y = 0;
      _x = start;
      direction = Direction(0, 1);
    //Right edge:
    } else if (widthOfPlayArea + 1 <= start && start <= widthOfPlayArea + heightOfPlayArea) {
      _y = start - widthOfPlayArea;
      _x = widthOfPlayArea + 1;
      direction = Direction(-1, 0);
    //Top edge:
    } else if (widthOfPlayArea + heightOfPlayArea + 1 <= start && start <= 2*widthOfPlayArea + heightOfPlayArea) {
      _y = heightOfPlayArea + 1;
      _x = 2*widthOfPlayArea + heightOfPlayArea +1 - start;
      direction = Direction(0, -1);
    //Left edge:
    } else if (2*widthOfPlayArea + heightOfPlayArea +1 <= start && start <= 2*widthOfPlayArea + 2*heightOfPlayArea) {
      _y = 2*widthOfPlayArea + 2*heightOfPlayArea +1 - start;
      _x = 0;
      direction = Direction(1, 0);
    }
    position = Position(_x, _y);
  }

  int start;
  int _x;
  int _y;
  Position position;
  Direction direction;
  Position projectedPosition=Position(0, 0);

  static int convert({Position coordinates, int widthOfPlayArea, int heightOfPlayArea}){
    int slot;
    //Bottom edge:
    if (coordinates.y == 0){
      slot = coordinates.x;
      //Right edge:
    } else if (coordinates.x == widthOfPlayArea+1) {
      slot = coordinates.y + widthOfPlayArea;
      //Top edge:
    } else if (coordinates.y == heightOfPlayArea+1) {
      slot = 2*widthOfPlayArea + heightOfPlayArea+1 - coordinates.x;
      //Left edge:
    } else if (coordinates.x == 0) {
      slot = 2*widthOfPlayArea + 2*heightOfPlayArea +1 -coordinates.y;
    }
    return slot;
  }
}


class Position {
  Position(this.x, this.y);
  int x;
  int y;
  List<int> toList(){
    return [x, y];
  }
}

class Direction {
  Direction(this.xDir, this.yDir);
  int xDir;
  int yDir;
  List<int> toList(){
    return [xDir, yDir];
  }
}
