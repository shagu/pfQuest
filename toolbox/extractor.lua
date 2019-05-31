#!/usr/bin/lua
-- depends on luasql

-- map pngs with alpha channel generated with:
-- `convert $file  -transparent white -resize '100x100!' $file`

do -- server config
  cmangos = setmetatable({}, { __index = function(tab,key)
    local value = tostring(key)
    rawset(tab,key,value)
    return value
  end})

  vmangos = {
    ["cmangos-vanilla"] = "vmangos",
    ["Id"] = "entry",
    ["Entry"] = "entry",
    ["Faction"] = "faction",
    ["Name"] = "name",
    ["MinLevel"] = "level_min",
    ["MaxLevel"] = "level_max",
    ["Rank"] = "rank",
    ["RequiresSpellFocus"] = "requiresSpellFocus",
    ["dbscripts_on_event"] = "event_scripts",
  }
end

local C = vmangos

local target = {
  ["init"] = true,
  ["unit"] = true,
  ["object"] = true,
  ["item"] = true,
  ["quest"] = true,
  ["meta"] = true,
}

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

    -- no mapfile means valid map
    if not maps[map] then return true end

    -- error handling
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

do -- environment
  -- available locales
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

  -- create required directories
  for loc in pairs(locales) do
    os.execute("mkdir -p output/" .. loc)
  end
end

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

  function hasdata(tbl)
    for _ in pairs(tbl) do
      return true
    end
    return nil
  end
end

do -- database connection
  luasql = require("luasql.mysql").mysql()
  mysql = luasql:connect(C["cmangos-vanilla"],"mangos","mangos","127.0.0.1")
end

do -- database query functions
  function GetCreatureCoords(id)
    local creature = {}
    local ret = {}

    local sql = [[
      SELECT * FROM creature LEFT JOIN aowow.aowow_zones
      ON ( aowow.aowow_zones.mapID = creature.map
        AND aowow.aowow_zones.x_min < creature.position_x
        AND aowow.aowow_zones.x_max > creature.position_x
        AND aowow.aowow_zones.y_min < creature.position_y
        AND aowow.aowow_zones.y_max > creature.position_y
        AND aowow.aowow_zones.areatableID > 0)
      WHERE creature.id = ]] .. id

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
          local coord = { px, py, zone, ( tonumber(creature.spawntimesecsmin) > 0 and creature.spawntimesecsmin or 0) }
          table.insert(ret, coord)
        end
      end
    end

    return ret
  end

  function GetGameObjectCoords(id)
    local gameobject = {}
    local ret = {}

    local sql = [[
      SELECT * FROM gameobject LEFT JOIN aowow.aowow_zones
      ON ( aowow.aowow_zones.mapID = gameobject.map
        AND aowow.aowow_zones.x_min < gameobject.position_x
        AND aowow.aowow_zones.x_max > gameobject.position_x
        AND aowow.aowow_zones.y_min < gameobject.position_y
        AND aowow.aowow_zones.y_max > gameobject.position_y
        AND aowow.aowow_zones.areatableID > 0)
      WHERE gameobject.id = ]] .. id

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
          local coord = { px, py, zone, ( tonumber(gameobject.spawntimesecsmin) > 0 and gameobject.spawntimesecsmin or 0) }
          table.insert(ret, coord)
        end
      end
    end

    return ret
  end
end

do -- nice progress display
  progress = {}
  progress.cache = {}
  progress.lastmsg = ""

  function progress:InitTable(sqltable)
    local ret = {}
    local query = mysql:execute('SELECT COUNT(*) FROM ' .. sqltable)
    while query:fetch(ret, "a") do
      self.cache[sqltable] = { 1, ret['COUNT(*)'] }
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

    io.write("\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b")
    io.write(string.format("%.1f%%\t",perc, cur, max) .. msg .. "\t[" .. cur .. "/" .. max .. "]")
    io.flush()

    self.cache[sqltable][1] = self.cache[sqltable][1] + 1
  end
end

if target.init then -- initDB
  local file = io.open("output/init.lua", "w")
  file:write([[
pfDB = {
  ["units"] = {},
  ["objects"] = {},
  ["quests"] = {},
  ["items"] = {},
  ["zones"] = {},
  ["professions"] = {},
  ["meta"] = {},
}
  ]])
  file:close()
end

if target.unit then -- unitDB [data]
  local file = io.open("output/units.lua", "w")
  file:write("pfDB[\"units\"][\"data\"] = {\n")

  -- iterate over all creatures
  local creature_template = {}
  local query = mysql:execute('SELECT * FROM creature_template GROUP BY creature_template.entry ORDER BY creature_template.entry')
  while query:fetch(creature_template, "a") do
    progress:Print("creature_template", "unitDB (data)")

    local entry   = creature_template[C.Entry]
    local name    = creature_template[C.Name]
    local minlvl  = creature_template[C.MinLevel]
    local maxlvl  = creature_template[C.MaxLevel]
    local rnk     = creature_template[C.Rank]

    local lvl     = (minlvl == maxlvl) and minlvl or minlvl .. "-" .. maxlvl

    file:write("  [" .. entry .. "] = { -- " .. name .. "\n")
    file:write("    [\"lvl\"] = \"" .. lvl .. "\",\n")

    if tonumber(rnk) > 0 then
      file:write("    [\"rnk\"] = " .. rnk .. ",\n")
    end

    do -- detect faction
      local fac = ""
      local faction = {}
      local sql = [[
        SELECT A, H FROM creature_template, aowow.aowow_factiontemplate
        WHERE aowow.aowow_factiontemplate.factiontemplateID = creature_template.]] .. C.Faction .. [[
        AND creature_template.]] .. C.Entry .. [[ = ]] .. creature_template[C.Entry]

      local query = mysql:execute(sql)
      while query:fetch(faction, "a") do
        local A = faction.A
        local H = faction.H
        if A == "1" then fac = fac .. "A" end
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
      local query = mysql:execute('SELECT * FROM ' .. C.dbscripts_on_event .. ' WHERE ' .. C.dbscripts_on_event .. '.datalong = ' .. creature_template[C.Entry])
      while query:fetch(event_scripts, "a") do
        local script = event_scripts.datalong

        local spell_template = {}
        local query = mysql:execute('SELECT * FROM spell_template WHERE spell_template.requiresSpellFocus > 0 AND spell_template.effectMiscValue1 = ' .. event_scripts.id)
        while query:fetch(spell_template, "a") do
          local spellfocus = spell_template[C.RequiresSpellFocus]

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
    file:write("  },\n")
  end

  file:write("}\n")
  file:close()
  print()
end

if target.unit then -- unitDB [locales]
  local files = {}
  for loc in pairs(locales) do
    files[loc] = io.open("output/" .. loc .. "/units.lua", "w")
    files[loc]:write("pfDB[\"units\"][\"" .. loc .. "\"] = {\n")
  end

  local locales_creature = {}
  local query = mysql:execute('SELECT * FROM creature_template LEFT JOIN locales_creature ON locales_creature.entry = creature_template.entry GROUP BY creature_template.entry ORDER BY creature_template.entry ASC')
  while query:fetch(locales_creature, "a") do
    progress:Print("creature_template", "unitDB (lang)")

    local entry = locales_creature.entry
    local name  = locales_creature.name

    if entry then
      for loc in pairs(locales) do
        local name_loc = locales_creature["name_loc" .. locales[loc]]
        if not name_loc or name_loc == "" then name_loc = name or "" end
        files[loc]:write("  [" .. entry .. "] = \"" .. sanitize(name_loc) .. "\",\n")
      end
    end
  end

  for loc in pairs(locales) do
    files[loc]:write("}\n")
    files[loc]:close()
  end

  print()
end

if target.object then -- objectDB [data]
  local file = io.open("output/objects.lua", "w")
  file:write("pfDB[\"objects\"][\"data\"] = {\n")

  -- iterate over all objects
  local gameobject_template = {}
  local query = mysql:execute('SELECT * FROM gameobject_template GROUP BY gameobject_template.entry ORDER BY gameobject_template.entry ASC')
  while query:fetch(gameobject_template, "a") do
    progress:Print("gameobject_template", "objectDB (data)")

    local entry   = gameobject_template.entry
    file:write("  [" .. entry .. "] = { -- " .. gameobject_template.name .. "\n")

    do -- detect faction
      local fac = ""
      local faction = {}
      local sql = [[
        SELECT A FROM gameobject_template, aowow.aowow_factiontemplate
        WHERE aowow.aowow_factiontemplate.factiontemplateID = gameobject_template.faction
        AND gameobject_template.entry = ]] .. gameobject_template.entry

      local query = mysql:execute(sql)
      while query:fetch(faction, "a") do
        local A = faction.A
        if A == "1" then fac = fac .. "A" end
      end

      local faction = {}
      local sql = [[
        SELECT H FROM gameobject_template, aowow.aowow_factiontemplate
        WHERE aowow.aowow_factiontemplate.factiontemplateID = gameobject_template.faction
        AND gameobject_template.entry = ]] .. gameobject_template.entry

      local query = mysql:execute(sql)
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

      for id,data in pairs(GetGameObjectCoords(entry)) do
        local x,y,zone,respawn = unpack(data)
        if count == 0 then
          file:write("    [\"coords\"] = {\n")
        end
        count = count + 1
        file:write(string.format("      [%s] = { %s, %s, %s, %s },\n", count, x, y, zone, respawn))
      end

      if count > 0 then
        file:write("    },\n")
      end
    end
    file:write("  },\n")
  end

  file:write("}\n")
  file:close()
  print()
end

if target.object then -- objectDB [locales]
  local files = {}
  for loc in pairs(locales) do
    files[loc] = io.open("output/" .. loc .. "/objects.lua", "w")
    files[loc]:write("pfDB[\"objects\"][\"" .. loc .. "\"] = {\n")
  end

  local locales_gameobject = {}
  local query = mysql:execute('SELECT * FROM gameobject_template LEFT JOIN locales_gameobject ON locales_gameobject.entry = gameobject_template.entry GROUP BY gameobject_template.entry ORDER BY gameobject_template.entry ASC')
  while query:fetch(locales_gameobject, "a") do
    progress:Print("gameobject_template", "objectDB (lang)")

    local entry = locales_gameobject.entry
    local name  = locales_gameobject.name

    if entry then
      for loc in pairs(locales) do
        local name_loc = locales_gameobject["name_loc" .. locales[loc]]
        if not name_loc or name_loc == "" then name_loc = name or "" end
        files[loc]:write("  [" .. entry .. "] = \"" .. sanitize(name_loc) .. "\",\n")
      end
    end
  end

  for loc in pairs(locales) do
    files[loc]:write("}\n")
    files[loc]:close()
  end

  print()
end

if target.item then -- itemDB [data]
  local file = io.open("output/items.lua", "w")
  file:write("pfDB[\"items\"][\"data\"] = {\n")

  -- iterate over all items
  local item_template = {}
  local query = mysql:execute('SELECT entry, name FROM item_template GROUP BY item_template.entry ASC')
  while query:fetch(item_template, "a") do
    progress:Print("item_template", "itemDB (data)")

    local items = { [0] = { item_template.entry, nil } }
    local subdata = {
      ["U"] = {},
      ["O"] = {},
      ["V"] = {},
    }

    -- add items that contain the actual item to the itemlist
    local item_loot_item = {}
    local count = 0
    local query = mysql:execute('SELECT entry, ChanceOrQuestChance FROM item_loot_template WHERE item = ' .. item_template.entry .. ' ORDER BY entry')
    while query:fetch(item_loot_item, "a") do
      if math.abs(item_loot_item.ChanceOrQuestChance) > 0 then
        table.insert(items, { item_loot_item.entry, math.abs(item_loot_item.ChanceOrQuestChance) })
      end
    end

    -- recursively read U, O, V blocks of the item
    for id, item in pairs(items) do
      local entry = item[1]
      local chance = item[2] and item[2] / 100 or 1

      -- fill unit table
      local creature_loot_template = {}
      local count = 0
      local query = mysql:execute('SELECT entry, ChanceOrQuestChance FROM creature_loot_template WHERE item = ' .. entry .. ' ORDER BY entry')
      while query:fetch(creature_loot_template, "a") do
        local chance = round(math.abs(creature_loot_template.ChanceOrQuestChance) * chance, 5)
        if chance > 0 then
          table.insert(subdata.U, { creature_loot_template.entry, chance })
        end
      end


      -- fill object table (reference_loot)
      local gameobject_loot_template = {}
      local count = 0
      local query = mysql:execute([[
        SELECT creature_loot_template.entry, creature_loot_template.ChanceOrQuestChance FROM reference_loot_template
        INNER JOIN creature_loot_template ON creature_loot_template.item = reference_loot_template.entry
        AND reference_loot_template.item = ]] .. entry .. [[
        AND creature_loot_template.mincountOrRef < 0
        ORDER BY creature_loot_template.entry;
      ]])

      while query:fetch(gameobject_loot_template, "a") do
        local chance = round(math.abs(gameobject_loot_template.ChanceOrQuestChance) * chance, 5)
        if chance > 0 then
          table.insert(subdata.U, { gameobject_loot_template.entry, chance })
        end
      end

      -- fill object table (object_loot)
      local gameobject_loot_template = {}
      local count = 0
      local query = mysql:execute([[
        SELECT gameobject_template.entry, gameobject_loot_template.ChanceOrQuestChance FROM gameobject_loot_template
        INNER JOIN gameobject_template ON gameobject_template.data1 = gameobject_loot_template.entry
        WHERE ( gameobject_template.type = 3 OR gameobject_template.type = 25 )
        AND gameobject_loot_template.item = ]] .. entry .. [[ ORDER BY gameobject_template.entry ]])
      while query:fetch(gameobject_loot_template, "a") do
        local chance = round(math.abs(gameobject_loot_template.ChanceOrQuestChance) * chance, 5)
        if chance > 0 then
          table.insert(subdata.O, { gameobject_loot_template.entry, chance })
        end
      end

      -- fill object table (reference_loot)
      local gameobject_loot_template = {}
      local count = 0
      local query = mysql:execute([[
        SELECT gameobject_template.entry, gameobject_loot_template.ChanceOrQuestChance FROM reference_loot_template
        INNER JOIN gameobject_loot_template ON gameobject_loot_template.item = reference_loot_template.entry
        INNER JOIN gameobject_template ON gameobject_loot_template.entry = gameobject_template.data1
        WHERE ( gameobject_template.type = 3 OR gameobject_template.type = 25 )
        AND reference_loot_template.item = ]] .. entry .. [[
        AND gameobject_loot_template.mincountOrRef < 0
        ORDER BY gameobject_template.entry;
      ]])

      while query:fetch(gameobject_loot_template, "a") do
        local chance = round(math.abs(gameobject_loot_template.ChanceOrQuestChance) * chance, 5)
        if chance > 0 then
          table.insert(subdata.O, { gameobject_loot_template.entry, chance })
        end
      end

      local npc_vendor = {}
      local count = 0
      local query = mysql:execute('SELECT entry, maxcount FROM npc_vendor WHERE item = ' .. entry .. ' ORDER BY entry')
      while query:fetch(npc_vendor, "a") do
        table.insert(subdata.V, { npc_vendor.entry, npc_vendor.maxcount })
      end
    end

    -- write item entries
    file:write("  [" .. item_template.entry .. "] = { -- " .. item_template.name .. "\n")
    for _, t in pairs({ "U", "O", "V"}) do
      if #subdata[t] > 0 then
        table.sort(subdata[t], function(a,b) return a[2] > b[2] end)
        local cache = {}
        file:write("    [\"" .. t .. "\"] = {\n")
        for _, data in pairs(subdata[t]) do
          if not cache[data[1]] then
            file:write("      [" .. data[1] .. "] = " .. data[2] .. ",\n")
            cache[data[1]] = true
          end
        end
        file:write("    },\n")
      end
    end
    file:write("  },\n")
  end

  file:write("}\n")
  file:close()
  print()
end

if target.item then -- itemDB [locales]
  local files = {}
  for loc in pairs(locales) do
    files[loc] = io.open("output/" .. loc .. "/items.lua", "w")
    files[loc]:write("pfDB[\"items\"][\"" .. loc .. "\"] = {\n")
  end

  local locales_item = {}
  local query = mysql:execute('SELECT * FROM item_template LEFT JOIN locales_item ON locales_item.entry = item_template.entry GROUP BY item_template.entry ORDER BY item_template.entry ASC')
  while query:fetch(locales_item, "a") do
    progress:Print("item_template", "itemDB (lang)")

    local entry = locales_item.entry
    local name  = locales_item.name

    if entry then
      for loc in pairs(locales) do
        local name_loc = locales_item["name_loc" .. locales[loc]]
        if not name_loc or name_loc == "" then name_loc = name or "" end
        files[loc]:write("  [" .. entry .. "] = \"" .. sanitize(name_loc) .. "\",\n")
      end
    end
  end

  for loc in pairs(locales) do
    files[loc]:write("}\n")
    files[loc]:close()
  end

  print()
end

if target.quest then -- questDB [data]
  local quest_template = {}
  local file = io.open("output/quests.lua", "w")
  file:write("pfDB[\"quests\"][\"data\"] = {\n")

  local sql = [[
    SELECT * FROM quest_template GROUP BY quest_template.entry ]]

  local query = mysql:execute(sql)
  while query:fetch(quest_template, "a") do
    progress:Print("quest_template", "questDB (data)")
    file:write("  [" .. quest_template.entry .. "] = {\n")

    if quest_template.MinLevel and quest_template.MinLevel ~= "0" then
      file:write("    [\"min\"] = " .. quest_template.MinLevel .. ",\n")
    end

    if quest_template.QuestLevel and quest_template.QuestLevel ~= "0" then
      file:write("    [\"lvl\"] = " .. quest_template.QuestLevel .. ",\n")
    end

    if quest_template.RequiredClasses and quest_template.RequiredClasses ~= "0" then
      file:write("    [\"class\"] = " .. quest_template.RequiredClasses .. ",\n")
    end

    if quest_template.RequiredRaces and quest_template.RequiredRaces ~= "0" then
      file:write("    [\"race\"] = " .. quest_template.RequiredRaces .. ",\n")
    end

    if quest_template.RequiredSkill and quest_template.RequiredSkill ~= "0" then
      file:write("    [\"skill\"] = " .. quest_template.RequiredSkill .. ",\n")
    end

    if quest_template.PrevQuestId and quest_template.PrevQuestId ~= "0" then
      file:write("    [\"pre\"] = " .. quest_template.PrevQuestId .. ",\n")
    end

    if quest_template.NextQuestInChain and quest_template.NextQuestInChain ~= "0" then
      file:write("    [\"next\"] = " .. quest_template.NextQuestInChain .. ",\n")
    end

    -- quest objectives
    local units, objects, items = {}, {}, {}

    for i=1,4 do
      if quest_template["ReqCreatureOrGOId" .. i] and tonumber(quest_template["ReqCreatureOrGOId" .. i]) > 0 then
        units[quest_template["ReqCreatureOrGOId" .. i]] = true
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

    -- scan required object/areas for usable quest items
    if quest_template["SrcItemId"] ~= "0" then
      local item_template = {}
      local query = mysql:execute('SELECT * FROM item_template WHERE item_template.entry = ' .. quest_template["SrcItemId"])
      while query:fetch(item_template, "a") do
        if item_template["spellid_1"] ~= "0" then
          local spell_template = {}
          local query = mysql:execute('SELECT * FROM spell_template WHERE spell_template.' .. C.Id .. ' = ' .. item_template["spellid_1"])
          while query:fetch(spell_template, "a") do
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
    end

    do -- write objectives
      if hasdata(units) or hasdata(objects) or hasdata(items) then
        file:write("    [\"obj\"] = {\n")

        local first = true
        for id in opairs(units) do
          if first then
            file:write("      [\"U\"] = { " .. id)
            first = false
          else
            file:write(", " .. id)
          end
        end
        if not first then file:write(" },\n") end

        local first = true
        for id  in opairs(objects) do
          if first then
            file:write("      [\"O\"] = { " .. id)
            first = false
          else
            file:write(", " .. id)
          end
        end
        if not first then file:write(" },\n") end

        local first = true
        for id in opairs(items) do
          if first then
            file:write("      [\"I\"] = { " .. id)
            first = false
          else
            file:write(", " .. id)
          end
        end
        if not first then file:write(" },\n") end

        file:write("    },\n")
      end
    end

    do -- quest starter
      local starter = true

      local creature_questrelation = {}
      local first = true
      local sql = [[
        SELECT * FROM creature_questrelation WHERE creature_questrelation.quest = ]] .. quest_template.entry
      local query = mysql:execute(sql)
      while query:fetch(creature_questrelation, "a") do
        if starter then file:write("    [\"start\"] = {\n"); starter = nil; end
        if first then
          file:write("      [\"U\"] = { " .. creature_questrelation.id)
          first = false
        else
          file:write(", " .. creature_questrelation.id)
        end
      end
      if not first then file:write(" },\n") end

      local gameobject_questrelation = {}
      local first = true
      local sql = [[
        SELECT * FROM gameobject_questrelation WHERE gameobject_questrelation.quest = ]] .. quest_template.entry
      local query = mysql:execute(sql)
      while query:fetch(gameobject_questrelation, "a") do
        if starter then file:write("    [\"start\"] = {\n"); starter = nil; end
        if first then
          file:write("      [\"O\"] = { " .. gameobject_questrelation.id)
          first = false
        else
          file:write(", " .. gameobject_questrelation.id)
        end
      end
      if not first then file:write(" },\n") end

      if not starter then file:write("    },\n") end
    end

    do -- quest ender
      local ender = true

      local creature_involvedrelation = {}
      local first = true
      local sql = [[
        SELECT * FROM creature_involvedrelation WHERE creature_involvedrelation.quest = ]] .. quest_template.entry
      local query = mysql:execute(sql)
      while query:fetch(creature_involvedrelation, "a") do
        if ender then file:write("    [\"end\"] = {\n"); ender = nil; end
        if first then
          file:write("      [\"U\"] = { " .. creature_involvedrelation.id)
          first = false
        else
          file:write(", " .. creature_involvedrelation.id)
        end
      end
      if not first then file:write(" },\n") end

      local gameobject_involvedrelation = {}
      local first = true
      local sql = [[
        SELECT * FROM gameobject_involvedrelation WHERE gameobject_involvedrelation.quest = ]] .. quest_template.entry
      local query = mysql:execute(sql)
      while query:fetch(gameobject_involvedrelation, "a") do
        if ender then file:write("    [\"end\"] = {\n"); ender = nil; end
        if first then
          file:write("      [\"O\"] = { " .. gameobject_involvedrelation.id)
          first = false
        else
          file:write(", " .. gameobject_involvedrelation.id)
        end
      end
      if not first then file:write(" },\n") end

      if not ender then file:write("    },\n") end
    end

    file:write("  },\n")
  end

  file:write("}\n")
  print()
end

if target.quest then -- questDB [locales]
  local files = {}
  for loc in pairs(locales) do
    files[loc] = io.open("output/" .. loc .. "/quests.lua", "w")
    files[loc]:write("pfDB[\"quests\"][\"" .. loc .. "\"] = {\n")
  end

  local locales_quest = {}
  local query = mysql:execute('SELECT * FROM quest_template LEFT JOIN locales_quest ON locales_quest.entry = quest_template.entry GROUP BY quest_template.entry ORDER BY quest_template.entry ASC')
  while query:fetch(locales_quest, "a") do
    progress:Print("quest_template", "questDB (lang)")

    for loc in pairs(locales) do
      local entry = locales_quest.entry

      local title_loc = locales_quest["Title_loc" .. locales[loc]]
      local details_loc = locales_quest["Details_loc" .. locales[loc]]
      local objectives_loc = locales_quest["Objectives_loc" .. locales[loc]]

      if not title_loc or title_loc == "" then title_loc = locales_quest.Title or "" end
      if not details_loc or details_loc == "" then details_loc = locales_quest.Details or "" end
      if not objectives_loc or objectives_loc == "" then objectives_loc = locales_quest.Objectives or "" end

      if entry then
        files[loc]:write("  [" .. entry .. "] = {\n")
        files[loc]:write("    [\"T\"] = \"" .. sanitize(title_loc) .. "\",\n")
        files[loc]:write("    [\"O\"] = \"" .. sanitize(objectives_loc) .. "\",\n")
        files[loc]:write("    [\"D\"] = \"" .. sanitize(details_loc) .. "\",\n")
        files[loc]:write("  },\n")
      end
    end
  end

  for loc in pairs(locales) do
    files[loc]:write("}\n")
    files[loc]:close()
  end

  print()
end

if target.meta then -- metaDB [data]
  local file = io.open("output/meta.lua", "w")

  --[[
  extract Lock.dbc relations to gameobject_template data0:

    #!/bin/bash
    function add_skills() {
      cat Lock.dbc.csv | while read line; do
        if [ "$(echo $line | cut -d "," -f 2)" = "0x2" ]; then
          if [ "$(echo $line | cut -d "," -f 10)" = "$1" ]; then
            echo -n " [$(echo $line | cut -d "," -f 1)] = $(echo $line | cut -d "," -f 18),"
          fi
        fi
      done
    }

    echo "skills = {"
    echo "  ["mining"] = {$(add_skills 3)},"
    echo "  ["herbalism"] = {$(add_skills 2)},"
    echo "  ["chests"] = { [57] = 0, }
    echo "}"
  ]]--

  local skills = {
    ["mines"] = {
      [18] = 25, [19] = 50, [20] = 75, [21] = 100, [22] = 125, [25] = 150, [38] = 0, [39] = 65, [40] = 75, [41] = 125,
      [42] = 155, [379] = 175, [380] = 230, [399] = 310, [400] = 245, [719] = 230, [939] = 275, [1632] = 305,
    },

    ["herbs"] = {
      [8] = 25, [9] = 50, [10] = 75, [11] = 100, [26] = 125, [27] = 150, [29] = 0, [30] = 15, [31] = 70, [32] = 115,
      [33] = 120, [34] = 130, [35] = 140, [45] = 125, [47] = 160, [48] = 215, [49] = 185, [50] = 205, [51] = 195,
      [439] = 210, [440] = 220, [441] = 230, [442] = 235, [443] = 245, [444] = 250, [519] = 85, [521] = 170,
      [1119] = 260, [1120] = 270, [1121] = 280, [1122] = 285, [1123] = 290, [1124] = 300,
    },

    ["chests"] = {
      [57] = 0,
    }
  }

  local mines = {}
  local herbs = {}
  local chests = {}

  do -- gameobject relations
    local gameobject_template = {}
    local query = mysql:execute('SELECT *  FROM `gameobject_template` WHERE `type` = 3 AND `flags` = 0 AND `data1` > 0 GROUP BY gameobject_template.entry ORDER BY gameobject_template.entry ASC')
    while query:fetch(gameobject_template, "a") do
      local entry   = tonumber(gameobject_template.entry) * -1
      local lockid  = tonumber(gameobject_template.data0)
      mines[entry] = skills["mines"][lockid] and skills["mines"][lockid] or nil
      herbs[entry] = skills["herbs"][lockid] and skills["herbs"][lockid] or nil
      chests[entry] = skills["chests"][lockid] and skills["chests"][lockid] or nil
    end
  end

  file:write("pfDB[\"meta\"][\"mines\"] = {\n")
  for id, skill in pairs(mines) do
    file:write("  [" .. id .. "] = " .. skill .. ",\n")
  end
  file:write("}\n")

  file:write("pfDB[\"meta\"][\"herbs\"] = {\n")
  for id, skill in pairs(herbs) do
    file:write("  [" .. id .. "] = " .. skill .. ",\n")
  end
  file:write("}\n")

  file:write("pfDB[\"meta\"][\"chests\"] = {\n")
  for id, skill in pairs(chests) do
    file:write("  [" .. id .. "] = " .. skill .. ",\n")
  end

  file:write("}\n")
end
