import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:blackbox/my_firebase_labels.dart';
import 'package:blackbox/my_firebase.dart';
import 'package:flutter/material.dart';

void tempFirebaseOperations() async {
  print('Running temp_firebase operations main()');
  WidgetsFlutterBinding.ensureInitialized();
  MyFirebase.myFutureFirebaseApp = Firebase.initializeApp();
  print('Before awaiting myFutureFirebaseApp');
  await MyFirebase.myFutureFirebaseApp;
  print('After awaiting myFutureFirebaseApp');

  int i = 0;
  int j =0;

  ///Add i ---------------------------------------------
  // QuerySnapshot query = await MyFirebase.storeObject.collection('setups').orderBy('timestamp', descending: false).get();
  // List<DocumentSnapshot> docs = query.docs;
  // // print('After awaiting query');
  // for(DocumentSnapshot doc in docs){
  //   j++;
  //   print('adding i $j');
  //   Map<String, dynamic> docData = doc.data();
  //   // print(docData);
  //   if(true) {
  //     MyFirebase.storeObject.collection(kCollectionSetups).doc(doc.id).update({
  //       'i': j
  //     });
  //   }
  // }
///Temporary code for adding 'timestamp' field where missing, (from game hub StreamBuilder):
//                    print('timestamp is ${setup.data()['timestamp'].toDate()}');
//                    print(i);
//                    //January 1, 2001 at 12:00:00 AM UTC+3
//                    if (setup.data()['timestamp'] == null) {
//                      print(i);
//                      print(DateTime(2001));
//
//                      //Adds a new field to the document, but overwrites any old field with the same name (key), i.e. 'results':
//                      firestoreObject.collection('setups').doc(setup.id).set({
//                        'timestamp': DateTime(2001),
//
//                      }, merge: true);
//                    }
//                  if(setup.data()['sender'] == 'marshallmusyimi@gmail.com') {
//                    print('Sender: ${setup.data()['sender']}, timestamp: ${setup.data()['timestamp'].toDate()}');
//                  }
//                  print('Sender: ${setup.data()['sender']}, timestamp: ${setup.data()['timestamp'].toDate()}');
//                    if(setup.data()['timestamp'])

  ///Add Started Playing ---------------------------------------------
//   QuerySnapshot query = await MyFirebase.storeObject.collection('setups').orderBy('timestamp', descending: false).get();
//   List<DocumentSnapshot> docs = query.docs;

  //
  // for(DocumentSnapshot doc in docs){
  //   j++;
  //   Map<String, dynamic> docData = doc.data();
  //   // print(docData);
  //   if(docData.containsKey(kFieldPlaying) && docData[kFieldPlaying].isNotEmpty) {
  //     i++;
  //     for(String playing in docData[kFieldPlaying].keys){
  //       MyFirebase.storeObject.collection(kSetupCollection).doc(doc.id).update({
  //         '$kFieldPlaying.$playing.$kSubFieldStartedPlaying': FieldValue.serverTimestamp()
  //       });
  //     }
  //   }
  // }

//   ///Change uid in sender and results---------------------------------------------
//   QuerySnapshot query = await MyFirebase.storeObject.collection(kCollectionSetups).get();
//   List<DocumentSnapshot> docs = query.docs;
//
//   int i = 0;
//   int j =0;
//   int k =0;
//
//
//   for(DocumentSnapshot doc in docs){
//     j++;
//     Map<String, dynamic> docData = doc.data();
//     // print(docData);
//     // bool match = false;
//     //Change Results:
//     ///Change old ID here:
//       if(docData.containsKey(kFieldResults) && docData[kFieldResults].containsKey('Geu7ZdaWkPeyuW0tGUCK')) {
//         print('match in ${doc.id}');
//         // match = true;
//         i++;
//         // if(i==1){
// // 0741373466
//         print('docData before: $docData');
//
//         ///new and old here:
//         MyFirebase.storeObject.collection(kSetupCollection).doc(doc.id).update({
//           '$kSetupResults.T0Kx2fhO2BRot5BGF6GJbP3weSi2': docData[kFieldResults]['Geu7ZdaWkPeyuW0tGUCK']
//           //Will create the player ID key in 'result' if it's not there.
//         });
//
//         ///Old here (very important!):
//         MyFirebase.storeObject.collection(kCollectionSetups).doc(doc.id).update({
//           '$kSetupResults.Geu7ZdaWkPeyuW0tGUCK': FieldValue.delete()
//         });
//
//         // DocumentSnapshot newDoc = await MyFirebase.storeObject.collection(kCollectionSetups).doc(doc.id).get();
//         // docData = newDoc.data();
//         // print('docData after: $docData');
//
//       }
//           // Change sender:
//         ///Change old here:
//       if(docData[kFieldSender]== 'Geu7ZdaWkPeyuW0tGUCK') {
//         print('match in ${doc.id}');
//         // match = true;
//         k++;
//           print('docData before: $docData');
//         ///And new here:
//           MyFirebase.storeObject.collection(kCollectionSetups).doc(doc.id).update({
//             kFieldSender: 'T0Kx2fhO2BRot5BGF6GJbP3weSi2'
//           });
//           // DocumentSnapshot newDoc = await MyFirebase.storeObject.collection(kCollectionSetups).doc(doc.id).get();
//           // docData = newDoc.data();
//           // print('docData after: $docData');
//         }
//
//   }
//   print('Found $i matching results and $k matching senders, out of $j docs');
//   // print('List of uid is ${uidList.length} long');
//
// /// Change doc.id to uid ---------------------------------------------
// //   QuerySnapshot query = await MyFirebase.storeObject.collection(kCollectionUserInfo).get();
// //   List<DocumentSnapshot> docs = query.docs;
// //
// //   List<String> userEmails = [];
// //   List<String> docIds = [];
// //   for(DocumentSnapshot doc in docs) {
// //     Map<String, dynamic> docData = doc.data();
// //     userEmails.add(docData[kFieldEmail]);
// //     docIds.add(doc.id);
// //   }
// //
// //   print(userEmails);
// //
// //   http.Response res;
// //   http.Response resOneUser;
// //
// //   try {
// //     res = await http.post('https://us-central1-blackbox-6b836.cloudfunctions.net/userIds',
// //       headers: {"content-type": "application/json"},
// //       body: jsonEncode({
// //         "emails": userEmails
// //       })
// //     );
// //   } catch (e) {
// //     print(e);
// //   }
// //
// //   print(res.body);
// //   List<dynamic> uidList = jsonDecode(res.body);
// //   print(uidList);
// //   print(docIds);
// //
// //   int i = 0;
// //   int j =0;
// //   for(DocumentSnapshot doc in docs){
// //     j++;
// //     Map<String, dynamic> docData = doc.data();
// //     bool match = false;
// //     for (var uid in uidList) {
// //       if(doc.id == uid) {
// //         // print('match $uid');
// //         match = true;
// //       }
// //     }
// //     if(!match) {
// //       i++;
// //       match =false;
// //       try {
// //         resOneUser = await http.post('https://us-central1-blackbox-6b836.cloudfunctions.net/userIds',
// //             headers: {"content-type": "application/json"},
// //             body: jsonEncode({
// //               "emails": [docData[kFieldEmail]]
// //             })
// //         );
// //       } catch (e) {
// //         print(e);
// //       }
// //       List<dynamic> newId = jsonDecode(resOneUser.body);
// //       print('New ID is ${newId[0]}');
// //       if(i==1) {
// //         print('Making new doc with ID ${newId[0]} for old ID ${doc.id}');
// //         // MyFirebase.storeObject.collection(kCollectionUserInfo).doc(newId[0]).set(docData);
// //       }
// //     }
// //     // i=0;
// //   }
  print('Found $i matching docs, out of $j');
// //   print('List of uid is ${uidList.length} long');
}