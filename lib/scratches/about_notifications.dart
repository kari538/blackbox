/// What is the deal with notifications?
///
/// I gotta work this out, once and for all...
///
/// So you can send to tokens and you can send to topics.
/// If you send to a token AND a topic, the token person will get it twice... Unless this can
/// be resolved using collapse key... and it probably can't, because you can't know which
/// notification reaches first...
///
/// If I don't actively set the collapse key, the key "com.karolinadart.blackbox" will be
/// set automatically.
///
/// If the app is active, it can get local notifications. In these, the message can be changed
/// according to user ID etc. These can also be cancelled by "id".
/// Remote notifications are not automatically displayed if app is active.
///
/// If the app is not active, only remote notifications can be displayed. These do not know
/// your Uid etc... but if I link a user ID to a certain token, I can still
/// send a specialized message to that person. But I still can't remove them from the topic.
///
/// Local notifications replace each other. Remote msg notifications just pile up.
///
/// Only sending to a bunch of tokens and not to topics probably takes a lot of time...
/// Especially since that has to be done with a loop in the phone, no...? Or could I make
/// a Cloud Function that loops through all the tokens...? Of course I can... but what does
/// that imply? What would I send to the Cloud Function? Can a Cloud Function call another
/// Cloud Function in a loop? Because that could erase the time problem... Although a loop
/// in the phone calling an async Cloud Function isn't very time consuming either... But I think
/// downloading all the tokens from the database is... but maybe that bit can be put in the
/// async function? I already have a userIdMap..... Maybe I can download all the tokens
/// when I enter the game hub?
///
/// As it is right now, I clearly send very specialized local notifications, and you don't get
/// one if it was you triggering it (like you started playing). If the app is running in background,
/// I get two notifications... one local, one remote. It navigates to the specific game when I
/// tap it.
///
/// Sometimes, the content in localNotification will override the notification specified in
/// onMessage. See initializeFcm()
///
/// Message events:
/// const String kMsgEventStoppedPlaying = 'stopped_playing';
/// const String kMsgEventStartedPlaying = 'started_playing';
/// const String kMsgEventResumedPlaying = 'resumed_playing';
/// const String kMsgEventNewGameHubSetup = 'new_game_hub_setup';
/// const String kMsgEventAddedToken = 'added_token';
///
/// Message topics:
/// const String kTopicGameHubSetup = 'kTopicGameHubSetup';
/// const String kTopicPlayingSetup = 'kTopicPlayingSetup';
/// const String kTopicResumedPlayingSetup = 'kTopicResumedPlayingSetup';
/// const String kTopicPlayingYourSetup = 'kTopicPlayingYourSetup';
/// const String kTopicAllAppUpdates = 'AllAppUpdates';
/// const String kTopicMajorAppUpdates = 'MajorAppUpdates';
/// const String kTopicDeveloper = 'Developer'; //(me)

/// Info sent when stopped playing (from PlayScreen):
///
///         String jsonString = jsonEncode({
///           "data": {
///             "event": "$kMsgEventStoppedPlaying",
///             kMsgPlaying: "$myUid",
///             "$kMsgSetupSender": "${setup[kFieldSender]}",
///             "i": "${setupData['i']}",
///             kMsgSetupID: "$setupID",
///             // "collapse_key": myUid + "_playing_" + setupData['i'].toString(),
///           },
///           // "token": "${await myGlobalToken}",
///           // "topic": topic,
///           "topic": kTopicDeveloper, // For testing
///         });
///
/// Info sent when started OR resumed playing (from PlayScreen):
///
///     String jsonString = jsonEncode({
///       "data": {
///         "event": "${topic == kTopicPlayingSetup ? 'started_playing' : topic == kTopicResumedPlayingSetup ? 'resumed_playing' : ''}",
///         "playing": "$myUid",
///         "last_move": "${topic == kTopicResumedPlayingSetup ? '${setupData[kFieldPlaying][myUid][kSubFieldLastMove]}' : null}",
///         "earlier_results": "$resultKeys",
///         // "earlier_results": setupData[kFieldResults], // I was thinking I could send the score... to send notifications for very high or low score setups, but...
///         kMsgSetupSender: "${setupData[kFieldSender]}",
///         kMsgI: setupData['i'].toString(),
///         kMsgSetupID: "$setupID"
///         // "collapse_key": myUid + "_playing_" + setupData['i'].toString(),
///       },
///       // "token": "${await myGlobalToken}",
///       "topic": topic,
///     });
///
/// None of the above send a notification! Only data. Notification is created in Cloud Function.
/// And sometimes overridden in receiving phone.
///
/// If somebody subscribes to all Game Hub Updates:
///   If phone active:
///     A remoteMsg will come in to topic kTopicPlayingSetup, with event "started_playing" or "resumed_playing"
///     Another will come to my token, and I should show which ever one reaches first and not the other
///     If my setup:
///       Cloud created notification will be overridden and a local "Playing your message" will be displayed.
///     else:
///       Cloud created notification shown.
///
///   If phone not active:
///     A remoteMsg will come in to topic kTopicPlayingSetup, with event "started_playing" or "resumed_playing"
///     Another will come to my token, and could possibly collapse the above
///     If the player removes their playing tag, a collapse key could make the above disappear
///
/// If somebody subscribes to only playing MY games:
///   If phone active:
///     A remote Msg will come to my token, saying "Playing your setup".
///
///   If phone not active:
///     A remote Msg will come to my token, saying "Playing your setup".
