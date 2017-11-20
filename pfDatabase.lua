pfDatabase = {}

local loc = GetLocale()
local dbs = { "items", "quests", "vendors", "spawns", "zones" }

-- detect localized databases
for id, db in pairs(dbs) do
  pfDatabase[db] = pfDB[db][loc] or pfDB[db]["enUS"]
end

-- add database shortcuts
local items = pfDatabase["items"]
local quests = pfDatabase["quests"]
local vendors = pfDatabase["vendors"]
local spawns = pfDatabase["spawns"]
local zones = pfDatabase["zones"]

SLASH_PFDB1, SLASH_PFDB2, SLASH_PFDB3, SLASH_PFDB4 = "/db", "/shagu", "/pfquest", "/pfdb"
SlashCmdList["PFDB"] = function(input, editbox)
  local params = {}
  if (input == "" or input == nil) then
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffccpf|cffffffffQuest (v" .. tostring(GetAddOnMetadata("pfQuest", "Version")) .. "):")
    DEFAULT_CHAT_FRAME:AddMessage("/db show |cffaaaaaa - show database interface")
    DEFAULT_CHAT_FRAME:AddMessage("/db config |cffaaaaaa - show configuration interface")
    DEFAULT_CHAT_FRAME:AddMessage("/db spawn <mob|gameobject> |cffaaaaaa - search objects")
    DEFAULT_CHAT_FRAME:AddMessage("/db item <item> |cffaaaaaa - search loot")
    DEFAULT_CHAT_FRAME:AddMessage("/db vendor <item> |cffaaaaaa - vendors for item")
    DEFAULT_CHAT_FRAME:AddMessage("/db quest <questname> |cffaaaaaa - show specific questgiver")
    DEFAULT_CHAT_FRAME:AddMessage("/db quests <area> |cffaaaaaa - show all quest spots on the map")
    DEFAULT_CHAT_FRAME:AddMessage("/db clean |cffaaaaaa - clean map")
  end

  local commandlist = { }
  local command

  for command in string.gfind(input, "[^ ]+") do
    table.insert(commandlist, command)
  end

  local arg1, arg2 = commandlist[1], ""

  -- handle whitespace mob- and item names correctly
  for i in commandlist do
    if (i ~= 1) then
      arg2 = arg2 .. commandlist[i]
      if (commandlist[i+1] ~= nil) then
        arg2 = arg2 .. " "
      end
    end
  end

  -- argument: item
  if (arg1 == "item") then
    local map = pfDatabase:SearchItem(arg2)
    if not pfMap:ShowMapID(map) then
      DEFAULT_CHAT_FRAME:AddMessage("No matches.")
    end
  end

  -- argument: vendor
  if (arg1 == "vendor") then
    local map = pfDatabase:SearchVendor(arg2)
    if not pfMap:ShowMapID(map) then
      DEFAULT_CHAT_FRAME:AddMessage("No matches.")
    end
  end

  -- argument: spawn
  if (arg1 == "spawn") then
    local map = pfDatabase:SearchMob(arg2)
    if not pfMap:ShowMapID(map) then
      DEFAULT_CHAT_FRAME:AddMessage("No matches.")
    end
  end

  -- argument: quest
  if (arg1 == "quest") then
    local map = pfDatabase:SearchQuest(arg2)
    if not pfMap:ShowMapID(map) then
      DEFAULT_CHAT_FRAME:AddMessage("No matches.")
    end
  end

  -- argument: quests
  if (arg1 == "quests") then
    local map = pfDatabase:SearchQuests(arg2)
    if not pfMap:ShowMapID(map) then
      DEFAULT_CHAT_FRAME:AddMessage("No matches.")
    end
  end

  -- argument: clean
  if (arg1 == "clean") then
    pfMap:DeleteNode("PFDB")
    pfMap:UpdateNodes()
  end

  -- argument: show
  if (arg1 == "show") then
    if pfBrowser then pfBrowser:Show() end
  end

  -- argument: show
  if (arg1 == "config") then
    if pfQuestConfig then pfQuestConfig:Show() end
  end
end

function pfDatabase:HexDifficultyColor(level, force)
  if force and UnitLevel("player") < level then
    return "|cffff5555"
  else
    local c = GetDifficultyColor(level)
    return string.format("|cff%02x%02x%02x", c.r*255, c.g*255, c.b*255)
  end
end

function pfDatabase:SearchMob(mob, meta)
  local maps = {}

  if spawns[mob] and spawns[mob]["coords"] then
    for id, data in pairs(spawns[mob]["coords"]) do
      local f, t, x, y, zone = strfind(data, "(.*),(.*),(.*)")
      zone = tonumber(zone)

      if pfMap:IsValidMap(zone) and zone > 0 then
        -- add all gathered data
        meta = meta or {}
        meta["x"]     = x
        meta["y"]     = y
        meta["zone"]  = zone
        meta["spawn"] = mob
        meta["respawn"] = spawns[mob]["respawn"] and SecondsToTime(spawns[mob]["respawn"])
        meta["spawntype"] = spawns[mob]["type"] or UNKNOWN
        meta["level"] = spawns[mob]["level"] or UNKNOWN
        meta["title"] = meta["quest"] or meta["item"] or meta["spawn"]
        maps[zone] = maps[zone] and maps[zone] + 1 or 1
        pfMap:AddNode(meta)
      end
    end

    -- calculate best map results
    local bestmap, bestscore = nil, 0
    for map, count in pairs(maps) do
      if count > bestscore then
        bestscore = count
        bestmap   = map
      end
    end

    return bestmap, bestscore
  end
  return nil, nil
end

function pfDatabase:SearchItem(item, meta)
  local maps = {}

  if items[item] then
    for id, field in pairs(items[item]) do
      local f, t, monsterName, dropRate = strfind(field, "(.*),(.*)")

      meta = meta or {}
      meta["droprate"] = dropRate
      meta["item"] = item
      meta["itemid"] = items[item]["id"]
      local zone, score = pfDatabase:SearchMob(monsterName, meta)
      if zone then maps[zone] = maps[zone] and maps[zone] + score or 1 end
    end

    -- calculate best map results
    local bestmap, bestscore = nil, 0
    for map, count in pairs(maps) do
      if count > bestscore then
        bestscore = count
        bestmap   = map
      end
    end

    return bestmap, bestscore
  end

  return nil
end

function pfDatabase:SearchVendor(item, meta)
  local maps = {}

  if vendors[item] then
    for id, field in pairs(vendors[item]) do
      local f, t, vendorName, sellCount = strfind(field, "(.*),(.*)")

      meta = meta or {}
      meta["sellcount"] = sellCount
      meta["item"] = item
      meta["itemid"] = items[item] and items[item]["id"]
      meta["texture"] = "Interface\\AddOns\\pfQuest\\img\\icon_vendor"
      meta["layer"] = 6

      if spawns[vendorName] and spawns[vendorName]["coords"] then
        local zone, score = pfDatabase:SearchMob(vendorName, meta)
        if zone then maps[zone] = maps[zone] and maps[zone] + score or 1 end
      end
    end

    -- calculate best map results
    local bestmap, bestscore = nil, 0
    for map, count in pairs(maps) do
      if count > bestscore then
        bestscore = count
        bestmap   = map
      end
    end

    return bestmap, bestscore
  end

  return nil
end

function pfDatabase:SearchQuest(quest, meta, dbobj)
  local maps = {}

  if not quests[quest] then
    local qname = nil
    for name, tab in pairs(quests) do
      local f, t, questname, _ = strfind(name, "(.*),.*")
      if questname == quest then
        quest = name
      end
    end
  end

  if quests[quest] then
    if quests[quest]["start"] then
      for questGiver, field in pairs(quests[quest]["start"]) do
        local objectType = field

        meta = meta or {}
        _, _, meta["quest"] = strfind(quest, "(.*),.*")
        meta["qlvl"] = quests[quest]["lvl"]
        meta["qmin"] = quests[quest]["min"]

        if quests[quest]["end"][questGiver] then
          if meta["qstate"] == "progress" then
            meta["texture"] = "Interface\\AddOns\\pfQuest\\img\\startendstart"
            meta["layer"] = 5
          else
            meta["texture"] = "Interface\\AddOns\\pfQuest\\img\\startend"
            meta["layer"] = 7
          end
        else
          meta["texture"] = "Interface\\AddOns\\pfQuest\\img\\available_c"
          meta["layer"] = 4
        end

        local zone, score = pfDatabase:SearchMob(questGiver, meta)
        if zone then maps[zone] = maps[zone] and maps[zone] + score or 1 end
      end
    end

    if quests[quest]["end"] then
      for questGiver, field in pairs(quests[quest]["end"]) do
        local objectType = field

        meta = meta or {}
        _, _, meta["quest"] = strfind(quest, "(.*),.*")

        if quests[quest]["start"][questGiver] then
          if meta["qstate"] == "progress" then
            meta["texture"] = "Interface\\AddOns\\pfQuest\\img\\startendstart"
            meta["layer"] = 5
          else
            meta["texture"] = "Interface\\AddOns\\pfQuest\\img\\startend"
            meta["layer"] = 7
          end
        else
          if meta["qstate"] == "done" or dbobj then
            meta["texture"] = "Interface\\AddOns\\pfQuest\\img\\complete_c"
            meta["layer"] = 8
          else
            meta["texture"] = "Interface\\AddOns\\pfQuest\\img\\complete"
            meta["layer"] = 1
          end
        end

        local zone, score = pfDatabase:SearchMob(questGiver, meta)
        if zone then maps[zone] = maps[zone] and maps[zone] + score or 1 end
      end
    end

    -- query database objects
    if dbobj then
      meta["texture"] = nil

      -- spawns
      if quests[quest]["spawn"] then
        for mob in pairs(quests[quest]["spawn"]) do
          local _, _, mob = strfind(mob, "(.*),.*")
          zone, score = pfDatabase:SearchMob(mob, meta)
          if zone then maps[zone] = maps[zone] and maps[zone] + score or 1 end
        end
      end

      -- items
      if quests[quest]["item"] then
        for item in pairs(quests[quest]["item"]) do
          local _, _, item = strfind(item, "(.*),.*")
          zone, score = pfDatabase:SearchItem(item, meta)
          if zone then maps[zone] = maps[zone] and maps[zone] + score or 1 end

          zone, score = pfDatabase:SearchVendor(item, meta)
          if zone then maps[zone] = maps[zone] and maps[zone] + score or 1 end
        end
      end
    end

    -- calculate best map results
    local bestmap, bestscore = nil, 0
    for map, count in pairs(maps) do
      if count > bestscore then
        bestscore = count
        bestmap   = map
      end
    end

    return bestmap, bestscore
  end

  return nil
end

local bitraces = { [1] = "Human", [2] = "Orc", [4] = "Dwarf", [8] = "NightElf",
  [16] = "Scourge", [32] = "Tauren", [64] = "Gnome", [128] = "Troll" }
local function GetBitByRace(model)
  -- local _, model == UnitRace("player")
  for bit, v in pairs(bitraces) do
    if model == v then return bit end
  end
end

local bitclasses = { [1] = "WARRIOR", [2] = "PALADIN", [4] = "HUNTER",
  [8] = "ROGUE", [16] = "PRIEST", [64] = "SHAMAN", [128] = "MAGE",
  [256] = "WARLOCK", [1024] = "DRUID" }
local function GetBitByClass(class)
  -- local _, class == UnitClass("player")
  for bit, v in pairs(bitclasses) do
    if class == v then return bit end
  end
end

function pfDatabase:SearchQuests(zone, meta)
  local faction = ( UnitFactionGroup("player") == "Horde" ) and "H" or "A"
  local level = UnitLevel("player")
  local _, race = UnitRace("player")
  local brace = GetBitByRace(race)
  local _, class = UnitClass("player")
  local bclass = GetBitByClass(class)

  zone = pfMap:GetMapIDByName(zone)
  if not pfMap:IsValidMap(zone) then
    zone = pfMap:GetMapID(GetCurrentMapContinent(), GetCurrentMapZone())
  end

  for title in pairs(quests) do
    for questgiver in pairs(quests[title]["start"]) do
      if spawns[questgiver] and strfind(spawns[questgiver]["faction"], faction) then

        meta = meta or {}
        _, _, meta["quest"] = strfind(title, "(.*),.*")
        meta["qlvl"] = quests[title]["lvl"]
        meta["qmin"] = quests[title]["min"]
        meta["vertex"] = { 0, 0, 0 }
        meta["layer"] = 3

        -- tint high level quests red
        if quests[title]["min"] and quests[title]["min"] > level then
          meta["vertex"] = { 1, .6, .6 }
          meta["layer"] = 2
        end

        -- treat highlevel quests with low requirements as dailies
        if quests[title]["min"] and quests[title]["lvl"] and quests[title]["min"] == 1 and quests[title]["lvl"] > 50 then
          meta["vertex"] = { .2, .8, 1 }
          meta["layer"] = 2
        end

        meta["texture"] = "Interface\\AddOns\\pfQuest\\img\\available"

        if meta["allquests"] then
          meta["addon"] = "PFQUEST"

          if pfQuest_history[meta["quest"]] then
            break
          elseif quests[title]["race"] and not ( bit.band(quests[title]["race"], brace) == brace ) then
            break
          elseif quests[title]["class"] and not ( bit.band(quests[title]["class"], bclass) == bclass ) then
            break
          elseif meta["hidelow"] and quests[title]["lvl"] and quests[title]["lvl"] < UnitLevel("player") - 9 then
            break
          elseif quests[title]["lvl"] and quests[title]["lvl"] > level + 10 then
            break
          elseif quests[title]["min"] and quests[title]["min"] > level + 3 then
            break
          elseif quests[title]["pre"] then
            _, _, pre = strfind(quests[title]["pre"], "(.*),.*")
            if not pfQuest_history[pre] then break end
          end
        end

        if tonumber(spawns[questgiver]["zone"]) == zone or meta["allquests"] then
          local zone, score = pfDatabase:SearchMob(questgiver, meta)
        end
      end
    end
  end

  return zone
end
