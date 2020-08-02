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

  blacklist[best] = true
  return db[best]
end

-- connection between objectives
local objectivepath = {}

-- connection between player and the first objective
local playerpath = {}


local function ClearPath(path)
  for id, tex in pairs(path) do
    tex.enable = nil
    tex:Hide()
  end
end

local function DrawLine(path,x,y,nx,ny,hl)
  local dx,dy = x - nx, y - ny
  local dots = ceil(math.sqrt(dx*1.5*dx*1.5+dy*dy))*1

  for i=2, dots-2 do
    local xpos = nx + dx/dots*i
    local ypos = ny + dy/dots*i

    xpos = xpos / 100 * WorldMapButton:GetWidth()
    ypos = ypos / 100 * WorldMapButton:GetHeight()

    WorldMapButton.routes = WorldMapButton.routes or CreateFrame("Frame", nil, WorldMapButton)
    WorldMapButton.routes:SetAllPoints()

    local nline = tablesize(path) + 1
    for id, tex in pairs(path) do
      if not tex.enable then nline = id break end
    end

    path[nline] = path[nline] or WorldMapButton.routes:CreateTexture(nil, "HIGH")
    path[nline]:SetWidth(4)
    path[nline]:SetHeight(4)
    path[nline]:SetTexture(pfQuestConfig.path.."\\img\\route")
    if hl then path[nline]:SetVertexColor(.3,1,.8,1) end
    path[nline]:ClearAllPoints()
    path[nline]:SetPoint("CENTER", WorldMapButton, "TOPLEFT", xpos, -ypos)
    path[nline]:Show()
    path[nline].enable = true
  end
end

pfQuest.route = CreateFrame("Frame", "pfQuestRoute", UIParent)
pfQuest.route:SetPoint("CENTER", 0, -100)
pfQuest.route:SetWidth(56)
pfQuest.route:SetHeight(42)
pfQuest.route:SetClampedToScreen(true)
pfQuest.route:SetMovable(true)
pfQuest.route:EnableMouse(true)
pfQuest.route:RegisterForDrag('LeftButton')
pfQuest.route:SetScript("OnDragStart", function()
  if IsShiftKeyDown() then
    this:StartMoving()
  end
end)

pfQuest.route:SetScript("OnDragStop", function()
  this:StopMovingOrSizing()
end)

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

local speed = 0
local lastdist = 0
local speedtick = 10
pfQuest.route:SetScript("OnUpdate", function()
  local xplayer, yplayer = GetPlayerMapPosition("player")

  -- always update arrow while distance is set
  if this.coords and this.coords[1] and this.coords[1][4] then
    local xDelta = this.coords[1][1] - xplayer*100
    local yDelta = this.coords[1][2] - yplayer*100
    local dir = atan2(xDelta, -(yDelta))
    dir = dir > 0 and (math.pi*2) - dir or -dir

    local degtemp = dir
    if degtemp < 0 then degtemp = degtemp + 360 end
    local angle = math.rad(degtemp)
    local player = pfQuestCompat.GetPlayerFacing()
    angle = angle - player
    local perc = math.abs(((math.pi - math.abs(angle)) / math.pi))
    local r, g, b = pfUI.api.GetColorGradient(perc)
    cell = modulo(floor(angle / (math.pi*2) * 108 + 0.5), 108)
    local column = modulo(cell, 9)
    local row = floor(cell / 9)
    local xstart = (column * 56) / 512
    local ystart = (row * 42) / 512
    local xend = ((column + 1) * 56) / 512
    local yend = ((row + 1) * 42) / 512

    -- update arrow
    this.arrow:SetTexCoord(xstart,xend,ystart,yend)
    this.arrow:SetVertexColor(r,g,b)

    if this.coords[1][3].texture then
      this.texture:SetTexture(this.coords[1][3].texture)

      local r, g, b = unpack(this.coords[1][3].vertex or {0,0,0})
      if r > 0 or g > 0 or b > 0 then
        this.texture:SetVertexColor(unpack(this.coords[1][3].vertex))
      else
        this.texture:SetVertexColor(1,1,1,1)
      end
    else
      this.texture:SetTexture(pfQuestConfig.path.."\\img\\node")
      this.texture:SetVertexColor(pfMap.str2rgb(this.coords[1][3].title))
    end

    -- update texture visibility
    local alpha = this.coords[1][4] - 2
    alpha = alpha > 1 and 1 or alpha
    alpha = alpha < 0 and 0 or alpha
    local texalpha = 1 - alpha
    texalpha = texalpha > 1 and 1 or texalpha
    texalpha = texalpha < 0 and 0 or texalpha

    this.arrow:SetAlpha(alpha)
    this.arrow:Show()

    this.texture:SetAlpha(texalpha)
    this.texture:Show()
  end

  -- limit distance and route updates to once per .1 seconds
  if ( this.tick or 5) > GetTime() then return else this.tick = GetTime() + .1 end

  -- update distances to player
  for id, data in pairs(this.coords) do
    if data[1] and data[2] then
      local x, y = xplayer*100 - data[1], yplayer*100 - data[2]
      this.coords[id][4] = ceil(math.sqrt(x*x+y*y)*100)/100
    end
  end

  -- sort all coords by distance
  table.sort(this.coords, function(a,b) return a[4] < b[4] end)

  -- abort without any nodes
  if not this.coords[1] then
    ClearPath(objectivepath)
    ClearPath(playerpath)
    return
  end

  -- check first node
  if this.firstnode ~= tostring(this.coords[1][1]..this.coords[1][2]) or TODO_TABLE_CHANGED then
    this.firstnode = tostring(this.coords[1][1]..this.coords[1][2])

    -- recalculate objective paths
    local route = { [1] = this.coords[1] }
    local blacklist = { [1] = true }
    for i=2, table.getn(this.coords) do
      route[i] = GetNearest(route[i-1][1], route[i-1][2], this.coords, blacklist)
    end

    ClearPath(objectivepath)
    for i, data in pairs(route) do
      if i > 1 then
        DrawLine(objectivepath, route[i-1][1],route[i-1][2],route[i][1],route[i][2])
      end
    end
  end

  -- calculate speed
  if speedtick > 0 then
    speedtick = speedtick - 1
  else
    speedtick = 10
    speed = lastdist - this.coords[1][4]
    lastdist = this.coords[1][4]
  end

  -- draw player
  ClearPath(playerpath)
  DrawLine(playerpath,xplayer*100,yplayer*100,this.coords[1][1],this.coords[1][2],true)

  -- set title text
  local color = "|cffffcc00"
  if tonumber(this.coords[1][3]["qlvl"]) then
    color = pfMap:HexDifficultyColor(tonumber(this.coords[1][3]["qlvl"]))
  end
  this.title:SetText(color..this.coords[1][3].title .. "|r")

  -- set description text
  if this.coords[1][3].description then
    this.description:SetText(this.coords[1][3].description)
  else
    this.description:SetText("")
  end

  -- set distance
  if this.coords[1][4] > 1 and speed > 0 and floor(this.coords[1][4]/speed) > 0 then
    this.distance:SetText(floor(this.coords[1][4]*10) .. " yards (|cffffffff" ..  SecondsToTime(floor(this.coords[1][4]/speed)) .. "|r)")
  else
    this.distance:SetText(floor(this.coords[1][4]*10) .. " yards")
  end
end)

pfQuest.route.texture = pfQuest.route:CreateTexture("pfQuestRouteNodeTexture", "OVERLAY")
pfQuest.route.texture:SetWidth(32)
pfQuest.route.texture:SetHeight(32)
pfQuest.route.texture:SetPoint("BOTTOM", 0, 0)
pfQuest.route.texture:Hide()

pfQuest.route.arrow = pfQuest.route:CreateTexture("pfQuestRouteArrow", "OVERLAY")
pfQuest.route.arrow:SetTexture(pfQuestConfig.path.."\\img\\arrow")
pfQuest.route.arrow:SetAllPoints()
pfQuest.route.arrow:Hide()

pfQuest.route.title = pfQuest.route:CreateFontString("pfQuestRouteText", "HIGH", "GameFontWhite")
pfQuest.route.title:SetPoint("TOP", pfQuest.route.arrow, "BOTTOM", 0, -10)
pfQuest.route.title:SetFont(pfUI.font_default, pfUI_config.global.font_size+2, "OUTLINE")
pfQuest.route.title:SetTextColor(1,.8,.2)
pfQuest.route.title:SetJustifyH("CENTER")

pfQuest.route.description = pfQuest.route:CreateFontString("pfQuestRouteText", "HIGH", "GameFontWhite")
pfQuest.route.description:SetPoint("TOP", pfQuest.route.title, "BOTTOM", 0, -2)
pfQuest.route.description:SetFont(pfUI.font_default, pfUI_config.global.font_size, "OUTLINE")
pfQuest.route.description:SetTextColor(1,1,1)
pfQuest.route.description:SetJustifyH("CENTER")

pfQuest.route.distance = pfQuest.route:CreateFontString("pfQuestRouteDistance", "HIGH", "GameFontWhite")
pfQuest.route.distance:SetPoint("TOP", pfQuest.route.description, "BOTTOM", 0, -2)
pfQuest.route.distance:SetFont(pfUI.font_default, pfUI_config.global.font_size, "OUTLINE")
pfQuest.route.distance:SetTextColor(.8,.8,.8)
pfQuest.route.distance:SetJustifyH("CENTER")
