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
  if rgbcache[text] ~= nil then return unpack(rgbcache[text]) end
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
pfMap.nodes = {}
pfMap.pins = {}
pfMap.mpins = {}

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

function pfMap:AddNode(addon, map, coords, icon, title, description, translucent, func)
  if not pfMap.nodes[addon] then pfMap.nodes[addon] = {} end
  if not pfMap.nodes[addon][map] then pfMap.nodes[addon][map] = {} end

  if not pfMap.nodes[addon][map][coords] then
    pfMap.nodes[addon][map][coords] = { icon = icon, title = title, description = description, addon = addon, translucent = translucent, func = func}
  end
end

function pfMap:DeleteNode(addon, title)
  if not addon then
    pfMap.nodes = {}
  elseif not title then
    pfMap.nodes[addon] = {}
  elseif pfMap.nodes[addon] then
    for map, foo in pairs(pfMap.nodes[addon]) do
      for coords, node in pairs(pfMap.nodes[addon][map]) do
        if pfMap.nodes[addon][map][coords].title == title then
          pfMap.nodes[addon][map][coords] = nil
        end
      end
    end
  end
end

function pfMap:BuildNode(name, parent)
  local f = CreateFrame("Button", name, parent)
  f:SetWidth(16)
  f:SetHeight(16)
  f:SetFrameLevel(112)

  f:SetScript("OnEnter", function()
    GameTooltip:SetOwner(this, ANCHOR_BOTTOMLEFT)
    GameTooltip:SetText(this.node.title, .3, 1, .8)
    for id, desc in pairs(this.node.description) do
      GameTooltip:AddLine(desc, 1, 1, 1)
    end
    GameTooltip:Show()
  end)

  f:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)

  f.tex = f:CreateTexture("OVERLAY")
  f.tex:SetAllPoints(f)

  return f
end

function pfMap:UpdateNode(frame, node)
  if node.icon then
    frame.tex:SetTexture(node.icon)
    frame.tex:SetVertexColor(1,1,1)
  else
    frame.tex:SetTexture("Interface\\AddOns\\pfQuest\\img\\node")
    local r,g,b = str2rgb(node.title)
    frame.tex:SetVertexColor(r,g,b,1)
  end

  if node.func then
    frame:SetScript("OnClick", node.func)
  else
    frame:SetScript("OnClick", function()
      pfMap:DeleteNode(this.node.addon, this.node.title)
      pfMap:UpdateNodes()
    end)
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
