-- multi api compat
local compat = pfQuestCompat

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

local function IsEmpty(tabl)
  for k,v in pairs(tabl) do
    return false
  end
  return true
end

local layers = {
  [pfQuestConfig.path.."\\img\\available"]    = 1,
  [pfQuestConfig.path.."\\img\\available_c"]  = 2,
  [pfQuestConfig.path.."\\img\\complete"]     = 3,
  [pfQuestConfig.path.."\\img\\complete_c"]   = 4,
  [pfQuestConfig.path.."\\img\\icon_vendor"]  = 5,
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

pfMap = CreateFrame("Frame")
pfMap.tooltips = {}
pfMap.nodes = {}
pfMap.pins = {}
pfMap.mpins = {}
pfMap.drawlayer = Minimap

pfMap.tooltip = CreateFrame("Frame" , "pfMapTooltip", GameTooltip)
pfMap.tooltip:SetScript("OnShow", function()
  local focus = GetMouseFocus()
  -- abort on pfQuest nodes
  if focus and focus.title then return end
  -- abort on quest timers
  if focus and focus.GetName and strsub((focus:GetName() or ""),0,10) == "QuestTimer" then return end

  local name = getglobal("GameTooltipTextLeft1") and getglobal("GameTooltipTextLeft1"):GetText()

  if name and pfMap.tooltips[name] then
    for title, meta in pairs(pfMap.tooltips[name]) do
      pfMap:ShowTooltip(meta, GameTooltip)
      GameTooltip:Show()
    end
  end
end)

function pfMap.tooltip:GetColor(min, max)
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
    local c = GetDifficultyColor(level)
    return string.format("|cff%02x%02x%02x", c.r*255, c.g*255, c.b*255)
  end
end

function pfMap:ShowTooltip(meta, tooltip)
  local catch = nil
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

        local foundObjective = nil
        if objectives then
          for i=1, objectives, 1 do
            local text, type, finished = GetQuestLogLeaderBoard(i, qid)

            if type == "monster" then
              -- kill
              local i, j, monsterName, objNum, objNeeded = strfind(text, pfUI.api.SanitizePattern(QUEST_MONSTERS_KILLED))
              if meta["spawn"] == monsterName then
                foundObjective = true
                local r,g,b = pfMap.tooltip:GetColor(objNum, objNeeded)
                tooltip:AddLine("|cffaaaaaa- |r" .. monsterName .. ": " .. objNum .. "/" .. objNeeded, r, g, b)
              end
            elseif table.getn(meta["item"]) > 0 and type == "item" and meta["droprate"] then
              -- loot
              local i, j, itemName, objNum, objNeeded = strfind(text, pfUI.api.SanitizePattern(QUEST_OBJECTS_FOUND))

              for mid, item in pairs(meta["item"]) do
                if item == itemName then
                  foundObjective = true
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
                  foundObjective = true
                  local r,g,b = pfMap.tooltip:GetColor(objNum, objNeeded)
                  local sellcount = tonumber(meta["sellcount"]) > 0 and " |cff555555[|cffcccccc" .. meta["sellcount"] .. "x" .. "|cff555555]" or ""
                  tooltip:AddLine("|cffaaaaaa- |cffffffff" .. pfQuest_Loc["Buy"] .. ": |r" .. itemName .. ": " .. objNum .. "/" .. objNeeded .. sellcount, r, g, b)
                end
              end
            end
          end
        end

        if not foundObjective and meta["qlvl"] and meta["texture"] then
          local qlvlstr = pfQuest_Loc["Level"] .. ": " .. pfMap:HexDifficultyColor(meta["qlvl"]) .. meta["qlvl"] .. "|r"
          local qminstr = meta["qmin"] and " / " .. pfQuest_Loc["Required"] .. ": " .. pfMap:HexDifficultyColor(meta["qmin"], true) .. meta["qmin"] .. "|r"  or ""
          tooltip:AddLine("|cffaaaaaa- |r" .. qlvlstr .. qminstr , .8,.8,.8)
        end
      end
    end

    if not catch then
      -- handle inactive quests
      local catchFallback = nil
      tooltip:AddLine("|cff555555[|cffffcc00!|cff555555]|r " .. meta["quest"], 1, 1, .7)

      if meta["item"] and meta["item"][1] and meta["droprate"] then
        for mid, item in pairs(meta["item"]) do
          catchFallback = true
          local dr,dg,db = pfMap.tooltip:GetColor(tonumber(meta["droprate"]), 100)
          local lootcolor = string.format("%02x%02x%02x", dr * 255,dg * 255, db * 255)
          tooltip:AddLine("|cffaaaaaa- |r" .. pfQuest_Loc["Loot"] .. ": " .. item .. " |cff555555[|cff" .. lootcolor .. meta["droprate"] .. "%|cff555555]", 1, .5, .5)
        end
      end

      if meta["item"] and meta["item"][1] and meta["sellcount"] then
        for mid, item in pairs(meta["item"]) do
          catchFallback = true
          local sellcount = tonumber(meta["sellcount"]) > 0 and " |cff555555[|cffcccccc" .. meta["sellcount"] .. "x" .. "|cff555555]" or ""
          tooltip:AddLine("|cffaaaaaa- |r" .. pfQuest_Loc["Buy"] .. ": " .. item .. sellcount, 1, .5, .5)
        end
      end

      if not catchFallback and meta["spawn"] and not meta["texture"] then
        catchFallback = true
        tooltip:AddLine("|cffaaaaaa- |r" .. pfQuest_Loc["Kill"] .. ": " .. meta["spawn"], 1,.5,.5)
      end

      if not catchFallback and meta["texture"] and meta["qlvl"] then
        local qlvlstr = "Level: " .. pfMap:HexDifficultyColor(meta["qlvl"]) .. meta["qlvl"] .. "|r"
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
    WorldMapFrame:Show()
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

customids = {
  ["AlteracValley"] = 2597,
}
function pfMap:GetMapID(cid, mid)
  cid = cid or GetCurrentMapContinent()
  mid = mid or GetCurrentMapZone()

  local list = {GetMapZones(cid)}
  local name = list[mid]
  local id = pfMap:GetMapIDByName(name)
  id = id or customids[GetMapInfo()]

  return id
end

function pfMap:AddNode(meta)

  local addon = meta["addon"] or "PFDB"
  local map = meta["zone"]
  local coords = meta["x"] .. "|" .. meta["y"]
  local title = meta["title"]
  local layer = GetLayerByTexture(meta["texture"])
  local spawn = meta["spawn"]
  local item = meta["item"]

  if not pfMap.nodes[addon] then pfMap.nodes[addon] = {} end
  if not pfMap.nodes[addon][map] then pfMap.nodes[addon][map] = {} end
  if not pfMap.nodes[addon][map][coords] then pfMap.nodes[addon][map][coords] = {} end

  if item and pfMap.nodes[addon][map][coords][title] and table.getn(pfMap.nodes[addon][map][coords][title].item) > 0 then
    -- check if item exists
    for id, name in pairs(pfMap.nodes[addon][map][coords][title].item) do
      if name == item then
        return
      end
    end
    table.insert(pfMap.nodes[addon][map][coords][title].item, item)
  end

  if pfMap.nodes[addon][map][coords][title] and pfMap.nodes[addon][map][coords][title].layer and layer and
   pfMap.nodes[addon][map][coords][title].layer >= layer then
    -- identical node already exists, exit here
    return
  end

  -- create new node from meta data
  local node = {}
  for key, val in pairs(meta) do
    node[key] = val
  end
  node.item = { [1] = item }

  pfMap.nodes[addon][map][coords][title] = node

  -- add to gametooltips
  if spawn and title then
    pfMap.tooltips[spawn]        = pfMap.tooltips[spawn]        or {}
    pfMap.tooltips[spawn][title] = pfMap.tooltips[spawn][title] or node
  end
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
end

function pfMap:NodeClick()
  if IsShiftKeyDown() and this.questid and this.texture and this.layer < 5 then
    -- mark questnode as done
    pfMap:DeleteNode(this.node[this.title].addon, this.title)
    pfQuest_history[this.questid] = true
    pfMap:UpdateNodes()
  elseif IsShiftKeyDown() then
    pfMap:DeleteNode(this.node[this.title].addon, this.title)
    pfMap:UpdateNodes()
  else
    -- switch color
    pfQuest_colors[this.color] = { str2rgb(this.color .. GetTime()) }
    pfMap:UpdateNodes()
  end
end

function pfMap:NodeEnter()
  local tooltip = this:GetParent() == WorldMapButton and WorldMapTooltip or GameTooltip
  tooltip:SetOwner(this, ANCHOR_BOTTOMLEFT)
  tooltip:SetText(this.spawn..(pfQuest_config.showids == "1" and " |cffcccccc("..this.spawnid..")|r" or ""), .3, 1, .8)
  tooltip:AddDoubleLine(pfQuest_Loc["Level"] .. ":", (this.level or UNKNOWN), .8,.8,.8, 1,1,1)
  tooltip:AddDoubleLine(pfQuest_Loc["Type"] .. ":", (this.spawntype or UNKNOWN), .8,.8,.8, 1,1,1)
  tooltip:AddDoubleLine(pfQuest_Loc["Respawn"] .. ":", (this.respawn or UNKNOWN), .8,.8,.8, 1,1,1)

  for title, meta in pairs(this.node) do
    pfMap:ShowTooltip(meta, tooltip)
  end

  -- trigger highlight
  pfMap.highlight = this.title
  pfMap:UpdateNodes()
end

function pfMap:NodeLeave()
  local tooltip = this:GetParent() == WorldMapButton and WorldMapTooltip or GameTooltip
  tooltip:Hide()

  -- reset highlight
  pfMap.highlight = nil
  pfMap.worldmap = GetTime() + .1
end

function pfMap:BuildNode(name, parent)
  local f = CreateFrame("Button", name, parent)
  f:SetWidth(16)
  f:SetHeight(16)

  f:SetScript("OnEnter", pfMap.NodeEnter)
  f:SetScript("OnLeave", pfMap.NodeLeave)

  f.tex = f:CreateTexture("OVERLAY")
  f.tex:SetAllPoints(f)

  return f
end

function pfMap:UpdateNode(frame, node, color, obj)

  -- reset layer
  frame.layer = 0

  for title, tab in pairs(node) do
    tab.layer = GetLayerByTexture(tab.texture)
    if tab.spawn and ( tab.layer > frame.layer or not frame.spawn ) then
      frame.updateTexture = (frame.texture ~= tab.texture)
      frame.updateVertex = (frame.vertex ~= tab.vertex )
      frame.updateColor = (frame.color ~= tab.color)
      frame.updateLayer = (frame.layer ~= tab.layer)

      -- set title and texture to the entry with highest layer
      -- and add core information
      frame.layer     = tab.layer
      frame.spawn     = tab.spawn
      frame.spawnid   = tab.spawnid
      frame.spawntype = tab.spawntype
      frame.respawn   = tab.respawn
      frame.level     = tab.level
      frame.questid   = tab.questid
      frame.texture   = tab.texture
      frame.vertex    = tab.vertex
      frame.title     = title
      frame.func      = tab.func

      if pfQuest_config["colorbyspawn"] == "1" then
        frame.color = tab.spawn or tab.title
      else
        frame.color = tab.title
      end
    end
  end

  if ( frame.updateTexture or frame.updateVertex ) and frame.texture then
    frame.tex:SetTexture(frame.texture)
    frame.tex:SetVertexColor(1,1,1)

    if frame.updateVertex and frame.vertex then
      local r, g, b = unpack(frame.vertex)
      if r > 0 or g > 0 or b > 0 then
        frame.tex:SetVertexColor(r, g, b, 1)
      end
    end
  end

  if ( frame.updateColor or frame.updateTexture ) and not frame.texture then
    if obj == "minimap" and pfQuest_config["cutoutminimap"] == "1" then
      frame.tex:SetTexture(pfQuestConfig.path.."\\img\\nodecut")
    else
      frame.tex:SetTexture(pfQuestConfig.path.."\\img\\node")
    end
    local r,g,b = str2rgb(frame.color)
    frame.tex:SetVertexColor(r,g,b,1)
  end

  if frame.updateLayer then
    frame:SetFrameLevel((obj == "minimap" and 1 or 112) + frame.layer)
  end

  if frame.updateTexture or frame.updateVertex or frame.updateColor or frame.updateLayer then
    frame:SetScript("OnClick", (frame.func or pfMap.NodeClick))
  end

  frame.node = node
end

function pfMap:UpdateNodes()
  local color = pfQuest_config["colorbyspawn"] == "1" and "spawn" or "title"
  local alpha = pfQuest_config["worldmaptransp"] + 0
  local map = pfMap:GetMapID(GetCurrentMapContinent(), GetCurrentMapZone())
  local i = 1

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
        x = x / 100 * WorldMapButton:GetWidth()
        y = y / 100 * WorldMapButton:GetHeight()

        -- set defaults
        pfMap.pins[i]:SetAlpha(alpha)
        pfMap.pins[i]:SetWidth(16)
        pfMap.pins[i]:SetHeight(16)

        pfMap.pins[i]:ClearAllPoints()
        pfMap.pins[i]:SetPoint("CENTER", WorldMapButton, "TOPLEFT", x, -y)
        pfMap.pins[i]:Show()

        -- handle highlight mode
        if pfMap.highlight and pfQuest_config.mouseover == "1" then
          if pfMap.pins[i].title == pfMap.highlight then
            -- highlight node
            pfMap.pins[i]:SetAlpha(1)
            if pfMap.pins[i].texture then
              -- zoom all symbols
              pfMap.pins[i]:SetWidth(24)
              pfMap.pins[i]:SetHeight(24)
            else
              -- colorize all nodes
              local r, g, b = pfMap.pins[i].tex:GetVertexColor()
              pfMap.pins[i].tex:SetVertexColor(r+.2, g+.2, b+.2, 1)
            end
          else
            -- fade all others
            pfMap.pins[i]:SetAlpha(.25)
          end
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
  -- throttle minimap updates
  if ( this.throttle or .2) > GetTime() then return else this.throttle = GetTime() + .05 end

  -- check for disabled minimap nodes
  if pfQuest_config["minimapnodes"] == "0" then
    pfMap:Hide()
    return
  end

  -- hide all minimap nodes while shift is pressed
  if IsShiftKeyDown() and MouseIsOver(pfMap.drawlayer) then
    this.xPlayer = nil

    for id, pin in pairs(pfMap.mpins) do
      pin:Hide()
    end

    return
  end

  local xPlayer, yPlayer = GetPlayerMapPosition("player")
  if xPlayer == 0 and yPlayer == 0 or GetCurrentMapZone() == 0 then
    if not WorldMapFrame:IsShown() then
      SetMapToCurrentZone()
      xPlayer, yPlayer = GetPlayerMapPosition("player")
    else
      -- hide existing nodes
      for pins, pin in pairs(pfMap.mpins) do
        pin:Hide()
      end
      return
    end
  end

  local mZoom = pfMap.drawlayer:GetZoom()
  xPlayer, yPlayer = xPlayer * 100, yPlayer * 100

  -- force refresh every second even without changed values, otherwise skip
  if this.xPlayer == xPlayer and this.yPlayer == yPlayer and this.mZoom == mZoom then
    if ( this.tick or 1) > GetTime() then return else this.tick = GetTime() + 1 end
  end

  this.xPlayer, this.yPlayer, this.mZoom = xPlayer, yPlayer, mZoom
  local color = pfQuest_config["colorbyspawn"] == "1" and "spawn" or "title"
  local alpha = tonumber(pfQuest_config["minimaptransp"]) or 1
  local mapID = pfMap:GetMapIDByName(GetRealZoneText())
  local mapZoom = minimap_zoom[minimap_indoor()][mZoom]
  local mapWidth = minimap_sizes[mapID] and minimap_sizes[mapID][1] or 0
  local mapHeight = minimap_sizes[mapID] and minimap_sizes[mapID][2] or 0

  local xRange = mapZoom / mapHeight * pfMap.drawlayer:GetHeight()/2 -- 16 as icon size
  local yRange = mapZoom / mapWidth * pfMap.drawlayer:GetWidth()/2 -- 16 as icon size

  local xScale = mapZoom / mapWidth
  local yScale = mapZoom / mapHeight

  local xDraw = pfMap.drawlayer:GetWidth() / xScale / 100
  local yDraw = pfMap.drawlayer:GetHeight() / yScale / 100

  local i = 1

  -- refresh all nodes
  for addon, data in pairs(pfMap.nodes) do
    if data[mapID] and minimap_sizes[mapID] then
      for coords, node in pairs(data[mapID]) do
        local x, y
        if coord_cache[coords] then
          x, y = coord_cache[coords][1], coord_cache[coords][2]
        else
          local _, _, strx, stry = strfind(coords, "(.*)|(.*)")
          x, y = strx + 0, stry + 0
          coord_cache[coords] = { x, y }
        end

        local xPos = ( xPlayer - x ) * xDraw
        local yPos = ( yPlayer - y ) * yDraw

        local display = nil
        if pfUI.minimap then
          display = ( abs(xPos) + 8 < pfMap.drawlayer:GetWidth() / 2 and abs(yPos) + 8 < pfMap.drawlayer:GetHeight()/2 ) and true or nil
        else
          local distance = sqrt(xPos * xPos + yPos * yPos)
          display = ( distance + 8 < pfMap.drawlayer:GetWidth() / 2 ) and true or nil
        end

        if display then
          if not pfMap.mpins[i] then
            pfMap.mpins[i] = pfMap:BuildNode("pfMiniMapPin" .. i, pfMap.drawlayer)
          end

          pfMap:UpdateNode(pfMap.mpins[i], node, color, "minimap")

          pfMap.mpins[i]:ClearAllPoints()
          pfMap.mpins[i]:SetPoint("CENTER", pfMap.drawlayer, "CENTER", -xPos, yPos)
          pfMap.mpins[i]:SetAlpha(alpha)
          pfMap.mpins[i]:Show()
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

pfMap:RegisterEvent("WORLD_MAP_UPDATE")
pfMap:SetScript("OnEvent", function()
  -- on each event, we delay the update function
  -- by one frame to make sure all nodes are getting
  -- drawn and shown on the parent frame, which takes a
  -- while to initialize
  this.worldmap = GetTime() + .5
  pfMap:UpdateNodes()
end)

pfMap:SetScript("OnUpdate", function()
  -- run the delayed function when an event was triggered
  if this.worldmap and this.worldmap < GetTime() then
    pfMap:UpdateNodes()
    this.worldmap = nil
  end

  -- always refresh all minimap nodes.
  pfMap:UpdateMinimap()
end)
