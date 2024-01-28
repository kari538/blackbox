// User info:
const String kCollectionUserInfo = 'userinfo';
const String kFieldScreenName = 'screenName';
const String kFieldEmail = 'email';
const String kFieldTokens = 'tokens';
const String kFieldNotifications = 'Notifications';
// const String kField = '';

// Setups:
const String kCollectionSetups = 'setups';
const String kFieldSender = 'sender';
const String kFieldAtoms = 'atoms';
const String kFieldWithAndHeight = 'WithAndHeight';
const String kFieldShuffleA = 'ShuffleA';
const String kFieldShuffleB = 'ShuffleB';
// const String kField = '';

// Pings:
const String kSubCollectionPlayingPings = 'PlayingPings';
const String kSubCollectionWatchingPings = 'WatchingPings';

// Results:
const String kFieldResults = 'results';
const String kFieldTimestamp = 'timestamp';
const String kSubFieldPlayerAtoms = 'playerAtoms';
const String kSubFieldSentBeams = 'sentBeams';
const String kSubFieldA = 'A';
const String kSubFieldB = 'B';
const String kSubFieldStartedPlaying = 'StartedPlaying';
const String kSubFieldFinishedPlaying = 'FinishedPlaying';
const String kSubFieldAlternativeSolutions = 'AlternativeSolutions';
// const String kSubField = '';
// const String kSubField = '';
// const String kSubField = '';
// const String kSubField = '';

// Playing:
const String kFieldPlaying = 'playing';
const String kSubFieldPlayingAtoms = 'playingAtoms';
const String kSubFieldPlayingBeams = 'playingBeams';
const String kSubFieldMarkUpList = 'MarkUpList';
const String kSubFieldFollowing = 'following';
const String kSubFieldLastMove = 'LatestMove';
const String kSubFieldPing = 'Ping';
const String kSubFieldPlayingDone = 'done';
// const String kSubField = '';


const String kPassword = 'password';

//Cloud messaging:
const String kMsgNotification = 'notification';
const String kMsgTitle = 'title';
const String kMsgBody = 'body';
const String kMsgData = 'data';
const String kMsgTopic = 'topic';
const String kMsgClickAction = 'click_action';
const String kMsgCollapseKey = 'collapse_key';
const String kMsgI = 'i';
const String kMsgSetupID = 'setup_ID';
const String kMsgSetupSender = 'setup_sender';
const String kMsgPlaying = 'playing';
const String kMsgEvent = 'event';
const String kMsgEventStoppedPlaying = 'stopped_playing';
const String kMsgEventStartedPlaying = 'started_playing';
const String kMsgEventResumedPlaying = 'resumed_playing';
const String kMsgEventNewGameHubSetup = 'new_game_hub_setup';
const String kMsgEventAddedToken = 'added_token';
const String kMsgShowLocalNotification = 'show_local_notification';
const String kMsgOverride = 'override';
const String kMsgOverrideYes = 'yes';
const String kMsgOverrideNo = 'no';
// const String kMsg = '';
// const String kMsg = '';
// const String kMsg = '';
// const String kMsg = '';
// const String kMsg = '';

/// If I want to change the below, I have to change them in the Cloud Function as well!
// Cloud topics:
const String kTopicGameHubSetup = 'kTopicGameHubSetup';
const String kTopicPlayingSetup = 'kTopicPlayingSetup';
const String kTopicResumedPlayingSetup = 'kTopicResumedPlayingSetup';
const String kTopicPlayingYourSetup = 'kTopicPlayingYourSetup';
const String kTopicAllAppUpdates = 'AllAppUpdates';
const String kTopicMajorAppUpdates = 'MajorAppUpdates';
const String kTopicDeveloper = 'Developer';
// const String kTopic = '';


//API
// TODO: ---Change "testing" to false in Cloud Function
// TODO: ---Change from localhost!!.... if on. That is, change emulating to false:
// const bool emulating = true;
const bool emulating = false;

// For functions emulator, to use with phone emulator (AVD):
// const String kApiEmulatorLink = 'http://localhost:5001/blackbox-6b836/us-central1/'; // Didn't work before Uri update
// const String kApiEmulatorLink = 'http://10.0.2.2:5001/blackbox-6b836/us-central1/';  // Worked before Uri update
const String kApiEmulatorLink = '10.0.2.2:5001'; // Works after Uri update
const String kApiEmulatorSendMsg = 'blackbox-6b836/us-central1/sendMsg';  // Works after Uri update. For emulator

// For real case:
// // Whole cloud function address: 'https://us-central1-blackbox-6b836.cloudfunctions.net/sendMsg'
const String kApiCloudFunctionsLink = 'us-central1-blackbox-6b836.cloudfunctions.net';
const String kApiSendMsg = 'sendMsg';

const String kApiContentType = 'content-type';
const String kApiApplicationJson = 'application/json';
// const String kApi = '';
// const String kApi = '';
// const String kApi = '';


// Responses:
const String kFcmResponseSuccess = "Success";
const String kFcmResponseError = 'Error';
const String kFcmResponseTokenNotRegistered = 'messaging/registration-token-not-registered';
// const String kFcmResponse = '';
// const String kFcmResponse = '';
// const String kFcmResponse = '';

