config
======

## ["minimapbutton"]
This option can be used to hide the pfQuest-minimap button.  
Default=1

## ["trackingmethod"]
The current method what quests should be automatically shown and tracked.  
Default=1
1. Show All Quests
2. Show Tracked Quests
3. Manual Selection ("Show"-Button)
4. Disable all Quests

## ["allquestgivers"]
If selected, this option will query for all questgivers and shows them on the map.  
Default=1

## ["showlowlevel"]
If `allquestgivers` is selected, this option can be used to hide low-level quests from the map. If set to `1`, then no filters are applied.  
Default=1

## ["showids"]
If selected, the result buttons of the browser and the tooltips of nodes on the maps will show the ID of the unit/object/item/quest.  
Default=0

## ["currentquestgivers"]
If selected, the current quest-ender npcs/objects will be shown on the map for active quests.  
Default=1

## ["minimapnodes"]
If selected, minimap nodes will be shown.  
Default=1

## ["questlogbuttons"]
If selected, buttons will be shown in the questlog to show, clean and reset the nodes.  
Default=1

## ["worldmapmenu"]
If selected, a dropdown menu will be shown on the worldmap to select the `trackingmethod`.  
Default=1

## ["worldmaptransp"]
This option represents the transparency of worldmap nodes. Can be values between 0.0 and 1.0  
Default=1.0

## ["minimaptransp"]
This option represents the transparency of minimap nodes. Can be values between 0.0 and 1.0  
Default=1.0

## ["mindropchance"]
This option defines the minimum drop chance a unit or object must have for an item, so that its node is displayed on the map. Can be values between 0.0 and 100.0. Values > 100 will show no drops at all.  
Default=0

## ["worldmaptexture"]
The default texture of worldmap nodes when no texture is set in the `meta`.  
Default="node1"

## ["minimaptexture"]
The default texture of minimap nodes when no texture is set in the `meta`.  
Default="node2"
