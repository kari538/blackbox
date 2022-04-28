import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:blackbox/my_firebase.dart';
import 'package:blackbox/my_firebase_labels.dart';
import 'package:blackbox/units/blackbox_popup.dart';
import 'package:flutter/cupertino.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pretty_json/pretty_json.dart';
// import 'package:flutter/material.dart';

/// Send a BuildContext if you want to get a popup for errors
Future<http.Response>  fcmSendMsg(String jsonString, [BuildContext context]) async {
// void fcmSendMsg(String jsonString, [BuildContext context]) async {
  http.Response res;
  String desc = '';
  String code = '';
  String apiAddress = emulating ? kApiEmulatorLink + kApiEmulatorSendMsg : kApiCloudFunctionsLink + kApiSendMsg;
  print('API address in fcmSendMsg() is $apiAddress');
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
  print("jsonString in fcmSendMsg() is:");
  printPrettyJson(jsonDecode(jsonString));

  Map<String, String> headers = {
    kApiContentType: kApiApplicationJson
  };

  try {
    if (emulating) {
      res = await http.post(
        Uri.http(kApiEmulatorLink, kApiEmulatorSendMsg),
        headers: headers,
        body: jsonString,
      );
    } else {
      res = await http.post(
        Uri.https(kApiCloudFunctionsLink, kApiSendMsg),
        headers: headers,
        body: jsonString,
      );
    }
  } catch (e) {
    print('Caught an error in sendMsg API call!\ne is: ${e.toString()}');
    print('Msg: $jsonString');
// errorMsg = e.toString();

    // if (context.findAncestorStateOfType().mounted){ // Only works if it actually IS mounted... ;(
    try {
      context.findAncestorStateOfType();
      print('The ancestor state of error popup is mounted.');
      if (context.findAncestorStateOfType().mounted) {
        Future.delayed(Duration(seconds: 1), (){
          // Has to wait so that initState() has time to complete...
          BlackboxPopup(context: context, title: 'Error sending notification', desc: '$e').show();
        });
      }
    } catch (e) {
      print('The ancestor state of error popup is probably not mounted.');
      print('$e');
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
  print('fcmSendMsg(): code is $code and desc is:');
  printPrettyJson(jsonDecode(desc));
  return res;
}


void handleMsgResponse({@required Future<http.Response> sendMsgRes, @required String token, @required String uid}) async {
  // String myUid = MyFirebase.authObject.currentUser.uid;

  http.Response res = await sendMsgRes;
  print('The sendMsg response body is ${res != null ? '${res.body}'
      '\nof type ${res.body.runtimeType}'
      '\nand res.statusCode is ${res.statusCode}' : 'null'}');
  var decodedResBody;

  try {
    decodedResBody = jsonDecode(res.body);
    print('jsonDecoded res.body is $decodedResBody of type ${jsonDecode(res.body).runtimeType}');
  } catch (e) {
    print('The sendMsg response body is not jsonDecodable: $e');
  }

  if (decodedResBody is Map) {
    // print('decodedResBody is a Map');
    Map<String, dynamic> resMap = decodedResBody;
    print('resMap is $resMap\nof type ${resMap.runtimeType}');
    print('resMap keys are ${resMap.keys}\nof type ${resMap.keys.runtimeType}');
    if (resMap.containsKey(kFcmResponseError)) {
      String code = resMap[kFcmResponseError]['code'];
      print('code is $code');
      if (code == kFcmResponseTokenNotRegistered) {
        print('Token $token\n is not registered. Removing!');
        await MyFirebase.storeObject.collection(kCollectionUserInfo).doc(uid).update({
          '$kFieldTokens': FieldValue.arrayRemove([token]),
        });
      }
    }
  } else {
    print('The sendMsg response body is not a Map. No action.');
    print('res.body is ${res != null ? '${res.body}\nof type ${res.body.runtimeType}' : 'null'}');
  }
}
