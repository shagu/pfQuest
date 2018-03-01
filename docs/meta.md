meta object
===========

The meta object is the core object of each node. It includes information such as x- and y-values of the node aswell as the zone. It's the main resource of all information which will later be shown in the tooltip and is also used to pass further options and arguments to the display functions of the map and database.

## Mandatory
### ["addon"]
The name of the addon that creates the node. This is later used to clean up nodes by addon name. pfQuest uses "PFQUEST" where empty values are defaulted to "PFDB" in order to make it possible to remove all nodes of one addon at once.

### ["title"]
This is the title of the node that should be displayd. This can also be used to remove all nodes by title.

### ["zone"]
The mapID (see zones.lua) of the node's position.

### ["x"]
The x-axis of the node's position

### ["y"]
The y-axis of the node's position

## Set by Spawn/Object Queries
### ["spawn"]
This defines the name of the spawn that should be shown and the title of the node. It gets replaced if either `"item"` or `"quest"` is set.  
The `SearchMob` and `SearchObject` function will use this to set the "title" of the node.

### ["spawnid"]
This defines the ID of the spawn that should be shown in the title of the node tooltip when the `showids` option is enabled.  
The `pfMap:NodeEnter()` function will use this to set the "title" of the node.

### ["level"]
Can be used to print a level for the created node this can either be a string with a number inside or a range like `"16-18"`.

### ["respawn"]
This can be set to the respawn timer of the given object/unit.

### ["spawntype"]
This should be set to the type the node is. Usually this is either `"Unit"` or `"Object"`.

## Set by Item Queries
### ["item"]
This defines the name of the item that should be shown and the title of the node. It gets replaced if "quest" is set.  
The `SearchMob` and `SearchObject` function will use this to set the "title" of the node.

### ["itemid"]
If the node displays an item, this value can be set to the corresponding itemid to make further working with the node easier.

### ["itemlink"]
This is not set directly. This can be set to the generated itemlink built with the rarity color, name and id of the item. This is usually done inside the Tooltip function and cached here.

### ["droprate"]
If the item is dropped or looted from any object or unit, this can represent the dropchance.

### ["sellcount"]
This is used for entries from within the vendor table of the item database to represent the number of items one vendor has. If set to `0` its equal to infinite.

## Set by Quest Queries
### ["qlvl"]
The quests minimal level to accept the quest.

### ["qmin"]
The quests display level, usually the recommended level by the questlog.

### ["quest"]
This defines the name of the quest that should be shown and the title of the node. If quest is set, neither spawn nor item will be used as title.  
The `SearchMob` and `SearchObject` function will use this to set the "title" of the node.

## Display Related
### ["texture"]
If no texture is set, the map function will use its default node icon. Otherwise this can be so vendor, quest or custom symbols. The value should be a path to an exising image file. ( e.g: `Interface\\AddOns\\pfQuest\\img\\icon_vendor` )

### ["vertex"]
This can be used to tint textures with a given color. The value is a table with RGB colors. ( e.g: `{ 1, .8, .4 }` )

### ["layer"]
[DEPRECATED: The layer is now auto-generated to a value based on its texture]
The layer can be used to force a position above or below other nodes. Multiple nodes on the same x/y-axis are merged into one. The higher the value, the more likely it is that this texture will replace the other nodes visibility.


## Additional Function Arguments
Those values are not reliable to read after the function calls. Those are used to request special behaviours of one of the DB-query functions.

### ["qlogid"]
Represents the quests current position in the players questlog. This is used to gather extended data, like current progress of the quest, which will be written into `qstate`. If this is set, the `SearchQuest` and `SearchQuestByID` functions will also behave in a way as the pfQuest tracker needs it:
  * It does not show the quest-starters
  * It uses grey question marks for incompleted quests
  * It uses yellow question marks for completed quests
  * It will skip already finished objectives

### ["qstate"]
This reflects the current state of the quest in the questlog, can be strings like `"done"` or `"progress"`.
