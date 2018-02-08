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

do -- progress
  progress = {}
  progress.cache = {}
  progress.lastmsg = ""

  function progress:InitTable(sqltable)
    local ret = {}
    local query = mysql:execute('SELECT COUNT(*) FROM ' .. sqltable)
    while query:fetch(ret, "a") do
      self.cache[sqltable] = { 0, ret['COUNT(*)'] }
      return true
    end
  end

  function progress:Print(sqltable, msg)
    if not self.cache[sqltable] or msg ~= self.lastmsg then
      self:InitTable(sqltable)
      self.lastmsg = msg
    end

    local cur, max = unpack(self.cache[sqltable])
    local perc = cur / max * 100

    io.write("\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b")
    io.write(msg .. string.format(": %.1f%%",perc))
    io.flush()

    self.cache[sqltable][1] = self.cache[sqltable][1] + 1
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
end

do -- database connection
  luasql = require("luasql.mysql").mysql()
  mysql = luasql:connect("elysium","mangos","mangos","127.0.0.1")
end

-- functions
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
      if isValidMap(zone, round(px), round(py)) then
        local coord = { px, py, zone, ( creature.spawntimesecsmin or 0) }
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
      if isValidMap(zone, round(px), round(py)) then
        local coord = { px, py, zone, ( gameobject.spawntimesecsmin or 0) }
        table.insert(ret, coord)
      end
    end
  end

  return ret
end

do -- unitDB [core]
  local file = io.open("unitDB.lua", "w")
  file:write("pfDB[\"units\"][\"core\"] = {\n")

  -- iterate over all creatures
  local creature_template = {}
  local query = mysql:execute('SELECT * FROM creature_template ORDER BY creature_template.entry ASC')
  while query:fetch(creature_template, "a") do
    progress:Print("creature_template", "unitDB (core)")

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
      local query = mysql:execute('SELECT A FROM creature_template, aowow.aowow_factiontemplate WHERE aowow.aowow_factiontemplate.factiontemplateID = creature_template.faction_A AND creature_template.entry = ' .. creature_template.entry)
      while query:fetch(faction, "a") do
        local A = faction.A
        if A == "1" then fac = fac .. "A" end
      end

      local faction = {}
      local query = mysql:execute('SELECT H FROM creature_template, aowow.aowow_factiontemplate WHERE aowow.aowow_factiontemplate.factiontemplateID = creature_template.faction_H AND creature_template.entry = ' .. creature_template.entry)
      while query:fetch(faction, "a") do
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
        local x,y,zone,respawn = unpack(data)
        if count == 0 then
          file:write("    [\"coords\"] = {\n")
        end
        count = count + 1
        file:write(string.format("      [%s] = { %s, %s, %s, %s },\n", count, x, y, zone, respawn))
      end

      -- search for summoned mobs
      local event_scripts = {}
      local query = mysql:execute('SELECT * FROM event_scripts WHERE event_scripts.datalong = ' .. creature_template.entry)
      while query:fetch(event_scripts, "a") do
        local script = event_scripts.datalong

        local spell_template = {}
        local query = mysql:execute('SELECT * FROM spell_template WHERE spell_template.requiresSpellFocus > 0 AND spell_template.effectMiscValue1 = ' .. event_scripts.id)
        while query:fetch(spell_template, "a") do
          local spellfocus = spell_template.requiresSpellFocus

          local gameobject_template = {}
          local query = mysql:execute('SELECT * FROM gameobject_template WHERE gameobject_template.type = 8 and gameobject_template.data0 = ' .. spellfocus)
          while query:fetch(gameobject_template, "a") do
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
  print()
end

do -- unitDB [locales]
  local files = {}
  for loc in pairs(locales) do
    files[loc] = io.open("unitDB_" .. loc .. ".lua", "w")
    files[loc]:write("pfDB[\"units\"][\"" .. loc .. "\"] = {\n")
  end

  local locales_creature = {}
  local query = mysql:execute('SELECT * FROM creature_template LEFT JOIN locales_creature ON locales_creature.entry = creature_template.entry ORDER BY creature_template.entry ASC')
  while query:fetch(locales_creature, "a") do
    progress:Print("creature_template", "unitDB (lang)")

    local entry = locales_creature.entry
    local name  = locales_creature.name

    if entry then
      for loc in pairs(locales) do
        local name_loc = locales_creature["name_loc" .. locales[loc]]
        files[loc]:write("  [" .. entry .. "] = \"" .. (name_loc or name) .. "\",\n")
      end
    end
  end

  for loc in pairs(locales) do
    files[loc]:write("}\n")
    files[loc]:close()
  end

  print()
end
