import 'package:flutter/foundation.dart';
//import 'package:provider/provider.dart';

class GameHubUpdates extends ChangeNotifier {
  Map<String, String?> userIdMap = {};
  /// Can sometimes be "Me" and "my":
  String? myScreenName = '';

  void updateMyScreenName(String? newMyScreenName){
    myScreenName = newMyScreenName;
    notifyListeners();
  }

  void updateUserIdMap(Map<String, String?> newUserIdMap){
    userIdMap = newUserIdMap;
    notifyListeners();
  }

  /// Returns 'Anonymous' if the uid is not found in providerUserIdMap
  String? getScreenName(String? key){
    return userIdMap.containsKey(key) ? userIdMap[key!] : "Anonymous";
  }
}