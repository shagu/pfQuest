local validmaps = setmetatable({},{__mode="kv"})

local rgbcache = setmetatable({},{__mode="kv"})

local minimap_sizes = {
  [1] = { 4924.9997558593805, 3283.33325195312 },
  [3] = { 2487.5,1658.33349609375 },
  [4] = { 3349.9998779296902, 2233.333984375 },
  [8] = { 2293.75, 1529.1669921875 },
  [10] = { 2699.999938964841, 1800.0 },
  [11] = { 4135.416687011719, 2756.25 },
  [12] = { 3470.83325195312, 2314.5830078125 },
  [14] = { 5287.49963378906, 3524.9998779296902 },
  [15] = { 5250.000061035156, 3499.99975585937 },
  [16] = { 5070.8327636718695, 3381.2498779296902 },
  [17] = { 10133.3330078125, 6756.24987792969 },
  [28] = { 4299.999908447271, 2866.666534423828 },
  [33] = { 6381.2497558593805, 4254.166015625 },
  [36] = { 2799.999938964841, 1866.666656494141 },
  [38] = { 2758.3331298828098, 1839.5830078125 },
  [40] = { 3499.9998168945312, 2333.3330078125 },
  [41] = { 2499.999938964849, 1666.6669921875 },
  [44] = { 2170.83325195312, 1447.916015625 },
  [45] = { 3599.999877929687, 2399.99992370606 },
  [46] = { 2929.166595458989, 1952.08349609375 },
  [47] = { 3850.0, 2566.6666259765598 },
  [51] = { 2231.249847412109, 1487.49951171875 },
  [85] = { 4518.74987792969, 3012.499816894536 },
  [130] = { 4199.9997558593805, 2799.9998779296902 },
  [139] = { 3870.83349609375, 2581.24975585938 },
  [141] = { 5091.66650390626, 3393.75 },
  [148] = { 6549.9997558593805, 4366.66650390625 },
  [215] = { 5137.49987792969, 3424.999847412109 },
  [267] = { 3199.9998779296902, 2133.33325195313 },
  [331] = { 5766.66638183594, 3843.749877929687 },
  [357] = { 6949.9997558593805, 4633.3330078125 },
  [361] = { 5749.99963378906, 3833.33325195312 },
  [400] = { 4399.999694824219, 2933.3330078125 },
  [405] = { 4495.8330078125, 2997.916564941411 },
  [406] = { 4883.33312988282, 3256.2498168945312 },
  [440] = { 6899.999526977539, 4600.0 },
  [490] = { 3699.9998168945312, 2466.66650390625 },
  [493] = { 2308.33325195313, 1539.5830078125 },
  [618] = { 7099.999847412109, 4733.3332519531195 },
  [1377] = { 3483.333984375, 2322.916015625 },
  [1497] = { 959.3750305175781, 640.10412597656 },
  [1519] = { 1344.2708053588917, 896.3544921875 },
  [1537] = { 790.625061035154, 527.6044921875 },
  [1637] = { 1402.6044921875, 935.41662597657 },
  [1638] = { 1043.749938964844, 695.833312988286 },
  [1657] = { 1058.33325195312, 705.7294921875 },
--  [2597] = -- "Alterac Valley",
--  [3277] = -- "Warsong Gulch",
--  [3358] = -- "Arathi Basin",
}

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

local function minimap_indoor()
  local tempzoom = 0
	local state = 1
	if GetCVar("minimapZoom") == GetCVar("minimapInsideZoom") then
		if GetCVar("minimapInsideZoom")+0 >= 3 then
			Minimap:SetZoom(Minimap:GetZoom() - 1)
			tempzoom = 1
		else
			Minimap:SetZoom(Minimap:GetZoom() + 1)
			tempzoom = -1
		end
	end

	if GetCVar("minimapInsideZoom")+0 == Minimap:GetZoom() then
    state = 0
  end

  Minimap:SetZoom(Minimap:GetZoom() + tempzoom)
	return state
end

local function str2rgb(text)
  if not text then return 1, 1, 1 end
  if pfQuest_colors[text] then return unpack(pfQuest_colors[text]) end
  if rgbcache[text] then return unpack(rgbcache[text]) end
  local counter = 1
  local l = string.len(text)
  for i = 1, l, 3 do
    counter = math.mod(counter*8161, 4294967279) +
        (string.byte(text,i)*16776193) +
        ((string.byte(text,i+1) or (l-i+256))*8372226) +
        ((string.byte(text,i+2) or (l-i+256))*3932164)
  end
  local hash = math.mod(math.mod(counter, 4294967291),16777216)
  local r = (hash - (math.mod(hash,65536))) / 65536
  local g = ((hash - r*65536) - ( math.mod((hash - r*65536),256)) ) / 256
  local b = hash - r*65536 - g*256
  rgbcache[text] = { r / 255, g / 255, b / 255 }
  return unpack(rgbcache[text])
end

pfMap = CreateFrame("Frame")
pfMap.tooltips = {}
pfMap.nodes = {}
pfMap.pins = {}
pfMap.mpins = {}

pfMap.tooltip = CreateFrame("Frame" , "pfMapTooltip", GameTooltip)
pfMap.tooltip:SetScript("OnShow", function()
  -- abort on pfQuest nodes
  if GetMouseFocus() and GetMouseFocus().title then return end

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
      local qtitle, _, _, _, _, complete = GetQuestLogTitle(qid)

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
                  tooltip:AddLine("|cffaaaaaa- |cffffffffBuy: |r" .. itemName .. ": " .. objNum .. "/" .. objNeeded .. sellcount, r, g, b)
                end
              end
            end
          end
        end

        if not foundObjective and meta["qlvl"] and meta["texture"] then
          local qlvlstr = "Level: " .. pfMap:HexDifficultyColor(meta["qlvl"]) .. meta["qlvl"] .. "|r"
          local qminstr = meta["qmin"] and " / Required: " .. pfMap:HexDifficultyColor(meta["qmin"], true) .. meta["qmin"] .. "|r"  or ""
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
          tooltip:AddLine("|cffaaaaaa- |rLoot: " .. item .. " |cff555555[|cff" .. lootcolor .. meta["droprate"] .. "%|cff555555]", 1, .5, .5)
        end
      end

      if meta["item"] and meta["item"][1] and meta["sellcount"] then
        for mid, item in pairs(meta["item"]) do
          catchFallback = true
          local sellcount = tonumber(meta["sellcount"]) > 0 and " |cff555555[|cffcccccc" .. meta["sellcount"] .. "x" .. "|cff555555]" or ""
          tooltip:AddLine("|cffaaaaaa- |rBuy: " .. item .. sellcount, 1, .5, .5)
        end
      end

      if not catchFallback and meta["spawn"] and not meta["texture"] then
        catchFallback = true
        tooltip:AddLine("|cffaaaaaa- |rKill: " .. meta["spawn"], 1,.5,.5)
      end

      if not catchFallback and meta["texture"] and meta["qlvl"] then
        local qlvlstr = "Level: " .. pfMap:HexDifficultyColor(meta["qlvl"]) .. meta["qlvl"] .. "|r"
        local qminstr = meta["qmin"] and " / Required: " .. pfMap:HexDifficultyColor(meta["qmin"], true) .. meta["qmin"] .. "|r"  or ""
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
      tooltip:AddLine("Vendor: " .. item .. sellcount, 1,1,1)
    elseif meta["item"][1] then
      local item = meta["itemlink"] or "[" .. meta["item"][1] .. "]"
      local r,g,b = pfMap.tooltip:GetColor(tonumber(meta["droprate"]), 100)
      tooltip:AddLine("|cffffffffLoot: " .. item ..  " |cff555555[|r" .. meta["droprate"] .. "%|cff555555]", r,g,b)
    end
  end

  tooltip:Show()
end

function pfMap:GetMapNameByID(id)
  id = tonumber(id)
  return pfDatabase["zones"][id] or nil
end

function pfMap:GetMapIDByName(search)
  for id, name in pairs(pfDatabase["zones"]) do
    if name == search then
      return id
    end
  end
end

function pfMap:IsValidMap(id)
  if validmaps[id] then return true end

  local search = pfDatabase["zones"][id]

  for cid, cname in pairs({GetMapContinents()}) do
    for mid, mname in pairs({GetMapZones(cid)}) do
      if mname == search then
        validmaps[id] = true
        return true
      end
    end
  end

  return nil
end

function pfMap:ShowMapID(map)
  if map then

    if not UISpecialFrames["WorldMapFrame"] then
      table.insert(UISpecialFrames, "WorldMapFrame")
    end

    pfMap:UpdateNodes()
    WorldMapFrame:Show()
    pfMap:SetMapByID(map)
    return true
  end

  return nil
end

function pfMap:SetMapByID(id)
  local search = pfDatabase["zones"][id]

  for cid, cname in pairs({GetMapContinents()}) do
    for mid, mname in pairs({GetMapZones(cid)}) do
      if mname == search then
        SetMapZoom(cid, mid)
        return
      end
    end
  end
end

function pfMap:GetMapID(cid, mid)
  cid = cid or GetCurrentMapContinent()
  mid = mid or GetCurrentMapZone()

  local list = {GetMapZones(cid)}
  local name = list[mid]

  return pfMap:GetMapIDByName(name)
end

function pfMap:AddNode(meta)

  local addon = meta["addon"] or "PFDB"
  local map = meta["zone"]
  local coords = meta["x"] .. "|" .. meta["y"]
  local title = meta["title"]
  local layer = meta["layer"]
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
      else
        table.insert(pfMap.nodes[addon][map][coords][title].item, item)
      end
    end
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
  if IsShiftKeyDown() then
    pfMap:DeleteNode(this.node[this.title].addon, this.title)
    pfQuest_history[this.title] = true
    pfMap:UpdateNodes()
  else
    pfQuest_colors[this.title] = { str2rgb(this.title .. GetTime()) }
    pfMap:UpdateNodes()
  end
end

function pfMap:NodeEnter()
  local tooltip = this:GetParent() == WorldMapButton and WorldMapTooltip or GameTooltip
  tooltip:SetOwner(this, ANCHOR_BOTTOMLEFT)
  tooltip:SetText(this.spawn, .3, 1, .8)

  tooltip:AddDoubleLine("Level:", (this.level or UNKNOWN), .8,.8,.8, 1,1,1)
  tooltip:AddDoubleLine("Type:", (this.spawntype or UNKNOWN), .8,.8,.8, 1,1,1)
  tooltip:AddDoubleLine("Respawn:", (this.respawn or UNKNOWN), .8,.8,.8, 1,1,1)

  for title, meta in pairs(this.node) do
    pfMap:ShowTooltip(meta, tooltip)
  end
end

function pfMap:NodeLeave()
  local tooltip = this:GetParent() == WorldMapButton and WorldMapTooltip or GameTooltip
  tooltip:Hide()
end

function pfMap:BuildNode(name, parent)
  local f = CreateFrame("Button", name, parent)
  f:SetWidth(16)
  f:SetHeight(16)
  f:SetFrameLevel(112)

  f:SetScript("OnEnter", pfMap.NodeEnter)
  f:SetScript("OnLeave", pfMap.NodeLeave)

  f.tex = f:CreateTexture("OVERLAY")
  f.tex:SetAllPoints(f)

  return f
end

function pfMap:UpdateNode(frame, node)
  frame.layer = -1

  for title, tab in pairs(node) do
    tab.layer = tab.layer or 0
    if tab.layer > frame.layer then
      -- set title and texture to the entry with highest layer
      -- and add core information
      frame.layer     = tab.layer
      frame.spawn     = tab.spawn
      frame.spawntype = tab.spawntype
      frame.respawn   = tab.respawn
      frame.level     = tab.level
      frame.title     = title

      if tab.texture then
        frame.tex:SetTexture(tab.texture)
        frame.tex:SetVertexColor(1,1,1)
      else
        frame.tex:SetTexture("Interface\\AddOns\\pfQuest\\img\\node")
        local r,g,b = str2rgb(title)
        frame.tex:SetVertexColor(r,g,b,1)
      end

      if tab.texture and tab.vertex then
        local r, g, b = unpack(tab.vertex)
        if r > 0 or g > 0 or b > 0 then
          frame.tex:SetVertexColor(r, g, b, 1)
        end
      end

      frame:SetScript("OnClick", tab.func or pfMap.NodeClick)
    end
  end

  frame.node = node
end

function pfMap:UpdateNodes()
  local map = pfMap:GetMapID(GetCurrentMapContinent(), GetCurrentMapZone())
  local i = 0

  -- hide existing nodes
  for pins, pin in pairs(pfMap.pins) do
    pin:Hide()
  end

  -- refresh all nodes
  for addon, _ in pairs(pfMap.nodes) do
    if pfMap.nodes[addon][map] then
      for coords, node in pairs(pfMap.nodes[addon][map]) do
        if not pfMap.pins[i] then
          pfMap.pins[i] = pfMap:BuildNode("pfMapPin" .. i, WorldMapButton)
        end

        pfMap:UpdateNode(pfMap.pins[i], node)

        if node.translucent then
          pfMap.pins[i]:SetAlpha((tonumber(pfQuest_config["worldmaptransp"]) or 1)/2)
        else
          pfMap.pins[i]:SetAlpha((tonumber(pfQuest_config["worldmaptransp"]) or 1))
        end

        -- set position
        local _, _, x, y = strfind(coords, "(.*)|(.*)")
        x = ( x / 100 * WorldMapButton:GetWidth() ) - pfMap.pins[i]:GetWidth()/2
        y = ( y / 100 * WorldMapButton:GetHeight() ) - pfMap.pins[i]:GetHeight()/2

        pfMap.pins[i]:ClearAllPoints()
        pfMap.pins[i]:SetPoint("TOPLEFT", x, -y)
        pfMap.pins[i]:Show()

        i = i + 1
      end
    end
  end
end

function pfMap:UpdateMinimap()
  -- hide existing nodes
  for pins, pin in pairs(pfMap.mpins) do
    pin:Hide()
  end

  if pfQuest_config["minimapnodes"] == "0" then
    pfMap:Hide()
    return
  end

  local xPlayer, yPlayer = GetPlayerMapPosition("player")
  local mZoom = Minimap:GetZoom()
  xPlayer, yPlayer = xPlayer * 100, yPlayer * 100

  -- force refresh every second even without changed values, otherwise skip
  if this.xPlayer == xPlayer and this.yPlayer == py and this.mZoom == mZoom then
    if ( limit or 1) > GetTime() then return else limit = GetTime() + 1 end
  else
    this.xPlayer, this.yPlayer, this.mZoom = xPlayer, yPlayer, mZoom
  end


  local mapID = pfMap:GetMapIDByName(GetZoneText())
  local mapZoom = minimap_zoom[minimap_indoor()][mZoom]
  local mapWidth = minimap_sizes[mapID] and minimap_sizes[mapID][1] or 0
  local mapHeight = minimap_sizes[mapID] and minimap_sizes[mapID][2] or 0
  local xRange = mapZoom / mapHeight * Minimap:GetHeight()/2 -- 16 as icon size
  local yRange = mapZoom / mapWidth * Minimap:GetWidth()/2 -- 16 as icon size

  local i = 0

  -- refresh all nodes
  for addon, _ in pairs(pfMap.nodes) do
    if pfMap.nodes[addon][mapID] then
      for coords, node in pairs(pfMap.nodes[addon][mapID]) do
        local _, _, x, y = strfind(coords, "(.*)|(.*)")
        x, y = tonumber(x), tonumber(y)

        local xScale = mapZoom / mapWidth
        local yScale = mapZoom / mapHeight

        local xPos = ( xPlayer - x ) / 100 * Minimap:GetWidth() / xScale
        local yPos = ( yPlayer - y ) / 100 * Minimap:GetHeight() / yScale

        local display = nil

        if pfUI.minimap then
          display = ( abs(xPos) + 8 < Minimap:GetWidth() / 2 and abs(yPos) + 8 < Minimap:GetHeight()/2 ) and true or nil
        else
          local distance = sqrt(xPos * xPos + yPos * yPos)
          display = ( distance + 8 < Minimap:GetWidth() / 2 ) and true or nil
        end

        if display then
          if not pfMap.mpins[i] then
            pfMap.mpins[i] = pfMap:BuildNode("pfMiniMapPin" .. i, Minimap)
          end

          pfMap:UpdateNode(pfMap.mpins[i], node)

          if node.translucent then
            pfMap.mpins[i]:SetAlpha((tonumber(pfQuest_config["minimaptransp"]) or 1)/2)
          else
            pfMap.mpins[i]:SetAlpha((tonumber(pfQuest_config["minimaptransp"]) or 1))
          end

          pfMap.mpins[i]:ClearAllPoints()
          pfMap.mpins[i]:SetPoint("CENTER", Minimap, "CENTER", -xPos, yPos)
          pfMap.mpins[i]:SetFrameLevel(2)
          pfMap.mpins[i]:Show()

          i = i + 1
        end
      end
    end
  end
end

pfMap:RegisterEvent("WORLD_MAP_UPDATE")
pfMap:SetScript("OnEvent", pfMap.UpdateNodes)
pfMap:SetScript("OnUpdate", pfMap.UpdateMinimap)
