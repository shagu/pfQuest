#!/usr/bin/lua
-- depends: pacman -S lua-sql-mysql

local function sanitize(str)
  str = string.gsub(str, "\"", "\\\"")
  str = string.gsub(str, "\'", "\\\'")
  str = string.gsub(str, "\r", "")
  str = string.gsub(str, "\n", "")
  return str
end

local locales = {
  ["enUS"] = 0,
  ["koKR"] = 1,
  ["frFR"] = 2,
  ["deDE"] = 3,
  ["zhCN"] = 4,
  ["zhTW"] = 5,
  ["esES"] = 6,
  ["esMX"] = 7,
  ["ruRU"] = 8,
}

local loc_name = arg[1] or "enUS"

if not locales[loc_name] then
  print("!! invalid locale !!")
  return 1
end

local loc_id = locales[loc_name]

local env = assert (require"luasql.mysql".mysql())
local con = assert (env:connect("elysium","mangos","mangos","127.0.0.1"))

local quest_template = {}
local quest_template_pre = {}
local creature_questrelation = {}
local gameobject_questrelation = {}
local creature_involvedrelation = {}
local gameobject_involvedrelation = {}
local questitems = {}
local spawns = {}
local items = {}

print("pfDB[\"quests\"][\"" .. loc_name .. "\"] = {")

local q1 = con:execute("select * from quest_template \
  INNER JOIN locales_quest ON quest_template.entry = locales_quest.entry")
while q1:fetch(quest_template, "a") do
  local title = quest_template["Title_loc" .. loc_id] or quest_template.Title
  local objectives = quest_template["Objectives_loc" .. loc_id] or quest_template.Objectives
  local details = quest_template["Details_loc" .. loc_id] or quest_template.Details
  local title = title .. "," .. string.sub((objectives or ""), 1, 10)

  print("  [\"" .. sanitize(title) .. "\"] = {")
  print("    [\"id\"] = " .. quest_template.entry .. ",")
  if quest_template.MinLevel and quest_template.MinLevel ~= "0" then
    print("    [\"min\"] = " .. quest_template.MinLevel .. ",")
  end

  if quest_template.QuestLevel and quest_template.QuestLevel ~= "0" then
    print("    [\"lvl\"] = " .. quest_template.QuestLevel .. ",")
  end

  if quest_template.RequiredClasses and quest_template.RequiredClasses ~= "0" then
    print("    [\"class\"] = " .. quest_template.RequiredClasses .. ",")
  end

  if quest_template.RequiredRaces and quest_template.RequiredRaces ~= "0" then
    print("    [\"race\"] = " .. quest_template.RequiredRaces .. ",")
  end

  if quest_template.PrevQuestId and quest_template.PrevQuestId ~= "" then -- prequests
    local prequest = con:execute("select * from quest_template \
      INNER JOIN locales_quest ON quest_template.entry = locales_quest.entry \
      WHERE quest_template.entry = " .. quest_template.PrevQuestId)

    while prequest:fetch(quest_template_pre, "a") do
      local title = quest_template_pre["Title_loc" .. loc_id] or quest_template_pre.Title
      local objectives = quest_template_pre["Objectives_loc" .. loc_id] or quest_template_pre.Objectives
      local title = title .. "," .. string.sub((objectives or ""), 1, 10)
      print("    [\"pre\"] = \"" .. sanitize(title) .. "\",")
    end
  end

  --[[ maybe later
  if quest_template.NextQuestInChain and quest_template.NextQuestInChain ~= "0" then
    print("    [\"next\"] = " .. quest_template.NextQuestInChain .. ",")
  end
  ]]--

  if quest_template.Details and quest_template.Details ~= "" then
    print("    [\"log\"] = \"" .. sanitize(details) .. "\",")
  end

  if quest_template.Objectives and quest_template.Objectives ~= "" then
    print("    [\"obj\"] = \"" .. sanitize(objectives) .. "\",")
  end

  do -- quest starter
    print("    [\"start\"] = {")

    local q2 = con:execute(" \
      select * from creature_questrelation \
      INNER JOIN creature_template ON creature_template.Entry = creature_questrelation.id \
      INNER JOIN locales_creature ON creature_template.Entry = locales_creature.entry \
      WHERE quest = " .. quest_template.entry
    )

    while q2:fetch(creature_questrelation, "a") do
      local name = creature_questrelation["name_loc" .. loc_id] or creature_questrelation.name
      print("      [\"" .. sanitize(name) .. "\"] = \"NPC\",")
    end

    local q3 = con:execute(" \
      select * from gameobject_questrelation \
      INNER JOIN gameobject_template ON gameobject_template.entry = gameobject_questrelation.id \
      INNER JOIN locales_gameobject ON gameobject_template.entry = locales_gameobject.entry \
      WHERE quest = " .. quest_template.entry
    )

    while q3:fetch(gameobject_questrelation, "a") do
      local name = gameobject_questrelation["name_loc" .. loc_id] or gameobject_questrelation.name
      print("      [\"" .. sanitize(name) .. "\"] = \"OBJECT\",")
    end

    print("    },")
  end

  do -- quest ender
    print("    [\"end\"] = {")

    local q2 = con:execute(" \
      select * from creature_involvedrelation \
      INNER JOIN creature_template ON creature_template.Entry = creature_involvedrelation.id \
      INNER JOIN locales_creature ON creature_template.Entry = locales_creature.entry \
      WHERE quest = " .. quest_template.entry
    )

    while q2:fetch(creature_involvedrelation, "a") do
      local name = creature_involvedrelation["name_loc" .. loc_id] or creature_involvedrelation.name
      print("      [\"" .. sanitize(name) .. "\"] = \"NPC\",")
    end

    local q3 = con:execute(" \
      select * from gameobject_involvedrelation \
      INNER JOIN gameobject_template ON gameobject_template.entry = gameobject_involvedrelation.id \
      INNER JOIN locales_gameobject ON gameobject_template.entry = locales_gameobject.entry \
      WHERE quest = " .. quest_template.entry
    )

    while q3:fetch(gameobject_involvedrelation, "a") do
      local name = gameobject_involvedrelation["name_loc" .. loc_id] or gameobject_involvedrelation.name
      print("      [\"" .. sanitize(name) .. "\"] = \"OBJECT\",")
    end

    print("    },")
  end

  if -- spawn objectives
    ( quest_template.ReqCreatureOrGOId1 and quest_template.ReqCreatureOrGOId1 ~= "" and quest_template.ReqCreatureOrGOId1 ~= "0" ) or
    ( quest_template.ReqCreatureOrGOId2 and quest_template.ReqCreatureOrGOId2 ~= "" and quest_template.ReqCreatureOrGOId2 ~= "0" ) or
    ( quest_template.ReqCreatureOrGOId3 and quest_template.ReqCreatureOrGOId3 ~= "" and quest_template.ReqCreatureOrGOId3 ~= "0" ) or
    ( quest_template.ReqCreatureOrGOId4 and quest_template.ReqCreatureOrGOId4 ~= "" and quest_template.ReqCreatureOrGOId4 ~= "0" ) then

    print("    [\"spawn\"] = {")

    for i=1,4 do
      if quest_template["ReqCreatureOrGOId" .. i] and tonumber(quest_template["ReqCreatureOrGOId" .. i]) > 0 then
        -- fetch creatures
        local q2 = con:execute(" \
          select * from creature_template \
          INNER JOIN locales_creature ON creature_template.Entry = locales_creature.entry \
          WHERE creature_template.Entry = " .. quest_template["ReqCreatureOrGOId" .. i]
        )

        while q2:fetch(spawns, "a") do
          local name = spawns["name_loc" .. loc_id] or spawns.name
          print("      [\"" .. sanitize(name) .. "," .. (quest_template["ReqCreatureOrGOCount" .. i] or 1) .. "\"] = \"NPC\",")
        end

      elseif quest_template["ReqCreatureOrGOId" .. i] and tonumber(quest_template["ReqCreatureOrGOId" .. i]) < 0 then
        -- fetch gameobjects
        local q2 = con:execute(" \
          select * from gameobject_template \
          INNER JOIN locales_gameobject ON gameobject_template.entry = locales_gameobject.entry \
          WHERE gameobject_template.entry = " .. math.abs(quest_template["ReqCreatureOrGOId" .. i])
        )

        while q2:fetch(spawns, "a") do
          local name = spawns["name_loc" .. loc_id] or spawns.name
          print("      [\"" .. sanitize(spawns.name) .. "," .. (quest_template["ReqCreatureOrGOCount" .. i] or 1) .. "\"] = \"OBJECT\",")
        end
      end
    end
    print("    },")
  end

  if -- item objectives
    ( quest_template.ReqItemId1 and quest_template.ReqItemId1 ~= "" and quest_template.ReqItemId1 ~= "0" ) or
    ( quest_template.ReqItemId2 and quest_template.ReqItemId2 ~= "" and quest_template.ReqItemId2 ~= "0" ) or
    ( quest_template.ReqItemId3 and quest_template.ReqItemId3 ~= "" and quest_template.ReqItemId3 ~= "0" ) or
    ( quest_template.ReqItemId4 and quest_template.ReqItemId4 ~= "" and quest_template.ReqItemId4 ~= "0" ) or

    ( quest_template.ReqSourceId1 and quest_template.ReqSourceId1 ~= "" and quest_template.ReqSourceId1 ~= "0" ) or
    ( quest_template.ReqSourceId2 and quest_template.ReqSourceId2 ~= "" and quest_template.ReqSourceId2 ~= "0" ) or
    ( quest_template.ReqSourceId3 and quest_template.ReqSourceId3 ~= "" and quest_template.ReqSourceId3 ~= "0" ) or
    ( quest_template.ReqSourceId4 and quest_template.ReqSourceId4 ~= "" and quest_template.ReqSourceId4 ~= "0" ) then

    print("    [\"item\"] = {")

    -- items
    for i=1,4 do
      if quest_template["ReqItemId" .. i] and tonumber(quest_template["ReqItemId" .. i]) > 0 then
        -- fetch creatures
        local q2 = con:execute(" \
          select * from item_template \
          INNER JOIN locales_item ON item_template.entry = locales_item.entry \
          WHERE item_template.entry = " .. quest_template["ReqItemId" .. i]
        )

        while q2:fetch(items, "a") do
          local name = items["name_loc" .. loc_id] or items.name
          print("      [\"" .. sanitize(name) .. "," .. (quest_template["ReqItemCount" .. i] or 1) .. "\"] = \"ITEM\",")
        end
      end
    end

    -- quest items
    for i=1,4 do
      if quest_template["ReqItemId" .. i] and tonumber(quest_template["ReqItemId" .. i]) > 0 then
        -- fetch creatures
        local q2 = con:execute(" \
          select * from item_template \
          INNER JOIN locales_item ON item_template.entry = locales_item.entry \
          WHERE item_template.entry = " .. quest_template["ReqSourceId" .. i]
        )

        while q2:fetch(questitems, "a") do
          local name = items["name_loc" .. loc_id] or items.name
          print("      [\"" .. sanitize(name) .. "," .. (quest_template["ReqSourceCount" .. i] or 1) .. "\"] = \"QUEST\",")
        end
      end
    end

    print("    },")
  end

  print("  },")
end

print("}")
