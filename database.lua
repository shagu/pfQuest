-- multi api compat
local compat = pfQuestCompat

pfDatabase = {}

local loc = GetLocale()
local dbs = { "items", "quests", "objects", "units", "zones", "professions" }

-- detect localized databases
pfDatabase.dbstring = ""
for id, db in pairs(dbs) do
  -- assign existing locale
  pfDB[db]["loc"] = pfDB[db][loc] or pfDB[db]["enUS"]
  pfDatabase.dbstring = pfDatabase.dbstring .. " |cffcccccc[|cffffffff" .. db .. "|cffcccccc:|cff33ffcc" .. ( pfDB[db][loc] and loc or "enUS" ) .. "|cffcccccc]"
end

-- add database shortcuts
local items = pfDB["items"]["data"]
local units = pfDB["units"]["data"]
local objects = pfDB["objects"]["data"]
local quests = pfDB["quests"]["data"]
local refloot = pfDB["refloot"]["data"]
local zones = pfDB["zones"]["loc"]
local professions = pfDB["professions"]["loc"]

local bitraces = {
  [1] = "Human",
  [2] = "Orc",
  [4] = "Dwarf",
  [8] = "NightElf",
  [16] = "Scourge",
  [32] = "Tauren",
  [64] = "Gnome",
  [128] = "Troll",
  [256] = "Goblin",
  [512] = "BloodElf",
  [1024] = "Draenei"
}

local bitclasses = {
  [1] = "WARRIOR",
  [2] = "PALADIN",
  [4] = "HUNTER",
  [8] = "ROGUE",
  [16] = "PRIEST",
  [64] = "SHAMAN",
  [128] = "MAGE",
  [256] = "WARLOCK",
  [1024] = "DRUID"
}

-- Patch databases to further expansions
local function patchtable(base, diff)
  for k, v in pairs(diff) do
    if base[k] and type(v) == "table" then
      patchtable(base[k], v)
    elseif type(v) == "string" and v == "_" then
      base[k] = nil
    else
      base[k] = v
    end
  end
end

local loc_core, loc_update
for _, exp in pairs({ "-tbc", "-wotlk" }) do
  for _, db in pairs(dbs) do
    if pfDB[db]["data"..exp] then
      loc_core = pfDB[db][loc] or pfDB[db]["enUS"]
      loc_update = pfDB[db][loc..exp] or pfDB[db]["enUS"..exp]
      patchtable(pfDB[db]["data"], pfDB[db]["data"..exp])
      patchtable(loc_core, loc_update)
    end
  end

  loc_core = pfDB["professions"][loc] or pfDB["professions"]["enUS"]
  loc_update = pfDB["professions"][loc..exp] or pfDB["professions"]["enUS"..exp]
  if loc_update then patchtable(loc_core, loc_update) end

  loc_core = pfDB["zones"][loc] or pfDB["zones"]["enUS"]
  loc_update = pfDB["zones"][loc..exp] or pfDB["zones"]["enUS"..exp]
  if loc_update then patchtable(loc_core, loc_update) end

  if pfDB["minimap"..exp] then patchtable(pfDB["minimap"], pfDB["minimap"..exp]) end
end

-- PlayerHasSkill
-- Returns false if the player has the required skill
function pfDatabase:PlayerHasSkill(skill)
  if not professions[skill] then return false end

  for i=0,GetNumSkillLines() do
    if GetSkillLineInfo(i) == professions[skill] then
      return true
    end
  end

  return false
end

-- GetBitByRace
-- Returns bit of the current race
function pfDatabase:GetBitByRace(model)
  -- local _, model == UnitRace("player")
  for bit, v in pairs(bitraces) do
    if model == v then return bit end
  end
end

-- GetBitByClass
-- Returns bit of the current class
function pfDatabase:GetBitByClass(class)
  -- local _, class == UnitClass("player")
  for bit, v in pairs(bitclasses) do
    if class == v then return bit end
  end
end

local function strcomp(old, new)
  local prv = {}
  for o = 0, string.len(old) do
    prv[o] = ""
  end
  for n = 1, string.len(new) do
    local nxt = {[0] = string.sub(new,1, n)}
    local nn = string.sub(new, n, n)
    for o = 1, string.len(old) do
      local result
      if nn == string.sub(old, o, o) then
        result = prv[o-1]
      else
        result = prv[o]..nn
        if string.len(nxt[o-1]) <= string.len(result) then
          result = nxt[o-1]
        end
      end
      nxt[o] = result
    end
    prv = nxt
  end

  local diff = strlen(prv[string.len(old)])
  if diff == 0 then
    return 0
  else
    return diff/strlen(old)
  end
end

-- CompareString
-- Shows a score based on the similarity of two strings
function pfDatabase:CompareString(old, new)
  local s1 = strcomp(old, new)
  local s2 = strcomp(new, old)
  return (math.abs(s1) + math.abs(s2))/2
end

-- GetHexDifficultyColor
-- Returns a string with the difficulty color of the given level
function pfDatabase:GetHexDifficultyColor(level, force)
  if force and UnitLevel("player") < level then
    return "|cffff5555"
  else
    local c = GetDifficultyColor(level)
    return string.format("|cff%02x%02x%02x", c.r*255, c.g*255, c.b*255)
  end
end

-- GetRaceMaskByID
function pfDatabase:GetRaceMaskByID(id, db)
  -- 64 + 8 + 4 + 1 = 77 = Alliance
  -- 128 + 32 + 16 + 2 = 178 = Horde
  local factionMap = {["A"]=77, ["H"]=178, ["AH"]=255, ["HA"]=255}
  local raceMask = 0

  if db == "quests" then
    raceMask = quests[id]["race"] or raceMask

    if (quests[id]["start"]) then
      local questStartRaceMask = 0

      -- get quest starter faction
      if (quests[id]["start"]["U"]) then
        for _, startUnitId in ipairs(quests[id]["start"]["U"]) do
          if units[startUnitId]["fac"] and factionMap[units[startUnitId]["fac"]] then
            questStartRaceMask = bit.bor(factionMap[units[startUnitId]["fac"]])
          end
        end
      end

      -- get quest object starter faction
      if (quests[id]["start"]["O"]) then
        for _, startObjectId in ipairs(quests[id]["start"]["O"]) do
          if objects[startObjectId]["fac"] and factionMap[objects[startObjectId]["fac"]] then
            questStartRaceMask = bit.bor(factionMap[objects[startObjectId]["fac"]])
          end
        end
      end

      -- apply starter faction as racemask
      if questStartRaceMask > 0 and questStartRaceMask ~= raceMask then
        raceMask = questStartRaceMask
      end
    end
  elseif pfDB[db] and pfDB[db]["data"] and pfDB[db]["data"]["fac"] then
    raceMask = factionMap[pfDB[db]["data"]["fac"]]
  end

  return raceMask
end

-- GetIDByName
-- Scans localization tables for matching IDs
-- Returns table with all IDs
function pfDatabase:GetIDByName(name, db, partial)
  if not pfDB[db] then return nil end
  local ret = {}

  for id, loc in pairs(pfDB[db]["loc"]) do
    if db == "quests" then loc = loc["T"] end

    if loc and name then
      if partial == true and strfind(strlower(loc), strlower(name), 1, true) then
        ret[id] = loc
      elseif partial == "LOWER" and strlower(loc) == strlower(name) then
        ret[id] = loc
      elseif loc == name then
        ret[id] = loc
      end
    end
  end
  return ret
end

-- GetIDByIDPart
-- Scans localization tables for matching IDs
-- Returns table with all IDs
function pfDatabase:GetIDByIDPart(idPart, db)
  if not pfDB[db] then return nil end
  local ret = {}

  for id, loc in pairs(pfDB[db]["loc"]) do
    if db == "quests" then loc = loc["T"] end

    if idPart and loc and strfind(tostring(id), idPart) then
      ret[id] = loc
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
  for map, count in pairs(maps or {}) do
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

    if zone > 0 then
      -- add all gathered data
      meta = meta or {}
      meta["spawn"] = pfDB.units.loc[id]
      meta["spawnid"] = id

      meta["title"] = meta["quest"] or meta["item"] or meta["spawn"]
      meta["zone"]  = zone
      meta["x"]     = x
      meta["y"]     = y

      meta["level"] = units[id]["lvl"] or UNKNOWN
      meta["spawntype"] = "Unit"
      meta["respawn"] = respawn > 0 and SecondsToTime(respawn)

      maps[zone] = maps[zone] and maps[zone] + 1 or 1
      pfMap:AddNode(meta)
    end
  end

  return maps
end

-- Search MetaRelation
-- Scans for all entries within the specified meta name
-- Adds map nodes for each and returns its map table
-- query = { relation-name, relation-min, relation-max }
function pfDatabase:SearchMetaRelation(query, meta, show)
  local maps = {}

  local relname = query[1] -- search name (chests)
  local relmins = query[2] -- min skill level
  local relmaxs = query[3] -- max skill level

  if pfDB["meta"] and pfDB["meta"][relname] then
    for id, skill in pairs(pfDB["meta"][relname]) do
      if ( not relmins or tonumber(relmins) <= skill ) and
         ( not relmaxs or tonumber(relmaxs) >= skill )
      then
        if id < 0 then
          pfDatabase:SearchObjectID(math.abs(id), meta, maps)
        else
          pfDatabase:SearchMobID(id, meta, maps)
        end
      end
    end
  end

  return maps
end

-- SearchMob
-- Scans for all mobs with a specified name
-- Adds map nodes for each and returns its map table
function pfDatabase:SearchMob(mob, meta, partial)
  local maps = {}

  for id in pairs(pfDatabase:GetIDByName(mob, "units", partial)) do
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

    if zone > 0 then
      -- add all gathered data
      meta = meta or {}
      meta["spawn"] = pfDB.objects.loc[id]
      meta["spawnid"] = id

      meta["title"] = meta["quest"] or meta["item"] or meta["spawn"]
      meta["zone"]  = zone
      meta["x"]     = x
      meta["y"]     = y

      meta["level"] = nil
      meta["spawntype"] = "Object"
      meta["respawn"] = respawn and SecondsToTime(respawn)

      maps[zone] = maps[zone] and maps[zone] + 1 or 1
      pfMap:AddNode(meta)
    end
  end

  return maps
end

-- SearchObject
-- Scans for all objects with a specified name
-- Adds map nodes for each and returns its map table
function pfDatabase:SearchObject(obj, meta, partial)
  local maps = {}

  for id in pairs(pfDatabase:GetIDByName(obj, "objects", partial)) do
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
function pfDatabase:SearchItemID(id, meta, maps, allowedTypes)
  if not items[id] then return maps end

  local maps = maps or {}
  local meta = meta or {}

  meta["itemid"] = id
  meta["item"] = pfDB.items.loc[id]

  local minChance = tonumber(pfQuest_config.mindropchance)
  if not minChance then minChance = 0 end

  -- search unit drops
  if items[id]["U"] and ((not allowedTypes) or allowedTypes["U"]) then
    for unit, chance in pairs(items[id]["U"]) do
      if chance >= minChance then
        meta["texture"] = nil
        meta["droprate"] = chance
        meta["sellcount"] = nil
        maps = pfDatabase:SearchMobID(unit, meta, maps)
      end
    end
  end

  -- search object loot (veins, chests, ..)
  if items[id]["O"] and ((not allowedTypes) or allowedTypes["O"]) then
    for object, chance in pairs(items[id]["O"]) do
      if chance >= minChance and chance > 0 then
        meta["texture"] = nil
        meta["droprate"] = chance
        meta["sellcount"] = nil
        maps = pfDatabase:SearchObjectID(object, meta, maps)
      end
    end
  end

  -- search reference loot (objects, creatures)
  if items[id]["R"] then
    for ref, chance in pairs(items[id]["R"]) do
      if chance >= minChance and refloot[ref] then
        -- ref creatures
        if refloot[ref]["U"] and ((not allowedTypes) or allowedTypes["U"]) then
          for unit in pairs(refloot[ref]["U"]) do
            meta["texture"] = nil
            meta["droprate"] = chance
            meta["sellcount"] = nil
            maps = pfDatabase:SearchMobID(unit, meta, maps)
          end
        end

        -- ref objects
        if refloot[ref]["O"] and ((not allowedTypes) or allowedTypes["O"]) then
          for object in pairs(refloot[ref]["O"]) do
            meta["texture"] = nil
            meta["droprate"] = chance
            meta["sellcount"] = nil
            maps = pfDatabase:SearchObjectID(object, meta, maps)
          end
        end
      end
    end
  end

  -- search vendor goods
  if items[id]["V"] and ((not allowedTypes) or allowedTypes["V"]) then
    for unit, chance in pairs(items[id]["V"]) do
      meta["texture"] = pfQuestConfig.path.."\\img\\icon_vendor"
      meta["droprate"] = nil
      meta["sellcount"] = chance
      maps = pfDatabase:SearchMobID(unit, meta, maps)
    end
  end

  return maps
end

-- SearchItem
-- Scans for all items with a specified name
-- Adds map nodes for each drop and vendor
-- Returns its map table
function pfDatabase:SearchItem(item, meta, partial)
  local maps = {}
  local bestmap, bestscore = nil, 0

  for id in pairs(pfDatabase:GetIDByName(item, "items", partial)) do
    maps = pfDatabase:SearchItemID(id, meta, maps)
  end

  return maps
end

-- SearchVendor
-- Scans for all items with a specified name
-- Adds map nodes for each vendor
-- Returns its map table
function pfDatabase:SearchVendor(item, meta)
  local maps = {}
  local meta = meta or {}
  local bestmap, bestscore = nil, 0

  for id in pairs(pfDatabase:GetIDByName(item, "items")) do
    meta["itemid"] = id
    meta["item"] = pfDB.items.loc[id]

    -- search vendor goods
    if items[id] and items[id]["V"] then
      for unit, chance in pairs(items[id]["V"]) do
        meta["texture"] = pfQuestConfig.path.."\\img\\icon_vendor"
        meta["droprate"] = nil
        meta["sellcount"] = chance
        maps = pfDatabase:SearchMobID(unit, meta, maps)
      end
    end
  end

  return maps
end

-- SearchQuestID
-- Scans for all quests with a specified ID
-- Adds map nodes for each objective and involved units
-- Returns its map table
function pfDatabase:SearchQuestID(id, meta, maps)
  local maps = maps or {}
  local meta = meta or {}

  meta["questid"] = id
  meta["quest"] = pfDB.quests.loc[id].T
  meta["qlvl"] = quests[id]["lvl"]
  meta["qmin"] = quests[id]["min"]

  if pfQuest_config["currentquestgivers"] == "1" then
    -- search quest-starter
    if quests[id]["start"] and not meta["qlogid"] then
      -- units
      if quests[id]["start"]["U"] then
        for _, unit in pairs(quests[id]["start"]["U"]) do
          meta = meta or {}
          meta["layer"] = meta["layer"] or 4
          meta["texture"] = pfQuestConfig.path.."\\img\\available_c"
          maps = pfDatabase:SearchMobID(unit, meta, maps)
        end
      end

      -- objects
      if quests[id]["start"]["O"] then
        for _, object in pairs(quests[id]["start"]["O"]) do
          meta = meta or {}
          meta["texture"] = pfQuestConfig.path.."\\img\\available_c"
          maps = pfDatabase:SearchObjectID(object, meta, maps)
        end
      end
    end

    -- search quest-ender
    if quests[id]["end"] then
      -- units
      if quests[id]["end"]["U"] then
        for _, unit in pairs(quests[id]["end"]["U"]) do
          meta = meta or {}

          if meta["qlogid"] then
            local _, _, _, _, _, complete = compat.GetQuestLogTitle(meta["qlogid"])
            complete = complete or GetNumQuestLeaderBoards(meta["qlogid"]) == 0 and true or nil
            if complete then
              meta["texture"] = pfQuestConfig.path.."\\img\\complete_c"
            else
              meta["texture"] = pfQuestConfig.path.."\\img\\complete"
            end
          else
            meta["texture"] = pfQuestConfig.path.."\\img\\complete_c"
          end
          maps = pfDatabase:SearchMobID(unit, meta, maps)
        end
      end

      -- objects
      if quests[id]["end"]["O"] then
        for _, object in pairs(quests[id]["end"]["O"]) do
          meta = meta or {}

          if meta["qlogid"] then
            local _, _, _, _, _, complete = compat.GetQuestLogTitle(meta["qlogid"])
            complete = complete or GetNumQuestLeaderBoards(meta["qlogid"]) == 0 and true or nil
            if complete then
              meta["texture"] = pfQuestConfig.path.."\\img\\complete_c"
            else
              meta["texture"] = pfQuestConfig.path.."\\img\\complete"
            end
          else
            meta["texture"] = pfQuestConfig.path.."\\img\\complete_c"
          end

          maps = pfDatabase:SearchObjectID(object, meta, maps)
        end
      end
    end
  end

  local parse_obj = {
    ["U"] = {},
    ["O"] = {},
    ["I"] = {},
  }

  -- If QuestLogID is given, scan and add all finished objectives to blacklist
  if meta["qlogid"] then
    local objectives = GetNumQuestLeaderBoards(meta["qlogid"])
    local _, _, _, _, _, complete = compat.GetQuestLogTitle(meta["qlogid"])

    if objectives and not complete then
      for i=1, objectives, 1 do
        local text, type, done = GetQuestLogLeaderBoard(i, meta["qlogid"])

        -- spawn data
        if type == "monster" then
          local i, j, monsterName, objNum, objNeeded = strfind(text, pfUI.api.SanitizePattern(QUEST_MONSTERS_KILLED))
          for id in pairs(pfDatabase:GetIDByName(monsterName, "units")) do
            parse_obj["U"][id] = ( objNum + 0 >= objNeeded + 0 or done ) and "DONE" or "PROG"
          end

          for id in pairs(pfDatabase:GetIDByName(monsterName, "objects")) do
            parse_obj["O"][id] = ( objNum + 0 >= objNeeded + 0 or done ) and "DONE" or "PROG"
          end
        end

        -- item data
        if type == "item" then
          local i, j, itemName, objNum, objNeeded = strfind(text, pfUI.api.SanitizePattern(QUEST_OBJECTS_FOUND))
          for id in pairs(pfDatabase:GetIDByName(itemName, "items")) do
            parse_obj["I"][id] = ( objNum + 0 >= objNeeded + 0 or done ) and "DONE" or "PROG"
          end
        end
      end
    end
  end

  -- search quest-objectives
  if quests[id]["obj"] then

    if meta["qlogid"] then
      local _, _, _, _, _, complete = compat.GetQuestLogTitle(meta["qlogid"])
      if complete then return maps end
    end

    -- units
    if quests[id]["obj"]["U"] then
      for _, unit in pairs(quests[id]["obj"]["U"]) do
        if not parse_obj["U"][unit] or parse_obj["U"][unit] ~= "DONE" then
          meta = meta or {}
          meta["texture"] = nil
          maps = pfDatabase:SearchMobID(unit, meta, maps)
        end
      end
    end

    -- objects
    if quests[id]["obj"]["O"] then
      for _, object in pairs(quests[id]["obj"]["O"]) do
        if not parse_obj["O"][object] or parse_obj["O"][object] ~= "DONE" then
          meta = meta or {}
          meta["texture"] = nil
          meta["layer"] = 2
          maps = pfDatabase:SearchObjectID(object, meta, maps)
        end
      end
    end

    -- items
    if quests[id]["obj"]["I"] then
      for _, item in pairs(quests[id]["obj"]["I"]) do
        if not parse_obj["I"][item] or parse_obj["I"][item] ~= "DONE" then
          meta = meta or {}
          meta["texture"] = nil
          meta["layer"] = 2
          maps = pfDatabase:SearchItemID(item, meta, maps)
        end
      end
    end
  end

  return maps
end

-- SearchQuest
-- Scans for all quests with a specified name
-- Adds map nodes for each objective and involved unit
-- Returns its map table
function pfDatabase:SearchQuest(quest, meta, partial)
  local maps = {}

  for id in pairs(pfDatabase:GetIDByName(quest, "quests", partial)) do
    maps = pfDatabase:SearchQuestID(id, meta, maps)
  end

  return maps
end

-- SearchQuests
-- Scans for all available quests
-- Adds map nodes for each quest starter and ender
-- Returns its map table
function pfDatabase:SearchQuests(meta, maps)
  local level, minlvl, maxlvl, race, class, prof
  local maps = maps or {}
  local meta = meta or {}

  local plevel = UnitLevel("player")
  local pfaction = UnitFactionGroup("player")
  if pfaction == "Horde" then
    pfaction = "H"
  elseif pfaction == "Alliance" then
    pfaction = "A"
  else
    pfaction = "GM"
  end

  local _, race = UnitRace("player")
  local prace = pfDatabase:GetBitByRace(race)
  local _, class = UnitClass("player")
  local pclass = pfDatabase:GetBitByClass(class)

  local currentQuests = {}
  for id=1, GetNumQuestLogEntries() do
    local title = compat.GetQuestLogTitle(id)
    currentQuests[title] = true
  end

  for id in pairs(quests) do
    minlvl = quests[id]["min"] or quests[id]["lvl"] or plevel
    maxlvl = quests[id]["lvl"] or quests[id]["min"] or plevel

    if pfDB.quests.loc[id] and currentQuests[pfDB.quests.loc[id].T] then
      -- hide active quest
    elseif pfQuest_history[id] then
      -- hide completed quests
    elseif quests[id]["pre"] and not pfQuest_history[quests[id]["pre"]] then
      -- hide missing pre-quests
    elseif quests[id]["race"] and not ( bit.band(quests[id]["race"], prace) == prace ) then
      -- hide non-available quests for your race
    elseif quests[id]["class"] and not ( bit.band(quests[id]["class"], pclass) == pclass ) then
      -- hide non-available quests for your class
    elseif quests[id]["lvl"] and quests[id]["lvl"] < plevel - 9 and pfQuest_config["showlowlevel"] == "0" then
      -- hide lowlevel quests
    elseif quests[id]["lvl"] and quests[id]["lvl"] > plevel + 10 then
      -- hide highlevel quests
    elseif quests[id]["min"] and quests[id]["min"] > plevel + 3 then
      -- hide highlevel quests
    elseif math.abs(minlvl - maxlvl) >= 30 and pfQuest_config["showfestival"] == "0" then
      -- hide event quests
    elseif minlvl > plevel and pfQuest_config["showhighlevel"] == "0" then
      -- hide level+3 quests
    elseif quests[id]["skill"] and not pfDatabase:PlayerHasSkill(quests[id]["skill"]) then
      -- hide non-available quests for your class
    else
      -- set metadata
      meta["quest"] = ( pfDB.quests.loc[id] and pfDB.quests.loc[id].T ) or UNKNOWN
      meta["questid"] = id
      meta["texture"] = pfQuestConfig.path.."\\img\\available_c"

      meta["qlvl"] = quests[id]["lvl"]
      meta["qmin"] = quests[id]["min"]

      meta["vertex"] = { 0, 0, 0 }
      meta["layer"] = 3

      -- tint high level quests red
      if minlvl > plevel then
        meta["texture"] = pfQuestConfig.path.."\\img\\available"
        meta["vertex"] = { 1, .6, .6 }
        meta["layer"] = 2
      end

      -- tint low level quests grey
      if maxlvl + 9 < plevel then
        meta["texture"] = pfQuestConfig.path.."\\img\\available"
        meta["vertex"] = { 1, 1, 1 }
        meta["layer"] = 2
      end

      -- treat big difference in level requirements as daily quests
      if math.abs(minlvl - maxlvl) >= 30 then
        meta["texture"] = pfQuestConfig.path.."\\img\\available"
        meta["vertex"] = { .2, .8, 1 }
        meta["layer"] = 2
      end

      -- iterate over all questgivers
      if quests[id]["start"] then
        -- units
        if quests[id]["start"]["U"] then
          for _, unit in pairs(quests[id]["start"]["U"]) do
            if units[unit] and strfind(units[unit]["fac"] or pfaction, pfaction) then
              maps = pfDatabase:SearchMobID(unit, meta, maps)
            end
          end
        end

        -- objects
        if quests[id]["start"]["O"] then
          for _, object in pairs(quests[id]["start"]["O"]) do
            if objects[object] and strfind(objects[object]["fac"] or pfaction, pfaction) then
              maps = pfDatabase:SearchObjectID(object, meta, maps)
            end
          end
        end
      end
    end
  end
end

function pfDatabase:FormatQuestText(questText)
  questText = string.gsub(questText, "$[Nn]", UnitName("player"))
  questText = string.gsub(questText, "$[Cc]", strlower(UnitClass("player")))
  questText = string.gsub(questText, "$[Rr]", strlower(UnitRace("player")))
  questText = string.gsub(questText, "$[Bb]", "\n")
  -- UnitSex("player") returns 2 for male and 3 for female
  -- that's why there is an unused capture group around the $[Gg]
  return string.gsub(questText, "($[Gg])(.+):(.+);", "%"..UnitSex("player"))
end

-- GetQuestIDs
-- Try to guess the quest ID based on the questlog ID
-- automatically runs a deep scan if no result was found.
-- Returns possible quest IDs
function pfDatabase:GetQuestIDs(qid, deep)
  if GetQuestLink then
    local questLink = GetQuestLink(qid)
      if questLink then
      local _, _, id = strfind(questLink, "|c.*|Hquest:([%d]+):([%d]+)|h%[(.*)%]|h|r")
      if id then return { [1] = tonumber(id) } end
    end
  end

  local oldID = GetQuestLogSelection()
  SelectQuestLogEntry(qid)
  local text, objective = GetQuestLogQuestText()
  local title, level, _, header = compat.GetQuestLogTitle(qid)
  SelectQuestLogEntry(oldID)

  local _, race = UnitRace("player")
  local prace = pfDatabase:GetBitByRace(race)
  local _, class = UnitClass("player")
  local pclass = pfDatabase:GetBitByClass(class)

  local best = 0
  local results = {}

  for id, data in pairs(pfDB["quests"]["loc"]) do
    local score = 0

    if quests[id] and (data.T == title or ( deep and strsub(pfDatabase:FormatQuestText(pfDB.quests.loc[id]["O"]),0,10) == strsub(objective,0,10))) then
      if quests[id]["lvl"] == level then
        score = score + 1
      end

      if pfDB.quests.loc[id]["O"] == objective then
        score = score + 2
      end

      if quests[id]["race"] and ( bit.band(quests[id]["race"], prace) == prace ) then
        score = score + 4
      end

      if quests[id]["class"] and ( bit.band(quests[id]["class"], pclass) == pclass ) then
        score = score + 4
      end

      local dbtext = strsub(pfDatabase:FormatQuestText(pfDB.quests.loc[id]["D"]),0,10)
      local qstext = strsub(text,0,10)

      if pfDatabase:CompareString(dbtext, qstext) < 0.1 then
        score = score + 8
      end

      if score > best then best = score end
      results[score] = results[score] or {}
      table.insert(results[score], id)
    end
  end

  return results[best] or ( not deep and pfDatabase:GetQuestIDs(qid, 1) or {} )
end

-- browser search related defaults and values
pfDatabase.lastSearchQuery = ""
pfDatabase.lastSearchResults = {["items"] = {}, ["quests"] = {}, ["objects"] = {}, ["units"] = {}}

-- BrowserSearch
-- Search for a list of IDs of the specified `searchType` based on if `query` is
-- part of the name or ID of the database entry it is compared against.
--
-- `query` must be a string. If the string represents a number, the search is
-- based on IDs, otherwise it compares names.
--
-- `searchType` must be one of these strings: "items", "quests", "objects" or
-- "units"
--
-- Returns a table and an integer, the latter being the element count of the
-- former. The table contains the ID as keys for the name of the search result.
-- E.g.: {{[5] = "Some Name", [231] = "Another Name"}, 2}
-- If the query doesn't satisfy the minimum search length requiered for its
-- type (number/string), the favourites for the `searchType` are returned.
function pfDatabase:BrowserSearch(query, searchType)
  local queryLength = strlen(query) -- needed for some checks
  local queryNumber = tonumber(query) -- if nil, the query is NOT a number
  local results = {} -- save results
  local resultCount = 0; -- count results

  -- Set the DB to be searched
  local minChars = 3
  local minInts = 1
  if (queryLength >= minChars) or (queryNumber and (queryLength >= minInts)) then -- make sure this is no fav display
    if ((queryLength > minChars) or (queryNumber and (queryLength > minInts)))
       and (pfDatabase.lastSearchQuery ~= "" and queryLength > strlen(pfDatabase.lastSearchQuery))
    then
      -- there are previous search results to use
      local searchDatabase = pfDatabase.lastSearchResults[searchType]
      -- iterate the last search
      for id, _ in pairs(searchDatabase) do
        local dbLocale = pfDB[searchType]["loc"][id]
        if (dbLocale) then
          local compare
          local search = query
          if (queryNumber) then
            -- do number search
            compare = tostring(id)
          else
            -- do name search
            search = strlower(query)
            if (searchType == "quests") then
              compare = strlower(dbLocale["T"])
            else
              compare = strlower(dbLocale)
            end
          end
          -- search and save on match
          if (strfind(compare, search)) then
            results[id] = dbLocale
            resultCount = resultCount + 1
          end
        end
      end
      return results, resultCount
    else
      -- no previous results, search whole DB
      if (queryNumber) then
        results = pfDatabase:GetIDByIDPart(query, searchType)
      else
        results = pfDatabase:GetIDByName(query, searchType, true)
      end
      local resultCount = 0
      for _,_ in pairs(results) do
        resultCount = resultCount + 1
      end
      return results, resultCount
    end
  else
    -- minimal search length not satisfied, reset search results and return favourites
    return pfBrowser_fav[searchType], -1
  end
end

local function LoadCustomData(always)
  -- table.getn doesn't work here :/
  local icount = 0
  for _,_ in pairs(pfQuest_server["items"]) do
    icount = icount + 1
  end

  if icount > 0 or always then
    for id, name in pairs(pfQuest_server["items"]) do
      pfDB["items"]["loc"][id] = name
    end
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffccpf|cffffffffQuest: |cff33ffcc" .. icount .. "|cffffffff " .. pfQuest_Loc["custom items loaded."])
  end
end

local pfServerScan = CreateFrame("Frame", "pfServerItemScan", UIParent)
pfServerScan:SetWidth(200)
pfServerScan:SetHeight(100)
pfServerScan:SetPoint("TOP", 0, 0)
pfServerScan:Hide()

pfServerScan.scanID = 1
pfServerScan.max = 1000000
pfServerScan.perloop = 100

pfServerScan.header = pfServerScan:CreateFontString("Caption", "LOW", "GameFontWhite")
pfServerScan.header:SetFont(STANDARD_TEXT_FONT, 13, "OUTLINE")
pfServerScan.header:SetJustifyH("CENTER")
pfServerScan.header:SetPoint("CENTER", 0, 0)

pfServerScan:RegisterEvent("VARIABLES_LOADED")
pfServerScan:SetScript("OnEvent", function()
  pfQuest_server = pfQuest_server or { }
  pfQuest_server["items"] = pfQuest_server["items"] or {}
  LoadCustomData()
end)

pfServerScan:SetScript("OnHide", function()
  ItemRefTooltip:Show()
  LoadCustomData(true)
end)

pfServerScan:SetScript("OnShow", function()
  this.scanID = 1
  pfQuest_server["items"] = {}
  DEFAULT_CHAT_FRAME:AddMessage("|cff33ffccpf|cffffffffQuest: " .. pfQuest_Loc["Server scan started..."])
end)

pfServerScan:SetScript("OnUpdate", function()
  if this.scanID >= this.max then
    this:Hide()
    return
  end

  -- scan X items per update
  for i=this.scanID,this.scanID+this.perloop do
    pfServerScan.header:SetText(pfQuest_Loc["Scanning server for items..."] .. " " .. floor(100*i/this.max) .. "%")
    local link = "item:" .. i .. ":0:0:0"

    ItemRefTooltip:SetOwner(UIParent, "ANCHOR_PRESERVE")
    ItemRefTooltip:SetHyperlink(link)

    if ItemRefTooltipTextLeft1 and ItemRefTooltipTextLeft1:IsVisible() then
      local name = ItemRefTooltipTextLeft1:GetText()
      ItemRefTooltip:Hide()

      if not pfDB["items"]["loc"][i] then
        pfQuest_server["items"][i] = name
      end
    end
  end

  this.scanID = this.scanID+this.perloop
end)

function pfDatabase:ScanServer()
  pfServerScan:Show()
end
