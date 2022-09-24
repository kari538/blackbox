// import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

void main(){
  // Timestamp(1601324727, 357000000);
  stdout.write('Rock, scissors or paper? (r/s/p)  ');
  final String? input = stdin.readLineSync();
  print(input);
}