import 'package:blackbox/token.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'local_notifications.dart';
import 'my_firebase_labels.dart';
import 'package:blackbox/firestore_lables.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'my_firebase.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

Future<String> token;

void initializeFcm() async {
  print('Initializing Firebase Cloud Messaging...');
  await MyFirebase.myFutureFirebaseApp;
  if (MyFirebase.authObject.currentUser != null) {
    String myUid = MyFirebase.authObject.currentUser.uid;
    FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
    _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    _firebaseMessaging.requestPermission(
      sound: true,
      //The rest as default
    );
    _firebaseMessaging.setAutoInitEnabled(true);
    //TODO: Make condition here! (Move this to registration of new user)! Lest they'll resubscribe every time they open the app...:
    _firebaseMessaging.subscribeToTopic(kTopicNewSetup);
    _firebaseMessaging.subscribeToTopic(kTopicPlayingSetup);
    _firebaseMessaging.subscribeToTopic(kTopicResumedPlayingSetup);

    FirebaseMessaging.onMessage.listen((remoteMsg) {
      print('onMessage');
      print(remoteMsg.notification.title);
      print(remoteMsg.notification.body);
      print(remoteMsg.data);
      print(remoteMsg.data.isNotEmpty);
      print(remoteMsg.data.containsKey(kMsgPlaying));
      print(remoteMsg.data[kMsgPlaying] == myUid);
      print(remoteMsg.data.keys);
      if(remoteMsg.data.isNotEmpty &&  remoteMsg.data.containsKey(kMsgPlaying) && remoteMsg.data[kMsgPlaying] == myUid) {
        print('No notification because player is me.');
      } else if (remoteMsg.data.isNotEmpty && remoteMsg.data.containsKey(kMsgSetupSender) && remoteMsg.data[kMsgSetupSender] == myUid){
        LocalNotifications.showNotification("Someone is playing your setup!", "Someone is playing your setup now in the game hub");
      } else {
        LocalNotifications.showNotification('${remoteMsg.notification.title}', "${remoteMsg.notification.body}");
      }
    },
      onError: (error){
        print('Error in onMessage: $error');
      }
    );

    // FirebaseMessaging.onBackgroundMessage((message) => null);  //Can't here coz inside a class! Must be top-level.

    // RemoteMessage(
    //   data:
    // )

    // Get the token each time the application loads:
    token =  _firebaseMessaging.getToken();
    myGlobalToken = token;
    print('My device token is ${await token}');

    // Save the initial token to the database:
    await saveTokenToDatabase(await token);

    // Any time the token refreshes, store this in the database too:
    FirebaseMessaging.instance.onTokenRefresh.listen(saveTokenToDatabase);
  }
}

Future<void> saveTokenToDatabase(String token) async {
  myGlobalToken = Future(() => token);
// TODO: Change user document IDs to Uids...
//  String userId;
  String userEmail;
  try {
//    userId = MyFirebase.authObject.currentUser.uid;
    if(MyFirebase.authObject.currentUser != null) userEmail = MyFirebase.authObject.currentUser.email;
//    print("My user ID in saveTokenToDatabase() is $userId");
    print("My user email in saveTokenToDatabase() is $userEmail");
  } on Exception catch (e) {
    print(e);
  }

//  if (userId != null) {
  if (userEmail != null) {
    String myDocumentId = await getUserId(userEmail);
    try {
      await MyFirebase.storeObject
//          .collection('users')
//          .doc(userId)
          .collection(kUserinfoCollection)
          .doc(myDocumentId)
          .update({
        'tokens': FieldValue.arrayUnion([token]),
      });
    } on Exception catch (e) {
      print(e);
    }
  }
}


Future<String> getUserId(String myEmail) async {
  print("Getting user ID");
  QuerySnapshot userinfoSnapshot = await MyFirebase.storeObject.collection('userinfo').where(kUserinfoEmail, isEqualTo: myEmail).get();
  List<DocumentSnapshot> myDoc = userinfoSnapshot.docs;
  String myDocId = myDoc[0].id;
  return myDocId;
}

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage remoteMsg) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  // FirebaseApp app = await Firebase.initializeApp();
  await Firebase.initializeApp();
  // FirebaseAuth authObject = FirebaseAuth.instanceFor(app: app);
  FirebaseAuth authObject = FirebaseAuth.instance;
  String myUid = authObject.currentUser.uid;
  print("Handling a background message: ${remoteMsg.notification.title} ${remoteMsg.notification.body} ${remoteMsg.data}");

  if(remoteMsg.data.isNotEmpty &&  remoteMsg.data.containsKey(kMsgPlaying) && remoteMsg.data[kMsgPlaying] == myUid) {
    print('No notification because player is me.');
  } else if (remoteMsg.data.isNotEmpty && remoteMsg.data.containsKey(kMsgSetupSender) && remoteMsg.data[kMsgSetupSender] == myUid){
    LocalNotifications.showNotification("Someone is playing your setup!", "Someone is playing your setup now in the game hub");
  } else {
    // LocalNotifications.showNotification('${remoteMsg.notification.title}', "${remoteMsg.notification.body}");
    print('A background msg has come in. No local notification.');
  }
}

