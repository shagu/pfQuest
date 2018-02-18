pfDatabase = {}

local loc = GetLocale()
local dbs = { "items", "quests", "objects", "units", "zones" }

-- detect localized databases
for id, db in pairs(dbs) do
  -- assign existing locale
  pfDB[db]["loc"] = pfDB[db][loc] or pfDB[db]["enUS"]
end

-- add database shortcuts
local items = pfDB["items"]["data"]
local units = pfDB["units"]["data"]
local objects = pfDB["objects"]["data"]
local quests = pfDB["quests"]["data"]
local zones = pfDB["zones"]["loc"]

function pfDatabase:HexDifficultyColor(level, force)
  if force and UnitLevel("player") < level then
    return "|cffff5555"
  else
    local c = GetDifficultyColor(level)
    return string.format("|cff%02x%02x%02x", c.r*255, c.g*255, c.b*255)
  end
end

-- GetIDByName
-- Scans localization tables for matching IDs
-- Returns table with all IDs
function pfDatabase:GetIDByName(name, db)
  if not pfDB[db] then return nil end
  local ret = {}

  for id, loc in pairs(pfDB[db]["loc"]) do
    if strlower(loc) == strlower(name) then
      ret[id] = true
    end
  end
  return ret
end

-- GetBestMap
-- Scans a map table for all spawns
-- Returns the map with most spawns
function pfDatabase:GetBestMap(maps)
  local bestmap, bestscore = nil, 0

  -- calculate best map results
  for map, count in pairs(maps) do
    if count > bestscore then
      bestscore = count
      bestmap   = map
    end
  end

  return bestmap or nil, bestscore or nil
end

-- SearchMobID
-- Scans for all mobs with a specified ID
-- Adds map nodes for each and returns its map table
function pfDatabase:SearchMobID(id, meta, maps)
  if not units[id] or not units[id]["coords"] then return maps end

  local maps = maps or {}

  for _, data in pairs(units[id]["coords"]) do
    local x, y, zone, respawn = unpack(data)

    if pfMap:IsValidMap(zone) and zone > 0 then
      -- add all gathered data
      meta = meta or {}
      meta["x"]     = x
      meta["y"]     = y
      meta["zone"]  = zone
      meta["spawn"] = pfDB.units.loc[id]
      meta["respawn"] = respawn and SecondsToTime(respawn)
      meta["spawntype"] = "UNIT"
      meta["level"] = units[id]["lvl"] or UNKNOWN
      meta["title"] = meta["quest"] or meta["item"] or meta["spawn"]
      maps[zone] = maps[zone] and maps[zone] + 1 or 1
      pfMap:AddNode(meta)
    end
  end

  return maps
end

-- SearchMob
-- Scans for all mobs with a specified name
-- Adds map nodes for each and returns its map table
function pfDatabase:SearchMob(mob, meta, show)
  local maps = {}

  for id in pairs(pfDatabase:GetIDByName(mob, "units")) do
    if units[id] and units[id]["coords"] then
      maps = pfDatabase:SearchMobID(id, meta, maps)
    end
  end

  return maps
end

-- Scans for all objects with a specified ID
-- Adds map nodes for each and returns its map table
function pfDatabase:SearchObjectID(id, meta, maps)
  if not objects[id] or not objects[id]["coords"] then return maps end

  local maps = maps or {}

  for _, data in pairs(objects[id]["coords"]) do
    local x, y, zone, respawn = unpack(data)

    if pfMap:IsValidMap(zone) and zone > 0 then
      -- add all gathered data
      meta = meta or {}
      meta["x"]     = x
      meta["y"]     = y
      meta["zone"]  = zone
      meta["spawn"] = pfDB.objects.loc[id]
      meta["respawn"] = respawn and SecondsToTime(respawn)
      meta["spawntype"] = "OBJECT"
      meta["level"] = UNKNOWN
      meta["title"] = meta["quest"] or meta["item"] or meta["spawn"]
      maps[zone] = maps[zone] and maps[zone] + 1 or 1
      pfMap:AddNode(meta)
    end
  end

  return maps
end

-- SearchObject
-- Scans for all objects with a specified name
-- Adds map nodes for each and returns its map table
function pfDatabase:SearchObject(obj, meta)
  local maps = {}

  for id in pairs(pfDatabase:GetIDByName(obj, "objects")) do
    if objects[id] and objects[id]["coords"] then
      maps = pfDatabase:SearchObjectID(id, meta, maps)
    end
  end

  return maps
end


-- SearchItemID
-- Scans for all items with a specified ID
-- Adds map nodes for each drop and vendor
-- Returns its map table
function pfDatabase:SearchItemID(id, meta, maps)
  local maps = maps or {}

  -- search unit drops
  if items[id]["U"] then
    for unit, chance in pairs(items[id]["U"]) do
      meta = meta or {}
      meta["droprate"] = chance
      meta["item"] = item
      meta["itemid"] = id
      maps = pfDatabase:SearchMobID(unit, meta, maps)
      pfMap:AddNode(meta)
    end
  end

  -- search object loot (veins, chests, ..)
  if items[id]["O"] then
    for object, chance in pairs(items[id]["O"]) do
      meta = meta or {}
      meta["droprate"] = chance
      meta["item"] = item
      meta["itemid"] = id
      maps = pfDatabase:SearchObjectID(object, meta, maps)
      pfMap:AddNode(meta)
    end
  end

  -- search vendor goods
  if items[id]["U"] then
    for unit, chance in pairs(items[id]["U"]) do
      meta = meta or {}
      meta["droprate"] = chance
      meta["item"] = item
      meta["itemid"] = id
      maps = pfDatabase:SearchMobID(unit, meta, maps)
      pfMap:AddNode(meta)
    end
  end

  return maps
end

-- SearchItem
-- Scans for all items with a specified name
-- Adds map nodes for each drop and vendor
-- Returns its map table
function pfDatabase:SearchItem(item, meta)
  local maps = {}
  local bestmap, bestscore = nil, 0

  for id in pairs(pfDatabase:GetIDByName(item, "items")) do
    maps = pfDatabase:SearchItemID(id, meta, maps)
  end

  return maps
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
