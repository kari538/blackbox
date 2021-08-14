import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:blackbox/game_hub_menu.dart';
import 'package:blackbox/my_types_and_functions.dart';
import 'package:blackbox/constants.dart';
import 'package:blackbox/scratches/temp_firebase_operations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:blackbox/my_firebase_labels.dart';
import 'package:blackbox/my_firebase.dart';
import 'dart:async';
import 'package:blackbox/game_hub_updates.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

const double _outerPadding = 20;

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  void initState() {
    super.initState();
    profileChangeStream();
  }

  @override
  void dispose() {
    super.dispose();
    if (profileListener != null) profileListener.cancel();
  }

  bool showSpinner = false;
  StreamSubscription profileListener;
  Map<String, dynamic> profileData;

  // String myUid = Myself.userData[kFieldUid];
  String myUid = MyFirebase.authObject.currentUser.uid;
  List<String> profileTextFields = [kFieldScreenName, kPassword];

  Map<String, bool> editing = {};
  Map<String, TextEditingController> controller = {};

  void profileChangeStream() {
    profileListener = MyFirebase.storeObject.collection(kCollectionUserInfo).doc(myUid).snapshots().listen((event) {
      profileData = event.data();
      print('profileData is $profileData');
      for (String field in profileTextFields) {
        controller.addAll({
          field: TextEditingController(text: profileData[field].toString()),
        });
      }
      print('controller is $controller');

      showSpinner = false;
      Provider.of<GameHubUpdates>(context, listen: false).updateMyScreenName(profileData[kFieldScreenName]); //Is this already done somewhere...?

      setState(() {
        //Build again with new values
      });
    });
  }

  Widget profileTextField(String key) {
    print('Building profileTextField');
    String newValue;
    return (editing[key] ?? false)
        ? Column(
            children: [
              TextField(
                onChanged: (value) {
                  newValue = value;
                },
                decoration: InputDecoration(),
                controller: controller[key],
                autofocus: true,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  RaisedButton(
                      child: Text('Cancel'),
                      onPressed: () {
                        setState(() {
                          newValue = null;
                          editing[key] = false;
                          controller[key].text = profileData[key].toString(); //Needed for zoom
                        });
                      }),
                  RaisedButton(
                      child: Text('Save Changes'),
                      onPressed: () {
                        print('newValue is $newValue');
                        if (newValue != null) {
                          showSpinner = true;
                          // print('Key is $key');
                          // print('key == kFieldPhotoUrl is ${key == kFieldPhotoUrl}');
                          if (newValue != null) {
                            MyFirebase.storeObject.collection(kCollectionUserInfo).doc(myUid).update({key: newValue});
                          }
                          newValue = null;
                        }
                        setState(() {
                          editing[key] = false;
                          // zoomChanged = false;
                        });
                      }),
                ],
              ),
            ],
          )
        : Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
                child: Text(
              '${profileData != null ? profileData[key] : ''}',
              style: TextStyle(color: Colors.blueGrey.shade100),
            )),
            GestureDetector(
              child: Icon(Icons.edit),
              onTap: () async {
                setState(() {
                  editing[key] = true;
                });
              },
            ),
          ],
        );
  }

  Widget authUserField(String key) {
    print('Building authUserField');
    return (editing[key] ?? false)
        ? Column(
            children: [
              Center(
                child: SelectableLinkify(text: 'Click "Change ${capitalizeFirst(key)}" and an email will be sent to your registered email address with '
                    'instructions on how to change your ${key.toLowerCase()}.\n\n'
                    'If you don\'t have access to your blackbox email address or if you have forgotten it, '
                    'contact support at karolinahagegard@gmail.com and we shall sort you out! 😉\n'
                ,
                  onOpen: (link) async {
                    if (await canLaunch(link.url)) {
                      await launch(link.url);
                    } else {
                      throw 'Could not launch $link';
                    }
                  },
                ),
                // child: Text('Click "Change ${capitalizeFirst(key)}" and an email will be sent to your registered email address with '
                //     'instructions on how to change your ${key.toLowerCase()}.\n\n'
                //     'If you don\'t have access to your blackbox email address or if you have forgotten it, '
                //     'contact support at karolinahagegard@gmail.com and we shall sort you out! 😉\n'
                // ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  RaisedButton(
                      child: Text('Cancel'),
                      onPressed: () {
                        setState(() {
                          editing[key] = false;
                          controller[key].text = profileData[key].toString(); //Needed for zoom
                        });
                      }),
                  RaisedButton(
                      child: Text('Change ${capitalizeFirst(key)}'),
                      onPressed: () async {
                        print('Before change password');
                        // await MyFirebase.authObject.currentUser.updatePassword('111111');  //Ok, this works...
                        await MyFirebase.authObject.sendPasswordResetEmail(email: MyFirebase.authObject.currentUser.email);
                        print('After change password');
                        setState(() {
                          editing[key] = false;
                          // zoomChanged = false;
                        });
                      }),
                ],
              ),
            ],
          )
        : Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
                child: Text(
              '',
              style: TextStyle(color: Colors.blueGrey.shade100),
            )),
            GestureDetector(
              child: Icon(Icons.edit),
              onTap: () async {
                setState(() {
                  editing[key] = true;
                });
              },
            ),
          ],
        );
  }

  Widget divider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Divider(thickness: 2, height: 2, color: Colors.blueGrey),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('my profile'),
        actions: [GameHubMenu(context)],
      ),
      body: Padding(
        padding: const EdgeInsets.all(_outerPadding),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Text(
                      'Welcome ${Provider.of<GameHubUpdates>(context).myScreenName}',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontFamily: 'Pacifico', fontSize: 30),
                    )),
              ),
              HeadlineText('My screen name:'),
              profileTextField(kFieldScreenName),
              divider(),
              HeadlineText('Password:'),
              authUserField(kPassword),
              divider(),
              // HeadlineText('Tag Line:'),
              // profileTextField(''),
              // divider(),
            ],
          ),
        ),
      ),
    );
  }
}

class HeadlineText extends StatelessWidget {
  HeadlineText(this.text);

  final String text;

  final TextStyle style = TextStyle(color: kHubSetupColor);
  // final TextStyle style = TextStyle(color: kSmallResultsColor);

  // final TextStyle style = const TextStyle(color: Colors.tealAccent);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: style);
  }
}
