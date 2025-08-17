#!/usr/bin/lua
-- depends on luasql
-- map pngs with alpha channel generated with:
-- `convert $file  -transparent white -resize '100x100!' $file`

local debugsql = {
  ["areatrigger"] = { "Using only client-data to find areatrigger locations" },
  --
  ["units"] = { "Iterate over all creatures using mangos data" },
  ["units_faction"] = { "Using mangos and client-data to find unit faction" },
  ["units_coords"] = { "Using mangos and client-data to find unit locations" },
  ["units_coords_pool"] = { "Only applies to CMaNGOS(TBC) to find pooled unit locations" },
  ["units_event"] = { "Using mangos data to find spawns from events" },
  ["units_event_map_object"] = { "Using mangos data to determine map based on object requirements associated with event" },
  ["units_event_spell"] = { "Using mangos data to find spells associated with spawn" },
  ["units_event_spell_map_object"] = { "Using mangos data to determine map based on objects associated with spawn spells" },
  ["units_event_spell_map_item"] = { "Using mangos data to determine map based on items associated with spawn spells" },
  ["units_summon_fixed"] = { "Using mangos data to find units that summon others and use their map with fixed spawn positions" },
  ["units_summon_unknown"] = { "Using mangos data to find units that summon others and use their coordinates as target spawn positions" },
  --
  ["objects"] = { "Iterate over all gameobjects using mangos data" },
  ["objects_faction"] = { "Using mangos and client-data to find object faction" },
  ["objects_coords"] = { "Using mangos and client-data to find unit locations" },
  --
  ["items"] = { "Iterate over all items using mangos data" },
  ["items_container"] = { "Using mangos data to find items that are looted from other items" },
  ["items_unit"] = { "Using mangos data to find units that drop an item" },
  ["items_object"] = { "Using mangos data to find objects that drop an item" },
  ["items_reference"] = { "Using mangos data to query for shared loot lists" },
  ["items_vendor"] = { "Using mangos data to find vendors for items" },
  ["items_vendortemplate"] = { "Using mangos data to find vendor templates of the item" },
  --
  ["refloot"] = { "Using mangos data to find shared loot lists" },
  ["refloot_unit"] = { "Using mangos data to find units for shared loot" },
  ["refloot_object"] = { "Using mangos data to find objects for shared loot" },
  --
  ["quests"] = { "Using mangos data to iterate over all quests" },
  ["quests_events"] = { "Using mangos data to detect event quests" },
  ["quests_eventscreature"] = { "Using mangos data to detect event quests based on creature" },
  ["quests_eventsobjects"] = { "Using mangos data to detect event quests based on objects" },
  ["quests_prequests"] = { "Using mangos data to detect pre-quests based on other quests next entries" },
  ["quests_prequestchain"] = { "Using mangos data to detect quest-chains based on other quests next entries" },
  ["quests_questspellobject"] = { "Using mangos data find objects associated with quest_template spell requirements" },
  ["quests_credit"] = { "Only applies to CMaNGOS(TBC) to find units that give shared credit to the quest" },
  ["quests_item"] = { "Using mangos data to scan through all items with spell requirements" },
  ["quests_itemspell"] = { "Using mangos data to scan through spells that apply to the given item" },
  ["quests_itemspellcreature"] = { "Using mangos data to find all creatures that are a spell target of the given item" },
  ["quests_itemspellobject"] = { "Using mangos data to find all objects that are a spell target of the given item" },
  ["quests_itemspellscript"] = { "Using mangos data to find all scripts that are a spell target of the given item" },
  ["quests_itemobject"] = { "Using mangos database and client data to search for object that can be used via item" },
  ["quests_itemcreature"] = { "Using mangos database and client data to search for creature that can be target of item" },
  ["quests_areatrigger"] = { "Using mangos data to find associated areatriggers" },
  ["quests_starterunit"] = { "Using mangos data to search for quest starter units" },
  ["quests_starterobject"] = { "Using mangos data to search for quest starter objects" },
  ["quests_starteritem"] = { "Using mangos data to search for quest starter items" },
  ["quests_enderunit"] = { "Using mangos data to search for quest ender units" },
  ["quests_enderobject"] = { "Using mangos data to search for quest ender objects" },
  --
  ["zones"] = { "Using client data to read zone data" },
  --
  ["minimap"] = { "Using client data to read minimap zoom levels" },
  --
  ["meta_rares"] = { "Using client and mangos data to find rare mobs" },
  ["meta_npcs"] = { "Using client and mangos data to find npcs" },
  ["meta_objects"] = { "Using client and mangos data to find objects" },
  ["meta_openable"] = { "Using client and mangos data to find chests, herbs and mines" },
  --
  ["locales_unit"] = { "Using mangos data to find unit translations" },
  ["locales_object"] = { "Using mangos data to find object translations" },
  ["locales_item"] = { "Using mangos data to find item translations" },
  ["locales_quest"] = { "Using mangos data to find quest translations" },
  ["locales_profession"] = { "Using client and mangos data to find profession translations" },
  ["locales_zone"] = { "Using client and mangos data to find zone translations" },
}

-- limit all sql loops
local limit = nil
function debug(name)
  -- count sql debugs
  debugsql[name][2] = debugsql[name][2] or 0
  debugsql[name][2] = debugsql[name][2] + 1

  -- abort here when no debug limit is set
  if not limit then return nil end
  return debugsql[name][2] > limit or nil
end

function debug_statistics()
  for name, data in pairs(debugsql) do
    local count = data[2] or 0
    if count == 0 then
      print("WARNING: \27[1m\27[31m" .. count .. "\27[0m \27[1m" .. name .. "\27[0m \27[2m-- " .. data[1] .. "\27[0m")
    end
    debugsql[name][2] = nil
  end
end

-- local associations
local all_locales = {
  ["enUS"] = 0,
  ["koKR"] = 1,
  ["frFR"] = 2,
  ["deDE"] = 3,
  ["zhCN"] = 4,
  ["zhTW"] = 5,
  ["esES"] = 6,
  ["ruRU"] = 8,
  ["ptBR"] = 10,
}

local config = {
  -- known expansions and their config
  expansions = {
    {
      name = "vanilla",
      core = "vmangos",
      database = "vmangos",
      locales = all_locales,
      custom = false,
    },
    {
      name = "tbc",
      core = "cmangos",
      database = "cmangos-tbc",
      locales = all_locales,
      custom = false,
    },
  },

  -- core-type database column glue tables
  -- every table column name that differs
  -- from cmangos should be listed here
  cores = {
    ["cmangos"] = setmetatable({}, { __index = function(tab,key)
      local value = tostring(key)
      rawset(tab,key,value)
      return value
    end }),

    ["vmangos"] = {
      ["Id"] = "entry",
      ["Entry"] = "entry",
      ["Faction"] = "faction",
      ["Name"] = "name",
      ["MinLevel"] = "level_min",
      ["MaxLevel"] = "level_max",
      ["Rank"] = "rank",
      ["RequiresSpellFocus"] = "requiresSpellFocus",
      ["dbscripts_on_event"] = "event_scripts",
      ["VendorTemplateId"] = "vendor_id",
      ["NpcFlags"] = "npc_flags",
      ["EffectTriggerSpell"] = "effectTriggerSpell",
      ["Map"] = "map_bound",
      ["startquest"] = "start_quest",
      ["targetEntry"] = "target_entry",
    },
  }
}

if false then
  -- add turtle settings to expansions
  table.insert(config.expansions, {
    name = "turtle",
    core = "vmangos",
    database = "turtle",
    locales = { ["enUS"] = 0 },
    custom = true,
  })
end

do -- map lookup functions
  maps = {}
  package.path = './pngLua/?.lua;' .. package.path
  require("png")

  function isFile(name)
    if type(name)~="string" then return false end
    if not ( os.rename(name,name) and true or false ) then return false end
    local f = io.open(name)
    if not f then return false end
    f:close()
    return true
  end

  function isValidMap(map,x,y,expansion)
    local id = map..expansion

    -- load map if required
    if not maps[id] then
      local preferred = string.format("maps/%s/%s.png", expansion, map)
      local fallback = string.format("maps/%s.png", map)

      if isFile(preferred) then
        maps[id] = pngImage(preferred)
      elseif isFile(fallback) then
        maps[id] = pngImage(fallback)
      end
    end

    -- no mapfile means valid map
    if not maps[id] then return true end

    -- error handling
    if not maps[id].getPixel then return false end
    if x == 0 or y == 0 then return false end

    -- check pixel alpha
    local pixel = maps[id]:getPixel(x,y)
    if pixel and pixel.A and pixel.A > 0 then
      return true
    else
      return false
    end
  end
end

do -- helper functions
  function round(input, places)
    if not places then places = 0 end
    if type(input) == "number" and type(places) == "number" then
      local pow = 1
      for i = 1, places do pow = pow * 10 end
      local result = math.floor(input * pow + 0.5) / pow
      return result == math.floor(result) and math.floor(result) or result
    end
  end

  function sanitize(str)
    str = string.gsub(str, "\\", "\\\\")
    str = string.gsub(str, "\"", "\\\"")
    str = string.gsub(str, "\'", "\\\'")
    str = string.gsub(str, "\r", "")
    str = string.gsub(str, "\n", "")
    return str
  end

  -- http://lua-users.org/wiki/SortedIteration
  function __genOrderedIndex( t )
    local orderedIndex = {}
    for key in pairs(t) do
      table.insert( orderedIndex, key )
    end
    table.sort( orderedIndex )
    return orderedIndex
  end

  function orderedNext(t, state)
    local key = nil
    if state == nil then
      t.__orderedIndex = __genOrderedIndex( t )
      key = t.__orderedIndex[1]
    else
      for i = 1,#t.__orderedIndex do
        if t.__orderedIndex[i] == state then
          key = t.__orderedIndex[i+1]
        end
      end
    end

    if key then
      return key, t[key]
    end

    t.__orderedIndex = nil
    return
  end

  function opairs(t)
      return orderedNext, t, nil
  end
  --

  function tblsize(tbl)
    local count = 0
    for _ in pairs(tbl) do
      count = count + 1
    end
    return count
  end

  function smalltable(tbl)
    local size = tblsize(tbl)
    if size > 10 then return end
    if size < 1 then return end

    for i=1, size do
      if not tbl[i] then return end
      if type(tbl[i]) == "table" then return end
    end

    return true
  end

  function trealsize(tbl)
    local count = 0
    for _ in pairs(tbl) do
      count = count + 1
    end
    return count
  end

  local dupehashes = {}
  function removedupes(tbl)
    dupehashes = {}
    local output = {}

    -- [count] = { x, y, zone, respawn }
    for k, coords in pairs(tbl) do
      local hash = ""
      for k, v in pairs(coords) do
        hash = hash .. v
      end

      if not dupehashes[hash] then
        dupehashes[hash] = true
        table.insert(output, coords)
      end
    end

    return output
  end

  -- return true if the base table or any of its subtables
  -- has different values than the new table
  function isdiff(new, base)
    -- different types
    if type(new) ~= type(base) then
      return true
    end

    -- different values
    if type(new) ~= "table" then
      if new ~= base then
        return true
      end
    end

    -- recursive on tables
    if type(new) == "table" then
      for k, v in pairs(new) do
        local result = isdiff(new[k], base[k])
        if result then return true end
      end
    end

    return nil
  end

  -- create a new table with only those indexes that are
  -- either different or non-existing in the base table
  function tablesubstract(new, base)
    local result = {}

    -- changed value
    for k, v in pairs(new) do
      if new[k] and ( not base or not base[k] ) then
        -- write new entries
        result[k] = new[k]
      elseif new[k] and base[k] and isdiff(new[k], base[k]) then
        -- write different entries
        result[k] = new[k]
      end
    end

    -- remove obsolete entries
    if base then
      for k, v in pairs(base) do
        if base[k] and not new[k] then
          result[k] = "_"
        end
      end
    end

    return result
  end

  function serialize(file, name, tbl, spacing, flat)
    local closehandle = type(file) == "string"
    local file = type(file) == "string" and io.open(file, "w") or file
    local spacing = spacing or ""

    if tblsize(tbl) == 0 then
      file:write(string.format("%s%s = {}%s\n", spacing, name, (spacing == "" and "" or ",")))
    else
      file:write(spacing .. name .. " = {\n")

      for k, v in opairs(tbl) do
        local prefix = "["..k.."]"
        if type(k) == "string" then
          prefix = "[\""..k.."\"]"
        end

        if type(v) == "table" and flat then
          file:write("  "..spacing..prefix .. " = {},\n")
        elseif type(v) == "table" and smalltable(v) then
          local init
          local line = spacing.."  "..prefix.." = { "
          for _, v in pairs(v) do
            line = line .. (init and ", " or "") .. (type(v) == "string" and "\""..v.."\"" or v)
            if not init then
              init = true
            end
          end
          line = line .. " },\n"
          file:write(line)

        elseif type(v) == "table" then
          serialize(file, prefix, v, spacing .. "  ")
        elseif type(v) == "string" then
          file:write("  "..spacing..prefix .. " = " .. "\"" .. v .. "\",\n")
        elseif type(v) == "number" then
          file:write("  "..spacing..prefix .. " = " .. v .. ",\n")
        end
      end

      file:write(spacing.."}" .. (not closehandle and "," or "") .. "\n")
    end

    if closehandle then file:close() end
  end
end

local pfDB = {}
for id, settings in pairs(config.expansions) do
  print("Extracting: " .. settings.name)

  local expansion = settings.name
  local db = settings.database
  local core = settings.core
  local locales = settings.locales

  local C = config.cores[core]

  local idcolumns = core == "vmangos" and { "id", "id2", "id3", "id4" } or { "id" }
  local exp = expansion == "vanilla" and "" or "-"..expansion
  local data = "data".. exp

  do -- database connection
    luasql = require("luasql.mysql").mysql()
    mysql = luasql:connect(settings.database, "mangos", "mangos", "127.0.0.1")
  end

  do -- database query functions
    function GetAreaTriggerCoords(id)
      local areatrigger = {}
      local ret = {}

      local sql = [[
        SELECT * FROM pfquest.AreaTrigger_]]..expansion..[[ LEFT JOIN pfquest.WorldMapArea_]]..expansion..[[
        ON ( pfquest.WorldMapArea_]]..expansion..[[.mapID = pfquest.AreaTrigger_]]..expansion..[[.MapID
          AND pfquest.WorldMapArea_]]..expansion..[[.x_min < pfquest.AreaTrigger_]]..expansion..[[.X
          AND pfquest.WorldMapArea_]]..expansion..[[.x_max > pfquest.AreaTrigger_]]..expansion..[[.X
          AND pfquest.WorldMapArea_]]..expansion..[[.y_min < pfquest.AreaTrigger_]]..expansion..[[.Y
          AND pfquest.WorldMapArea_]]..expansion..[[.y_max > pfquest.AreaTrigger_]]..expansion..[[.Y
          AND pfquest.WorldMapArea_]]..expansion..[[.areatableID > 0)
        WHERE pfquest.AreaTrigger_]]..expansion..[[.ID = ]] .. id .. [[ ORDER BY areatableID ]]

      local query = mysql:execute(sql)
      while query:fetch(areatrigger, "a") do
        local zone = areatrigger.areatableID
        local x = areatrigger.X
        local y = areatrigger.Y
        local x_max = areatrigger.x_max
        local x_min = areatrigger.x_min
        local y_max = areatrigger.y_max
        local y_min = areatrigger.y_min
        local px, py = 0, 0

        if x and y and x_min and y_min then
          px = round(100 - (y - y_min) / ((y_max - y_min)/100),1)
          py = round(100 - (x - x_min) / ((x_max - x_min)/100),1)
          if isValidMap(zone, round(px), round(py), expansion) then
            local coord = { px, py, tonumber(zone) }
            table.insert(ret, coord)
          end
        end
      end

      return ret
    end

    function GetCustomCoords(m,x,y)
      local worldmap = {}
      local ret = {}

      local sql = [[
        SELECT * FROM pfquest.WorldMapArea_]]..expansion..[[
        WHERE pfquest.WorldMapArea_]]..expansion..[[.mapID = ]] .. m .. [[
          AND pfquest.WorldMapArea_]]..expansion..[[.x_min < ]] .. x .. [[
          AND pfquest.WorldMapArea_]]..expansion..[[.x_max > ]] .. x .. [[
          AND pfquest.WorldMapArea_]]..expansion..[[.y_min < ]] .. y .. [[
          AND pfquest.WorldMapArea_]]..expansion..[[.y_max > ]] .. y .. [[
          AND pfquest.WorldMapArea_]]..expansion..[[.areatableID > 0
        ]]

      local query = mysql:execute(sql)
      while query:fetch(worldmap, "a") do
        local zone = worldmap.areatableID
        local x_max = worldmap.x_max
        local x_min = worldmap.x_min
        local y_max = worldmap.y_max
        local y_min = worldmap.y_min
        local px, py = 0, 0

        if x and y and x_min and y_min then
          px = round(100 - (y - y_min) / ((y_max - y_min)/100),1)
          py = round(100 - (x - x_min) / ((x_max - x_min)/100),1)
          if isValidMap(zone, round(px), round(py), expansion) then
            local coord = { px, py, tonumber(zone), 0 }
            table.insert(ret, coord)
          end
        end
      end

      return ret
    end

    function GetCreatureCoordsPool(id)
      local creature = {}
      local ret = {}

      local sql = [[
        SELECT * FROM creature, creature_spawn_entry, pfquest.WorldMapArea_]]..expansion..[[
        WHERE creature_spawn_entry.entry = ]] .. id .. [[
        AND creature.guid = creature_spawn_entry.guid
        AND ( pfquest.WorldMapArea_]]..expansion..[[.mapID = creature.map
          AND pfquest.WorldMapArea_]]..expansion..[[.x_min < creature.position_x
          AND pfquest.WorldMapArea_]]..expansion..[[.x_max > creature.position_x
          AND pfquest.WorldMapArea_]]..expansion..[[.y_min < creature.position_y
          AND pfquest.WorldMapArea_]]..expansion..[[.y_max > creature.position_y
          AND pfquest.WorldMapArea_]]..expansion..[[.areatableID > 0)
        ORDER BY areatableID, position_x, position_y, spawntimesecsmin ]]

      local query = mysql:execute(sql)
      while query:fetch(creature, "a") do
        local zone = creature.areatableID
        local x = creature.position_x
        local y = creature.position_y
        local x_max = creature.x_max
        local x_min = creature.x_min
        local y_max = creature.y_max
        local y_min = creature.y_min
        local px, py = 0, 0

        if x and y and x_min and y_min then
          px = round(100 - (y - y_min) / ((y_max - y_min)/100),1)
          py = round(100 - (x - x_min) / ((x_max - x_min)/100),1)
          if isValidMap(zone, round(px), round(py), expansion) then
            local coord = { px, py, tonumber(zone), ( tonumber(creature.spawntimesecsmin) > 0 and tonumber(creature.spawntimesecsmin) or 0) }
            table.insert(ret, coord)
          end
        end
      end

      return ret
    end

    function GetCreatureCoords(id)
      local creature = {}
      local ret = {}

      for _, column in pairs(idcolumns) do
        local sql = [[
          SELECT * FROM creature LEFT JOIN pfquest.WorldMapArea_]]..expansion..[[
          ON ( pfquest.WorldMapArea_]]..expansion..[[.mapID = creature.map
            AND pfquest.WorldMapArea_]]..expansion..[[.x_min < creature.position_x
            AND pfquest.WorldMapArea_]]..expansion..[[.x_max > creature.position_x
            AND pfquest.WorldMapArea_]]..expansion..[[.y_min < creature.position_y
            AND pfquest.WorldMapArea_]]..expansion..[[.y_max > creature.position_y
            AND pfquest.WorldMapArea_]]..expansion..[[.areatableID > 0)
          WHERE creature.]] .. column  .. [[ = ]] .. id .. [[ ORDER BY areatableID, position_x, position_y, spawntimesecsmin ]]

        local query = mysql:execute(sql)
        while query:fetch(creature, "a") do
          local zone = creature.areatableID
          local x = creature.position_x
          local y = creature.position_y
          local x_max = creature.x_max
          local x_min = creature.x_min
          local y_max = creature.y_max
          local y_min = creature.y_min
          local px, py = 0, 0

          if x and y and x_min and y_min then
            px = round(100 - (y - y_min) / ((y_max - y_min)/100),1)
            py = round(100 - (x - x_min) / ((x_max - x_min)/100),1)
            if isValidMap(zone, round(px), round(py), expansion) then
              local coord = { px, py, tonumber(zone), ( tonumber(creature.spawntimesecsmin) > 0 and tonumber(creature.spawntimesecsmin) or 0) }
              table.insert(ret, coord)
            end
          end
        end
      end

      return ret
    end

    function GetGameObjectCoords(id)
      local gameobject = {}
      local ret = {}

      local sql = [[
        SELECT * FROM gameobject LEFT JOIN pfquest.WorldMapArea_]]..expansion..[[
        ON ( pfquest.WorldMapArea_]]..expansion..[[.mapID = gameobject.map
          AND pfquest.WorldMapArea_]]..expansion..[[.x_min < gameobject.position_x
          AND pfquest.WorldMapArea_]]..expansion..[[.x_max > gameobject.position_x
          AND pfquest.WorldMapArea_]]..expansion..[[.y_min < gameobject.position_y
          AND pfquest.WorldMapArea_]]..expansion..[[.y_max > gameobject.position_y
          AND pfquest.WorldMapArea_]]..expansion..[[.areatableID > 0)
        WHERE gameobject.id = ]] .. id .. [[ ORDER BY areatableID, position_x, position_y, spawntimesecsmin ]]

      local query = mysql:execute(sql)
      while query:fetch(gameobject, "a") do
        local zone   = gameobject.areatableID
        local x      = gameobject.position_x
        local y      = gameobject.position_y
        local x_max  = gameobject.x_max
        local x_min  = gameobject.x_min
        local y_max  = gameobject.y_max
        local y_min  = gameobject.y_min
        local px, py = 0, 0

        if x and y and x_min and y_min then
          px = round(100 - (y - y_min) / ((y_max - y_min)/100),1)
          py = round(100 - (x - x_min) / ((x_max - x_min)/100),1)
          if isValidMap(zone, round(px), round(py), expansion) then
            local coord = { px, py, tonumber(zone), ( tonumber(gameobject.spawntimesecsmin) > 0 and tonumber(gameobject.spawntimesecsmin) or 0) }
            table.insert(ret, coord)
          end
        end
      end

      return ret
    end
  end

  do -- areatrigger
    print("- loading areatrigger...")

    pfDB["areatrigger"] = pfDB["areatrigger"] or {}
    pfDB["areatrigger"][data] = {}

    -- iterate over all areatriggers
    local areatrigger = {}
    local query = mysql:execute('SELECT * FROM pfquest.AreaTrigger_'..expansion..' ORDER BY ID')
    while query:fetch(areatrigger, "a") do
      if debug("areatrigger") then break end

      local entry = tonumber(areatrigger.ID)
      pfDB["areatrigger"][data][entry] = {}

      do -- coordinates
        pfDB["areatrigger"][data][entry]["coords"] = {}
        for id, coords in pairs(GetAreaTriggerCoords(entry)) do
          local x, y, zone, respawn = table.unpack(coords)
          table.insert(pfDB["areatrigger"][data][entry]["coords"], { x, y, zone, respawn })
        end
      end
    end
  end

  do -- units
    print("- loading units...")

    pfDB["units"] = pfDB["units"] or {}
    pfDB["units"][data] = {}

    -- iterate over all creatures
    local creature_template = {}
    local query = mysql:execute('SELECT * FROM creature_template GROUP BY creature_template.entry ORDER BY creature_template.entry')
    while query:fetch(creature_template, "a") do
      if debug("units") then break end

      local entry   = tonumber(creature_template[C.Entry])
      local name    = creature_template[C.Name]
      local minlvl  = creature_template[C.MinLevel]
      local maxlvl  = creature_template[C.MaxLevel]
      local rnk     = creature_template[C.Rank]
      local lvl     = (minlvl == maxlvl) and minlvl or minlvl .. "-" .. maxlvl

      pfDB["units"][data][entry] = {}
      pfDB["units"][data][entry]["lvl"] = lvl
      if tonumber(rnk) > 0 then
        pfDB["units"][data][entry]["rnk"] = rnk
      end

      do -- detect faction
        local fac = ""
        local faction = {}
        local sql = [[
          SELECT A, H FROM creature_template, pfquest.FactionTemplate_]]..expansion..[[
          WHERE pfquest.FactionTemplate_]]..expansion..[[.factiontemplateID = creature_template.]] .. C.Faction .. [[
          AND creature_template.]] .. C.Entry .. [[ = ]] .. creature_template[C.Entry]

        local query = mysql:execute(sql)
        while query:fetch(faction, "a") do
          if debug("units_faction") then break end
          local A, H = faction.A, faction.H
          if A == "1" and not string.find(fac, "A") then fac = fac .. "A" end
          if H == "1" and not string.find(fac, "H") then fac = fac .. "H" end
        end

        if fac ~= "" then
          pfDB["units"][data][entry]["fac"] = fac
        end
      end

      do -- coordinates
        pfDB["units"][data][entry]["coords"] = {}

        for id, coords in pairs(GetCreatureCoords(entry)) do
          local x, y, zone, respawn = table.unpack(coords)
          if debug("units_coords") then break end
          table.insert(pfDB["units"][data][entry]["coords"], { x, y, zone, respawn })
        end

        if core ~= "vmangos" then
          for id, coords in pairs(GetCreatureCoordsPool(entry)) do
            local x, y, zone, respawn = table.unpack(coords)
            if debug("units_coords_pool") then break end
            table.insert(pfDB["units"][data][entry]["coords"], { x, y, zone, respawn })
          end
        end

        -- search for Event summons (fixed position)
        -- [Gazban:2624, Maraudine Khan Guard:6069, Echeyakee:3475]
        local dbscripts_on_event = {}
        local query = mysql:execute('SELECT id as event, x as x, y as y FROM '..C.dbscripts_on_event..' WHERE command = 10 AND datalong = ' .. entry)
        while query:fetch(dbscripts_on_event, "a") do
          if debug("units_event") then break end
          local event = tonumber(dbscripts_on_event.event)
          local x = tonumber(dbscripts_on_event.x)
          local y = tonumber(dbscripts_on_event.y)
          local map = nil

          -- guess map based on gameobject relation
          -- [Gazban:2624]
          local map_object = {}
          local query = mysql:execute([[
            SELECT map AS map FROM gameobject_template, gameobject
            WHERE gameobject_template.type = 10
              AND gameobject_template.data2 = ]]..event..[[
              AND gameobject.id = gameobject_template.entry
            GROUP BY gameobject.map
          ]])
          while query:fetch(map_object, "a") do
            if debug("units_event_map_object") then break end
            map = map or tonumber(map_object.map)
          end

          -- guess map based on spell relation
          local spell_template = {}
          local query = mysql:execute([[
            SELECT ]]..C.Id..[[ AS spell, ]]..C.RequiresSpellFocus..[[ AS focus FROM spell_template
            WHERE ( EffectMiscValue1 = ]]..event..[[ AND effect1 = 61 )
               OR ( EffectMiscValue2 = ]]..event..[[ AND effect2 = 61 )
               OR ( EffectMiscValue3 = ]]..event..[[ AND effect3 = 61 )
          ]])
          while query:fetch(spell_template, "a") do
            if debug("units_event_spell") then break end
            local spell = tonumber(spell_template.spell)
            local focus = tonumber(spell_template.focus)

            -- guess map based on gameobject target
            -- [Echeyakee:3475]
            local gameobject_template = {}
            local query = mysql:execute([[
              SELECT map as map FROM gameobject_template, gameobject
              WHERE gameobject.id = gameobject_template.entry
                AND gameobject_template.data0 > 0
                AND gameobject_template.type = 8
                AND gameobject_template.data0 = ]]..focus..[[
              GROUP BY map
            ]])
            while query:fetch(gameobject_template, "a") do
              if debug("units_event_spell_map_object") then break end
              map = map or tonumber(gameobject_template.map)
            end

            -- guess map based on item map/area bond
            -- [Maraudine Khan Guard:6069]
            local item_template = {}
            local query = mysql:execute([[
              SELECT ]]..C.Map..[[ as map FROM item_template
              WHERE spelltrigger_1 = 0 AND spellid_1 = ]]..spell..[[
              GROUP BY map
            ]])
            while query:fetch(item_template, "a") do
              if debug("units_event_spell_map_item") then break end
              -- Zul'Farrak Executioner Key is not bound to map.
              -- Ignoring its unlocking spell that spawns sandfuries.
              if spell == 10738 then break end
              map = map or tonumber(item_template.map)
            end
          end

          if map then -- in case we found a map, add the coordinates
            for id, coords in pairs(GetCustomCoords(map, x, y)) do
              local x, y, zone, respawn = table.unpack(coords)
              table.insert(pfDB["units"][data][entry]["coords"], { x, y, zone, respawn })
            end
          end
        end

        -- search for AI summons (fixed position)
        -- [Verog Derwisch:3395]
        local creature_ai_scripts = {}
        local query = mysql:execute(core == "vmangos" and [[
          SELECT creature.map AS map, x AS x, y AS y FROM creature_ai_scripts, creature_ai_events, creature
          WHERE creature.id = creature_ai_events.creature_id
            AND creature_ai_scripts.command = 10
            AND creature_ai_scripts.id = creature_ai_events.id
            AND creature_ai_scripts.datalong = ]]..entry..[[
            AND x != 0 AND y != 0
          GROUP BY map
        ]] or [[
          SELECT creature.map as map, creature_ai_summons.position_x AS x, creature_ai_summons.position_y AS y FROM creature_ai_scripts
          LEFT JOIN creature_ai_summons ON creature_ai_scripts.action2_type = 32 AND creature_ai_scripts.action2_param3 = creature_ai_summons.id
          LEFT JOIN creature ON creature_ai_scripts.creature_id = creature.id
          WHERE action2_type = 32
            AND action2_param1 = ]]..entry..[[
          GROUP BY map
        ]])
        while query:fetch(creature_ai_scripts, "a") do
          if debug("units_summon_fixed") then break end
          for id, coords in pairs(GetCustomCoords(tonumber(creature_ai_scripts.map), tonumber(creature_ai_scripts.x), tonumber(creature_ai_scripts.y))) do
            local x, y, zone, respawn = table.unpack(coords)
            table.insert(pfDB["units"][data][entry]["coords"], { x, y, zone, respawn })
          end
        end

        -- search for AI summons (summoner position)
        -- [Darrowshire Spirit:11064]
        local creature_ai_scripts = {}
        local query = mysql:execute(core == "vmangos" and [[
          SELECT creature_ai_events.creature_id AS summoner FROM creature_ai_scripts, creature_ai_events
          WHERE creature_ai_scripts.command = 10
            AND creature_ai_scripts.id = creature_ai_events.id
            AND creature_ai_scripts.datalong = ]]..entry..[[
            AND x = 0 AND y = 0
        ]] or [[
          SELECT creature_id AS summoner FROM spell_template
          LEFT JOIN creature_ai_scripts ON action1_type = 11 AND action1_param1 = spell_template.Id
          WHERE spell_template.Effect1 = 28 AND creature_id > 0 AND spell_template.EffectMiscValue1 = ]]..entry..[[
        ]])
        while query:fetch(creature_ai_scripts, "a") do
          if debug("units_summon_unknown") then break end
          for id, coords in pairs(GetCreatureCoords(tonumber(creature_ai_scripts.summoner))) do
            local x, y, zone, respawn = table.unpack(coords)
            table.insert(pfDB["units"][data][entry]["coords"], { x, y, zone, respawn })
          end

          if core ~= "vmangos" then
            for id, coords in pairs(GetCreatureCoordsPool(tonumber(creature_ai_scripts.summoner))) do
              local x, y, zone, respawn = table.unpack(coords)
              table.insert(pfDB["units"][data][entry]["coords"], { x, y, zone, respawn })
            end
          end
        end

        -- clear duplicates
        pfDB["units"][data][entry]["coords"] = removedupes(pfDB["units"][data][entry]["coords"])
      end
    end

    do -- Patch creature table with manual entries
      -- Only use this method of adding creatures if there is REALLY no way
      -- to extract data out of the databases of the mangos cores. If the list
      -- becomes too big, this should be separated to another file.
      pfDB["units"][data][420] = {
        ["coords"] = { [1] = { 69, 21, 148, 300 } },
        ["fac"] = "H", ["lvl"] = "60",
      }

      do -- Sentinel Selarin:3694
        -- taken from https://classic.wowhead.com/npc=3694/sentinel-selarin
        pfDB["units"][data][3694]["coords"] = { [1] = { 39.2, 43.4, 42, 0 } }
      end

      do -- Mokk the Savage:1514
        -- taken from https://classic.wowhead.com/npc=1514/mokk-the-savage
        pfDB["units"][data][1514]["coords"] = { [1] = { 35.2, 60.4, 33, 0 } }
      end
    end
  end

  do -- objects
    print("- loading objects...")

    pfDB["objects"] = pfDB["objects"] or {}
    pfDB["objects"][data] = {}

    -- iterate over all objects
    local gameobject_template = {}
    local query = mysql:execute('SELECT * FROM gameobject_template GROUP BY gameobject_template.entry ORDER BY gameobject_template.entry ASC')
    while query:fetch(gameobject_template, "a") do
      if debug("objects") then break end

      local entry  = tonumber(gameobject_template.entry)
      local name   = gameobject_template.name

      pfDB["objects"][data][entry] = {}

      do -- detect faction
        local fac = ""
        local faction = {}
        local sql = [[
          SELECT A, H FROM gameobject_template, pfquest.FactionTemplate_]]..expansion..[[
          WHERE pfquest.FactionTemplate_]]..expansion..[[.factiontemplateID = gameobject_template.faction
          AND gameobject_template.entry = ]] .. gameobject_template.entry

        local query = mysql:execute(sql)
        while query:fetch(faction, "a") do
          if debug("objects_faction") then break end
          local A, H = faction.A, faction.H
          if A == "1" and not string.find(fac, "A") then fac = fac .. "A" end
          if H == "1" and not string.find(fac, "H") then fac = fac .. "H" end
        end

        if fac ~= "" then
          pfDB["objects"][data][entry]["fac"] = fac
        end
      end

      do -- coordinates
        pfDB["objects"][data][entry]["coords"] = {}

        for id,coords in pairs(GetGameObjectCoords(entry)) do
          if debug("objects_coords") then break end
          local x, y, zone, respawn = table.unpack(coords)
          table.insert(pfDB["objects"][data][entry]["coords"], { x, y, zone, respawn })
        end
      end

      -- clear duplicates
      pfDB["objects"][data][entry]["coords"] = removedupes(pfDB["objects"][data][entry]["coords"])
    end
  end

  do -- items
    print("- loading items...")

    pfDB["items"] = pfDB["items"] or {}
    pfDB["items"][data] = {}

    -- iterate over all items
    local item_template = {}
    local query = mysql:execute('SELECT entry, name FROM item_template GROUP BY item_template.entry ASC')
    while query:fetch(item_template, "a") do
      if debug("items") then break end

      local entry = tonumber(item_template.entry)
      local scans = { [0] = { entry, nil } }

      -- add items that contain the actual item to the itemlist
      local item_loot_item = {}
      local count = 0
      local query = mysql:execute('SELECT entry, ChanceOrQuestChance FROM item_loot_template WHERE item = ' .. item_template.entry .. ' ORDER BY entry')
      while query:fetch(item_loot_item, "a") do
        if debug("items_container") then break end
        if math.abs(item_loot_item.ChanceOrQuestChance) > 0 then
          local chance = math.abs(item_loot_item.ChanceOrQuestChance)
          chance = chance < 0.01 and round(chance, 5) or round(chance, 2)
          table.insert(scans, { tonumber(item_loot_item.entry), chance })
        end
      end

      -- recursively read U, O, V, R blocks of the item
      for id, item in pairs(scans) do
        local entry = tonumber(item[1])
        local chance = item[2] and item[2] / 100 or 1
        pfDB["items"][data][entry] = pfDB["items"][data][entry] or {}

        -- fill unit table
        local creature_loot_template = {}
        local query = mysql:execute('SELECT entry, ChanceOrQuestChance FROM creature_loot_template WHERE item = ' .. entry .. ' ORDER BY entry')
        while query:fetch(creature_loot_template, "a") do
          if debug("items_unit") then break end
          local chance = math.abs(creature_loot_template.ChanceOrQuestChance) * chance
          chance = chance < 0.01 and round(chance, 5) or round(chance, 2)

          if chance > 0 then
            pfDB["items"][data][entry]["U"] = pfDB["items"][data][entry]["U"] or {}
            pfDB["items"][data][entry]["U"][tonumber(creature_loot_template.entry)] = chance
          end
        end

        -- fill object table
        local gameobject_loot_template = {}
        local query = mysql:execute([[
          SELECT gameobject_template.entry, gameobject_loot_template.ChanceOrQuestChance FROM gameobject_loot_template
          INNER JOIN gameobject_template ON gameobject_template.data1 = gameobject_loot_template.entry
          WHERE ( gameobject_template.type = 3 OR gameobject_template.type = 25 )
          AND gameobject_loot_template.item = ]] .. entry .. [[ ORDER BY gameobject_template.entry ]])
        while query:fetch(gameobject_loot_template, "a") do
          if debug("items_object") then break end
          local chance = math.abs(gameobject_loot_template.ChanceOrQuestChance) * chance
          chance = chance < 0.01 and round(chance, 5) or round(chance, 2)

          if chance > 0 then
            pfDB["items"][data][entry]["O"] = pfDB["items"][data][entry]["O"] or {}
            pfDB["items"][data][entry]["O"][tonumber(gameobject_loot_template.entry)] = chance
          end
        end

        -- fill reference table
        local reference_loot_template = {}
        local query = mysql:execute([[
          SELECT entry, ChanceOrQuestChance FROM reference_loot_template where reference_loot_template.item = ]] .. entry .. [[ GROUP BY entry
        ]])
        while query:fetch(reference_loot_template, "a") do
          if debug("items_reference") then break end
          local chance = math.abs(reference_loot_template.ChanceOrQuestChance)
          chance = chance < 0.01 and round(chance, 5) or round(chance, 2)

          pfDB["items"][data][entry]["R"] = pfDB["items"][data][entry]["R"] or {}
          pfDB["items"][data][entry]["R"][tonumber(reference_loot_template.entry)] = chance
        end

        -- fill vendor table
        local npc_vendor = {}
        local query = mysql:execute('SELECT entry, maxcount FROM npc_vendor WHERE item = ' .. entry .. ' ORDER BY entry')
        while query:fetch(npc_vendor, "a") do
          if debug("items_vendor") then break end
          pfDB["items"][data][entry]["V"] = pfDB["items"][data][entry]["V"] or {}
          pfDB["items"][data][entry]["V"][tonumber(npc_vendor.entry)] = tonumber(npc_vendor.maxcount)
        end

        -- handle vendor template tables
        local npc_vendor = {}
        local query = mysql:execute('SELECT creature_template.Entry, maxcount FROM npc_vendor_template, creature_template WHERE item = ' .. entry .. ' and creature_template.' .. C["VendorTemplateId"] .. ' = npc_vendor_template.entry ORDER BY creature_template.Entry')
        while query:fetch(npc_vendor, "a") do
          if debug("items_vendortemplate") then break end
          pfDB["items"][data][entry]["V"] = pfDB["items"][data][entry]["V"] or {}
          pfDB["items"][data][entry]["V"][tonumber(npc_vendor.Entry)] = tonumber(npc_vendor.maxcount)
        end
      end
    end
  end

  do -- refloot
    print("- loading refloot...")

    pfDB["refloot"] = pfDB["refloot"] or {}
    pfDB["refloot"][data] = {}

    -- iterate over all reference loots
    local reference_loot_template = {}
    local query = mysql:execute('SELECT entry, ChanceOrQuestChance FROM reference_loot_template GROUP BY entry')
    while query:fetch(reference_loot_template, "a") do
      if debug("refloot") then break end

      local entry = tonumber(reference_loot_template.entry)

      -- fill unit table
      local creature_loot_template = {}
      local count = 0
      local query = mysql:execute([[
        SELECT entry FROM creature_loot_template
        WHERE creature_loot_template.mincountOrRef < 0
        AND item = ]] .. entry .. [[ ORDER BY entry
      ]])
      while query:fetch(creature_loot_template, "a") do
        if debug("refloot_unit") then break end
        pfDB["refloot"][data][entry] = pfDB["refloot"][data][entry] or {}
        pfDB["refloot"][data][entry]["U"] = pfDB["refloot"][data][entry]["U"] or {}
        pfDB["refloot"][data][entry]["U"][tonumber(creature_loot_template.entry)] = 1
      end

      -- fill object table
      local gameobject_template = {}
      local count = 0
      local query = mysql:execute([[
        SELECT gameobject_template.entry FROM gameobject_template, gameobject_loot_template
        WHERE gameobject_template.data1 = gameobject_loot_template.entry
        AND gameobject_loot_template.mincountOrRef < 0
        AND gameobject_loot_template.item = ]] .. entry .. [[ ORDER BY gameobject_template.entry ;
      ]])
      while query:fetch(gameobject_template, "a") do
        if debug("refloot_object") then break end
        pfDB["refloot"][data][entry] = pfDB["refloot"][data][entry] or {}
        pfDB["refloot"][data][entry]["O"] = pfDB["refloot"][data][entry]["O"] or {}
        pfDB["refloot"][data][entry]["O"][tonumber(gameobject_template.entry)] = 1
      end
    end
  end

  do -- quests
    print("- loading quests...")

    pfDB["quests"] = pfDB["quests"] or {}
    pfDB["quests"][data] = {}

    pfDB["quests-itemreq"] = pfDB["quests-itemreq"] or {}
    pfDB["quests-itemreq"][data] = {}

    -- iterate over all quests
    local quest_template = {}
    local query = mysql:execute('SELECT * FROM quest_template GROUP BY quest_template.entry')
    while query:fetch(quest_template, "a") do
      if debug("quests") then break end

      local entry = tonumber(quest_template.entry)
      local minlevel = tonumber(quest_template.MinLevel)
      local questlevel = tonumber(quest_template.QuestLevel)
      local class = tonumber(quest_template.RequiredClasses)
      local race = tonumber(quest_template.RequiredRaces)
      local skill = tonumber(quest_template.RequiredSkill)
      local chain = tonumber(quest_template.NextQuestInChain)
      local srcitem = tonumber(quest_template.SrcItemId)
      local repeatable = tonumber(quest_template.SpecialFlags) & 1
      local exclusive = tonumber(quest_template.ExclusiveGroup)
      local close = nil
      local event = nil

      -- seach for quests closed by this one
      if exclusive and exclusive > 0 then
        close = close or {}
        local exclusive_template = {}
        local query = mysql:execute('SELECT entry, ExclusiveGroup FROM quest_template WHERE ExclusiveGroup = ' .. exclusive .. ' GROUP BY quest_template.entry')
        while query:fetch(exclusive_template, "a") do
          table.insert(close, tonumber(exclusive_template.entry))
        end
      end

      -- try to detect event by quest event entry
      local game_event_quest = {}
      local query = mysql:execute('SELECT event FROM game_event_quest WHERE quest = ' .. entry)
      while query:fetch(game_event_quest, "a") do
        if debug("quests_events") then break end
        event = tonumber(game_event_quest.event)
        break
      end

      -- try to detect event by creature event
      if not event then
        local game_event_creature = {}
        local sql = [[
          SELECT game_event_creature.event as event FROM creature, game_event_creature, creature_questrelation
          WHERE creature.guid = game_event_creature.guid
          AND creature.id = creature_questrelation.id
          AND creature_questrelation.quest = ]] .. quest_template.entry
        local query = mysql:execute(sql)
        while query:fetch(game_event_creature, "a") do
          if debug("quests_eventscreature") then break end
          event = tonumber(game_event_creature.event)
          break
        end
      end

      -- try to detect event by gameobject event
      if not event then
        local game_event_gameobject = {}
        local sql = [[
          SELECT game_event_gameobject.event as event FROM gameobject, game_event_gameobject, gameobject_questrelation
          WHERE gameobject.guid = game_event_gameobject.guid
          AND gameobject.id = gameobject_questrelation.id
          AND gameobject_questrelation.quest = ]] .. quest_template.entry
        local query = mysql:execute(sql)
        while query:fetch(game_event_gameobject, "a") do
          if debug("quests_eventsobjects") then break end
          event = tonumber(game_event_gameobject.event)
          break
        end
      end

      pfDB["quests"][data][entry] = {}
      pfDB["quests"][data][entry]["min"] = minlevel ~= 0 and minlevel
      pfDB["quests"][data][entry]["skill"] = skill ~= 0 and skill
      pfDB["quests"][data][entry]["lvl"] = questlevel ~= 0 and questlevel
      pfDB["quests"][data][entry]["class"] = class ~= 0 and class
      pfDB["quests"][data][entry]["race"] = race ~= 0 and race
      pfDB["quests"][data][entry]["skill"] = skill ~= 0 and skill
      pfDB["quests"][data][entry]["event"] = event ~= 0 and event
      pfDB["quests"][data][entry]["close"] = close and close

      -- quest objectives
      local units, objects, items, itemreq, areatrigger, zones, pre = {}, {}, {}, {}, {}, {}, {}

      -- add single pre-quests
      if tonumber(quest_template.PrevQuestId) ~= 0 then
        pre[math.abs(tonumber(quest_template.PrevQuestId))] = true
      end

      -- add required pre-quests
      local prequests = {}
      local query = mysql:execute('SELECT quest_template.entry FROM quest_template WHERE NextQuestId = ' .. entry .. ' AND ExclusiveGroup < 0')
      while query:fetch(prequests, "a") do
        if debug("quests_prequests") then break end
        pre[tonumber(prequests["entry"])] = true
      end

      -- add pre quests from quest chains
      local query = mysql:execute('SELECT quest_template.entry FROM quest_template WHERE NextQuestInChain = ' .. entry)
      while query:fetch(prequests, "a") do
        if debug("quests_prequestchain") then break end
        pre[tonumber(prequests["entry"])] = true
      end

      -- temporary add provided quest item
      items[srcitem] = true

      for i=1,4 do
        if quest_template["ReqCreatureOrGOId" .. i] and tonumber(quest_template["ReqCreatureOrGOId" .. i]) > 0 then
          units[tonumber(quest_template["ReqCreatureOrGOId" .. i])] = true
        elseif quest_template["ReqCreatureOrGOId" .. i] and tonumber(quest_template["ReqCreatureOrGOId" .. i]) < 0 then
          objects[math.abs(tonumber(quest_template["ReqCreatureOrGOId" .. i]))] = true
        end
        if quest_template["ReqItemId" .. i] and tonumber(quest_template["ReqItemId" .. i]) > 0 then
          items[tonumber(quest_template["ReqItemId" .. i])] = true
        end
        if quest_template["ReqSourceId" .. i] and tonumber(quest_template["ReqSourceId" .. i]) > 0 then
          items[tonumber(quest_template["ReqSourceId" .. i])] = true
        end

        if quest_template["ReqSpellCast" .. i] and tonumber(quest_template["ReqSpellCast" .. i]) > 0 then
          local spell_template = {}
          local query = mysql:execute('SELECT * FROM spell_template WHERE spell_template.' .. C.Id .. ' = ' .. quest_template["ReqSpellCast" .. i])
          while query:fetch(spell_template, "a") do
            if debug("quests_questspellobject") then break end
            if spell_template[C.RequiresSpellFocus] ~= "0" then
              local gameobject_template = {}
              local query = mysql:execute('SELECT * FROM gameobject_template WHERE gameobject_template.type = 8 and gameobject_template.data0 = ' .. spell_template[C.RequiresSpellFocus])
              while query:fetch(gameobject_template, "a") do
                objects[tonumber(gameobject_template["entry"])] = true
              end
            end
          end
        end
      end

      -- add all units that give kill credit for one of the known units
      if core ~= "vmangos" then
        for id in pairs(units) do
          local creature_template = {}
          local query = mysql:execute('SELECT * FROM creature_template WHERE KillCredit1 = ' .. id .. ' or KillCredit2 = ' .. id)
          while query:fetch(creature_template, "a") do
            if debug("quests_credit") then break end
            units[tonumber(creature_template["Entry"])] = true
          end
        end
      end

      -- scan all involved questitems for spells that require or are required by gameobjects, units or zones
      for id in pairs(items) do
        if id > 0 then
          local item_template = {}
          for _, spellcolumn in pairs({ "spellid_1", "spellid_2", "spellid_3", "spellid_4", "spellid_5" }) do
            local query = mysql:execute('SELECT * FROM item_template WHERE ' .. spellcolumn .. ' > 0 and entry = ' .. id)
            while query:fetch(item_template, "a") do
              if debug("quests_item") then break end
              local spellid = item_template[spellcolumn]

              -- scan through all spells that are associated with the item
              local spell_template = {}
              local query = mysql:execute('SELECT * FROM spell_template WHERE ' .. C.Id .. ' = ' .. spellid)
              while query:fetch(spell_template, "a") do
                if debug("quests_itemspell") then break end
                local area = spell_template["AreaId"]
                local focus = spell_template[C.RequiresSpellFocus]
                local match = nil

                -- spell requires focusing a creature
                local spell_script_target = {}
                for itemid in pairs(items) do
                  local query = mysql:execute([[
                    SELECT spell_script_target.targetEntry AS creature
                    FROM spell_script_target, item_template
                    WHERE ]] .. spellid .. [[ > 0 AND ]] .. spellid .. [[ = spell_script_target.entry
                  ]])
                  while query:fetch(spell_script_target, "a") do
                    if debug("quests_itemspellcreature") then break end
                    pfDB["quests-itemreq"][data][id] = pfDB["quests-itemreq"][data][id] or {}
                    pfDB["quests-itemreq"][data][id][tonumber(spell_script_target.creature)] = spellid
                    itemreq[id] = true
                    match = true
                  end
                end

                -- spell requries focusing an object
                if focus and tonumber(focus) > 0  then
                  local gameobject_template = {}
                  local query = mysql:execute('SELECT * FROM gameobject_template WHERE gameobject_template.type = 8 and gameobject_template.data0 = ' .. focus)
                  while query:fetch(gameobject_template, "a") do
                    if debug("quests_itemspellobject") then break end
                    pfDB["quests-itemreq"][data][id] = pfDB["quests-itemreq"][data][id] or {}
                    pfDB["quests-itemreq"][data][id][-tonumber(gameobject_template["entry"])] = spellid
                    itemreq[id] = true
                    match = true
                  end
                end

                -- spell triggers something that requires a special target
                for _, trigger in pairs({ spell_template[C["EffectTriggerSpell"]..1], spell_template[C["EffectTriggerSpell"]..2], spell_template[C["EffectTriggerSpell"]..3] }) do
                  if trigger and tonumber(trigger) > 0 then
                    local spell_script_target = {}
                    local query = mysql:execute('SELECT * FROM spell_script_target WHERE entry = ' .. trigger)
                    while query:fetch(spell_script_target, "a") do
                      if debug("quests_itemspellscript") then break end
                      local targetobj = spell_script_target["type"]
                      local targetentry = spell_script_target["targetEntry"]

                      if tonumber(targetobj) == 0 then
                        -- object
                        pfDB["quests-itemreq"][data][id] = pfDB["quests-itemreq"][data][id] or {}
                        pfDB["quests-itemreq"][data][id][-tonumber(targetentry)] = spellid
                        itemreq[id] = true
                        match = true
                      elseif tonumber(targetobj) == 1 then
                        -- unit
                        pfDB["quests-itemreq"][data][id] = pfDB["quests-itemreq"][data][id] or {}
                        pfDB["quests-itemreq"][data][id][tonumber(targetentry)] = spellid
                        itemreq[id] = true
                        match = true
                      end
                    end
                  end
                end

                -- only spell limitation is a zone
                if not match and area and tonumber(area) > 0 then
                  zones[tonumber(area)] = true
                end
              end
            end
          end

          -- item is used to open a creature
          local creature_items = {}
          local query = mysql:execute([[
            SELECT ]] .. C.targetEntry .. [[ AS creature FROM item_required_target
            WHERE entry = ]] .. id .. [[
          ]])
          while query:fetch(creature_items, "a") do
            if debug("quests_itemcreature") then break end
            pfDB["quests-itemreq"][data][id] = pfDB["quests-itemreq"][data][id] or {}
            pfDB["quests-itemreq"][data][id][tonumber(creature_items.creature)] = 0
            itemreq[id] = true
          end

          -- item is used to open an object
          local object_items = {}
          local query = mysql:execute([[
            SELECT gameobject_template.entry AS object
            FROM gameobject_template, pfquest.Lock_]]..expansion..[[
            WHERE type = 10 and data0 = pfquest.Lock_]]..expansion..[[.id
            AND pfquest.Lock_]]..expansion..[[.data = ]] .. id .. [[
          ]])
          while query:fetch(object_items, "a") do
            if debug("quests_itemobject") then break end
            pfDB["quests-itemreq"][data][id] = pfDB["quests-itemreq"][data][id] or {}
            pfDB["quests-itemreq"][data][id][-tonumber(object_items.object)] = 0
            itemreq[id] = true
          end
        end
      end

      -- scan for related areatriggers
      local areatrigger_involvedrelation = {}
      local query = mysql:execute('SELECT * FROM areatrigger_involvedrelation WHERE quest = ' .. entry)
      while query:fetch(areatrigger_involvedrelation, "a") do
        if debug("quests_areatrigger") then break end
        areatrigger[tonumber(areatrigger_involvedrelation["id"])] = true
      end

      -- remove provided quest item from objectives
      items[srcitem] = nil

      -- write pre-quests
      for id in opairs(pre) do
        pfDB["quests"][data][entry]["pre"] = pfDB["quests"][data][entry]["pre"] or {}
        table.insert(pfDB["quests"][data][entry]["pre"], tonumber(id))
      end

      do -- write objectives
        if tblsize(units) > 0 or tblsize(objects) > 0 or tblsize(items) > 0 or tblsize(itemreq) > 0 or tblsize(areatrigger) > 0 or tblsize(zones) > 0 then
          pfDB["quests"][data][entry]["obj"] = pfDB["quests"][data][entry]["obj"] or {}

          for id in opairs(units) do
            pfDB["quests"][data][entry]["obj"]["U"] = pfDB["quests"][data][entry]["obj"]["U"] or {}
            table.insert(pfDB["quests"][data][entry]["obj"]["U"], tonumber(id))
          end

          for id in opairs(objects) do
            pfDB["quests"][data][entry]["obj"]["O"] = pfDB["quests"][data][entry]["obj"]["O"] or {}
            table.insert(pfDB["quests"][data][entry]["obj"]["O"], tonumber(id))
          end

          for id in opairs(items) do
            pfDB["quests"][data][entry]["obj"]["I"] = pfDB["quests"][data][entry]["obj"]["I"] or {}
            table.insert(pfDB["quests"][data][entry]["obj"]["I"], tonumber(id))
          end

          for id in opairs(itemreq) do
            pfDB["quests"][data][entry]["obj"]["IR"] = pfDB["quests"][data][entry]["obj"]["IR"] or {}
            table.insert(pfDB["quests"][data][entry]["obj"]["IR"], tonumber(id))
          end

          for id in opairs(areatrigger) do
            pfDB["quests"][data][entry]["obj"]["A"] = pfDB["quests"][data][entry]["obj"]["A"] or {}
            table.insert(pfDB["quests"][data][entry]["obj"]["A"], tonumber(id))
          end

          for id in opairs(zones) do
            pfDB["quests"][data][entry]["obj"]["Z"] = pfDB["quests"][data][entry]["obj"]["Z"] or {}
            table.insert(pfDB["quests"][data][entry]["obj"]["Z"], tonumber(id))
          end
        end
      end

      do -- quest starter
        local creature_questrelation = {}
        local sql = [[
          SELECT * FROM creature_questrelation WHERE creature_questrelation.quest = ]] .. quest_template.entry
        local query = mysql:execute(sql)
        while query:fetch(creature_questrelation, "a") do
          if debug("quests_starterunit") then break end
          pfDB["quests"][data][entry]["start"] = pfDB["quests"][data][entry]["start"] or {}
          pfDB["quests"][data][entry]["start"]["U"] = pfDB["quests"][data][entry]["start"]["U"] or {}
          table.insert(pfDB["quests"][data][entry]["start"]["U"], tonumber(creature_questrelation.id))
        end

        local gameobject_questrelation = {}
        local sql = [[
          SELECT * FROM gameobject_questrelation WHERE gameobject_questrelation.quest = ]] .. quest_template.entry
        local query = mysql:execute(sql)
        while query:fetch(gameobject_questrelation, "a") do
          if debug("quests_starterobject") then break end
          pfDB["quests"][data][entry]["start"] = pfDB["quests"][data][entry]["start"] or {}
          pfDB["quests"][data][entry]["start"]["O"] = pfDB["quests"][data][entry]["start"]["O"] or {}
          table.insert(pfDB["quests"][data][entry]["start"]["O"], tonumber(gameobject_questrelation.id))
        end

        local item_template = {}
        local sql = [[
          SELECT entry as id FROM item_template WHERE ]] .. C.startquest .. [[ = ]] .. quest_template.entry
        local query = mysql:execute(sql)
        while query:fetch(item_template, "a") do
          if debug("quests_starteritem") then break end

          -- remove quest start items from objectives
          if pfDB["quests"][data][entry]["obj"] and pfDB["quests"][data][entry]["obj"]["I"] then
            for id, objective in pairs(pfDB["quests"][data][entry]["obj"]["I"]) do
              if objective == tonumber(item_template.id) then
                pfDB["quests"][data][entry]["obj"]["I"][id] = nil
              end
            end
          end

          -- add item to quest starters
          pfDB["quests"][data][entry]["start"] = pfDB["quests"][data][entry]["start"] or {}
          pfDB["quests"][data][entry]["start"]["I"] = pfDB["quests"][data][entry]["start"]["I"] or {}
          table.insert(pfDB["quests"][data][entry]["start"]["I"], tonumber(item_template.id))
        end
      end

      do -- quest ender
        local creature_involvedrelation = {}
        local sql = [[
          SELECT * FROM creature_involvedrelation WHERE creature_involvedrelation.quest = ]] .. quest_template.entry
        local query = mysql:execute(sql)
        while query:fetch(creature_involvedrelation, "a") do
          if debug("quests_enderunit") then break end
          pfDB["quests"][data][entry]["end"] = pfDB["quests"][data][entry]["end"] or {}
          pfDB["quests"][data][entry]["end"]["U"] = pfDB["quests"][data][entry]["end"]["U"] or {}
          table.insert(pfDB["quests"][data][entry]["end"]["U"], tonumber(creature_involvedrelation.id))
        end

        local gameobject_involvedrelation = {}
        local first = true
        local sql = [[
          SELECT * FROM gameobject_involvedrelation WHERE gameobject_involvedrelation.quest = ]] .. quest_template.entry
        local query = mysql:execute(sql)
        while query:fetch(gameobject_involvedrelation, "a") do
          if debug("quests_enderobject") then break end
          pfDB["quests"][data][entry]["end"] = pfDB["quests"][data][entry]["end"] or {}
          pfDB["quests"][data][entry]["end"]["O"] = pfDB["quests"][data][entry]["end"]["O"] or {}
          table.insert(pfDB["quests"][data][entry]["end"]["O"], tonumber(gameobject_involvedrelation.id))
        end
      end
    end
  end

  do -- zones
    print("- loading zones...")
    pfDB["zones"] = pfDB["zones"] or {}
    pfDB["zones"][data] = {}

    local zones = {}
    local query = mysql:execute('SELECT * FROM pfquest.WorldMapOverlay_'..expansion..' LEFT JOIN pfquest.AreaTable_'..expansion..' ON pfquest.WorldMapOverlay_'..expansion..'.areaID = pfquest.AreaTable_'..expansion..'.id')
    while query:fetch(zones, "a") do
      if debug("zones") then break end
      local entry = tonumber(zones.id)
      local zone = tonumber(zones.zoneID)
      local textureWidth = tonumber(zones.textureWidth)
      local textureHeight = tonumber(zones.textureHeight)
      local offsetX = tonumber(zones.offsetX)
      local offsetY = tonumber(zones.offsetY)

      -- convert square to map scale
      local hitRectTop = tonumber(zones.hitRectTop)/668*100
      local hitRectLeft = tonumber(zones.hitRectLeft)/1002*100
      local hitRectBottom = tonumber(zones.hitRectBottom)/668*100
      local hitRectRight = tonumber(zones.hitRectRight)/1002*100

      -- area size
      local width = hitRectRight - hitRectLeft
      local height = hitRectBottom - hitRectTop

      -- area center
      local cx = (hitRectLeft+hitRectRight)/2
      local cy = (hitRectTop+hitRectBottom)/2

      if entry then
        pfDB["zones"][data][entry] = { zone, round(width,2), round(height,2), round(cx,2), round(cy,2)}
      end
    end
  end

  do -- minimap
    print("- loading minimap...")

    pfDB["minimap"..exp] = pfDB["minimap"..exp] or {}

    local minimap_size = {}
    local query = mysql:execute('SELECT * FROM pfquest.WorldMapArea_'..expansion..' ORDER BY areatableID ASC')
    while query:fetch(minimap_size, "a") do
      if debug("minimap") then break end
      local mapID = minimap_size.mapID
      local areaID = minimap_size.areatableID
      local name = minimap_size.name
      local x_min = minimap_size.x_min
      local y_min = minimap_size.y_min
      local x_max = minimap_size.x_max
      local y_max = minimap_size.y_max

      local x = -1 * x_min + x_max
      local y = -1 * y_min + y_max

      pfDB["minimap"..exp][tonumber(areaID)] = { tonumber(y+.0), tonumber(x+.0) }
    end
  end

  do -- meta
    print("- loading meta...")

    pfDB["meta"..exp] = pfDB["meta"..exp] or {
      ["mines"] = {},
      ["herbs"] = {},
      ["chests"] = {},
      ["rares"] = {},
      ["flight"] = {},
    }


    do -- raremobs
      local creature_template = {}
      local query = mysql:execute([[
        SELECT * FROM `creature_template` WHERE ]] .. C.Rank .. [[ = 4 OR ]] .. C.Rank .. [[ = 2
      ]])

      while query:fetch(creature_template, "a") do
        if debug("meta_rares") then break end
        local entry = tonumber(creature_template[C.Entry])
        local level = tonumber(creature_template[C.MinLevel])
        pfDB["meta"..exp].rares[entry] = level
      end
    end

    do -- npcs
      local creature_flags = {
        [4] = "vendor",
        [8] = "flight",
        [32] = "spirithealer",
        [64] = "spirithealer",
        [128] = "innkeeper",
        [256] = "banker",
        [2048] = "battlemaster",
        [4096] = "auctioneer",
        [8192] = "stablemaster",
        [16384] = "repair",
      }

      local tbc_flag_map = {
        [4] = 128, [8] = 8192, [32] = 16384, [64] = 32768,
        [128] = 65536, [256] = 20000, [2048] = 1048576,
        [4096] = 2097152, [8192] = 4194304, [16384] = 4096,
      }

      for mask, name in pairs(creature_flags) do
        -- create meta relation table if not existing
        pfDB["meta"..exp][name] = pfDB["meta"..exp][name] or {}

        local mask = core == "vmangos" and mask or tbc_flag_map[mask]

        local creature_template = {}
        local query = mysql:execute([[
          SELECT Entry, A, H FROM `creature_template`, `pfquest`.FactionTemplate_]]..expansion..[[
          WHERE pfquest.FactionTemplate_]]..expansion..[[.factiontemplateID = creature_template.]] .. C.Faction .. [[
          AND ( ]] .. C.NpcFlags .. [[ & ]]..mask..[[) > 0
        ]])

        while query:fetch(creature_template, "a") do
          if debug("meta_npcs") then break end
          local fac = ""
          local entry = tonumber(creature_template.Entry)
          local A = tonumber(creature_template.A)
          local H = tonumber(creature_template.H)
          if A >= 0 then fac = fac .. "A" end
          if H >= 0 then fac = fac .. "H" end
          pfDB["meta"..exp][name][entry] = fac
        end
      end
    end

    do -- objects
      local gameobject_flags = {
        [19] = "mailbox",
        [23] = "meetingstone",
        [25] = "fish",
      }

      for flag, name in pairs(gameobject_flags) do
        -- create meta relation table if not existing
        pfDB["meta"..exp][name] = pfDB["meta"..exp][name] or {}

        -- gameobject_template.type
        local gameobject_template = {}
        local query = mysql:execute([[
          SELECT * FROM `gameobject_template`
          LEFT JOIN pfquest.FactionTemplate_]]..expansion..[[
          ON pfquest.FactionTemplate_]]..expansion..[[.factiontemplateID = gameobject_template.faction
          WHERE `type` = ]]..flag..[[
        ]])

        while query:fetch(gameobject_template, "a") do
          if debug("meta_objects") then break end
          local entry = tonumber(gameobject_template.entry) * -1
          local A = tonumber(gameobject_template.A)
          local H = tonumber(gameobject_template.H)
          local fac = ""

          if not A or A >= 0 then fac = fac .. "A" end
          if not H or H >= 0 then fac = fac .. "H" end

          pfDB["meta"..exp][name][entry] = fac
        end
      end
    end

    do -- openables
      local gameobject_template = {}
      local query = mysql:execute([[
        SELECT * FROM `gameobject_template`, pfquest.Lock_]]..expansion..[[
        WHERE `type` = 3 AND `locktype` = 2 AND `flags` = 0 AND `data1` > 0 and id = data0 GROUP BY `gameobject_template`.entry ORDER BY `gameobject_template`.entry ASC
      ]])

      while query:fetch(gameobject_template, "a") do
        if debug("meta_openable") then break end
        local entry   = tonumber(gameobject_template.entry) * -1
        local data = tonumber(gameobject_template.data)
        local skill = tonumber(gameobject_template.skill)
        if data == 1 then
          pfDB["meta"..exp]["chests"][entry] = skill
        elseif data == 2 then
          pfDB["meta"..exp]["herbs"][entry] = skill
        elseif data == 3 then
          pfDB["meta"..exp]["mines"][entry] = skill
        end
      end
    end
  end

  print("- loading locales...")
  do -- unit locales
    -- load unit locales
    local units_loc = {}
    local locales_creature = {}
    local query = mysql:execute('SELECT *, creature_template.'..C.Entry..' AS _entry FROM creature_template LEFT JOIN locales_creature ON locales_creature.entry = creature_template.entry GROUP BY creature_template.entry ORDER BY creature_template.entry ASC')
    while query:fetch(locales_creature, "a") do
      if debug("locales_unit") then break end

      local entry = tonumber(locales_creature["_entry"])
      local name  = locales_creature[C.Name]

      if entry then
        for loc in pairs(locales) do
          local name_loc = locales_creature["name_loc" .. locales[loc]]
          if not name_loc or name_loc == "" then name_loc = name or "" end
          if name_loc and name_loc ~= "" then
            local locale = loc .. ( expansion ~= "vanilla"  and "-" .. expansion or "" )
            pfDB["units"][locale] = pfDB["units"][locale] or { [420] = "Shagu" }
            pfDB["units"][locale][entry] = sanitize(name_loc)
          end
        end
      end
    end
  end

  do -- objects locales
    local locales_gameobject = {}
    local query = mysql:execute('SELECT *, gameobject_template.entry AS _entry FROM gameobject_template LEFT JOIN locales_gameobject ON locales_gameobject.entry = gameobject_template.entry GROUP BY gameobject_template.entry ORDER BY gameobject_template.entry ASC')
    while query:fetch(locales_gameobject, "a") do
      if debug("locales_object") then break end

      local entry = tonumber(locales_gameobject["_entry"])
      local name  = locales_gameobject.name

      if entry then
        for loc in pairs(locales) do
          local name_loc = locales_gameobject["name_loc" .. locales[loc]]
          if not name_loc or name_loc == "" then name_loc = name or "" end
          if name_loc and name_loc ~= "" then
            local locale = loc .. ( expansion ~= "vanilla"  and "-" .. expansion or "" )
            pfDB["objects"][locale] = pfDB["objects"][locale] or {}
            pfDB["objects"][locale][entry] = sanitize(name_loc)
          end
        end
      end
    end
  end

  do -- items locales
    local items_loc = {}
    local locales_item = {}
    local query = mysql:execute('SELECT *, item_template.entry AS _entry FROM item_template LEFT JOIN locales_item ON locales_item.entry = item_template.entry GROUP BY item_template.entry ORDER BY item_template.entry ASC')
    while query:fetch(locales_item, "a") do
      if debug("locales_item") then break end

      local entry = tonumber(locales_item["_entry"])
      local name  = locales_item.name

      if entry then
        for loc in pairs(locales) do
          local name_loc = locales_item["name_loc" .. locales[loc]]
          if not name_loc or name_loc == "" then name_loc = name or "" end
          if name_loc and name_loc ~= "" then
            local locale = loc .. ( expansion ~= "vanilla"  and "-" .. expansion or "" )
            pfDB["items"][locale] = pfDB["items"][locale] or {}
            pfDB["items"][locale][entry] = sanitize(name_loc)
          end
        end
      end
    end
  end

  do -- quests locales
    local locales_quest = {}
    local query = mysql:execute('SELECT *, quest_template.entry AS _entry FROM quest_template LEFT JOIN locales_quest ON locales_quest.entry = quest_template.entry GROUP BY quest_template.entry ORDER BY quest_template.entry ASC')
    while query:fetch(locales_quest, "a") do
      if debug("locales_quest") then break end

      for loc in pairs(locales) do
        local entry = tonumber(locales_quest["_entry"])

        if entry then
          local locale = loc .. ( expansion ~= "vanilla"  and "-" .. expansion or "" )
          pfDB["quests"][locale] = pfDB["quests"][locale] or {}

          local title_loc = locales_quest["Title_loc" .. locales[loc]]
          local details_loc = locales_quest["Details_loc" .. locales[loc]]
          local objectives_loc = locales_quest["Objectives_loc" .. locales[loc]]

          -- fallback to enUS titles
          if not title_loc or title_loc == "" then title_loc = locales_quest.Title or "" end
          if not details_loc or details_loc == "" then details_loc = locales_quest.Details or "" end
          if not objectives_loc or objectives_loc == "" then objectives_loc = locales_quest.Objectives or "" end

          pfDB["quests"][locale][entry] = {
            ["T"] = sanitize(title_loc),
            ["O"] = sanitize(objectives_loc),
            ["D"] = sanitize(details_loc)
          }
        end
      end
    end
  end

  do -- professions locales
    pfDB["professions"] = {}
    local locales_professions = {}
    local query = mysql:execute('SELECT * FROM pfquest.SkillLine_'..expansion..' ORDER BY id ASC')
    while query:fetch(locales_professions, "a") do
      if debug("locales_profession") then break end

      local entry = tonumber(locales_professions.id)

      if entry then
        for loc in pairs(locales) do
          local name = locales_professions["name_loc" .. locales[loc]]
          if name and name ~= "" then
            local locale = loc .. ( expansion ~= "vanilla"  and "-" .. expansion or "" )
            pfDB["professions"][locale] = pfDB["professions"][locale] or {}
            pfDB["professions"][locale][entry] = sanitize(name)
          end
        end
      end
    end
  end

  do -- zones locales
    local locales_zones = {}
    local query = mysql:execute('SELECT * FROM pfquest.AreaTable_'..expansion..' ORDER BY id ASC')
    while query:fetch(locales_zones, "a") do
      if debug("locales_zone") then break end

      local entry = tonumber(locales_zones.id)

      if entry then
        for loc in pairs(locales) do
          local name = locales_zones["name_loc" .. locales[loc]]
          if name and name ~= "" then
            local locale = loc .. ( expansion ~= "vanilla"  and "-" .. expansion or "" )
            pfDB["zones"][locale] = pfDB["zones"][locale] or {}
            pfDB["zones"][locale][entry] = sanitize(name)
          end
        end
      end
    end
  end

  if expansion ~= "vanilla" then
    print("- compress DB")
    pfDB["areatrigger"][data] = tablesubstract(pfDB["areatrigger"][data], pfDB["areatrigger"]["data"])
    pfDB["units"][data] = tablesubstract(pfDB["units"][data], pfDB["units"]["data"])
    pfDB["objects"][data] = tablesubstract(pfDB["objects"][data], pfDB["objects"]["data"])
    pfDB["items"][data] = tablesubstract(pfDB["items"][data], pfDB["items"]["data"])
    pfDB["refloot"][data] = tablesubstract(pfDB["refloot"][data], pfDB["refloot"]["data"])
    pfDB["quests"][data] = tablesubstract(pfDB["quests"][data], pfDB["quests"]["data"])
    pfDB["quests-itemreq"][data] = tablesubstract(pfDB["quests-itemreq"][data], pfDB["quests-itemreq"]["data"])
    pfDB["zones"][data] = tablesubstract(pfDB["zones"][data], pfDB["zones"]["data"])
    pfDB["minimap"..exp] = tablesubstract(pfDB["minimap"..exp], pfDB["minimap"])
    pfDB["meta"..exp] = tablesubstract(pfDB["meta"..exp], pfDB["meta"])

    for loc in pairs(locales) do
      local locale = loc .. exp
      local prev_locale = loc

      pfDB["units"][locale] = pfDB["units"][locale] and tablesubstract(pfDB["units"][locale], pfDB["units"][prev_locale]) or {}
      pfDB["objects"][locale] = pfDB["objects"][locale] and tablesubstract(pfDB["objects"][locale], pfDB["objects"][prev_locale]) or {}
      pfDB["items"][locale] = pfDB["items"][locale] and tablesubstract(pfDB["items"][locale], pfDB["items"][prev_locale]) or {}
      pfDB["quests"][locale] = pfDB["quests"][locale] and tablesubstract(pfDB["quests"][locale], pfDB["quests"][prev_locale]) or {}
      pfDB["zones"][locale] = pfDB["zones"][locale] and tablesubstract(pfDB["zones"][locale], pfDB["zones"][prev_locale]) or {}
      pfDB["professions"][locale] = pfDB["professions"][locale] and tablesubstract(pfDB["professions"][locale], pfDB["professions"][prev_locale]) or {}
    end
  end

  -- write down tables
  print("- writing database...")
  local output = settings.custom and "output/custom/" or "output/"

  os.execute("mkdir -p " .. output)
  serialize(output .. string.format("areatrigger%s.lua", exp), "pfDB[\"areatrigger\"][\""..data.."\"]", pfDB["areatrigger"][data])
  serialize(output .. string.format("units%s.lua", exp), "pfDB[\"units\"][\""..data.."\"]", pfDB["units"][data])
  serialize(output .. string.format("objects%s.lua", exp), "pfDB[\"objects\"][\""..data.."\"]", pfDB["objects"][data])
  serialize(output .. string.format("items%s.lua", exp), "pfDB[\"items\"][\""..data.."\"]", pfDB["items"][data])
  serialize(output .. string.format("refloot%s.lua", exp), "pfDB[\"refloot\"][\""..data.."\"]", pfDB["refloot"][data])
  serialize(output .. string.format("quests%s.lua", exp), "pfDB[\"quests\"][\""..data.."\"]", pfDB["quests"][data])
  serialize(output .. string.format("quests-itemreq%s.lua", exp), "pfDB[\"quests-itemreq\"][\""..data.."\"]", pfDB["quests-itemreq"][data])
  serialize(output .. string.format("zones%s.lua", exp), "pfDB[\"zones\"][\""..data.."\"]", pfDB["zones"][data])
  serialize(output .. string.format("minimap%s.lua", exp), "pfDB[\"minimap"..exp.."\"]", pfDB["minimap"..exp])
  serialize(output .. string.format("meta%s.lua", exp), "pfDB[\"meta"..exp.."\"]", pfDB["meta"..exp])

  for loc in pairs(locales) do
    local locale = loc .. ( expansion ~= "vanilla"  and "-" .. expansion or "" )

    os.execute("mkdir -p " .. output .. loc)
    serialize(output .. string.format("%s/units%s.lua", loc, exp), "pfDB[\"units\"][\""..locale.."\"]", pfDB["units"][locale])
    serialize(output .. string.format("%s/objects%s.lua", loc, exp), "pfDB[\"objects\"][\""..locale.."\"]", pfDB["objects"][locale])
    serialize(output .. string.format("%s/items%s.lua", loc, exp), "pfDB[\"items\"][\""..locale.."\"]", pfDB["items"][locale])
    serialize(output .. string.format("%s/quests%s.lua", loc, exp), "pfDB[\"quests\"][\""..locale.."\"]", pfDB["quests"][locale])
    serialize(output .. string.format("%s/professions%s.lua", loc, exp), "pfDB[\"professions\"][\""..locale.."\"]", pfDB["professions"][locale])
    serialize(output .. string.format("%s/zones%s.lua", loc, exp), "pfDB[\"zones\"][\""..locale.."\"]", pfDB["zones"][locale])
  end

  if not settings.custom then
    serialize(output .. "init.lua", "pfDB", pfDB, nil, true)
  end

  debug_statistics()
end
