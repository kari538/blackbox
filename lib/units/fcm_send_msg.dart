import 'package:blackbox/my_firebase_labels.dart';
import 'package:blackbox/blackbox_popup.dart';
import 'package:flutter/cupertino.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
// import 'package:flutter/material.dart';

void fcmSendMsg(BuildContext context) async {
  http.Response res;
  String desc = '';
  String code = '';

  String jsonBody = jsonEncode({
    "notification": {
      "title": "New Game Hub Setup",
      "body": "fcmSendMsg(): A new blackbox setup has come in to game hub",
    },
    "data": {
      "click_action": "FLUTTER_NOTIFICATION_CLICK",
    },
    // "token": "${await token}",
    "topic": kTopicNewSetup,
  });
  print("jsonString is $jsonBody");
  Map<String, String> headers = {
    "content-type": "application/json"
  };

  try {
    res = await http.post(
      'https://us-central1-blackbox-6b836.cloudfunctions.net/sendMsg',
      headers: headers,
      body: jsonBody,
    );
  } catch (e) {
    print('Caught an error in sendMsg to topic $kTopicNewSetup API call!');
    print('e is: ${e.toString()}');
// errorMsg = e.toString();
    BlackboxPopup(context: context, title: 'Error sending notification', desc: '$e').show();
    if (res != null) print('Status code in apiCall() catch is ${res.statusCode}');
  }
  if (res != null) {
    print('sendMsg to topic $kTopicNewSetup API call response body: ${res.body}');
    print('sendMsg to topic $kTopicNewSetup API call response code: ${res.statusCode}');
    desc = res.body;
    code = res.statusCode.toString();
  } else {
    print('sendMsg to topic $kTopicNewSetup API call response is $res');
  }
// BlackboxPopup(context: context, title: 'Response $code', desc: '$desc').show();
  print('code is $code and desc is $desc in Upload Setup Button');
}