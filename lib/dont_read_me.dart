///First, atom positions are determined, either by player or randomly. Atom positions are saved as a property in the Play class object. Or as a static property of the Play object... Or as an object of its own?...
///
///Then the board is built, and it doesn't show anything on it. But it has the potential for showing yellow or white atoms... It also has the potential for showing right and wrong... All this is kept in PlayBoardTile objects of the PlayBoardTile class (for the "Middle Elements". This object is a stateful widget, and basically a button, which shows different children. What child is to be shown is decided from different places at different times in the game...
///
/// Then the player plays by clicking edge elements, which are also buttons and stateful widgets, of the EdgeTile class. When an EdgeTile is clicked, that EdgeTile plus another one changes child
///
/// It is possible to make a showAtom nested list of bools... and let the PlayBoardTile call it every time...
///
///
///
///
///
///