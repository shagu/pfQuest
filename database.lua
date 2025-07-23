-- multi api compat
local compat = pfQuestCompat

pfDatabase = { icons = {} }

local loc = GetLocale()
local dbs = { "items", "quests", "quests-itemreq", "objects", "units", "zones", "professions", "areatrigger", "refloot" }
local noloc = { items = true, quests = true, objects = true, units = true }

pfDB.locales = {
  ["enUS"] = "English",
  ["koKR"] = "Korean",
  ["frFR"] = "French",
  ["deDE"] = "German",
  ["zhCN"] = "Chinese (Simplified)",
  ["zhTW"] = "Chinese (Traditional)",
  ["esES"] = "Spanish",
  ["ruRU"] = "Russian",
  ["ptBR"] = "Portuguese",
}

-- Patch databases to further expansions
local function patchtable(base, diff)
  for k, v in pairs(diff) do
    if type(v) == "string" and v == "_" then
      base[k] = nil
    else
      base[k] = v
    end
  end
end

-- Return the best cluster point for a coordiante table
local best, neighbors = { index = 1, neighbors = 0 }, 0
local cache, cacheindex = {}
local ymin, ymax, xmin, ymax
local function getcluster(tbl, name)
  local count = 0
  best.index, best.neighbors = 1, 0
  cacheindex = string.format("%s:%s", name, table.getn(tbl))

  -- calculate new cluster if nothing is cached
  if not cache[cacheindex] then
    for index, data in pairs(tbl) do
      -- precalculate the limits, and compare directly.
      -- This way is much faster than the math.abs function.
      xmin, xmax = data[1] - 5, data[1] + 5
      ymin, ymax = data[2] - 5, data[2] + 5
      neighbors = 0
      count = count + 1

      for _, compare in pairs(tbl) do
        if compare[1] > xmin and compare[1] < xmax and compare[2] > ymin and compare[2] < ymax then
          neighbors = neighbors + 1
        end
      end

      if neighbors > best.neighbors then
        best.neighbors = neighbors
        best.index = index
      end
    end

    cache[cacheindex] = { tbl[best.index][1] + .001, tbl[best.index][2] + .001, count }
  end

  return cache[cacheindex][1], cache[cacheindex][2], cache[cacheindex][3]
end

-- Detects if a non indexed table is empty
local function isempty(tbl)
  for _ in pairs(tbl) do return end
  return true
end

-- Returns the levenshtein distance between two strings
-- based on: https://gist.github.com/Badgerati/3261142
local len1, len2, cost, best
local levcache = {}
local function lev(str1, str2, limit)
  if levcache[str1..":"..str2] then
    return levcache[str1..":"..str2]
  end

  len1, len2, cost = string.len(str1), string.len(str2), 0

  -- abort early on empty strings
  if len1 == 0 then
    return len2
  elseif len2 == 0 then
    return len1
  elseif str1 == str2 then
    return 0
  end

  -- initialise the base matrix
  local matrix = {}
  for i = 0, len1, 1 do
    matrix[i] = { [0] = i }
  end

  for j = 0, len2, 1 do
    matrix[0][j] = j
  end

  -- levenshtein algorithm
  for i = 1, len1, 1 do
    best = limit

    for j = 1, len2, 1 do
      cost = string.byte(str1,i) == string.byte(str2,j) and 0 or 1
      matrix[i][j] = math.min(matrix[i-1][j] + 1, matrix[i][j-1] + 1, matrix[i-1][j-1] + cost)

      if limit and matrix[i][j] < limit then
        best = matrix[i][j]
      end
    end

    if limit and best >= limit then
      levcache[str1..":"..str2] = limit
      return limit
    end
  end

  -- return the levenshtein distance
  levcache[str1..":"..str2] = matrix[len1][len2]
  return matrix[len1][len2]
end

local loc_core, loc_update
for _, exp in pairs({ "-tbc", "-wotlk" }) do
  for _, db in pairs(dbs) do
    if pfDB[db]["data"..exp] then
      patchtable(pfDB[db]["data"], pfDB[db]["data"..exp])
    end

    for loc, _ in pairs(pfDB.locales) do
      if pfDB[db][loc] and pfDB[db][loc..exp] then
        loc_update = pfDB[db][loc..exp] or pfDB[db]["enUS"..exp]
        patchtable(pfDB[db][loc], loc_update)
      end
    end
  end

  loc_core = pfDB["professions"][loc] or pfDB["professions"]["enUS"]
  loc_update = pfDB["professions"][loc..exp] or pfDB["professions"]["enUS"..exp]
  if loc_update then patchtable(loc_core, loc_update) end

  if pfDB["minimap"..exp] then patchtable(pfDB["minimap"], pfDB["minimap"..exp]) end
  if pfDB["meta"..exp] then patchtable(pfDB["meta"], pfDB["meta"..exp]) end
end

-- detect installed locales
for key, name in pairs(pfDB.locales) do
  if not pfDB["quests"][key] then pfDB.locales[key] = nil end
end

-- detect localized databases
pfDatabase.dbstring = ""
for id, db in pairs(dbs) do
  -- assign existing locale
  pfDB[db]["loc"] = pfDB[db][loc] or pfDB[db]["enUS"] or {}
  pfDatabase.dbstring = pfDatabase.dbstring .. " |cffcccccc[|cffffffff" .. db .. "|cffcccccc:|cff33ffcc" .. ( pfDB[db][loc] and loc or "enUS" ) .. "|cffcccccc]"
end

-- track all previous meta selections on login
pfDatabase.tracking = CreateFrame("Frame", "pfDatabaseMetaTracking", UIParent)
pfDatabase.tracking:RegisterEvent("PLAYER_ENTERING_WORLD")
pfDatabase.tracking:SetScript("OnEvent", function()
  -- break on empty config
  if not pfQuest_track then return end

  -- enable all tracked
  for name, data in pairs(pfQuest_track) do
    pfDatabase:SearchMetaRelation(data[1], data[2])
  end

  -- remove events
  this:UnregisterAllEvents()
end)

-- track questitems to maintain object requirements
pfDatabase.itemlist = CreateFrame("Frame", "pfDatabaseQuestItemTracker", UIParent)
pfDatabase.itemlist.update = 0
pfDatabase.itemlist.db = {}
pfDatabase.itemlist.db_tmp = {}
pfDatabase.itemlist.registry = {}
pfDatabase.TrackQuestItemDependency = function(self, item, qid)
  self.itemlist.registry[item] = qid
  self.itemlist.update = GetTime() + .5
  self.itemlist:Show()
end

pfDatabase.itemlist:RegisterEvent("BAG_UPDATE")
pfDatabase.itemlist:SetScript("OnEvent", function()
  this.update = GetTime() + .5
  this:Show()
end)

pfDatabase.itemlist:SetScript("OnUpdate", function()
  if GetTime() < this.update then return end

  -- remove obsolete registry entries
  for item, qid in pairs(this.registry) do
    if not pfQuest.questlog[qid] then
      this.registry[item] = nil
    end
  end

  -- save and clean previous items
  local previous = this.db
  this.db = {}

  -- fill new item db with bag items
  for bag = 4, 0, -1 do
    for slot = 1, GetContainerNumSlots(bag) do
      local link = GetContainerItemLink(bag,slot)
      local _, _, parse = strfind((link or ""), "(%d+):")
      if parse then
        local item = GetItemInfo(parse)
        if item then this.db[item] = true end
      end
    end
  end

  -- fill new item db with equipped items
  for i=1,19 do
    if GetInventoryItemLink("player", i) then
      local _, _, link = string.find(GetInventoryItemLink("player", i), "(item:%d+:%d+:%d+:%d+)");
      local item = GetItemInfo(link)
      if item then this.db[item] = true end
    end
  end

  -- find new items
  for item in pairs(this.db) do
    if not previous[item] and this.registry[item] then
      pfQuest.questlog[this.registry[item]] = nil
      pfQuest:UpdateQuestlog()
    end
  end

  -- find removed items
  for item in pairs(previous) do
    if not this.db[item] and this.registry[item] then
      pfQuest.questlog[this.registry[item]] = nil
      pfQuest:UpdateQuestlog()
    end
  end

  this:Hide()
end)

-- check for unlocalized servers and fallback to enUS databases when the server
-- returns item names that are different to the database ones. (check via. Hearthstone)
CreateFrame("Frame", "pfQuestLocaleCheck", UIParent):SetScript("OnUpdate", function()
  -- throttle to to one item per second
  if ( this.tick or 0) > GetTime() then return else this.tick = GetTime() + .1 end

  if not this.dryrun then
    -- give the server one iteration to return the itemname.
    -- this is required for clients that use a clean wdb folder.
    ItemRefTooltip:SetOwner(UIParent, "ANCHOR_PRESERVE")
    ItemRefTooltip:SetHyperlink("item:6948:0:0:0")
    ItemRefTooltip:Hide()
    this.dryrun = true
    return
  end

  -- try to load hearthstone into tooltip
  ItemRefTooltip:SetOwner(UIParent, "ANCHOR_PRESERVE")
  ItemRefTooltip:SetHyperlink("item:6948:0:0:0")

  -- check tooltip for results
  if ItemRefTooltip:IsShown() and ItemRefTooltipTextLeft1 and ItemRefTooltipTextLeft1:IsVisible() then
    -- once the tooltip shows up, read the name and hide it
    local name = ItemRefTooltipTextLeft1:GetText()
    ItemRefTooltip:Hide()

    -- check for noloc
    if name and name ~= "" and pfDB["items"][loc] and pfDB["items"][loc][6948] then
      if not strfind(name, pfDB["items"][loc][6948], 1) then
        pfDatabase.dbstring = ""
        for id, db in pairs(dbs) do
          -- assign existing locale and update dbstring
          pfDB[db]["loc"] = noloc[db] and pfDB[db]["enUS"] or pfDB[db][loc] or {}
          pfDatabase.dbstring = pfDatabase.dbstring .. " |cffcccccc[|cffffffff" .. db .. "|cffcccccc:|cff33ffcc" .. ( noloc[db] and "enUS" or loc ) .. "|cffcccccc]"
        end
      end

      pfDatabase.localized = true
      this:Hide()
    end
  end

  -- set a detection timeout to 15 seconds
  if GetTime() > 15 then
    pfDatabase.localized = true
    this:Hide()
  end
end)

-- sanity check the databases
if isempty(pfDB["quests"]["loc"]) then
  CreateFrame("Frame"):SetScript("OnUpdate", function()
    if GetTime() < 3 then return end
    DEFAULT_CHAT_FRAME:AddMessage("|cffff5555 !! |cffffaaaaWrong version of |cff33ffccpf|cffffffffQuest|cffffaaaa detected.|cffff5555 !!")
    DEFAULT_CHAT_FRAME:AddMessage("|cffffccccThe language pack does not match the gameclient's language.")
    DEFAULT_CHAT_FRAME:AddMessage("|cffffccccYou'd either need to pick the complete or the " .. GetLocale().."-version.")
    DEFAULT_CHAT_FRAME:AddMessage("|cffffccccFor more details, see: https://shagu.org/pfQuest")
    this:Hide()
  end)
end

-- add database shortcuts
local items, units, objects, quests, zones, refloot, itemreq, areatrigger, professions
pfDatabase.Reload = function()
  items = pfDB["items"]["data"]
  units = pfDB["units"]["data"]
  objects = pfDB["objects"]["data"]
  quests = pfDB["quests"]["data"]
  zones = pfDB["zones"]["data"]
  refloot = pfDB["refloot"]["data"]
  itemreq = pfDB["quests-itemreq"]["data"]
  areatrigger = pfDB["areatrigger"]["data"]
  professions = pfDB["professions"]["loc"]
end

pfDatabase.Reload()

local bitraces = {
  [1] = "Human",
  [2] = "Orc",
  [4] = "Dwarf",
  [8] = "NightElf",
  [16] = "Scourge",
  [32] = "Tauren",
  [64] = "Gnome",
  [128] = "Troll"
}

-- append with playable races by expansion
if pfQuestCompat.client > 11200 then
  bitraces[512] = "BloodElf"
  bitraces[1024] = "Draenei"
end

-- make it public for extensions
pfDB.bitraces = bitraces

local bitclasses = {
  [1] = "WARRIOR",
  [2] = "PALADIN",
  [4] = "HUNTER",
  [8] = "ROGUE",
  [16] = "PRIEST",
  [32] = "DEATHKNIGHT",
  [64] = "SHAMAN",
  [128] = "MAGE",
  [256] = "WARLOCK",
  [1024] = "DRUID"
}

-- make it public for extensions
pfDB.bitclasses = bitclasses

function pfDatabase:IsFriendly(id)
  if id and units[id] and units[id].fac then
    local faction = string.lower(UnitFactionGroup("player") or "")
    faction = faction == "horde" and "H" or faction == "alliance" and "A" or "UNKNOWN"

    if string.find(units[id].fac, faction) then
      return true
    end
  end

  return false
end

function pfDatabase:BuildQuestDescription(meta)
  if not meta.title or not meta.quest or not meta.QTYPE then return meta.description end

  if meta.QTYPE == "NPC_START" then
    return string.format(pfQuest_Loc["Speak with |cff33ffcc%s|r to obtain |cffffcc00[!]|cff33ffcc %s|r"], (meta.spawn or UNKNOWN), (meta.quest or UNKNOWN))
  elseif meta.QTYPE == "OBJECT_START" then
    return string.format(pfQuest_Loc["Interact with |cff33ffcc%s|r to obtain |cffffcc00[!]|cff33ffcc %s|r"], (meta.spawn or UNKNOWN), (meta.quest or UNKNOWN))
  elseif meta.QTYPE == "NPC_END" then
    return string.format(pfQuest_Loc["Speak with |cff33ffcc%s|r to complete |cffffcc00[?]|cff33ffcc %s|r"], (meta.spawn or UNKNOWN), (meta.quest or UNKNOWN))
  elseif meta.QTYPE == "OBJECT_END" then
    return string.format(pfQuest_Loc["Interact with |cff33ffcc%s|r to complete |cffffcc00[?]|cff33ffcc %s|r"], (meta.spawn or UNKNOWN), (meta.quest or UNKNOWN))
  elseif meta.QTYPE == "UNIT_OBJECTIVE" then
    if pfDatabase:IsFriendly(meta.spawnid) then
      return string.format(pfQuest_Loc["Talk to |cff33ffcc%s|r"], (meta.spawn or UNKNOWN))
    else
      return string.format(pfQuest_Loc["Kill |cff33ffcc%s|r"], (meta.spawn or UNKNOWN))
    end
  elseif meta.QTYPE == "UNIT_OBJECTIVE_ITEMREQ" then
    return string.format(pfQuest_Loc["Use |cff33ffcc%s|r on |cff33ffcc%s|r"], (meta.itemreq or UNKNOWN), (meta.spawn or UNKNOWN))
  elseif meta.QTYPE == "OBJECT_OBJECTIVE" then
    return string.format(pfQuest_Loc["Interact with |cff33ffcc%s|r"], (meta.spawn or UNKNOWN))
  elseif meta.QTYPE == "OBJECT_OBJECTIVE_ITEMREQ" then
    return string.format(pfQuest_Loc["Use |cff33ffcc%s|r at |cff33ffcc%s|r"], (meta.itemreq or UNKNOWN), (meta.spawn or UNKNOWN))
  elseif meta.QTYPE == "ITEM_OBJECTIVE_LOOT" then
    return string.format(pfQuest_Loc["Loot |cff33ffcc[%s]|r from |cff33ffcc%s|r"], (meta.item or UNKNOWN), (meta.spawn or UNKNOWN))
  elseif meta.QTYPE == "ITEM_OBJECTIVE_USE" then
    return string.format(pfQuest_Loc["Loot and/or Use |cff33ffcc[%s]|r from |cff33ffcc%s|r"], (meta.item or UNKNOWN), (meta.spawn or UNKNOWN))
  elseif meta.QTYPE == "AREATRIGGER_OBJECTIVE" then
    return string.format(pfQuest_Loc["Explore |cff33ffcc%s|r"], (meta.spawn or UNKNOWN))
  elseif meta.QTYPE == "ZONE_OBJECTIVE" then
    return string.format(pfQuest_Loc["Use Quest Item at |cff33ffcc%s|r"], (meta.spawn or UNKNOWN))
  end
end

-- ShowExtendedTooltip
-- Draws quest informations into a tooltip
function pfDatabase:ShowExtendedTooltip(id, tooltip, parent, anchor, offx, offy)
  local tooltip = tooltip or GameTooltip
  local parent = parent or this
  local anchor = anchor or "ANCHOR_LEFT"

  tooltip:SetOwner(parent, anchor, offx, offy)

  local locales = pfDB["quests"]["loc"][id]
  local data = pfDB["quests"]["data"][id]

  if locales then
    tooltip:SetText((locales["T"] or UNKNOWN), .3, 1, .8)
    tooltip:AddLine(" ")
  else
    tooltip:SetText(UNKNOWN, .3, 1, .8)
  end

  if data then
    -- scan for active quests
    local queststate = pfQuest_history[id] and 2 or 0
    queststate = pfQuest.questlog[id] and 1 or queststate

    if queststate == 0 then
      tooltip:AddLine(pfQuest_Loc["You don't have this quest."] .. "\n\n", 1, .5, .5)
    elseif queststate == 1 then
      tooltip:AddLine(pfQuest_Loc["You are on this quest."] .. "\n\n", 1, 1, .5)
    elseif queststate == 2 then
      tooltip:AddLine(pfQuest_Loc["You already did this quest."] .. "\n\n", .5, 1, .5)
    end

    -- quest start
    if data["start"] then
      for key, db in pairs({["U"]="units", ["O"]="objects", ["I"]="items"}) do
        if data["start"][key] then
          local entries = ""
          for _, id in pairs(data["start"][key]) do
            entries = entries .. (entries == "" and "" or ", ") .. ( pfDB[db]["loc"][id] or UNKNOWN )
          end

          tooltip:AddDoubleLine(pfQuest_Loc["Quest Start"]..":", entries, 1,1,1, 1,1,.8)
        end
      end
    end

    -- quest end
    if data["end"] then
      for key, db in pairs({["U"]="units", ["O"]="objects"}) do
        if data["end"][key] then
          local entries = ""
          for _, id in ipairs(data["end"][key]) do
            entries = entries .. (entries == "" and "" or ", ") .. ( pfDB[db]["loc"][id] or UNKNOWN )
          end

          tooltip:AddDoubleLine(pfQuest_Loc["Quest End"]..":", entries, 1,1,1, 1,1,.8)
        end
      end
    end
  end

  if locales then
    -- obectives
    if locales["O"] and locales["O"] ~= "" then
      tooltip:AddLine(" ")
      tooltip:AddLine(pfDatabase:FormatQuestText(locales["O"]),1,1,1,true)
    end

    -- details
    if locales["D"] and locales["D"] ~= "" then
      tooltip:AddLine(" ")
      tooltip:AddLine(pfDatabase:FormatQuestText(locales["D"]),.6,.6,.6,true)
    end
  end

  -- add levels
  if data then
    if data["lvl"] or data["min"] then
      tooltip:AddLine(" ")
    end
    if data["lvl"] then
      local questlevel = tonumber(data["lvl"])
      local color = pfQuestCompat.GetDifficultyColor(questlevel)
      tooltip:AddLine("|cffffffff" .. pfQuest_Loc["Quest Level"] .. ": |r" .. questlevel, color.r, color.g, color.b)
    end
    if data["min"] then
      local questlevel = tonumber(data["min"])
      local color = pfQuestCompat.GetDifficultyColor(questlevel)
      tooltip:AddLine("|cffffffff" .. pfQuest_Loc["Required Level"] .. ": |r" .. questlevel, color.r, color.g, color.b)
    end
  end

  tooltip:Show()
end

-- GetPlayerSkill
-- Returns false if the player doesn't have the required skill, or their rank if they do
function pfDatabase:GetPlayerSkill(skill)
  if not professions[skill] then return false end

  for i=0,GetNumSkillLines() do
    local skillName, _, _, skillRank = GetSkillLineInfo(i)
    if skillName == professions[skill] then
      return skillRank
    end
  end

  return false
end

-- GetBitByRace
-- Returns bit of the current race
function pfDatabase:GetBitByRace(model)
  -- scan for regular bitmasks
  for bit, v in pairs(bitraces) do
    if model == v then return bit end
  end

  -- return alliance/horde racemask as fallback for unknown races
  return UnitFactionGroup("player") == "Alliance" and 77 or 178
end

-- GetBitByClass
-- Returns bit of the current class
function pfDatabase:GetBitByClass(class)
  for bit, v in pairs(bitclasses) do
    if class == v then return bit end
  end
end

-- GetHexDifficultyColor
-- Returns a string with the difficulty color of the given level
function pfDatabase:GetHexDifficultyColor(level, force)
  if force and UnitLevel("player") < level then
    return "|cffff5555"
  else
    local c = pfQuestCompat.GetDifficultyColor(level)
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
          if units[startUnitId] and units[startUnitId]["fac"] and factionMap[units[startUnitId]["fac"]] then
            questStartRaceMask = bit.bor(factionMap[units[startUnitId]["fac"]])
          end
        end
      end

      -- get quest object starter faction
      if (quests[id]["start"]["O"]) then
        for _, startObjectId in ipairs(quests[id]["start"]["O"]) do
          if objects[startObjectId] and objects[startObjectId]["fac"] and factionMap[objects[startObjectId]["fac"]] then
            questStartRaceMask = bit.bor(factionMap[objects[startObjectId]["fac"]])
          end
        end
      end

      -- apply starter faction as racemask
      if raceMask == 0 and questStartRaceMask > 0 and questStartRaceMask ~= raceMask then
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
function pfDatabase:GetIDByName(name, db, partial, server)
  if not pfDB[db] then return nil end
  local ret = {}

  for id, loc in pairs(pfDB[db]["loc"]) do
    if db == "quests" then loc = loc["T"] end

    local custom = server and pfQuest_server[db] and pfQuest_server[db][id] or not server
    if loc and name then
      if partial == true and strfind(strlower(loc), strlower(name), 1, true) and custom then
        ret[id] = loc
      elseif partial == "LOWER" and strlower(loc) == strlower(name) and custom then
        ret[id] = loc
      elseif loc == name and custom then
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
    if count > bestscore or ( count == 0 and bestscore == 0 ) then
      bestscore = count
      bestmap   = map
    end
  end

  return bestmap or nil, bestscore or nil
end

-- SearchAreaTriggerID
-- Scans for all mobs with a specified ID
-- Adds map nodes for each and returns its map table
function pfDatabase:SearchAreaTriggerID(id, meta, maps, prio)
  if not areatrigger[id] or not areatrigger[id]["coords"] then return maps end

  local maps = maps or {}
  local prio = prio or 1

  for _, data in pairs(areatrigger[id]["coords"]) do
    local x, y, zone = unpack(data)

    if zone and zone > 0 then
      -- add all gathered data
      meta = meta or {}
      meta["spawn"] = pfQuest_Loc["Exploration Mark"]
      meta["spawnid"] = id
      meta["item"] = nil

      meta["title"] = meta["quest"] or meta["item"] or meta["spawn"]
      meta["zone"]  = zone
      meta["x"]     = x
      meta["y"]     = y

      meta["level"] = pfQuest_Loc["N/A"]
      meta["spawntype"] = pfQuest_Loc["Trigger"]
      meta["respawn"] = pfQuest_Loc["N/A"]

      maps[zone] = maps[zone] and maps[zone] + prio or prio
      pfMap:AddNode(meta)
    end
  end

  return maps
end

-- SearchMobID
-- Scans for all mobs with a specified ID
-- Adds map nodes for each and returns its map table
function pfDatabase:SearchMobID(id, meta, maps, prio)
  if not units[id] or not units[id]["coords"] then return maps end

  local maps = maps or {}
  local prio = prio or 1

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
      meta["spawntype"] = pfQuest_Loc["Unit"]
      meta["respawn"] = respawn > 0 and SecondsToTime(respawn)

      maps[zone] = maps[zone] and maps[zone] + prio or prio
      pfMap:AddNode(meta)
    end
  end

  return maps
end

-- Search MetaRelation
-- Scans for all entries within the specified meta name
-- Adds map nodes for each and returns its map table
-- query = { relation-name, relation-min, relation-max }
local alias = {
  ["flightmaster"] = "flight",
  ["taxi"] = "flight",
  ["flights"] = "flight",
  ["raremobs"] = "rares",
}

local skill = {
  ["herbs"] = true,
  ["mines"] = true,
  ["rares"] = true,
  ["chests"] = true,
}

function pfDatabase:SearchMetaRelation(query, meta, show)
  local maps = {}

  -- abort on invalid queries
  if not query.name then return end

  -- convert track name aliases
  local track = alias[query.name] or query.name

  if pfDB["meta"] and pfDB["meta"][track] then
    -- check which faction should be searched
    local faction = query.faction and string.lower(query.faction) or string.lower(UnitFactionGroup("player"))
    faction = faction == "horde" and "H" or faction == "alliance" and "A" or ""

    -- iterate over all tracking entries
    for entry, value in pairs(pfDB["meta"][track]) do
      if skill[track] and tonumber(query.min) and tonumber(value) < tonumber(query.min) then
        -- required skill is lower than the queried one
      elseif skill[track] and tonumber(query.max) and tonumber(value) > tonumber(query.max) then
        -- required skill is lower than the queried one
      elseif not skill[track] and not string.find(value, faction) then
        -- faction is different from the queried one
      else
        local prev_icon = meta.icon
        local object = pfDB["objects"]["loc"][math.abs(entry)]
        local unit = pfDB["units"]["loc"][entry]

        -- handle custom tracking icons
        if pfQuest_config.trackingicons == "0" then
          meta.icon = nil
        elseif entry < 0 and object and pfDatabase.icons[object] then
          meta.icon = pfDatabase.icons[object]
        elseif entry > 0 and unit and pfDatabase.icons[unit] then
          meta.icon = pfDatabase.icons[unit]
        end

        if entry < 0 then
          pfDatabase:SearchObjectID(math.abs(entry), meta, maps)
        else
          pfDatabase:SearchMobID(entry, meta, maps)
        end

        meta.icon = prev_icon
      end
    end
  end

  return maps
end

-- Search TrackMeta
-- Scans for all entries within the specified list
-- Adds map nodes for each, saves it to the persistent
-- tracking variable per character and returns a map table
function pfDatabase:TrackMeta(list, state)
  local list = alias[list] and alias[list] or list
  local identifier = "TRACK_"..string.upper(list)

  local meta = {
    ["addon"] = identifier,
    ["icon"] = pfQuestConfig.path.."\\img\\tracking\\"..list,
  }

  local query = {
    name = list
  }

  local maps = nil

  -- hide previous tracks
  pfQuest_track[list] = nil
  pfMap:DeleteNode(identifier)
  pfMap:UpdateNodes()

  -- break here if nothing should be tracked
  if not state then return end

  -- add extended state values to query
  -- this is used for min/max values
  if type(state) == "table" then
    for k, v in pairs(state) do
      query[k] = v
    end
  end

  -- save and perform the actual meta tracking
  pfQuest_track[list] = { query, meta }
  local maps = pfDatabase:SearchMetaRelation(query, meta)

  -- remove invalid results
  if not maps then pfQuest_track[list] = nil end

  -- return map results
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

-- SearchZoneID
-- Scans for all zones with a specific ID
-- Add nodes to the center of that location
function pfDatabase:SearchZoneID(id, meta, maps, prio)
  if not zones[id] then return maps end

  local maps = maps or {}
  local prio = prio or 1

  local zone, width, height, x, y, ex, ey = unpack(zones[id])

  if zone > 0 then
    maps[zone] = maps[zone] and maps[zone] + prio or prio

    meta = meta or {}
    meta["spawn"] = pfDB.zones.loc[id] or UNKNOWN
    meta["spawnid"] = id

    meta["title"] = meta["quest"] or meta["item"] or meta["spawn"]
    meta["zone"]  = zone
    meta["level"] = "N/A"
    meta["spawntype"] = pfQuest_Loc["Area/Zone"]
    meta["respawn"] = "N/A"
    meta["x"]     = x
    meta["y"]     = y

    pfMap:AddNode(meta)
    return maps
  end

  return maps
end

-- SearchZone
-- Scans for all zones with a specified name
-- Adds map nodes for each and returns its map table
function pfDatabase:SearchZone(obj, meta, partial)
  local maps = {}

  for id in pairs(pfDatabase:GetIDByName(obj, "zones", partial)) do
    if zones[id] then
      maps = pfDatabase:SearchZoneID(id, meta, maps)
    end
  end

  return maps
end

function pfDatabase:SearchObjectSkill(id)
  if not id or not tonumber(id) then return end
  local skill, caption = nil, nil

  if (pfDB["meta"]["herbs"][-id]) then
    skill = pfDB["meta"]["herbs"][-id]
    caption = pfQuest_Loc["Herbalism"]
  elseif (pfDB["meta"]["mines"][-id]) then
    skill = pfDB["meta"]["mines"][-id]
    caption = pfQuest_Loc["Mining"]
  end

  return skill, caption
end

-- Scans for all objects with a specified ID
-- Adds map nodes for each and returns its map table
function pfDatabase:SearchObjectID(id, meta, maps, prio)
  if not objects[id] or not objects[id]["coords"] then return maps end

  local skill, caption = pfDatabase:SearchObjectSkill(id)
  local maps = maps or {}
  local prio = prio or 1

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

      meta["level"] = skill and string.format("%s [%s]", skill, caption) or nil
      meta["spawntype"] = pfQuest_Loc["Object"]
      meta["respawn"] = respawn and SecondsToTime(respawn)

      maps[zone] = maps[zone] and maps[zone] + prio or prio
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
  if not quests[id] then return end
  local maps = maps or {}
  local meta = meta or {}

  meta["questid"] = id
  meta["quest"] = pfDB.quests.loc[id] and pfDB.quests.loc[id].T
  meta["qlvl"] = quests[id]["lvl"]
  meta["qmin"] = quests[id]["min"]

  -- clear previous unified quest nodes
  if meta.quest then
    pfMap.unifiedcache[meta.quest] = {}
  end

  if pfQuest_config["currentquestgivers"] == "1" then
    -- search quest-starter
    if quests[id]["start"] and not meta["qlogid"] then
      -- units
      if quests[id]["start"]["U"] then
        for _, unit in pairs(quests[id]["start"]["U"]) do
          meta = meta or {}
          meta["QTYPE"] = "NPC_START"
          meta["layer"] = meta["layer"] or 4
          meta["texture"] = pfQuestConfig.path.."\\img\\available_c"
          maps = pfDatabase:SearchMobID(unit, meta, maps, 0)
        end
      end

      -- objects
      if quests[id]["start"]["O"] then
        for _, object in pairs(quests[id]["start"]["O"]) do
          meta = meta or {}
          meta["QTYPE"] = "OBJECT_START"
          meta["texture"] = pfQuestConfig.path.."\\img\\available_c"
          maps = pfDatabase:SearchObjectID(object, meta, maps, 0)
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
          meta["QTYPE"] = "NPC_END"

          maps = pfDatabase:SearchMobID(unit, meta, maps, 0)
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

          meta["QTYPE"] = "OBJECT_END"

          maps = pfDatabase:SearchObjectID(object, meta, maps, 0)
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
    if complete then return maps end

    if objectives then
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
    local skip_objects
    local skip_creatures

    -- item requirements
    if quests[id]["obj"]["IR"] then
      local requirement

      for _, item in pairs(quests[id]["obj"]["IR"]) do
        if itemreq[item] then
          requirement = pfDB["items"]["loc"][item] or UNKNOWN

          for object, spell in pairs(itemreq[item]) do
            if object < 0 then
              -- gameobject
              meta["texture"] = nil
              meta["layer"] = 2
              meta["QTYPE"] = "OBJECT_OBJECTIVE_ITEMREQ"
              meta.itemreq = requirement

              skip_objects = skip_objects or {}
              skip_objects[math.abs(object)] = true

              pfDatabase:TrackQuestItemDependency(requirement, id)
              if pfDatabase.itemlist.db[requirement] then
                maps = pfDatabase:SearchObjectID(math.abs(object), meta, maps)
              end
            elseif object > 0 then
              -- creature
              meta["texture"] = nil
              meta["layer"] = 2
              meta["QTYPE"] = "UNIT_OBJECTIVE_ITEMREQ"
              meta.itemreq = requirement

              skip_creatures = skip_creatures or {}
              skip_creatures[math.abs(object)] = true

              pfDatabase:TrackQuestItemDependency(requirement, id)
              if pfDatabase.itemlist.db[requirement] then
                maps = pfDatabase:SearchMobID(math.abs(object), meta, maps)
              end
            end
          end
        end
      end
    end

    -- units
    if quests[id]["obj"]["U"] then
      for _, unit in pairs(quests[id]["obj"]["U"]) do
        if not parse_obj["U"][unit] or parse_obj["U"][unit] ~= "DONE" then
          if not skip_creatures or not skip_creatures[unit] then
            meta = meta or {}
            meta["texture"] = nil
            meta["QTYPE"] = "UNIT_OBJECTIVE"
            maps = pfDatabase:SearchMobID(unit, meta, maps)
          end
        end
      end
    end

    -- objects
    if quests[id]["obj"]["O"] then
      for _, object in pairs(quests[id]["obj"]["O"]) do
        if not parse_obj["O"][object] or parse_obj["O"][object] ~= "DONE" then
          if not skip_objects or not skip_objects[object] then
            meta = meta or {}
            meta["texture"] = nil
            meta["layer"] = 2
            meta["QTYPE"] = "OBJECT_OBJECTIVE"
            maps = pfDatabase:SearchObjectID(object, meta, maps)
          end
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
          if parse_obj["I"][item] then
            meta["QTYPE"] = "ITEM_OBJECTIVE_LOOT"
          else
            meta["QTYPE"] = "ITEM_OBJECTIVE_USE"
          end
          maps = pfDatabase:SearchItemID(item, meta, maps)
        end
      end
    end

    -- areatrigger
    if quests[id]["obj"]["A"] then
      for _, areatrigger in pairs(quests[id]["obj"]["A"]) do
        meta = meta or {}
        meta["texture"] = nil
        meta["layer"] = 2
        meta["QTYPE"] = "AREATRIGGER_OBJECTIVE"
        maps = pfDatabase:SearchAreaTriggerID(areatrigger, meta, maps)
      end
    end

    -- zones
    if quests[id]["obj"]["Z"] then
      for _, zone in pairs(quests[id]["obj"]["Z"]) do
        meta = meta or {}
        meta["texture"] = nil
        meta["layer"] = 2
        meta["QTYPE"] = "ZONE_OBJECTIVE"
        maps = pfDatabase:SearchZoneID(zone, meta, maps)
      end
    end
  end

  -- prepare unified quest location markers
  local addon = meta["addon"] or "PFDB"
  if pfMap.nodes[addon] then
    for map in pairs(pfMap.nodes[addon]) do
      if meta.quest and pfMap.unifiedcache[meta.quest] and pfMap.unifiedcache[meta.quest][map] then
        for hash, data in pairs(pfMap.unifiedcache[meta.quest][map]) do
          meta = data.meta
          meta["title"] = meta["quest"]
          meta["cluster"] = true
          meta["zone"]  = map

          local icon = pfQuest_config["clustermono"] == "1" and "_mono" or ""

          if meta.item then
            meta["x"], meta["y"], meta["priority"] = getcluster(data.coords, meta["quest"]..hash..map)
            meta["texture"] = pfQuestConfig.path.."\\img\\cluster_item" .. icon
            pfMap:AddNode(meta, true)
          elseif meta.spawntype and meta.spawntype == pfQuest_Loc["Unit"] and meta.spawn and not meta.itemreq then
            meta["x"], meta["y"], meta["priority"] = getcluster(data.coords, meta["quest"]..hash..map)
            meta["texture"] = pfQuestConfig.path.."\\img\\cluster_mob" .. icon
            pfMap:AddNode(meta, true)
          else
            meta["x"], meta["y"], meta["priority"] = getcluster(data.coords, meta["quest"]..hash..map)
            meta["texture"] = pfQuestConfig.path.."\\img\\cluster_misc" .. icon
            pfMap:AddNode(meta, true)
          end
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

function pfDatabase:QuestFilter(id, plevel, pclass, prace)
  -- hide active quest
  if pfQuest.questlog[id] then return end

  -- hide completed quests
  if pfQuest_history[id] then return end

  -- hide broken quests without names
  if not pfDB.quests.loc[id] or not pfDB.quests.loc[id].T then return end

  -- hide missing pre-quests
  if quests[id]["pre"] then
    -- check all pre-quests for one to be completed
    local one_complete = nil
    for _, prequest in pairs(quests[id]["pre"]) do
      if pfQuest_history[prequest] then
        one_complete = true
      end
    end

    -- hide if none of the pre-quests has been completed
    if not one_complete then return end
  end

  -- hide non-available quests for your race
  if quests[id]["race"] and not ( bit.band(quests[id]["race"], prace) == prace ) then return end

  -- hide non-available quests for your class
  if quests[id]["class"] and not ( bit.band(quests[id]["class"], pclass) == pclass ) then return end

  -- hide non-available quests for your profession
  if quests[id]["skill"] and not pfDatabase:GetPlayerSkill(quests[id]["skill"]) then return end

  -- hide lowlevel quests
  if quests[id]["lvl"] and quests[id]["lvl"] < plevel - 4 and pfQuest_config["showlowlevel"] == "0" then return end

  -- hide highlevel quests (or show those that are 3 levels above)
  if quests[id]["min"] and quests[id]["min"] > plevel + ( pfQuest_config["showhighlevel"] == "1" and 3 or 0 ) then return end

  -- hide event quests
  if quests[id]["event"] and pfQuest_config["showfestival"] == "0" then return end

  return true
end

-- SearchQuests
-- Scans for all available quests
-- Adds map nodes for each quest starter and ender
-- Returns its map table
function pfDatabase:SearchQuests(meta, maps)
  local level, minlvl, maxlvl, race, class, prof, festival
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

  for id in pairs(quests) do
    if pfDatabase:QuestFilter(id, plevel, pclass, prace) then
      -- set metadata
      meta["quest"] = ( pfDB.quests.loc[id] and pfDB.quests.loc[id].T ) or UNKNOWN
      meta["questid"] = id
      meta["texture"] = pfQuestConfig.path.."\\img\\available_c"

      meta["qlvl"] = quests[id]["lvl"]
      meta["qmin"] = quests[id]["min"]

      meta["vertex"] = { 0, 0, 0 }
      meta["layer"] = 3

      -- tint high level quests red
      if quests[id]["min"] and quests[id]["min"] > plevel then
        meta["texture"] = pfQuestConfig.path.."\\img\\available"
        meta["vertex"] = { 1, .6, .6 }
        meta["layer"] = 2
      end

      -- tint low level quests grey
      if quests[id]["lvl"] and quests[id]["lvl"] + 10 < plevel then
        meta["texture"] = pfQuestConfig.path.."\\img\\available"
        meta["vertex"] = { 1, 1, 1 }
        meta["layer"] = 2
      end

      -- tint event quests as blue
      if quests[id]["event"] then
        meta["texture"] = pfQuestConfig.path.."\\img\\available"
        meta["vertex"] = { .2, .8, 1 }
        meta["layer"] = 2
      end

      -- iterate over all questgivers
      if quests[id]["start"] then
        -- units
        if quests[id]["start"]["U"] then
          meta["QTYPE"] = "NPC_START"
          for _, unit in pairs(quests[id]["start"]["U"]) do
            if units[unit] and strfind(units[unit]["fac"] or pfaction, pfaction) then
              maps = pfDatabase:SearchMobID(unit, meta, maps)
            end
          end
        end

        -- objects
        if quests[id]["start"]["O"] then
          meta["QTYPE"] = "OBJECT_START"
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

-- AddCustomIcon
-- Helper function to add custom tracking node icons
--   id: negative for objects, positive for units
--   img: path to the image that is appended to root
--   root: optional, default: "Interface\\AddOns\\pfQuest"
function pfDatabase:AddCustomIcon(id, img, root)
  if not id or not img then return end

  root = root and root .. "\\" or pfQuestConfig.path .. "\\"

  local object = pfDB["objects"]["loc"][math.abs(id)]
  local unit = pfDB["units"]["loc"][math.abs(id)]

  if id < 0 and object then
    pfDatabase.icons[object] = root .. img
  elseif id > 0 and unit then
    pfDatabase.icons[unit] = root .. img
  end
end

function pfDatabase:FormatQuestText(questText)
  questText = string.gsub(questText, "$[Nn]", UnitName("player"))
  questText = string.gsub(questText, "$[Cc]", strlower(UnitClass("player")))
  questText = string.gsub(questText, "$[Rr]", strlower(UnitRace("player")))
  questText = string.gsub(questText, "$[Bb]", "\n")
  -- UnitSex("player") returns 2 for male and 3 for female
  -- that's why there is an unused capture group around the $[Gg]
  return string.gsub(questText, "($[Gg])([^:]+):([^;]+);", "%"..UnitSex("player"))
end

-- GetQuestIDs
-- Try to guess the quest ID based on the questlog ID
-- Returns possible quest IDs
function pfDatabase:GetQuestIDs(qid)
  if GetQuestLink then
    local questLink = GetQuestLink(qid)
      if questLink then
      local _, _, id = strfind(questLink, "|c.*|Hquest:([%d]+):([-]?[%d]+)|h%[(.*)%]|h|r")
      if id then return { [1] = tonumber(id) } end
    end
  end

  local oldID = GetQuestLogSelection()
  SelectQuestLogEntry(qid)
  local text, objective = GetQuestLogQuestText()
  local title, level, _, header = compat.GetQuestLogTitle(qid)
  SelectQuestLogEntry(oldID)

  if header or not title then return end
  local identifier = title .. ":" .. ( level or "") .. ":" .. ( objective or "") .. ":" .. ( text or "")

  -- always make sure the quest-cache exists
  pfQuest_questcache = pfQuest_questcache or {}

  if pfQuest_questcache[identifier] and pfQuest_questcache[identifier][1] then
    return pfQuest_questcache[identifier]
  end

  local _, race = UnitRace("player")
  local prace = pfDatabase:GetBitByRace(race)
  local _, class = UnitClass("player")
  local pclass = pfDatabase:GetBitByClass(class)

  local best = 0
  local results = {}

  local tcount = 0
  -- check if multiple quests share the same name
  for id, data in pairs(pfDB["quests"]["loc"]) do
    if quests[id] and data.T == title then tcount = tcount + 1 end
  end

  -- no title was found, run levenshtein on titles
  if tcount == 0 and title then
    local tlen = string.len(title)
    local tscore, tbest, ttitle = nil, math.min(tlen/2, 5), nil
    for id, data in pairs(pfDB["quests"]["loc"]) do
      if quests[id] and data.T then
        tscore = lev(data.T, title, tbest)
        if tscore < tbest then
          tbest = tscore
          ttitle = data.T
        end
      end
    end

    if not ttitle then
      -- return early on unknown quests.
      if not pfDatabase.localized then
        -- skip cache if locale-checks are still running
        return { title }
      else
        -- flag quest as unknown and return
        pfQuest_questcache[identifier] = { title }
        return pfQuest_questcache[identifier]
      end
    else
      -- set title to best result
      title = ttitle
    end
  end

  for id, data in pairs(pfDB["quests"]["loc"]) do
    local score = 0

    if quests[id] and data.T and data.T == title then
      -- low score for same name
      score = 1

      -- check level and set score
      if quests[id]["lvl"] == level then
        score = score + 8
      end

      -- check race and set score
      if quests[id]["race"] and ( bit.band(quests[id]["race"], prace) == prace ) then
        score = score + 8
      end

      -- check class and set score
      if quests[id]["class"] and ( bit.band(quests[id]["class"], pclass) == pclass ) then
        score = score + 8
      end

      -- if multiple quests share the same name, use levenshtein algorithm,
      -- to compare quest text distances in order to estimate the best quest id
      if tcount > 1 then
        -- check objective and calculate score
        score = score + max(24 - lev(pfDatabase:FormatQuestText(pfDB.quests.loc[id]["O"]), objective, 24),0)

        -- check description and calculate score
        score = score + max(24 - lev(pfDatabase:FormatQuestText(pfDB.quests.loc[id]["D"]), text, 24),0)
      end

      if score > best then best = score end
      results[score] = results[score] or {}
      if score > 0 then table.insert(results[score], id) end
    end
  end

  -- cache for next time
  pfQuest_questcache[identifier] = results[best]
  return results[best]
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
pfServerScan.max = 100000
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

local ignore, custom_id, custom_skip = {}, nil, nil
pfServerScan:SetScript("OnUpdate", function()
  if this.scanID >= this.max then
    this:Hide()
    return
  end

  -- scan X items per update
  for i=this.scanID,this.scanID+this.perloop do
    pfServerScan.header:SetText(pfQuest_Loc["Scanning server for items..."] .. " " .. string.format("%.1f",100*i/this.max) .. "%")
    local link = "item:" .. i .. ":0:0:0"

    ItemRefTooltip:SetOwner(UIParent, "ANCHOR_PRESERVE")
    ItemRefTooltip:SetHyperlink(link)

    if ItemRefTooltipTextLeft1 and ItemRefTooltipTextLeft1:IsVisible() then
      local name = ItemRefTooltipTextLeft1:GetText()
      ItemRefTooltip:Hide()

      -- skip-wait for item retrieval
      if name == (RETRIEVING_ITEM_INFO or "") then

        if not ignore[i] then
          if custom_id == i and custom_skip >= 3 then
            -- ignore item and proceed
            ignore[i] = true
          elseif custom_id == i then
            -- try again up to 3 times
            custom_skip = custom_skip + 1
            return
          elseif custom_id ~= i then
            -- give it another try
            custom_id = i
            custom_skip = 0
            return
          end
        end
      end

      -- assign item to custom server table
      if not pfDB["items"]["loc"][i] and not ignore[i] then
        pfQuest_server["items"][i] = name
      end
    end
  end

  this.scanID = this.scanID+this.perloop
end)

function pfDatabase:ScanServer()
  pfServerScan:Show()
end

function pfDatabase:QueryServer()
  -- break here on incompatible versions
  if not QueryQuestsCompleted then
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffccpf|cffffffffQuest: Option is not available on your server.")
    return
  end

  QueryQuestsCompleted()  -- Send the request to the server

  local frame = CreateFrame("Frame")  -- Create a new frame
  frame:RegisterEvent("QUEST_QUERY_COMPLETE")  -- Register the event on the frame

  local function OnQuestQueryComplete()
    frame:UnregisterEvent("QUEST_QUERY_COMPLETE")  -- Unregister the event once it's triggered

    -- Retrieve completed quests after the QUEST_QUERY_COMPLETE event
    local completedQuests = GetQuestsCompleted()

    if type(completedQuests) == "table" then
      for questID, _ in pairs(completedQuests) do
        pfQuest_history[questID] = { time(), UnitLevel("player") }
      end

      -- Reset all quest markers after processing completed quests
      pfQuest:ResetAll()
    elseif completedQuests == nil then
      -- Handle the case where GetQuestsCompleted() returned nil
      print("Error: GetQuestsCompleted() returned nil.")
    else
      -- Handle the case where GetQuestsCompleted() did not return a valid table
      print("Error: GetQuestsCompleted() did not return a valid table. Value: ", completedQuests)
    end
  end

  frame:SetScript("OnEvent", OnQuestQueryComplete)  -- Set the event handler
end
