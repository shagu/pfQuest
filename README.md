# pfQuest
<img src="https://raw.githubusercontent.com/shagu/ShaguAddons/master/_img/pfQuest/tooltips.png" float="right" align="right" width="25%">
This is an addon for World of Warcraft Classic (1.12). It helps players to find several ingame objects and quests. The addon reads questobjectives, parses them and uses its internal database to plot the found matches on the world- and minimap. It ships with a GUI to browse through all known objects. If one of the items is not yet available on your realm, you'll see a [?] in front of the name.

The addon is not designed to be a quest- or tourguide and won't ever going to be like that. Instead the goals are more like an ingame version of [AoWoW](http://db.vanillagaming.org/) or [Wowhead](http://www.wowhead.com/). By default it uses the opensource database provided by [Light's Hope](https://github.com/LightsHope/server/releases).

pfQuest is the successor of [ShaguQuest](https://shagu.org/ShaguQuest/) and has been entirely written from scratch. In comparison to [ShaguQuest](https://shagu.org/ShaguQuest/), this addon does not depend on any specific map- or questlog addon. It's designed to support the default interface aswell as every other addon. In case you experience any addon conflicts, please add an issue to the bugtracker.

# Downloads
The **noLoc** package is for people with localized clients (e.g deDE) playing on servers that don't provide localizations (e.g Kronos).

The release page provides downloads for several gameclients. Every build includes a specifically crafted database to match the gameclient. Using the `master`-zip instead, would include **all** languages, which cost more than 100MB of language-data and will dramatically increase your loading screen times. Please select only **one** language.

**[[Release Page]](https://github.com/shagu/pfQuest/releases/latest)**

### Suggested Addons
- [pfUI](http://github.com/shagu/pfUI): A complete and customizable UI replacement in a single addon
- [EQL3](https://github.com/laytya/EQL3): A reskinned Extended Quest Log addon inspired by TukUI

# Map & Minimap Nodes
<img src="https://raw.githubusercontent.com/shagu/ShaguAddons/master/_img/pfQuest/map-quests.png" width="55.35%" align="left">
<img src="https://raw.githubusercontent.com/shagu/ShaguAddons/master/_img/pfQuest/map-spawnpoints.png" width="39.65%">

<img src="https://raw.githubusercontent.com/shagu/ShaguAddons/master/_img/pfQuest/map-lootchance.png" width="45%" align="left">
<img src="https://raw.githubusercontent.com/shagu/ShaguAddons/master/_img/pfQuest/minimap-nodes.png" width="50%">


# Auto-Tracking
<img src="https://raw.githubusercontent.com/shagu/ShaguAddons/master/_img/pfQuest/map-autotrack.png" float="right" align="right" width="30%">
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
<img src="https://raw.githubusercontent.com/shagu/ShaguAddons/master/_img/pfQuest/browser-spawn.png" align="left" width="30%">
<img src="https://raw.githubusercontent.com/shagu/ShaguAddons/master/_img/pfQuest/browser-quests.png" align="left" width="30%">
<img src="https://raw.githubusercontent.com/shagu/ShaguAddons/master/_img/pfQuest/browser-items.png" align="center" width="33%">

The database GUI allows you to bookmark and browse through all entries within the pfQuest database. It can be opened by a click on the pfQuest minimap icon or via `/db show`. The browser will show a maximum of 100 entries at once for each tab. Use your scrollwheel or press the up/down arrows to go up and down the list.


# Questlog Integration
### Questlinks
<img src="https://raw.githubusercontent.com/shagu/ShaguAddons/master/_img/pfQuest/questlink.png" float="right" align="right" width="30%">

On servers that support questlinks, a shift-click on a selected quest will add a questlink into chat. Those links are similar to the known questlinks from TBC+ and are compatible to ones produced by [ShaguQuest](https://shagu.org/ShaguQuest/), [Questie](https://github.com/AeroScripts/QuestieDev) and [QuestLink](http://addons.us.to/addon/questlink-0). Please be aware that some servers (e.g Kronos) are blocking questlinks and you'll have to disable this feature in the pfQuest settings, in order to print the quest name into the chat instead of adding a questlink. Questlinks sent from pfQuest to pfQuest are locale independent and rely on the Quest ID.

The tooltip will display quest information such as your current state on the quest (new, in progress, already done) as well as the quest objective text and the full quest description. In addition to that, the suggested level and the minimum level are shown.

### Questlog Buttons
<img src="https://raw.githubusercontent.com/shagu/ShaguAddons/master/_img/pfQuest/questlog-integration.png" align="left" width="300">

The questlog will show 4 additional buttons on each quest in order to provide easy manual quest tracking. Those buttons can be used to show or hide individual quests on the map. Those buttons won't affect the entries that you've placed by using the database browser.

**Show**  
The "Show" button will add the questobjectives of the current quest to the map.

**Hide**  
The "Hide" button will remove the current selected quest from the map.

**Clean**  
The "Clean" button will remove all nodes that have been placed by pfQuest from the map.

**Reset**  
The "Reset" button will restore the default visibility of icons to match the set values on the map dropdown menu (e.g "All Quests" by default).


# Chat/Macro CLI
<img src="https://raw.githubusercontent.com/shagu/ShaguAddons/master/_img/pfQuest/chat-cli.png">

The addon features a CLI interface which allows you to easilly create macros to show your favourite herb or mining-veins. Let's say you want to display all **Iron Deposit** deposits, then type in chat or create a macro with the text: `/db object Iron Deposit`. If `/db` doesn't work for you, there are also some other aliases available like `/shagu`, `pfquest` and `/pfdb`.
