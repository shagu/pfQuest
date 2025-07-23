-- multi api compat
local compat = pfQuestCompat

-- fake the pfQuest minimap node names to Gatherer names,
-- if any minimap-breaking addon collector is found.
local nodename = "pfMiniMapPin"
local minimapbreakers = {
  ["ElvUI_MinimapButtons"] = true,
  ["MBB"] = true,
}

local compatnamefake = CreateFrame("Frame")
compatnamefake:RegisterEvent("PLAYER_ENTERING_WORLD")
compatnamefake:SetScript("OnEvent", function()
  -- only run once on login
  this:UnregisterAllEvents()

  -- scan through all addons to identify button collectors
  for i=1, GetNumAddOns() do
    local name, title, notes, enabled = GetAddOnInfo(i)
    if enabled and minimapbreakers[name] then
      nodename = "GatherNoteCompatFake"
    end
  end
end)

-- checking for control key is very time expensive in 1.12
-- this loop puts it into one place and only updates it every .2 seconds
-- it also only updates the key if the mouse is over a relevant frame
local controlkey = CreateFrame("Frame", "pfQuestControlKey", UIParent)
controlkey:SetScript("OnUpdate", function()
  if ( this.throttle or .2) > GetTime() then return else this.throttle = GetTime() + .2 end
  if WorldMapFrame:IsShown() and MouseIsOver(WorldMapFrame) or MouseIsOver(pfMap.drawlayer) then
    controlkey.pressed = IsControlKeyDown()
  end
end)

local validmaps = setmetatable({},{__mode="kv"})
local rgbcache = setmetatable({},{__mode="kv"})
local minimap_sizes = pfDB["minimap"]
local minimap_zoom = {
  [0] = { [0] = 300,
          [1] = 240,
          [2] = 180,
          [3] = 120,
          [4] = 80,
          [5] = 50,
         },

  [1] = { [0] = 466 + 2/3,
          [1] = 400,
          [2] = 333 + 1/3,
          [3] = 266 + 2/6,
          [4] = 200,
          [5] = 133 + 1/3,
        },
}

local unifiedcache = {}

-- used to store/cache combined meta data across nodes of
-- the same kind to avoid duplicating data for each pin
-- the objects here get directly attached to the pfMap nodes
local similar_nodes = {}

local function IsEmpty(tabl)
  for k,v in pairs(tabl) do
    return false
  end
  return true
end

local layers = {
  -- regular icons
  [pfQuestConfig.path.."\\img\\available"]          = 1,
  [pfQuestConfig.path.."\\img\\available_c"]        = 2,
  [pfQuestConfig.path.."\\img\\complete"]           = 3,
  [pfQuestConfig.path.."\\img\\complete_c"]         = 4,
  [pfQuestConfig.path.."\\img\\icon_vendor"]        = 5,
  [pfQuestConfig.path.."\\img\\fav"]                = 6,

  -- cluster textures
  [pfQuestConfig.path.."\\img\\cluster_item"]       = 9,
  [pfQuestConfig.path.."\\img\\cluster_mob"]        = 9,
  [pfQuestConfig.path.."\\img\\cluster_misc"]       = 9,
  [pfQuestConfig.path.."\\img\\cluster_mob_mono"]   = 9,
  [pfQuestConfig.path.."\\img\\cluster_item_mono"]  = 9,
  [pfQuestConfig.path.."\\img\\cluster_misc_mono"]  = 9,
}

local function GetLayerByTexture(tex)
  if layers[tex] then return layers[tex] else return 1 end
end

local function minimap_indoor()
  local tempzoom = 0
	local state = 1
	if GetCVar("minimapZoom") == GetCVar("minimapInsideZoom") then
		if GetCVar("minimapInsideZoom")+0 >= 3 then
			pfMap.drawlayer:SetZoom(pfMap.drawlayer:GetZoom() - 1)
			tempzoom = 1
		else
			pfMap.drawlayer:SetZoom(pfMap.drawlayer:GetZoom() + 1)
			tempzoom = -1
		end
	end

	if GetCVar("minimapInsideZoom")+0 == pfMap.drawlayer:GetZoom() then
    state = 0
  end

  pfMap.drawlayer:SetZoom(pfMap.drawlayer:GetZoom() + tempzoom)
	return state
end

local function str2rgb(text)
  if not text then return 1, 1, 1 end
  if pfQuest_colors[text] then return unpack(pfQuest_colors[text]) end
  if rgbcache[text] then return unpack(rgbcache[text]) end
  local counter = 1
  local l = string.len(text)
  for i = 1, l, 3 do
    counter = compat.mod(counter*8161, 4294967279) +
        (string.byte(text,i)*16776193) +
        ((string.byte(text,i+1) or (l-i+256))*8372226) +
        ((string.byte(text,i+2) or (l-i+256))*3932164)
  end
  local hash = compat.mod(compat.mod(counter, 4294967291),16777216)
  local r = (hash - (compat.mod(hash,65536))) / 65536
  local g = ((hash - r*65536) - ( compat.mod((hash - r*65536),256)) ) / 256
  local b = hash - r*65536 - g*256
  rgbcache[text] = { r / 255, g / 255, b / 255 }
  return unpack(rgbcache[text])
end

local fpsmod, step
local function NodeAnimate(self, zoom, alpha, fps)
  local cur_zoom = self:GetWidth()
  local cur_alpha = self:GetAlpha()
  local change = nil
  self:EnableMouse(true)
  fpsmod = math.min(2/fps, 2)
  step = fpsmod/10

  -- update size
  if math.abs(cur_zoom - zoom) < 3 then
    self:SetWidth(zoom)
    self:SetHeight(zoom)
  elseif cur_zoom < zoom then
    self:SetWidth(cur_zoom + fpsmod)
    self:SetHeight(cur_zoom + fpsmod)
    change = true
  elseif cur_zoom > zoom then
    self:SetWidth(cur_zoom - fpsmod)
    self:SetHeight(cur_zoom - fpsmod)
    change = true
  end

  -- update alpha
  if math.abs(cur_alpha - alpha) < step then
    self:SetAlpha(alpha)

    -- disable mouse on hidden
    if alpha < .1 then
      self:EnableMouse(nil)
    end
  elseif cur_alpha < alpha then
    self:SetAlpha(cur_alpha + step)
    change = true
  elseif cur_alpha > alpha then
    self:SetAlpha(cur_alpha - step)
    change = true
  end

  return change
end

-- put player position above everything on worldmap
for k, v in pairs({WorldMapFrame:GetChildren()}) do
  if v:IsObjectType("Model") and not v:GetName() then
    if string.find(strlower(v:GetModel()), "interface\\minimap\\minimaparrow") then
      v:SetFrameLevel(255)
      break
    end
  end
end

pfMap = CreateFrame("Frame", "pfQuestMap", WorldFrame)
pfMap.str2rgb = str2rgb
pfMap.tooltips = {}
pfMap.nodes = {}
pfMap.pins = {}
pfMap.mpins = {}
pfMap.drawlayer = Minimap
pfMap.unifiedcache = unifiedcache

pfMap.minimap_indoor = minimap_indoor
pfMap.minimap_zoom = minimap_zoom
pfMap.minimap_sizes = minimap_sizes

pfMap.tooltip = CreateFrame("Frame" , "pfMapTooltip", GameTooltip)
pfMap.tooltip:SetScript("OnShow", function()
  local focus = GetMouseFocus()
  -- abort on pfQuest nodes
  if focus and focus.title then return end
  -- abort on quest timers
  if focus and focus.GetName and strsub((focus:GetName() or ""),0,10) == "QuestTimer" then return end
  -- abort if tooltips are disabled
  if pfQuest_config.showtooltips == "0" then return end

  local name = getglobal("GameTooltipTextLeft1") and getglobal("GameTooltipTextLeft1"):GetText() or "__NONE__"
  local zone = pfMap:GetMapID(GetCurrentMapContinent(), GetCurrentMapZone())

  -- remove all colors from received tooltip text
  name = string.gsub(name, "|c%x%x%x%x%x%x%x%x", "")
  name = string.gsub(name, "|r", "")

  if pfMap.tooltips[name] and pfMap.tooltips[name] then
    for title, obj in pairs(pfMap.tooltips[name]) do
      if obj[zone] then
        pfMap:ShowTooltip(obj[zone], GameTooltip)
        GameTooltip:Show()
      end
    end
  end
end)

-- dummy function that can be used by extensions
-- to avoid drawing the minimap at some locations
function pfMap:HasMinimap()
  return true
end

function pfMap.tooltip:GetColor(min, max)
  local max = max or 1
  local min = min or max or 1

  local perc = min / max
  local r1, g1, b1, r2, g2, b2
  if perc <= 0.5 then
    perc = perc * 2
    r1, g1, b1 = 1, 0, 0
    r2, g2, b2 = 1, 1, 0
  else
    perc = perc * 2 - 1
    r1, g1, b1 = 1, 1, 0
    r2, g2, b2 = 0, 1, 0
  end
  r = r1 + (r2 - r1)*perc
  g = g1 + (g2 - g1)*perc
  b = b1 + (b2 - b1)*perc

  return r, g, b
end

function pfMap:HexDifficultyColor(level, force)
  if force and UnitLevel("player") < level then
    return "|cffff5555"
  else
    local c = pfQuestCompat.GetDifficultyColor(level)
    return string.format("|cff%02x%02x%02x", c.r*255, c.g*255, c.b*255)
  end
end

function pfMap:ShowTooltip(meta, tooltip)
  local catch = nil
  local catch_obj = nil
  local tooltip = tooltip or GameTooltip

  -- add quest data
  if meta["quest"] then
    -- scan all quest entries for matches
    for qid=1, GetNumQuestLogEntries() do
      local qtitle, _, _, _, _, complete = compat.GetQuestLogTitle(qid)

      if meta["quest"] == qtitle then
        -- handle active quests
        local objectives = GetNumQuestLeaderBoards(qid)
        catch = true

        local symbol = ( complete or objectives == 0 ) and "|cff555555[|cffffcc00?|cff555555]|r " or "|cff555555[|cffffcc00!|cff555555]|r "
        tooltip:AddLine(symbol .. meta["quest"], 1, 1, 0)

        if objectives then
          for i=1, objectives, 1 do
            local text, type, finished = GetQuestLogLeaderBoard(i, qid)

            if type == "monster" then
              -- kill
              local i, j, monsterName, objNum, objNeeded = strfind(text, pfUI.api.SanitizePattern(QUEST_MONSTERS_KILLED))
              if monsterName and meta["spawn"] == monsterName then
                catch_obj = true
                local r,g,b = pfMap.tooltip:GetColor(objNum, objNeeded)
                tooltip:AddLine("|cffaaaaaa- |r" .. monsterName .. ": " .. objNum .. "/" .. objNeeded, r, g, b)
              end
            elseif table.getn(meta["item"]) > 0 and type == "item" and meta["droprate"] then
              -- loot
              local i, j, itemName, objNum, objNeeded = strfind(text, pfUI.api.SanitizePattern(QUEST_OBJECTS_FOUND))

              for mid, item in pairs(meta["item"]) do
                if item == itemName then
                  catch_obj = true
                  local r,g,b = pfMap.tooltip:GetColor(objNum, objNeeded)
                  local dr,dg,db = pfMap.tooltip:GetColor(tonumber(meta["droprate"]), 100)
                  local lootcolor = string.format("%02x%02x%02x", dr * 255,dg * 255, db * 255)
                  tooltip:AddLine("|cffaaaaaa- |r" .. itemName .. ": " .. objNum .. "/" .. objNeeded .. " |cff555555[|cff" .. lootcolor .. meta["droprate"] .. "%|cff555555]", r, g, b)
                end
              end
            elseif table.getn(meta["item"]) > 0 and type == "item" and meta["sellcount"] then
              -- vendor
              local i, j, itemName, objNum, objNeeded = strfind(text, pfUI.api.SanitizePattern(QUEST_OBJECTS_FOUND))

              for mid, item in pairs(meta["item"]) do
                if item == itemName then
                  catch_obj = true
                  local r,g,b = pfMap.tooltip:GetColor(objNum, objNeeded)
                  local sellcount = tonumber(meta["sellcount"]) > 0 and " |cff555555[|cffcccccc" .. meta["sellcount"] .. "x" .. "|cff555555]" or ""
                  tooltip:AddLine("|cffaaaaaa- |r" .. pfQuest_Loc["Buy"] .. ": " .. itemName .. ": " .. objNum .. "/" .. objNeeded .. sellcount, r, g, b)
                end
              end
            end
          end
        end
      end
    end

    if not catch then
      tooltip:AddLine("|cff555555[|cffffcc00!|cff555555]|r " .. meta["quest"], 1, 1, .7)
    end

    if not catch_obj then
      -- handle inactive quests
      local catchFallback = nil

      if meta["item"] and meta["item"][1] and meta["droprate"] then
        for mid, item in pairs(meta["item"]) do
          catchFallback = true
          local dr, dg, db = pfMap.tooltip:GetColor(tonumber(meta["droprate"]), 100)
          local lootcolor = string.format("%02x%02x%02x", dr * 255, dg * 255, db * 255)
          tooltip:AddLine("|cffaaaaaa- |r" .. item .. " |cff555555[|cff" .. lootcolor .. meta["droprate"] .. "%|cff555555]", .7, .7, .7)
        end
      end

      if meta["item"] and meta["item"][1] and meta["sellcount"] then
        for mid, item in pairs(meta["item"]) do
          catchFallback = true
          local sellcount = tonumber(meta["sellcount"]) > 0 and " |cff555555[|cffcccccc" .. meta["sellcount"] .. "x" .. "|cff555555]" or ""
          tooltip:AddLine("|cffaaaaaa- |r" .. pfQuest_Loc["Buy"] .. ": " .. item .. sellcount, .7, .7, .7)
        end
      end

      if not catchFallback and meta["spawn"] and not meta["texture"] then
        catchFallback = true
        tooltip:AddLine("|cffaaaaaa- |r" .. (meta["spawntype"] and meta["spawntype"] == "Trigger" and pfQuest_Loc["Explore"] or meta["spawn"]), .7,.7,.7)
      end

      if not catchFallback and meta["texture"] and meta["qlvl"] then
        local texts = meta["questid"] and pfDB["quests"]["loc"][meta["questid"]] or nil

        if texts and texts["O"] and texts["O"] ~= "" then
          tooltip:AddLine(pfDatabase:FormatQuestText(texts["O"]),1,1,.9,true)
        end

        local qlvlstr = pfQuest_Loc["Level"] .. ": " .. pfMap:HexDifficultyColor(meta["qlvl"]) .. meta["qlvl"] .. "|r"
        local qminstr = meta["qmin"] and " / " .. pfQuest_Loc["Required"] .. ": " .. pfMap:HexDifficultyColor(meta["qmin"], true) .. meta["qmin"] .. "|r"  or ""
        tooltip:AddLine("|cffaaaaaa- |r" .. qlvlstr .. qminstr , .8,.8,.8)
      end
    end
  else
    -- handle non-quest objects
    if meta["item"][1] and meta["itemid"] and not meta["itemlink"] then
      local _, _, itemQuality = GetItemInfo(meta["itemid"])
      if itemQuality then
        local itemColor = "|c" .. string.format("%02x%02x%02x%02x", 255,
            ITEM_QUALITY_COLORS[itemQuality].r * 255,
            ITEM_QUALITY_COLORS[itemQuality].g * 255,
            ITEM_QUALITY_COLORS[itemQuality].b * 255)

        meta["itemlink"] = itemColor .."|Hitem:".. meta["itemid"] ..":0:0:0|h[".. meta["item"][1] .."]|h|r"
      end
    end

    if meta["sellcount"] then
      local item = meta["itemlink"] or "[" .. meta["item"][1] .. "]"
      local sellcount = tonumber(meta["sellcount"]) > 0 and " |cff555555[|cffcccccc" .. meta["sellcount"] .. "x" .. "|cff555555]" or ""
      tooltip:AddLine(pfQuest_Loc["Vendor"] .. ": " .. item .. sellcount, 1,1,1)
    elseif meta["item"][1] then
      local item = meta["itemlink"] or "[" .. meta["item"][1] .. "]"
      local r,g,b = pfMap.tooltip:GetColor(tonumber(meta["droprate"]), 100)
      tooltip:AddLine("|cffffffff" .. pfQuest_Loc["Loot"] .. ": " .. item ..  " |cff555555[|r" .. meta["droprate"] .. "%|cff555555]", r,g,b)
    end
  end

  tooltip:Show()
end

function pfMap:GetMapNameByID(id)
  id = tonumber(id)
  return pfDB["zones"]["loc"][id] or nil
end

function pfMap:GetMapIDByName(search)
  for id, name in pairs(pfDB["zones"]["loc"]) do
    if name == search then
      return id
    end
  end
end

function pfMap:ShowMapID(map)
  if map then
    if ToggleWorldMap then
      -- vanilla & tbc
      if not WorldMapFrame:IsShown() then
        ToggleWorldMap()
      end
    else
      -- wotlk
      WorldMapFrame:Show()
    end

    pfMap:SetMapByID(map)
    pfMap:UpdateNodes()
    return true
  end

  return nil
end

function pfMap:SetMapByID(id)
  local search = pfDB["zones"]["loc"][id]

  for cid, cname in pairs({GetMapContinents()}) do
    for mid, mname in pairs({GetMapZones(cid)}) do
      if mname == search then
        SetMapZoom(cid, mid)
        return
      end
    end
  end
end

local customids = {
  ["AlteracValley"] = 2597,
}

local map_zone_cache = { }
function pfMap:GetMapID(cid, mid)
  cid = cid or GetCurrentMapContinent()
  mid = mid or GetCurrentMapZone()

  -- GetMapZones() should always return the same amount
  -- of zones for each continent, so we can cache it to
  -- avoid further creations of the same table.
  if not map_zone_cache[cid] then
    map_zone_cache[cid] = { GetMapZones(cid) }
  end

  local list = map_zone_cache[cid]
  local name = list[mid]
  local id = pfMap:GetMapIDByName(name)
  id = id or customids[GetMapInfo()]

  return id
end

function pfMap:AddNode(meta)
  if not meta then return end
  if not meta["zone"] then return end
  if not meta["title"] then return end

  meta["description"] = pfDatabase:BuildQuestDescription(meta)

  local addon = meta["addon"] or "PFDB"
  local map = meta["zone"]
  local coords = meta["x"] .. "|" .. meta["y"]
  local title = meta["title"]
  local layer = GetLayerByTexture(meta["texture"])
  local spawn = meta["spawn"]
  local item = meta["item"]

  local sindex = string.format("%s:%s:%s:%s:%s:%s",
    (addon or ""), (map or ""), (coords or ""), (title or ""), (layer or ""), (spawn or ""), (item or ""))

  -- use prioritized clusters
  if layer >= 9 and meta["priority"] then
    layer = layer + (10 - min(meta["priority"], 10))
  end

  if not pfMap.nodes[addon] then pfMap.nodes[addon] = {} end
  if not pfMap.nodes[addon][map] then pfMap.nodes[addon][map] = {} end
  if not pfMap.nodes[addon][map][coords] then pfMap.nodes[addon][map][coords] = {} end

  -- skip early on existing nodes
  if pfMap.nodes[addon][map][coords][title] then
    if item and table.getn(pfMap.nodes[addon][map][coords][title].item) > 0 then
      -- check if item already exists
      for id, name in pairs(pfMap.nodes[addon][map][coords][title].item) do
        if name == item then return end
      end

      -- add new item and exit
      table.insert(pfMap.nodes[addon][map][coords][title].item, item)
      return
    end

    if pfMap.nodes[addon][map][coords][title] and pfMap.nodes[addon][map][coords][title].layer and layer and
     pfMap.nodes[addon][map][coords][title].layer >= layer then
      -- identical node already exists, exit here
      return
    end
  end

  -- create new combined data node from given meta data
  if not similar_nodes[sindex] then
    similar_nodes[sindex] = {}
    for key, val in pairs(meta) do similar_nodes[sindex][key] = val end
    similar_nodes[sindex].item = { [1] = item }
  end

  -- set current node to combined node
  pfMap.nodes[addon][map][coords][title] = similar_nodes[sindex]

  -- add node to unified cluster cache
  if not meta["cluster"] and not meta["texture"] then
    local node_index = meta.item or meta.spawn or UNKNOWN
    local x, y = tonumber(meta.x), tonumber(meta.y)

    -- create prerequisite table structure
    unifiedcache[title] = unifiedcache[title] or {}
    unifiedcache[title][map] = unifiedcache[title][map] or {}

    if not unifiedcache[title][map][node_index] then
      -- create new unified node from given meta data
      local unified_meta = {}
      for key, val in pairs(meta) do unified_meta[key] = val end

      -- save node to unified cache
      unifiedcache[title][map][node_index] = { meta = unified_meta, coords = {} }
    end

    -- append new coords to unified cache unified cache
    table.insert(unifiedcache[title][map][node_index].coords, { x, y })
  end

  -- add to gametooltips
  if spawn and title then
    pfMap.tooltips[spawn] = pfMap.tooltips[spawn] or {}
    pfMap.tooltips[spawn][title] = pfMap.tooltips[spawn][title] or {}
    pfMap.tooltips[spawn][title][map] = pfMap.tooltips[spawn][title][map] or similar_nodes[sindex]
  end

  pfMap.queue_update = GetTime()
end

function pfMap:GetNodes(addon, title)
  local nodes = {}

  if title and pfMap.nodes[addon] then
    for map, foo in pairs(pfMap.nodes[addon]) do
      for coords, node in pairs(pfMap.nodes[addon][map]) do
        if pfMap.nodes[addon][map][coords][title] then
          table.insert(nodes, pfMap.nodes[addon][map][coords][title])
        end
      end
    end
  end

  return nodes
end

function pfMap:DeleteNode(addon, title)
  -- remove tooltips
  if not addon then
    pfMap.tooltips = {}
  else
    for mk, mv in pairs(pfMap.tooltips) do
      for tk, tv in pairs(mv) do
        if ( title and tk == title ) or ( not title and tv.addon == addon ) then
          pfMap.tooltips[mk][tk] = nil
        end
      end
    end
  end

  -- remove nodes
  if not addon then
    pfMap.nodes = {}
  elseif not title then
    pfMap.nodes[addon] = {}
  elseif pfMap.nodes[addon] then
    for map, foo in pairs(pfMap.nodes[addon]) do
      for coords, node in pairs(pfMap.nodes[addon][map]) do
        if pfMap.nodes[addon][map][coords][title] then
          pfMap.nodes[addon][map][coords][title] = nil
          if IsEmpty(pfMap.nodes[addon][map][coords]) then
            pfMap.nodes[addon][map][coords] = nil
          end
        end
      end
    end
  end

  pfMap.queue_update = GetTime()
end

function pfMap:NodeClick()
  if IsShiftKeyDown() then
    if this.questid and this.texture and this.layer < 5 then
      -- mark questnode as done
      pfQuest_history[this.questid] = { time(), UnitLevel("player") }
    end

    if this.node and this.title and this.node[this.title] then
      -- delete node from map
      pfMap:DeleteNode(this.node[this.title].addon, this.title)
    end

    pfQuest.updateQuestGivers = true
  elseif this.texture and pfQuest.route and
   (( pfQuest_config["routecluster"] == "1" and this.layer >= 9 ) or
    ( pfQuest_config["routeender"] == "1" and this.layer == 4) or
    ( pfQuest_config["routestarter"] == "1" and this.layer == 1) or
    ( pfQuest_config["routestarter"] == "1" and this.layer == 2))
  then
    -- set as arrow target priority
    pfQuest.route.SetTarget((not pfQuest.route.IsTarget(this) and this))
    pfMap.queue_update = GetTime()
  else
    -- switch color
    pfQuest_colors[this.color] = { str2rgb(this.color .. GetTime()) }
    pfMap.queue_update = GetTime()
  end
end

function pfMap:NodeEnter()
  -- wotlk: need to disable blop tooltips first
  if compat.client >= 30300 then
    WorldMapPOIFrame.allowBlobTooltip = false
  end

  local tooltip = this:GetParent() == WorldMapButton and WorldMapTooltip or GameTooltip
  tooltip:SetOwner(this, "ANCHOR_LEFT")
  this.spawn = this.spawn or UNKNOWN
  tooltip:SetText(this.spawn..(pfQuest_config.showids == "1" and " |cffcccccc("..this.spawnid..")|r" or ""), .3, 1, .8)
  tooltip:AddDoubleLine(pfQuest_Loc["Level"] .. ":", (this.level or UNKNOWN), .8,.8,.8, 1,1,1)
  tooltip:AddDoubleLine(pfQuest_Loc["Type"] .. ":", (this.spawntype or UNKNOWN), .8,.8,.8, 1,1,1)
  tooltip:AddDoubleLine(pfQuest_Loc["Respawn"] .. ":", (this.respawn or UNKNOWN), .8,.8,.8, 1,1,1)

  for title, meta in pairs(this.node) do
    pfMap:ShowTooltip(meta, tooltip)
  end

  -- add tooltip help if setting is enabled
  if pfQuest_config["tooltiphelp"] == "1" then
    local text = pfQuest_Loc["Use <Shift>-Click To Remove Nodes"]

    if this.cluster then
      text = pfQuest_Loc["Hold <Ctrl> To Hide Cluster"]
    elseif tooltip == GameTooltip then
      text = pfQuest_Loc["Hold <Ctrl> To Hide Minimap Nodes"]
    elseif not this.texture then
      text = pfQuest_Loc["Click Node To Change Color"]
    elseif this.questid and this.texture and this.layer < 5 then
      text = pfQuest_Loc["Use <Shift>-Click To Mark Quest As Done"]
    end

    -- update tooltip and sizes
    tooltip:AddLine(text, .6, .6, .6)
    tooltip:Show()
  end

  pfMap.highlight = pfQuest_config["mouseover"] == "1" and this.title
end

function pfMap:NodeLeave()
  -- wotlk: re-enable blop tooltips
  if compat.client >= 30300 then
    WorldMapPOIFrame.allowBlobTooltip = true
  end

  local tooltip = this:GetParent() == WorldMapButton and WorldMapTooltip or GameTooltip
  tooltip:Hide()
  pfMap.highlight = nil
end

function pfMap:BuildNode(name, parent)
  local f = CreateFrame("Button", name, parent)

  if parent == WorldMapButton then
    f.defalpha = tonumber(pfQuest_config["worldmaptransp"]) or 1
    f.defsize = 16
  else
    f.defalpha = tonumber(pfQuest_config["minimaptransp"]) or 1
    f.defsize = 16
    f.minimap = true
  end

  f:SetWidth(f.defsize)
  f:SetHeight(f.defsize)

  f.Animate = NodeAnimate
  f:SetScript("OnEnter", pfMap.NodeEnter)
  f:SetScript("OnLeave", pfMap.NodeLeave)

  f.tex = f:CreateTexture(nil, "BACKGROUND")
  f.tex:SetAllPoints(f)

  f.pic = f:CreateTexture(nil, "NORMAL")
  f.pic:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -1)
  f.pic:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -1, 1)

  f.hl = f:CreateTexture(nil, "BORDER")
  f.hl:SetTexture(pfQuestConfig.path.."\\img\\track")
  f.hl:SetPoint("TOPLEFT", f, "TOPLEFT", -5, 5)
  f.hl:SetWidth(12)
  f.hl:SetHeight(12)
  return f
end

pfMap.highlightdb = {}
function pfMap:UpdateNode(frame, node, color, obj, distance)
  -- clear node to title association table
  if pfMap.highlightdb[frame] then
    for k,v in pairs(pfMap.highlightdb[frame]) do
      pfMap.highlightdb[frame][k] = nil
    end
  else
    pfMap.highlightdb[frame] = {}
  end

  -- reset layer
  frame.layer = 0

  for title, tab in pairs(node) do
    pfMap.highlightdb[frame][title] = true

    tab.layer = GetLayerByTexture(tab.texture)

    -- use prioritized clusters
    if tab.cluster and tab.priority then
      tab.layer = tab.layer + (10 - min(tab.priority , 10))
    end

    if tab.spawn and ( tab.layer > frame.layer or not frame.spawn ) then
      frame.updateTexture = (frame.texture ~= tab.texture)
      frame.updateVertex = (frame.vertex ~= tab.vertex )
      frame.updateColor = (frame.color ~= tab.color)
      frame.updateLayer = (frame.layer ~= tab.layer)

      -- set title and texture to the entry with highest layer
      -- and add core information
      frame.layer       = tab.layer
      frame.spawn       = tab.spawn
      frame.spawnid     = tab.spawnid
      frame.spawntype   = tab.spawntype
      frame.respawn     = tab.respawn
      frame.level       = tab.level
      frame.questid     = tab.questid
      frame.texture     = tab.texture
      frame.vertex      = tab.vertex
      frame.title       = title
      frame.func        = tab.func
      frame.cluster     = tab.cluster
      frame.description = tab.description
      frame.priority    = tab.priority
      frame.quest       = tab.quest
      frame.qlvl        = tab.qlvl
      frame.itemreq     = tab.itemreq
      frame.arrow       = tab.arrow
      frame.icon        = tab.icon

      if pfQuest_config["spawncolors"] == "1" then
        frame.color = tab.spawn or tab.title
      else
        frame.color = tab.title
      end
    end
  end

  if ( frame.updateTexture or frame.updateVertex or not frame.tex:GetTexture() ) and frame.texture then
    frame.tex:SetTexture(frame.texture)
    frame.tex:SetVertexColor(1,1,1)
    frame.pic:Hide()

    if frame.updateVertex and frame.vertex then
      local r, g, b = unpack(frame.vertex)
      if r > 0 or g > 0 or b > 0 then
        frame.tex:SetVertexColor(r, g, b, 1)
      end
    end
  end

  if ( frame.updateColor or frame.updateTexture or not frame.tex:GetTexture() ) and not frame.texture then
    local r, g, b = str2rgb(frame.color)

    if (frame.title and pfQuest.icons[frame.title]) or frame.icon then
      local texture = (frame.title and pfQuest.icons[frame.title]) or frame.icon
      frame.pic:SetTexture(texture)
      frame.pic:Show()

      if obj == "minimap" then
        -- Start fading the icon at 72% and have the icon fully
        -- translucent at 80% of half the minimap size.
        -- Fade animation range between 72% and 80%.
        local halfsize = pfMap.drawlayer:GetWidth()/2
        local fade_in = halfsize/100*72
        local fade_out = halfsize/100*80
        local alpha = ((distance or fade_out) - fade_in) / (fade_out - fade_in)
        alpha = math.max(alpha, 0)
        alpha = math.min(alpha, 1)
        frame.pic:SetAlpha(alpha)
      end
    else
      frame.pic:Hide()
    end

    if obj == "minimap" and pfQuest_config["cutoutminimap"] == "1" then
      frame.tex:SetTexture(pfQuestConfig.path.."\\img\\nodecut")
      frame.tex:SetVertexColor(r,g,b,1)
    elseif obj ~= "minimap" and pfQuest_config["cutoutworldmap"] == "1" then
      frame.tex:SetTexture(pfQuestConfig.path.."\\img\\nodecut")
      frame.tex:SetVertexColor(r,g,b,1)
    else
      frame.tex:SetTexture(pfQuestConfig.path.."\\img\\node")
      frame.tex:SetVertexColor(r,g,b,1)
    end
  end

  if frame.updateLayer then
    frame:SetFrameLevel((obj == "minimap" and 4 or 112) + frame.layer)
  end

  if frame.updateTexture or frame.updateVertex or frame.updateColor or frame.updateLayer then
    frame:SetScript("OnClick", (frame.func or pfMap.NodeClick))
  end

  local highlight = frame.texture and pfMap.highlightdb[frame][pfMap.highlight] and true or nil
  local target = frame.texture and pfQuest.route and pfQuest.route.IsTarget(frame) or nil

  -- set default sizes for different node types
  frame.defsize = (frame.cluster or frame.layer == 4) and 22 or 16

  -- make the current route target visible
  if target then frame.hl:Show() else frame.hl:Hide() end

  -- reset frame size except for highlights
  if not highlight then
    frame:SetWidth(frame.defsize)
    frame:SetHeight(frame.defsize)
  end

  frame.node = node
end

function pfMap:UpdateNodes()
  pfQuest:Debug("Update Nodes")

  local color = pfQuest_config["spawncolors"] == "1" and "spawn" or "title"
  local map = pfMap:GetMapID(GetCurrentMapContinent(), GetCurrentMapZone())
  local i = 1

  -- reset tracker
  pfQuest.tracker.Reset()

  -- reset route
  pfQuest.route:Reset()

  -- refresh all nodes
  for addon, _ in pairs(pfMap.nodes) do
    if pfMap.nodes[addon][map] then
      for coords, node in pairs(pfMap.nodes[addon][map]) do
        if not pfMap.pins[i] then
          pfMap.pins[i] = pfMap:BuildNode("pfMapPin" .. i, WorldMapButton)
        end

        pfMap:UpdateNode(pfMap.pins[i], node, color)

        -- set position
        local _, _, x, y = strfind(coords, "(.*)|(.*)")

        -- write points to the route plan
        if ( pfQuest_config["routecluster"] == "1" and pfMap.pins[i].layer >= 9 ) or
          ( pfQuest_config["routeender"] == "1" and pfMap.pins[i].layer == 4) or
          ( pfQuest_config["routestarter"] == "1" and pfMap.pins[i].layer == 1 and pfMap.pins[i].texture) or
          ( pfQuest_config["routestarter"] == "1" and pfMap.pins[i].layer == 2) or
          pfMap.pins[i].arrow == true
        then
          pfQuest.route:AddPoint({ x, y, pfMap.pins[i] })
        end

        -- hide cluster nodes if set
        if pfQuest_config["showcluster"] == "0" and pfMap.pins[i].cluster then
          pfMap.pins[i]:Hide()
        -- hide individual quest spawns
        elseif pfQuest_config["showspawn"] == "0" and addon == "PFQUEST" and not pfMap.pins[i].texture then
          pfMap.pins[i]:Hide()
        else
          -- populate quest list on map
          for title, node in pairs(pfMap.pins[i].node) do
            pfQuest.tracker.ButtonAdd(title, node)
          end

          x = x / 100 * WorldMapButton:GetWidth()
          y = y / 100 * WorldMapButton:GetHeight()

          pfMap.pins[i]:ClearAllPoints()
          pfMap.pins[i]:SetPoint("CENTER", WorldMapButton, "TOPLEFT", x, -y)

          pfMap.pins[i]:Show()
        end

        i = i + 1
      end
    end
  end

  -- hide remaining pins
  for j=i, table.getn(pfMap.pins) do
    if pfMap.pins[j] then pfMap.pins[j]:Hide() end
  end
end

local coord_cache = {}
function pfMap:UpdateMinimap()
  -- check for disabled minimap nodes
  if pfQuest_config["minimapnodes"] == "0" then
    return
  end

  -- hide all minimap nodes while shift is pressed
  if controlkey.pressed and MouseIsOver(pfMap.drawlayer) then
    this.xPlayer = nil

    for id, pin in pairs(pfMap.mpins) do
      pin:Hide()
    end

    return
  end

  -- hide nodes and skip further processing in dungeons
  local xPlayer, yPlayer = GetPlayerMapPosition("player")
  if xPlayer == 0 and yPlayer == 0 then
    for pins, pin in pairs(pfMap.mpins) do pin:Hide() end
    return
  end

  local mZoom = pfMap.drawlayer:GetZoom()
  xPlayer, yPlayer = xPlayer * 100, yPlayer * 100

  -- force refresh every second even without changed values, otherwise skip
  if this.xPlayer == xPlayer and this.yPlayer == yPlayer and this.mZoom == mZoom then
    if ( this.tick or 1) > GetTime() then return else this.tick = GetTime() + 1 end
  end

  this.xPlayer, this.yPlayer, this.mZoom = xPlayer, yPlayer, mZoom
  local color = pfQuest_config["spawncolors"] == "1" and "spawn" or "title"
  local mapID = pfMap:GetMapIDByName(GetRealZoneText())
  local mapZoom = minimap_zoom[minimap_indoor()][mZoom]
  local mapWidth = minimap_sizes[mapID] and minimap_sizes[mapID][1] or 0
  local mapHeight = minimap_sizes[mapID] and minimap_sizes[mapID][2] or 0

  local xScale = mapZoom / mapWidth
  local yScale = mapZoom / mapHeight

  local xDraw = pfMap.drawlayer:GetWidth() / xScale / 100
  local yDraw = pfMap.drawlayer:GetHeight() / yScale / 100

  local i = 1

  -- refresh all nodes
  for addon, data in pairs(pfMap.nodes) do
    -- hide minimap nodes in continent view
    if data[mapID] and minimap_sizes[mapID] and pfMap:HasMinimap(mapID) then
      for coords, node in pairs(data[mapID]) do
        local x, y
        if coord_cache[coords] then
          x, y = coord_cache[coords][1], coord_cache[coords][2]
        else
          local _, _, strx, stry = strfind(coords, "(.*)|(.*)")
          x, y = strx + 0, stry + 0
          coord_cache[coords] = { x, y }
        end

        local xPos = ( x - xPlayer) * xDraw
        local yPos = ( y - yPlayer) * yDraw

        if pfQuestCompat.rotateMinimap then
          -- TODO: this part is broken and does not work yet.
          local sinFacing = sin(pfQuestCompat.GetPlayerFacing())
          local cosFacing = cos(pfQuestCompat.GetPlayerFacing())

          local dx, dy = xPos, -yPos
          xPos = (dx * cosFacing) + (dy * sinFacing)
          yPos = -((-dx * sinFacing) + (dy * cosFacing))
        end

        local display = nil
        local distance = sqrt(xPos * xPos + yPos * yPos)

        if pfUI.minimap then
          display = ( abs(xPos) + 8 < pfMap.drawlayer:GetWidth() / 2 and abs(yPos) + 8 < pfMap.drawlayer:GetHeight()/2 ) and true or nil
        else
          display = ( distance + 8 < pfMap.drawlayer:GetWidth() / 2 ) and true or nil
        end

        if display then
          if not pfMap.mpins[i] then
            pfMap.mpins[i] = pfMap:BuildNode(nodename .. i, pfMap.drawlayer)
          end

          pfMap:UpdateNode(pfMap.mpins[i], node, color, "minimap", distance)

          pfMap.mpins[i].hl:Hide()

          if pfQuest_config["showclustermini"] == "0" and pfMap.mpins[i].cluster then
            pfMap.mpins[i]:Hide()
          elseif pfQuest_config["showspawnmini"] == "0" and addon == "PFQUEST" and not pfMap.mpins[i].texture then
            pfMap.mpins[i]:Hide()
          else
            pfMap.mpins[i]:ClearAllPoints()
            pfMap.mpins[i]:SetPoint("CENTER", pfMap.drawlayer, "CENTER", xPos, -yPos)
            pfMap.mpins[i]:Show()
          end

          i = i + 1
        end
      end
    end
  end

  -- hide remaining pins
  for j=i, table.getn(pfMap.mpins) do
    if pfMap.mpins[j] then pfMap.mpins[j]:Hide() end
  end
end

local zone, last_zone
pfMap:RegisterEvent("ZONE_CHANGED")
pfMap:RegisterEvent("ZONE_CHANGED_NEW_AREA")
pfMap:RegisterEvent("MINIMAP_ZONE_CHANGED")
pfMap:RegisterEvent("WORLD_MAP_UPDATE")
pfMap:SetScript("OnEvent", function()
  -- save current zone
  zone = GetCurrentMapZone()

  -- set map to current zone when possible
  if event == "ZONE_CHANGED" or event == "MINIMAP_ZONE_CHANGED" or event == "ZONE_CHANGED_NEW_AREA" then
    if not WorldMapFrame:IsShown() then
      SetMapToCurrentZone()
    end
  end

  -- update nodes on world map changes
  if event == "WORLD_MAP_UPDATE" and last_zone ~= zone then
    pfMap.UpdateNodes()
    last_zone = zone
  end
end)

local hlstate, shiftstate, transition, hidecluster, fps, resetmap
pfMap:SetScript("OnUpdate", function()
  -- handle highlights and animations
  if pfMap.queue_update or transition or pfMap.highlight ~= hlstate or shiftstate ~= hidecluster then
    hlstate, shiftstate, transition = pfMap.highlight, hidecluster, nil
    fps = math.max(.2, GetFramerate() / 30)

    for frame, data in pairs(pfMap.highlightdb) do
      local highlight = pfMap.highlightdb[frame][pfMap.highlight] and true or nil

      if hidecluster and frame.cluster then
        -- hide clusters
        transition = frame:Animate(frame.defsize, 0, fps) or transition
      elseif highlight then
        -- zoom node
        transition = frame:Animate((frame.texture and frame.defsize + 4 or frame.defsize), 1, fps) or transition
      elseif not highlight and pfMap.highlight then
        -- fade node
        transition = frame:Animate(frame.defsize, tonumber(pfQuest_config["nodefade"]) or 0.3, fps) or transition
      elseif frame.texture or frame.cluster then
        -- defaults for textured nodes
        transition = frame:Animate(frame.defsize, 1, fps) or transition
      else
        -- defaults
        transition = frame:Animate(frame.defsize, frame.defalpha, fps) or transition
      end
    end
  end

  -- limit all map updates to once per .05 seconds
  if ( this.throttle or .2) > GetTime() then return else this.throttle = GetTime() + .05 end

  -- process node updates if required
  if pfMap.queue_update and pfMap.queue_update + .25 < GetTime() then
    pfMap.queue_update = nil
    pfMap:UpdateNodes()
  end

  -- reset map to current zone once map is closed
  if WorldMapFrame:IsShown() then
    resetmap = true
  elseif resetmap == true then
    SetMapToCurrentZone()
    resetmap = nil
  end

  -- refresh minimap
  pfMap:UpdateMinimap()

  -- update hidecluster detection
  if controlkey.pressed then
    hidecluster = MouseIsOver(WorldMapFrame)
  else
    hidecluster = nil
  end
end)

-- only hook for 3.3.5
if compat.client >= 30300 then
  -- Initialize a variable to track the previous clicked title
  local previousTitle = nil
  -- Highlight Map Quest Log Selection Nodes
  local pfHookWorldMapQuestFrame_OnMouseUp = WorldMapQuestFrame_OnMouseUp
  WorldMapQuestFrame_OnMouseUp = function(self)
    pfHookWorldMapQuestFrame_OnMouseUp(self)
    WorldMapBlobFrame:Hide()
    WorldMapFrame_ClearQuestPOIs()
    if not IsShiftKeyDown() then
      pfMap.highlight = nil
      local questLogIndex = GetQuestLogSelection()
      local title = GetQuestLogTitle(questLogIndex)

      if title then
        if previousTitle == title then
          -- Reset the highlight if the same title is clicked again
          pfMap.highlight = nil
          previousTitle = nil
        else
          -- Logic for highlighting nodes associated with the clicked quest
          pfMap.highlight = title
          previousTitle = title
          pfMap.queue_update = GetTime()
        end
      end
    end
  end
end
