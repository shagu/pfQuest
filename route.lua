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
pfQuest.route:SetPoint("CENTER", 0, -200)
pfQuest.route:SetWidth(56)
pfQuest.route:SetHeight(42)

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

pfQuest.route:SetScript("OnUpdate", function()
  if ( this.tick or 5) > GetTime() then return else this.tick = GetTime() + .1 end

  -- update distances to player
  local xplayer, yplayer = GetPlayerMapPosition("player")
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

  -- draw player
  ClearPath(playerpath)
  DrawLine(playerpath,xplayer*100,yplayer*100,this.coords[1][1],this.coords[1][2],true)

  -- update arrow
  local xDelta = this.coords[1][1] - xplayer*100
  local yDelta = this.coords[1][2] - yplayer*100
  local dir = atan2(xDelta, -(yDelta))
  dir = dir > 0 and (math.pi*2) - dir or -dir

  local degtemp = dir
  if degtemp < 0 then degtemp = degtemp + 360; end
  local angle = math.rad(degtemp)
  local player = pfQuestCompat.GetPlayerFacing()
  angle = angle - player
  local perc = 1-  math.abs(((math.pi - math.abs(angle)) / math.pi))

  cell = modulo(floor(angle / (math.pi*2) * 108 + 0.5), 108);
  local column = modulo(cell, 9)
  local row = floor(cell / 9)
  local xstart = (column * 56) / 512
  local ystart = (row * 42) / 512
  local xend = ((column + 1) * 56) / 512
  local yend = ((row + 1) * 42) / 512
  this.arrow:SetTexCoord(xstart,xend,ystart,yend)
  this.arrow:Show()

  -- update arrow text
  this.text:SetText(this.coords[1][3].title)

  if this.coords[1][3].interaction then
    this.text:SetText(this.text:GetText().."\n".."|cff33ffcc"..this.coords[1][3].interaction)
  end
end)

pfQuest.route.arrow = pfQuest.route:CreateTexture("pfQuestRouteArrow", "OVERLAY")
pfQuest.route.arrow:SetTexture(pfQuestConfig.path.."\\img\\arrow")
pfQuest.route.arrow:SetAllPoints()
pfQuest.route.arrow:SetVertexColor(.3,1,.8)
pfQuest.route.arrow:Hide()

pfQuest.route.text = pfQuest.route:CreateFontString("pfQuestRouteText", "HIGH", "GameFontWhite")
pfQuest.route.text:SetPoint("TOP", pfQuest.route.arrow, "BOTTOM", 0, -10)
pfQuest.route.text:SetJustifyH("CENTER")
