local function tablesize(tbl)
  local count = 0
  for _ in pairs(tbl) do count = count + 1 end
  return count
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

pfQuest.route = CreateFrame("Frame")
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
    print("FULL UPD .. " .. GetTime())

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
end)
