import 'global.dart';
import 'package:blackbox/fcm.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:cloud_firestore/cloud_firestore.dart';

class MyFirebase {
//  MyFirebaseClass(this.initialization);
//  static final Future<FirebaseApp> initialization = Firebase.initializeApp();
  static Future<FirebaseApp> myFutureFirebaseApp;  //Initialized from main()
  static FirebaseFirestore storeObject = FirebaseFirestore.instance;
  static auth.FirebaseAuth authObject = auth.FirebaseAuth.instance;

  static void logOut(){
    authObject.signOut();
  }
}

void userChangesListener() async {
  print('Starting userChangesListener()');
  await MyFirebase.myFutureFirebaseApp;
  MyFirebase.authObject.idTokenChanges().listen((event) {
    print('Event in userChangesListener() is $event');
    if (event != null) initializeFcm('', GlobalVariable.navState);
  });
}
