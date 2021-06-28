import 'package:blackbox/my_firebase_labels.dart';
import 'file:///C:/Users/karol/AndroidStudioProjects/blackbox/lib/units/blackbox_popup.dart';
import 'package:flutter/cupertino.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
// import 'package:flutter/material.dart';

/// Send a BuildContext if you want to get a popup for errors
void fcmSendMsg(String jsonString, [BuildContext context]) async {
  http.Response res;
  String desc = '';
  String code = '';
  String apiAddress = kApiCloudFunctionsLink + kApiSendMsg;
  // String jsonString = jsonEncode({
  //   "notification": {
  //     "title": "New Game Hub Setup",
  //     "body": "fcmSendMsg(): A new blackbox setup has come in to game hub",
  //   },
  //   "data": {
  //     "click_action": "FLUTTER_NOTIFICATION_CLICK",
  //   },
  //   // "token": "${await token}",
  //   "topic": kTopicGameHubSetup,
  // });
  print("jsonString in fcmSendMsg() is $jsonString");
  print('API address in fcmSendMsg() is $apiAddress');

  Map<String, String> headers = {
    kApiContentType: kApiApplicationJson
  };

  try {
    res = await http.post(
      // 'https://us-central1-blackbox-6b836.cloudfunctions.net/sendMsg',
      apiAddress,
      headers: headers,
      body: jsonString,
    );
  } catch (e) {
    print('Caught an error in sendMsg API call! Msg: $jsonString');
    print('e is: ${e.toString()}');
// errorMsg = e.toString();

    // if (context.findAncestorStateOfType().mounted){ // Only works if it actually IS mounted... ;(
    try {
      context.findAncestorStateOfType();
      print('The ancestor state of error popup is mounted.');
      BlackboxPopup(context: context, title: 'Error sending notification', desc: '$e').show();
    } catch (e) {
      print('The ancestor state of error popup is not mounted.');
    }
    if (res != null) print('Status code in apiCall() catch is ${res.statusCode}');
  }
  if (res != null) {
    print('sendMsg API call response body in fcmSendMsg(): ${res.body}');
    print('sendMsg API call response code in fcmSendMsg(): ${res.statusCode}');
    desc = res.body;
    code = res.statusCode.toString();
  } else {
    print('sendMsg API call response is $res');
  }
// BlackboxPopup(context: context, title: 'Response $code', desc: '$desc').show();
  print('code is $code and desc is $desc in fcmSendMsg()');
}