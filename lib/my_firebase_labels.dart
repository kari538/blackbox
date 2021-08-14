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

// Playing:
const String kFieldPlaying = 'playing';
const String kSubFieldPlayingAtoms = 'playingAtoms';
const String kSubFieldPlayingBeams = 'playingBeams';
const String kSubFieldClearList = 'ClearList';
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
const String kMsgShowLocalNotification = 'show_local_notification';
const String kMsgOverride = 'override';
const String kMsgOverrideYes = 'yes';
const String kMsgOverrideNo = 'no';
// const String kMsg = '';
// const String kMsg = '';
// const String kMsg = '';
// const String kMsg = '';
// const String kMsg = '';

// Cloud topics:
const String kTopicGameHubSetup = 'kTopicGameHubSetup';
// const String kTopicNewSetup = 'newSetup';
const String kTopicPlayingSetup = 'kTopicPlayingSetup';
const String kTopicResumedPlayingSetup = 'kTopicResumedPlayingSetup';
const String kTopicPlayingYourSetup = 'kTopicPlayingYourSetup';
const String kTopicDeveloper = 'Developer';
const String kTopicAllAppUpdates = 'AllAppUpdates';
const String kTopicMajorAppUpdates = 'MajorAppUpdates';
// const String kTopic = '';


//API
// For real case:
// // Whole cloud function address: 'https://us-central1-blackbox-6b836.cloudfunctions.net/sendMsg'
const String kApiCloudFunctionsLink = 'us-central1-blackbox-6b836.cloudfunctions.net';
const String kApiSendMsg = 'sendMsg';

// For functions emulator, to use with phone emulator:
// TODO: Change from localhost!!.... if on.
// Change this to false:
// const bool emulator = true;
const bool emulator = false;
// const String kApiEmulatorLink = 'http://localhost:5001/blackbox-6b836/us-central1/'; // Didn't work before Uri update
// const String kApiEmulatorLink = 'http://10.0.2.2:5001/blackbox-6b836/us-central1/';  // Worked before Uri update
const String kApiEmulatorLink = '10.0.2.2:5001'; // Works after Uri update
// const String kApiEmulatorLink = 'localhost:5001'; // Doesn't work after Uri update
const String kApiEmulatorSendMsg = 'blackbox-6b836/us-central1/sendMsg';  // Works after Uri update. For emulator

const String kApiContentType = 'content-type';
const String kApiApplicationJson = 'application/json';
// const String kApi = '';
// const String kApi = '';
// const String kApi = '';


// Responses:
const String kFcmResponseSuccess = "Success";
const String kFcmResponseError = 'Error';
// const String kFcmResponseTokenNotRegistered = ''
//     'messaging/registration-token-not-registered'; // Old version...?
const String kFcmResponseTokenNotRegistered = 'messaging/invalid-argument';
// const String kFcmResponse = '';
// const String kFcmResponse = '';
// const String kFcmResponse = '';

