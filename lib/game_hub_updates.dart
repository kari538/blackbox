import 'package:flutter/foundation.dart';
//import 'package:provider/provider.dart';

class GameHubUpdates extends ChangeNotifier {
  Map<String, String> providerUserIdMap = {};
  String myScreenName = '';
  // String myId = '';
  String myEmail = '';

  void updateMyScreenName(String newMyScreenName){
    myScreenName = newMyScreenName;
    notifyListeners();
  }

  // void updateMyId(String newId){
  //   myId = newId;
  //   notifyListeners();
  // }

  void updateMyEmail(String newEmail){
    myEmail = newEmail;
    notifyListeners();
  }

  void updateUserIdMap(Map<String, String> newUserIdMap){
    providerUserIdMap = newUserIdMap;
    notifyListeners();
  }

  String getScreenName(String key){
    return providerUserIdMap.containsKey(key) ? providerUserIdMap[key] : "Anonymous";
  }
}