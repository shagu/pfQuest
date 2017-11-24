**!! DO NOT DOWNLOAD THE MASTER ARCHIVE !! CHOOSE A DOWNLOAD ON THE [RELEASE PAGE](https://github.com/shagu/pfQuest/releases/latest) INSTEAD !!**

# pfQuest
This is an addon for World of Warcraft Classic (1.12). It helps players to find several ingame objects and quests. The addon reads questobjectives, parses them and uses its internal database to plot the found matches on the world- and minimap. It ships with a GUI to browse through all known objects. If one of the items is not yet available on your realm, you'll see a [?] in front of the name.

The addon is not designed to be a quest- or tourguide and won't ever going to be like that. Instead the goals are more like an ingame version of [AoWoW](http://db.vanillagaming.org/) or [Wowhead](http://www.wowhead.com/). By default it uses the opensource database provided by [Light's Hope](https://github.com/LightsHope/server/releases).

pfQuest is the successor of [ShaguQuest](http://shagu.org/archive/) and has been entirely written from scratch. In comparison to [ShaguQuest](http://shagu.org/archive/), this addon does not depend on any specific map- or questlog addon. It's designed to support the default interface aswell as every other addon. In case you experience any addon conflicts, please add an issue to the bugtracker.

# Downloads
The release page provides downloads for several gameclients. Every build includes a specifically crafted database to match the gameclient. Using the `master`-zip instead, would include **all** languages, which cost more than 100MB of language-data and will dramatically increase your loading screen times. Please select only **one** language.

**[[Go to Release Page]](https://github.com/shagu/pfQuest/releases/latest)**

### Suggested Addons
- [pfUI](http://github.com/shagu/pfUI): A complete and customizable UI replacement in a single addon
- [EQL3](https://github.com/laytya/EQL3): A reskinned Extended Quest Log addon inspired by TukUI

# Auto-Tracking
<img src="http://shagu.org/pfQuest/img/map-autotrack.png" float="right" align="right" width="30%">
The addon features 4 different modes that define how the new or updated questobjectives should be handled. Those modes can be selected on the dropdown menu in the top-right area the map.

### Option: All Quests
Every quest will be automatically shown and updated on the map.

### Option: Tracked Quests

Only tracked quests (Shift-Click) will be automatically shown and updated on the map.

### Option: Manual Selection

Only quests that have been manually displayed ("Show"-Button in the Questlog) will resident on the map.

### Option: Hide Quests

Nothing will be shown on the map, except for nodes that have been manually added via the DB-Browser.


# Database Browser

<img src="http://shagu.org/pfQuest/img/browser-spawn.png" align="left" width="271">
<img src="http://shagu.org/pfQuest/img/browser-quests.png" align="left" width="271">
<img src="http://shagu.org/pfQuest/img/browser-items.png" align="center" width="300">

The database GUI allows you to bookmark and browse through all entries within the pfQuest database. It can be opened by a click on the pfQuest minimap icon or via `/db show`. The browser will show a maximum of 100 entries at once for each tab. Use your scrollwheel or press the up/down arrows to go up and down the list.


# Questlog Integration
<img src="http://shagu.org/pfQuest/img/questlog-integration.png" align="left" width="300">

shift-click on a selected quest will add a questlink into chat. Those links are similar to the known questlinks from TBC+ and are compatible to ones produced by [ShaguQuest](http://shagu.org/archive/), [Questie](https://github.com/AeroScripts/QuestieDev) and [QuestLink](http://addons.us.to/addon/questlink-0). Additionally a manual quest tracking is available by 3 buttons that show up on every quest in your questlog.

### Show
The "Show" button will add the questobjectives of the current quest to the map.

### Clean
The "Clean" button will remove all nodes that have been placed by pfQuest from the map.

### Reset
The "Reset" button will restore the default visibility of icons to match the set values on the map dropdown menu (e.g "All Quests" by default).


# Chat/Macro CLI
<img src="http://shagu.org/pfQuest/img/chat-cli.png">

The addon features a CLI interface which allows you to easilly create macros to show your favourite herb or mining-veins. Let's say you want to display all **Iron Deposit** deposits, then type in chat or create a macro with the text: `/db spawn Iron Deposit`. If `/db` doesn't work for you, there are also some other aliases available like `/shagu`, `pfquest` and `/pfdb`.


# Map & Minimap Nodes
<img src="http://shagu.org/pfQuest/img/map-quests.png" align="left">
<img src="http://shagu.org/pfQuest/img/map-spawnpoints.png" width="327">

<img src="http://shagu.org/pfQuest/img/map-lootchance.png" align="left" width="372">
<img src="http://shagu.org/pfQuest/img/minimap-nodes.png" width="412">
