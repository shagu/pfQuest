-- table.getn doesn't return sizes on tables that
-- are using a named index on which setn is not updated
local function tablesize(tbl)
  local count = 0
  for _ in pairs(tbl) do count = count + 1 end
  return count
end

function modulo(val, by)
  return val - math.floor(val/by)*by;
end

local function GetNearest(xstart, ystart, db, blacklist)
  local nearest = nil
  local best = nil

  for id, data in pairs(db) do
    if data[1] and data[2] and not blacklist[id] then
      local x,y = xstart - data[1], ystart - data[2]
      local distance = ceil(math.sqrt(x*x+y*y)*100)/100

      if not nearest or distance < nearest then
        nearest = distance
        best = id
      end
    end
  end

  if not best then return end

  blacklist[best] = true
  return db[best]
end

-- connection between objectives
local objectivepath = {}

-- connection between player and the first objective
local playerpath = {} -- worldmap
local mplayerpath = {} -- minimap

local function ClearPath(path)
  for id, tex in pairs(path) do
    tex.enable = nil
    tex:Hide()
  end
end

local function DrawLine(path,x,y,nx,ny,hl,minimap)
  local display = true
  local zoom = 1

  -- calculate minimap variables
  local xplayer, yplayer, xdraw, ydraw
  if minimap then
    -- player coords
    xplayer, yplayer = GetPlayerMapPosition("player")
    xplayer, yplayer = xplayer * 100, yplayer * 100

    -- query minimap zoom/size data
    local mZoom = pfMap.drawlayer:GetZoom()
    local mapID = pfMap:GetMapIDByName(GetRealZoneText())
    local mapZoom = pfMap.minimap_zoom[pfMap.minimap_indoor()][mZoom]
    local mapWidth = pfMap.minimap_sizes[mapID] and pfMap.minimap_sizes[mapID][1] or 0
    local mapHeight = pfMap.minimap_sizes[mapID] and pfMap.minimap_sizes[mapID][2] or 0

    -- calculate drawlayer size
    xdraw = pfMap.drawlayer:GetWidth() / (mapZoom / mapWidth) / 100
    ydraw = pfMap.drawlayer:GetHeight() / (mapZoom / mapHeight) / 100
    zoom = (((mapZoom / mapWidth))+((mapZoom / mapHeight))) * 3
  end

  -- general
  local dx, dy = x - nx, y - ny
  local dots = ceil(math.sqrt(dx*1.5*dx*1.5+dy*dy)) / zoom

  for i=(minimap and 1 or 2), dots-(minimap and 1 or 2) do
    local xpos = nx + dx/dots*i
    local ypos = ny + dy/dots*i

    if minimap then
      -- adjust values to minimap
      xpos = ( xplayer - xpos ) * xdraw
      ypos = ( yplayer - ypos ) * ydraw

      -- check if dot should be visible
      if pfUI.minimap then
        display = ( abs(xpos) + 1 < pfMap.drawlayer:GetWidth() / 2 and abs(ypos) + 1 < pfMap.drawlayer:GetHeight()/2 ) and true or nil
      else
        local distance = sqrt(xpos * xpos + ypos * ypos)
        display = ( distance + 1 < pfMap.drawlayer:GetWidth() / 2 ) and true or nil
      end
    else
      -- adjust values to worldmap
      xpos = xpos / 100 * WorldMapButton:GetWidth()
      ypos = ypos / 100 * WorldMapButton:GetHeight()
    end

    if display then
      local nline = tablesize(path) + 1
      for id, tex in pairs(path) do
        if not tex.enable then nline = id break end
      end

      path[nline] = path[nline] or (minimap and pfMap.drawlayer or WorldMapButton.routes):CreateTexture(nil, "OVERLAY")
      path[nline]:SetWidth(4)
      path[nline]:SetHeight(4)
      path[nline]:SetTexture(pfQuestConfig.path.."\\img\\route")
      if hl and minimap then
        path[nline]:SetVertexColor(.6,.4,.2,.5)
      elseif hl then
        path[nline]:SetVertexColor(1,.8,.4,1)
      else
        path[nline]:SetVertexColor(.6,.4,.2,1)
      end

      path[nline]:ClearAllPoints()

      if minimap then -- draw minimap
        path[nline]:SetPoint("CENTER", pfMap.drawlayer, "CENTER", -xpos, ypos)
      else -- draw worldmap
        path[nline]:SetPoint("CENTER", WorldMapButton, "TOPLEFT", xpos, -ypos)
      end

      path[nline]:Show()
      path[nline].enable = true
    end
  end
end

pfQuest.route = CreateFrame("Frame", "pfQuestRoute", WorldFrame)
pfQuest.route.firstnode = nil
pfQuest.route.coords = {}

pfQuest.route.Reset = function(self)
  self.coords = {}
  self.firstnode = nil
end

pfQuest.route.AddPoint = function(self, tbl)
  table.insert(self.coords, tbl)
  self.firstnode = nil
end

local targetTitle, targetCluster, targetLayer, targetTexture = nil, nil, nil, nil
pfQuest.route.SetTarget = function(node, default)
  if node and ( node.title ~= targetTitle
    or node.cluster ~= targetCluster
    or node.layer ~= targetLayer
    or node.texture ~= targetTexture )
  then
    pfMap.queue_update = true
  end

  targetTitle = node and node.title or nil
  targetCluster = node and node.cluster or nil
  targetLayer = node and node.layer or nil
  targetTexture = node and node.texture or nil
end

pfQuest.route.IsTarget = function(node)
  if node then
    if targetTitle and targetTitle == node.title
      and targetCluster == node.cluster
      and targetLayer == node.layer
      and targetTexture == node.texture
    then
      return true
    end
  end
  return nil
end

local lastpos, completed = 0, 0
local function sortfunc(a,b) return a[4] < b[4] end
pfQuest.route:SetScript("OnUpdate", function()
  local xplayer, yplayer = GetPlayerMapPosition("player")
  local wrongmap = xplayer == 0 and yplayer == 0 and true or nil
  local curpos = xplayer + yplayer

  -- limit distance and route updates to once per .1 seconds
  if ( this.tick or 5) > GetTime() and lastpos == curpos then return else this.tick = GetTime() + 1 end

  -- limit to a maxium of each .05 seconds even on position change
  if ( this.throttle or .2) > GetTime() then return else this.throttle = GetTime() + .05 end

  -- save current position
  lastpos = curpos

  -- update distances to player
  for id, data in pairs(this.coords) do
    if data[1] and data[2] then
      local x, y = (xplayer*100 - data[1])*1.5, yplayer*100 - data[2]
      this.coords[id][4] = ceil(math.sqrt(x*x+y*y)*100)/100
    end
  end

  -- sort all coords by distance only once per second
  if not this.recalculate or this.recalculate < GetTime() then
    table.sort(this.coords, sortfunc)

    -- order list on custom targets
    if targetTitle and this.coords[1] and not pfQuest.route.IsTarget(this.coords[1][3]) then
      local target = nil

      -- check for the old index of the target
      for id, data in pairs(this.coords) do
        if pfQuest.route.IsTarget(data[3]) then
          target = id
          break
        end
      end

      -- rearrange coordinates
      if target then
        local tmp = {}
        table.insert(tmp, this.coords[target])

        for id, data in pairs(this.coords) do
          if id ~= target then
            table.insert(tmp, this.coords[id])
          end
        end

        this.coords = tmp
      end
    end

    this.recalculate = GetTime() + 1
  end

  -- show arrow when route exists and is stable
  if not wrongmap and this.coords[1] and this.coords[1][4] and not this.arrow:IsShown() and pfQuest_config["arrow"] == "1" and GetTime() > completed + 1 then
    this.arrow:Show()
  end

  -- abort without any nodes or distances
  if not this.coords[1] or not this.coords[1][4] or pfQuest_config["routes"] == "0" then
    ClearPath(objectivepath)
    ClearPath(playerpath)
    ClearPath(mplayerpath)
    return
  end

  -- check first node for changes
  if this.firstnode ~= tostring(this.coords[1][1]..this.coords[1][2]) then
    this.firstnode = tostring(this.coords[1][1]..this.coords[1][2])

    -- recalculate objective paths
    local route = { [1] = this.coords[1] }
    local blacklist = { [1] = true }
    for i=2, table.getn(this.coords) do
      if route[i-1] then -- make sure the route was not blacklisted
        route[i] = GetNearest(route[i-1][1],route[i-1][2],this.coords, blacklist)
      end

      -- remove other item requirement gameobjects of same type from route
      if route[i] and route[i][3] and route[i][3].itemreq then
        for id, data in pairs(this.coords) do
          if not blacklist[id] and data[1] and data[2] and data[3]
            and data[3].itemreq and data[3].itemreq == route[i][3].itemreq
          then
            blacklist[id] = true
          end
        end
      end
    end

    ClearPath(objectivepath)
    for i, data in pairs(route) do
      if i > 1 then
        DrawLine(objectivepath, route[i-1][1],route[i-1][2],route[i][1],route[i][2])
      end
    end

    -- route calculation timestamp
    completed = GetTime()
  end

  if wrongmap then
    -- hide player-to-object path
    ClearPath(playerpath)
    ClearPath(mplayerpath)
  else
    -- draw player-to-object path
    ClearPath(playerpath)
    ClearPath(mplayerpath)
    DrawLine(playerpath,xplayer*100,yplayer*100,this.coords[1][1],this.coords[1][2],true)

    -- also draw minimap path if enabled
    if pfQuest_config["routeminimap"] == "1" then
      DrawLine(mplayerpath,xplayer*100,yplayer*100,this.coords[1][1],this.coords[1][2],true,true)
    end
  end
end)

pfQuest.route.drawlayer = CreateFrame("Frame", "pfQuestRouteDrawLayer", WorldMapButton)
pfQuest.route.drawlayer:SetFrameLevel(113)
pfQuest.route.drawlayer:SetAllPoints()

WorldMapButton.routes = CreateFrame("Frame", "pfQuestRouteDisplay", pfQuest.route.drawlayer)
WorldMapButton.routes:SetAllPoints()

pfQuest.route.arrow = CreateFrame("Frame", "pfQuestRouteArrow", UIParent)
pfQuest.route.arrow:SetPoint("CENTER", 0, -100)
pfQuest.route.arrow:SetWidth(48)
pfQuest.route.arrow:SetHeight(36)
pfQuest.route.arrow:SetClampedToScreen(true)
pfQuest.route.arrow:SetMovable(true)
pfQuest.route.arrow:EnableMouse(true)
pfQuest.route.arrow:RegisterForDrag('LeftButton')
pfQuest.route.arrow:SetScript("OnDragStart", function()
  if IsShiftKeyDown() then
    this:StartMoving()
  end
end)

pfQuest.route.arrow:SetScript("OnDragStop", function()
  this:StopMovingOrSizing()
end)

local invalid, lasttarget
local xplayer, yplayer, wrongmap, wrongmap
local xDelta, yDelta, dir, angle
local player, perc, column, row, xstart, ystart, xend, yend
local area, alpha, texalpha, color
local defcolor = "|cffffcc00"
local r, g, b

pfQuest.route.arrow:SetScript("OnUpdate", function()
  -- abort if the frame is not initialized yet
  if not this.parent then return end

  xplayer, yplayer = GetPlayerMapPosition("player")
  wrongmap = xplayer == 0 and yplayer == 0 and true or nil
  target = this.parent.coords and this.parent.coords[1] and this.parent.coords[1][4] and this.parent.coords[1] or nil

  -- disable arrow on invalid map/route
  if not target or wrongmap or pfQuest_config["arrow"] == "0" then
    if invalid and invalid < GetTime() then
      this:Hide()
    elseif not invalid then
      invalid = GetTime() + 1
    end

    return
  else
    invalid = nil
  end

  -- arrow positioning stolen from TomTomVanilla.
  -- all credits to the original authors:
  -- https://github.com/cralor/TomTomVanilla
  xDelta = (target[1] - xplayer*100)*1.5
  yDelta = (target[2] - yplayer*100)
  dir = atan2(xDelta, -(yDelta))
  dir = dir > 0 and (math.pi*2) - dir or -dir
  if dir < 0 then dir = dir + 360 end
  angle = math.rad(dir)

  player = pfQuestCompat.GetPlayerFacing()
  angle = angle - player
  perc = math.abs(((math.pi - math.abs(angle)) / math.pi))
  r, g, b = pfUI.api.GetColorGradient(floor(perc*100)/100)
  cell = modulo(floor(angle / (math.pi*2) * 108 + 0.5), 108)
  column = modulo(cell, 9)
  row = floor(cell / 9)
  xstart = (column * 56) / 512
  ystart = (row * 42) / 512
  xend = ((column + 1) * 56) / 512
  yend = ((row + 1) * 42) / 512

  -- guess area based on node count
  area = target[3].priority and target[3].priority or 1
  area = max(1, area)
  area = min(20, area)
  area = (area / 10) + 1

  alpha = target[4] - area
  alpha = alpha > 1 and 1 or alpha
  alpha = alpha < .5 and .5 or alpha

  texalpha = (1 - alpha) * 2
  texalpha = texalpha > 1 and 1 or texalpha
  texalpha = texalpha < 0 and 0 or texalpha

  r, g, b = r + texalpha, g + texalpha, b + texalpha

  -- update arrow
  this.model:SetTexCoord(xstart,xend,ystart,yend)
  this.model:SetVertexColor(r,g,b)

  -- recalculate values on target change
  if target ~= lasttarget then
    -- calculate difficulty color
    color = defcolor
    if tonumber(target[3]["qlvl"]) then
      color = pfMap:HexDifficultyColor(tonumber(target[3]["qlvl"]))
    end

    -- update node texture
    if target[3].texture then
      this.texture:SetTexture(target[3].texture)

      if target[3].vertex and ( target[3].vertex[1] > 0
        or target[3].vertex[2] > 0
        or target[3].vertex[3] > 0 )
      then
        this.texture:SetVertexColor(unpack(target[3].vertex))
      else
        this.texture:SetVertexColor(1,1,1,1)
      end
    else
      this.texture:SetTexture(pfQuestConfig.path.."\\img\\node")
      this.texture:SetVertexColor(pfMap.str2rgb(target[3].title))
    end

    -- update arrow texts
    local level = target[3].qlvl and "[" .. target[3].qlvl .. "] " or ""
    this.title:SetText(color..level..target[3].title.."|r")
    local desc = target[3].description or ""
    if not pfUI or not pfUI.uf then
      this.description:SetTextColor(1,.9,.7,1)
      desc = string.gsub(desc, "ff33ffcc", "ffffffff")
    end
    this.description:SetText(desc.."|r.")
  end

  -- only refresh distance text on change
  local distance = floor(target[4]*10)/10
  if distance ~= this.distance.number then
    this.distance:SetText("|cffaaaaaa" .. pfQuest_Loc["Distance"] .. ": "..string.format("%.1f", distance))
    this.distance.number = distance
  end

  -- update transparencies
  this.texture:SetAlpha(texalpha)
  this.model:SetAlpha(alpha)
end)

pfQuest.route.arrow.texture = pfQuest.route.arrow:CreateTexture("pfQuestRouteNodeTexture", "OVERLAY")
pfQuest.route.arrow.texture:SetWidth(28)
pfQuest.route.arrow.texture:SetHeight(28)
pfQuest.route.arrow.texture:SetPoint("BOTTOM", 0, 0)

pfQuest.route.arrow.model = pfQuest.route.arrow:CreateTexture("pfQuestRouteArrow", "MEDIUM")
pfQuest.route.arrow.model:SetTexture(pfQuestConfig.path.."\\img\\arrow")
pfQuest.route.arrow.model:SetTexCoord(0,0,0.109375,0.08203125)
pfQuest.route.arrow.model:SetAllPoints()

pfQuest.route.arrow.title = pfQuest.route.arrow:CreateFontString("pfQuestRouteText", "HIGH", "GameFontWhite")
pfQuest.route.arrow.title:SetPoint("TOP", pfQuest.route.arrow.model, "BOTTOM", 0, -10)
pfQuest.route.arrow.title:SetFont(pfUI.font_default, pfUI_config.global.font_size+1, "OUTLINE")
pfQuest.route.arrow.title:SetTextColor(1,.8,0)
pfQuest.route.arrow.title:SetJustifyH("CENTER")

pfQuest.route.arrow.description = pfQuest.route.arrow:CreateFontString("pfQuestRouteText", "HIGH", "GameFontWhite")
pfQuest.route.arrow.description:SetPoint("TOP", pfQuest.route.arrow.title, "BOTTOM", 0, -2)
pfQuest.route.arrow.description:SetFont(pfUI.font_default, pfUI_config.global.font_size, "OUTLINE")
pfQuest.route.arrow.description:SetTextColor(1,1,1)
pfQuest.route.arrow.description:SetJustifyH("CENTER")

pfQuest.route.arrow.distance = pfQuest.route.arrow:CreateFontString("pfQuestRouteDistance", "HIGH", "GameFontWhite")
pfQuest.route.arrow.distance:SetPoint("TOP", pfQuest.route.arrow.description, "BOTTOM", 0, -2)
pfQuest.route.arrow.distance:SetFont(pfUI.font_default, pfUI_config.global.font_size-1, "OUTLINE")
pfQuest.route.arrow.distance:SetTextColor(.8,.8,.8)
pfQuest.route.arrow.distance:SetJustifyH("CENTER")

pfQuest.route.arrow.parent = pfQuest.route
