import 'package:blackbox/global.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';import 'package:blackbox/units/small_widgets.dart';
import 'package:blackbox/online_button.dart';
import 'package:blackbox/units/blackbox_popup.dart';
import 'package:pretty_json/pretty_json.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:blackbox/game_hub_menu.dart';
import 'package:blackbox/my_types_and_functions.dart';
import 'package:blackbox/constants.dart';
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
    if (profileListener != null) profileListener!.cancel();
  }

  bool showSpinner = false;
  StreamSubscription? profileListener;
  Map<String, dynamic>? myProfileData;

  // String myUid = Myself.userData[kFieldUid];
  String myUid = MyFirebase.authObject.currentUser!.uid;
  List<String> profileTextFields = [kFieldScreenName, kPassword];

  Map<String, bool> editing = {};
  Map<String, TextEditingController> controller = {};

  void profileChangeStream() {
    profileListener = MyFirebase.storeObject.collection(kCollectionUserInfo).doc(myUid).snapshots().listen((event) {
      myProfileData = event.data();
      print('myProfileData is');
      printPrettyJson(myProfileData);

      if (myProfileData != null) {
        for (String field in profileTextFields) {
          controller.addAll({
            field: TextEditingController(text: myProfileData![field].toString()),
          });
        }
        print('controller map keys are ${controller.keys}');

        showSpinner = false;

        setState(() {
          //Build again with new values
        });
      }
    });
  }

  Widget profileTextField(String key) {
    print('Building profileTextField');
    String? newValue;
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
                          controller[key]!.text = myProfileData![key].toString(); //Needed for zoom
                        });
                }),
            RaisedButton(
                child: Text('Save Changes'),
                onPressed: () async {
                        print('newValue is $newValue');
                        if (newValue != null) {
                          showSpinner = true;
                          // print('Key is $key');
                          MyFirebase.storeObject.collection(kCollectionUserInfo).doc(myUid).update({key: newValue});
                          if (key == kFieldScreenName) {
                            MyFirebase.authObject.currentUser!.updateDisplayName(newValue);
                            if (newValue == '' || newValue == 'Anonymous') {
                              setState(() {
                                editing[key] = false;
                              });
                              await Future.delayed(Duration(milliseconds: 200)); // To give keyboard time to pop
                              BlackboxPopup(
                                      context: context,
                                      title: 'Information',
                                      desc: 'You will be'
                                          ' "Anonymous" to others, "Me" to yourself')
                                  .show();
                            }
                          }
                          newValue = null;
                        }
                  setState(() {
                    editing[key] = false;
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
              '${myProfileData != null ? myProfileData![key] : ''}',
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
                child: SelectableLinkify(
                  text: 'Click "Change ${capitalizeFirst(key)}" and an email will be sent to your registered email address with '
                      'instructions on how to change your ${key.toLowerCase()}.\n\n'
                      'If you don\'t have access to your blackbox email address or if you have forgotten it, '
                      'contact support at karolinahagegard@gmail.com and we shall sort you out! 😉\n',
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
                          controller[key]!.text = myProfileData![key].toString(); //Needed for zoom
                        });
                }),
            RaisedButton(
                child: Text('Change ${capitalizeFirst(key)}'),
                onPressed: () async {
                  print('Before change password');
                  // await MyFirebase.authObject.currentUser.updatePassword('111111');  //Ok, this works...
                  await MyFirebase.authObject.sendPasswordResetEmail(email: MyFirebase.authObject.currentUser!.email!);
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

  void setProfileScreenState({required bool spinner}) {
    print('Running setProfileScreenState()');

    setState(() {
      showSpinner = spinner;
    });
  }

  @override
  Widget build(BuildContext context) {
    print('Building ${widget.runtimeType}...');
    GameHubUpdates gameHubProviderListening = Provider.of<GameHubUpdates>(context, listen: true);
    return Scaffold(
      appBar: AppBar(
        title: Text('my profile'),
        actions: [GameHubMenu(context)],
      ),
      body: ModalProgressHUD(
        inAsyncCall: showSpinner,
        child: Padding(
          padding: const EdgeInsets.only(left: _outerPadding, top: _outerPadding, right: _outerPadding),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Text(
                        'Welcome ${gameHubProviderListening.myScreenName}',
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
                SizedBox(height: 50),
                Align(
                  child: OnlineButton(
                    text: "Delete my account",
                    onPressed: () {
                      deleteAccount(context, setProfileScreenState);
                    },
                  ),
                  alignment: Alignment.center,
                ),
              ],
            ),
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

Future deleteAccount(BuildContext context, Function setProfileScreenState) async {
  BlackboxPopup(
    context: context,
    title: 'Are you sure you want to delete your blackbox account?',
    desc: 'This action can not be undone.'
        '\n\nYou will no longer be able to play online (unless with another account).'
        '\n\nYour setups and results in the game hub will still be there, but with'
        ' an anonymous screen name.'
        '\n\nYou can always make a new blackbox account later.',
    buttons: [
      CancelPopupButton(context),
      DeleteAccountButton(context, setProfileScreenState),
    ],
  ).show();
}

// class DeleteAccountButton extends StatelessWidget {
class DeleteAccountButton extends BlackboxPopupButton {
  // DeleteAccountButton(this.context, this.setProfileScreenState);
  DeleteAccountButton(this.context, this.setProfileScreenState) : super(text: "text", onPressed: (){});
  // DeleteAccountButton(this.context, this.setProfileScreenState);

  final BuildContext context;
  final Function setProfileScreenState;
  final text = 'Delete';
  final String myUid = MyFirebase.authObject.currentUser!.uid;

  Widget build(BuildContext buttonContext) {
    return BlackboxPopupButton(
      text: text,
      onPressed: () async {
        Navigator.pop(context);
        setProfileScreenState(spinner: true);
        // await Future.delayed(Duration(seconds: 1));
        await MyFirebase.storeObject.collection(kCollectionUserInfo).doc(myUid).delete();
        await MyFirebase.authObject.currentUser!.delete();
        // :.(

        Navigator.popUntil(context, (route) => route.isFirst);

        BlackboxPopup(
          context: GlobalVariable.navState.currentContext!,
          title: 'Complete',
          desc: 'Your blackbox account has been deleted',
        ).show();
      },
    );
  }
}