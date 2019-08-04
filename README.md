# pfQuest
<img src="https://raw.githubusercontent.com/shagu/ShaguAddons/master/_img/pfQuest/tooltips.png" float="right" align="right" width="25%">
This is an addon for World of Warcraft Vanilla (1.12) and The Burning Crusade (2.4.3). It helps players to find several ingame objects and quests. The addon reads questobjectives, parses them and uses its internal database to plot the found matches on the world- and minimap. It ships with a GUI to browse through all known objects. If one of the items is not yet available on your realm, you'll see a [?] in front of the name.

The addon is not designed to be a quest- or tourguide and won't ever going to be like that. Instead the goals are more like an ingame version of [AoWoW](http://db.vanillagaming.org/) or [Wowhead](http://www.wowhead.com/). It is powered by the opensource database provided by [CMaNGOS](https://github.com/cmangos/).
The translations are taken from [MaNGOS Extras](https://github.com/MangosExtras).

pfQuest is the successor of [ShaguQuest](https://shagu.org/ShaguQuest/) and has been entirely written from scratch. In comparison to [ShaguQuest](https://shagu.org/ShaguQuest/), this addon does not depend on any specific map- or questlog addon. It's designed to support the default interface aswell as every other addon. In case you experience any addon conflicts, please add an issue to the bugtracker.

You can view the [[Latest Changes]](https://gitlab.com/shagu/pfQuest/commits/master) to see what has changed recently.

# Downloads
## Complete Version
The complete version includes databases of all languages and client expansions. Based on the folder name, this will launch in either vanilla or tbc mode. Due to the amount of included data, this snapshot will lead to a higher RAM/Disk-Usage and slightly increased loading times. But nowadays where people having gigabytes of RAM and storage, having an overhead of a few megabytes shouldn't harm the system at all. However, if your PC is very old and slow, you better choose a compact build.

1. Download **[Complete Version](https://gitlab.com/shagu/pfQuest/-/archive/master/pfQuest-master.zip)**
2. Unpack the Zip file
3. Rename the folder "pfQuest-master" to "pfQuest" (or "pfQuest-tbc")
4. Copy "pfQuest" (or "pfQuest-tbc") into Wow-Directory\Interface\AddOns
5. Restart Wow

## Compact Version
A compact build does only include the databases of a given language. Usually, one would pick the language that matches gameclients language. If a server returns english quests, but your gameclient is non-english (e.g deDE), then the server you play on is unlocalized and you'll need the `noLoc` package.

* **English** (*enUS*):
  [Vanilla (1.12.1)](https://gitlab.com/shagu/pfQuest/-/jobs/artifacts/master/download?job=enUS) |
  [The Burning Crusade (2.4.3)](https://gitlab.com/shagu/pfQuest/-/jobs/artifacts/master/download?job=enUS-tbc)
* **Korean** (*koKR*):
  [Vanilla (1.12.1)](https://gitlab.com/shagu/pfQuest/-/jobs/artifacts/master/download?job=koKR) |
  [The Burning Crusade (2.4.3)](https://gitlab.com/shagu/pfQuest/-/jobs/artifacts/master/download?job=koKR-tbc)
* **French** (*frFR*):
  [Vanilla (1.12.1)](https://gitlab.com/shagu/pfQuest/-/jobs/artifacts/master/download?job=frFR) |
  [The Burning Crusade (2.4.3)](https://gitlab.com/shagu/pfQuest/-/jobs/artifacts/master/download?job=frFR-tbc)
* **German** (*deDE*):
  [Vanilla (1.12.1)](https://gitlab.com/shagu/pfQuest/-/jobs/artifacts/master/download?job=deDE) |
  [The Burning Crusade (2.4.3)](https://gitlab.com/shagu/pfQuest/-/jobs/artifacts/master/download?job=deDE-tbc)
* **Chinese** (*zhCN*):
  [Vanilla (1.12.1)](https://gitlab.com/shagu/pfQuest/-/jobs/artifacts/master/download?job=zhCN) |
  [The Burning Crusade (2.4.3)](https://gitlab.com/shagu/pfQuest/-/jobs/artifacts/master/download?job=zhCN-tbc)
* **Spanish** (*esES*):
  [Vanilla (1.12.1)](https://gitlab.com/shagu/pfQuest/-/jobs/artifacts/master/download?job=esES) |
  [The Burning Crusade (2.4.3)](https://gitlab.com/shagu/pfQuest/-/jobs/artifacts/master/download?job=esES-tbc)
* **Russian** (*ruRU*):
  [Vanilla (1.12.1)](https://gitlab.com/shagu/pfQuest/-/jobs/artifacts/master/download?job=ruRU) |
  [The Burning Crusade (2.4.3)](https://gitlab.com/shagu/pfQuest/-/jobs/artifacts/master/download?job=ruRU-tbc)
* **Unlocalized** (*noLoc*):
  [Vanilla (1.12.1)](https://gitlab.com/shagu/pfQuest/-/jobs/artifacts/master/download?job=noLoc) |
  [The Burning Crusade (2.4.3)](https://gitlab.com/shagu/pfQuest/-/jobs/artifacts/master/download?job=noLoc-tbc)

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

The addon features a CLI interface which allows you to easilly create macros to show your favourite herb or mining-veins. Let's say you want to display all **Iron Deposit** deposits, then type in chat or create a macro with the text: `/db object Iron Deposit`. You can also display all mines on the map by typing: `/db meta mines`. This can be extended by giving the minimum and maximum required skill as paramter, like: `/db meta mines 150 225` to display all ores between skill 150 and 225. The `mines` parameter can also be replaced by `herbs` or `chests` in order to show those instead. If `/db` doesn't work for you, there are also some other aliases available like `/shagu`, `pfquest` and `/pfdb`.
