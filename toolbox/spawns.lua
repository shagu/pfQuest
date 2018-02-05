#!/usr/bin/lua
-- depends: pacman -S lua-sql-mysql

-- map pngs with alpha channel generated with: 
-- `convert $file  -transparent white -resize '100x100!' $file`

do -- helper functions
  function round(input, places)
    if not places then places = 0 end
    if type(input) == "number" and type(places) == "number" then
      local pow = 1
      for i = 1, places do pow = pow * 10 end
      return math.floor(input * pow + 0.5) / pow
    end
  end

  function sanitize(str)
    str = string.gsub(str, "\"", "\\\"")
    str = string.gsub(str, "\'", "\\\'")
    str = string.gsub(str, "\r", "")
    str = string.gsub(str, "\n", "")
    return str
  end
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

  function isValidMap(map,x,y)
    -- load map if required
    if not maps[map] and isFile("maps/" .. map .. ".png") then
      maps[map] = pngImage("maps/" .. map .. ".png")
    end

    -- error handling
    if not maps[map] then return false end
    if not maps[map].getPixel then return false end
    if x == 0 or y == 0 then return false end

    -- check pixel alpha
    local pixel = maps[map]:getPixel(x,y)
    if pixel and pixel.A and pixel.A > 0 then
      return true
    else
      return false
    end
  end
end

do -- locale detection
  locales = {
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

  loc_name = arg[1] or "enUS"

  if not locales[loc_name] then
    print("!! invalid locale !!")
    return 1
  end

  local loc_id = locales[loc_name]
end

do -- database connection
  luasql = require("luasql.mysql").mysql()
  mysql = luasql:connect("elysium","mangos","mangos","127.0.0.1")
end

local creature_template = {}
local aowowzones = {}
local event_scripts = {}
local spell_template = {}
local gameobject_template = {}


local function GetCreatureCoords(id)
  local creature = {}
  local ret = {}

  local sql = "\
    SELECT * FROM creature LEFT JOIN aowow.aowow_zones \
    ON ( aowow.aowow_zones.mapID = creature.map \
      AND aowow.aowow_zones.x_min < creature.position_x \
      AND aowow.aowow_zones.x_max > creature.position_x \
      AND aowow.aowow_zones.y_min < creature.position_y \
      AND aowow.aowow_zones.y_max > creature.position_y \
      AND aowow.aowow_zones.areatableID > 0) \
    \
    WHERE creature.id = " .. id

  local q2 = mysql:execute(sql)
  while q2:fetch(creature, "a") do

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
      if isValidMap(zone, round(px), round(py)) then
        local coord = { px, py, zone, ( creature.spawntimesecsmin or 0), ( creature.spawntimesecsmax or 0 ) }
        table.insert(ret, coord)
      end
    end
  end

  return ret
end

local function GetGameObjectCoords(id)
  local gameobject = {}
  local ret = {}

  local sql = "\
    SELECT * FROM gameobject LEFT JOIN aowow.aowow_zones \
    ON ( aowow.aowow_zones.mapID = gameobject.map \
      AND aowow.aowow_zones.x_min < gameobject.position_x \
      AND aowow.aowow_zones.x_max > gameobject.position_x \
      AND aowow.aowow_zones.y_min < gameobject.position_y \
      AND aowow.aowow_zones.y_max > gameobject.position_y \
      AND aowow.aowow_zones.areatableID > 0) \
    \
    WHERE gameobject.id = " .. id

  local q2 = mysql:execute(sql)
  while q2:fetch(gameobject, "a") do
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
      if isValidMap(zone, round(px), round(py)) then
        local coord = { px, py, zone, ( gameobject.spawntimesecsmin or 0), ( gameobject.spawntimesecsmax or 0 ) }
        table.insert(ret, coord)
      end
    end
  end

  return ret
end

do -- unitDB
  local file = io.open("unitDB.lua", "w")

  local progress = {}
  local progress_max = 0
  local progress_cur = 0
  local chksize = mysql:execute('SELECT COUNT(*) FROM creature_template ORDER BY creature_template.entry ASC')
  while chksize:fetch(progress, "a") do
    progress_max = progress['COUNT(*)']
  end


  file:write("pfDB[\"units\"][\"" .. loc_name .. "\"] = {\n")
  local q1 = mysql:execute('SELECT * FROM creature_template ORDER BY creature_template.entry ASC')
  while q1:fetch(creature_template, "a") do
    
    do -- update progress
      progress_cur = progress_cur + 1
      progress_perc = progress_cur / progress_max * 100

      io.write(string.format("unitDB: %.1f%%",progress_perc))
      io.flush()
      io.write("\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b")
    end
  
    local found_spawn = false
    local entry   = creature_template.entry
    local minlvl  = creature_template.minlevel
    local maxlvl  = creature_template.maxlevel
    local lvl     = (minlvl == maxlvl) and minlvl or minlvl .. "-" .. maxlvl
    local rnk     = creature_template.rank

    file:write("  [" .. entry .. "] = { -- " .. creature_template.name .. "\n")
    file:write("    [\"lvl\"] = \"" .. lvl .. "\",\n")

    if tonumber(rnk) > 0 then
      file:write("    [\"rnk\"] = " .. rnk .. ",\n")
    end

    do -- detect faction
      local fac = ""
      local faction = {}
      local q4 = mysql:execute('SELECT A FROM creature_template, aowow.aowow_factiontemplate WHERE aowow.aowow_factiontemplate.factiontemplateID = creature_template.faction_A AND creature_template.entry = ' .. creature_template.entry)
      while q4:fetch(faction, "a") do
        local A = faction.A
        if A == "1" then fac = fac .. "A" end
      end

      local faction = {}
      local q5 = mysql:execute('SELECT H FROM creature_template, aowow.aowow_factiontemplate WHERE aowow.aowow_factiontemplate.factiontemplateID = creature_template.faction_H AND creature_template.entry = ' .. creature_template.entry)
      while q5:fetch(faction, "a") do
        local H = faction.H
        if H == "1" then fac = fac .. "H" end
      end

      if fac ~= "" then
        file:write("    [\"fac\"] = \"" .. fac .. "\",\n")
      end
    end

    do -- coordinates
      local count = 0

      for id,data in pairs(GetCreatureCoords(entry)) do
        local x,y,zone,min,max = unpack(data)
        if count == 0 then 
          file:write("    [\"coords\"] = {\n") 
        end
        count = count + 1
        file:write(string.format("      [%s] = { %s, %s, %s, %s, %s },\n", count, x, y, zone, min, max))
      end
      
      -- search for summoned mobs
      local q3 = mysql:execute('SELECT * FROM event_scripts WHERE event_scripts.datalong = ' .. creature_template.entry)
      while q3:fetch(event_scripts, "a") do
        local script = event_scripts.datalong

        local q4 = mysql:execute('SELECT * FROM spell_template WHERE spell_template.requiresSpellFocus > 0 AND spell_template.effectMiscValue1 = ' .. event_scripts.id)
        while q4:fetch(spell_template, "a") do
          local spellfocus = spell_template.requiresSpellFocus
          local q5 = mysql:execute('SELECT * FROM gameobject_template WHERE gameobject_template.type = 8 and gameobject_template.data0 = ' .. spellfocus)
          while q5:fetch(gameobject_template, "a") do
            local object = gameobject_template.entry
            for id,data in pairs(GetGameObjectCoords(object)) do
              local x,y,zone,min,max = unpack(data)
              if count == 0 then 
                file:write("    [\"coords\"] = {\n") 
              end

              count = count + 1
              file:write(string.format("      [%s] = { %s, %s, %s, %s, %s },\n", count, x, y, zone, min, max))
            end
          end
        end
      end
      
      if count > 0 then 
        file:write("    },\n") 
      end
    end
    file:write("  }\n")
  end

  file:write("}\n")
  file:close()
end
