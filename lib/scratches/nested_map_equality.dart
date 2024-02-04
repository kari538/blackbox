// // import 'package:collection/src/equality.dart';
// // import 'dart:collection';
// import 'package:collection/collection.dart';
// // import 'package:cloud_firestore/cloud_firestore.dart';
//
// bool nestedMapEquality(Map map1, Map map2){
//   if (map1.length != map2.length) return false;
//   // Since I dunno how to sort them, I could check if all keys from map1 exist in map2 instead...
//   List keys1 = map1.keys.sorted((a, b) => null);
//   List keys2 = map2.keys.sorted((a, b) => null);
//   if (!ListEquality().equals(keys1, keys2)) return false;
//   // if (!ListEquality().equals(map1.keys, map2.keys)) return false;
//
//   // int index = 0;
//   for (var oneKey in keys1){
//     // for (var twoKey in keys2){
//       var value1 = map1[oneKey] as dynamic;
//       Type type1 = value1.runtimeType;
//       var value2 = map2[oneKey];
//       // var value2 = map2[twoKey];
//       Type type2 = value2.runtimeType;
//       if (type1 != type2) return false;
//       if (value1 is Map) if (!nestedMapEquality(value1, value2)) return false;
//       else if (value1 is List) if (!ListEquality().equals(value1, value2)) return false;
//     // }
//   }
//
//
//   return true;
// }