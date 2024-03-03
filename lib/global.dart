import 'package:flutter/material.dart';

// From a StackOverflow qn:
class GlobalVariable {
  static final GlobalKey<NavigatorState> navState = GlobalKey<NavigatorState>();
}

// If true, local notifications show up even if player is me.
// If someone else is playing my setup, it shows the actual content of
// the remoteMsg rather than notification specified here in the app.
// Similar for background messages...
// TODO: ---change testingNotifications to false:
// bool testingNotifications = true;
bool testingNotifications = false;
