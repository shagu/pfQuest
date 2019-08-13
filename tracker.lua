-- multi api compat
local compat = pfQuestCompat

local panelheight = 16
local entryheight = 20

local function HideTooltip()
  GameTooltip:Hide()
end

local function ShowTooltip()
  if this.tooltip then
    GameTooltip:ClearLines()
    GameTooltip_SetDefaultAnchor(GameTooltip, this)
    if this.text then
      GameTooltip:SetText(this.text:GetText())
      GameTooltip:SetText(this.text:GetText(), this.text:GetTextColor())
    else
      GameTooltip:SetText("|cff33ffccpf|cffffffffQuest")
    end

    if this.node and this.node.questid then
      if pfDB["quests"] and pfDB["quests"]["loc"] and pfDB["quests"]["loc"][this.node.questid] and pfDB["quests"]["loc"][this.node.questid]["O"] then
        GameTooltip:AddLine(pfDB["quests"]["loc"][this.node.questid]["O"], 1,1,1,1)
        GameTooltip:AddLine(" ")
      end

      if this.node.qlogid then
        local objectives = GetNumQuestLeaderBoards(this.node.qlogid)
        if objectives and objectives > 0 then
          for i=1, objectives, 1 do
            local text, _, done = GetQuestLogLeaderBoard(i, this.node.qlogid)
            local _, _, obj, cur, req = strfind(text, "(.*):%s*([%d]+)%s*/%s*([%d]+)")
            if done then
              GameTooltip:AddLine(" - " .. text, 0,1,0)
            elseif cur and req then
              local r,g,b = pfMap.tooltip:GetColor(cur, req)
              GameTooltip:AddLine(" - " .. text, r,g,b)
            else
              GameTooltip:AddLine(" - " .. text, 1,0,0)
            end
          end
          GameTooltip:AddLine(" ")
        end
      end
    end

    GameTooltip:AddLine(this.tooltip, 1,1,1)
    GameTooltip:Show()
  end
end

tracker = CreateFrame("Frame", "pfQuestMapTracker", UIParent)
tracker:SetPoint("LEFT", UIParent, "LEFT", 0, 0)
tracker:SetWidth(200)

tracker:SetMovable(true)
tracker:EnableMouse(true)
tracker:SetScript("OnMouseDown",function() this:StartMoving() end)
tracker:SetScript("OnMouseUp",function() this:StopMovingOrSizing() end)
tracker:SetScript("OnUpdate", function()
  if WorldMapFrame:IsShown() then
    if this.strata ~= "FULLSCREEN_DIALOG" then
      this:SetFrameStrata("FULLSCREEN_DIALOG")
      this.strata = "FULLSCREEN_DIALOG"
    end
  else
    if this.strata ~= "BACKGROUND" then
      this:SetFrameStrata("BACKGROUND")
      this.strata = "BACKGROUND"
    end
  end
end)

tracker.buttons = {}
tracker.mode = "QUEST_TRACKING"

pfUI.api.CreateBackdrop(tracker, nil, nil, .5)

do -- button panel
  local anchors = {}
  local buttons = {}
  local function CreateButton(icon, anchor, tooltip, func)
    anchors[anchor] = anchors[anchor] and anchors[anchor] + 1 or 0
    local pos = 1+(panelheight+1)*anchors[anchor]
    pos = anchor == "TOPLEFT" and pos or pos*-1
    local func = func

    local b = CreateFrame("Button", nil, tracker)
    b.tooltip = tooltip
    b.icon = b:CreateTexture(nil, "BACKGROUND")
    b.icon:SetAllPoints()
    b.icon:SetTexture(pfQuestConfig.path.."\\img\\tracker_"..icon)
    if table.getn(buttons) == 0 then b.icon:SetVertexColor(.2,1,.8) end

    b:SetPoint(anchor, pos, -1)
    b:SetWidth(panelheight-2)
    b:SetHeight(panelheight-2)

    b:SetScript("OnEnter", ShowTooltip)
    b:SetScript("OnLeave", HideTooltip)

    if anchor == "TOPLEFT" then
      table.insert(buttons, b)
      b:SetScript("OnClick", function()
        if func then func() end
        for id, button in pairs(buttons) do
          button.icon:SetVertexColor(1,1,1)
        end
        this.icon:SetVertexColor(.2,1,.8)
      end)
    else
      b:SetScript("OnClick", func)
    end

    return b
  end

  tracker.panel = tracker:CreateTexture(nil, "LOW")
  tracker.panel:SetTexture(0,0,0,.5)
  tracker.panel:SetPoint("TOPLEFT", 0, 0)
  tracker.panel:SetPoint("TOPRIGHT", 0, 0)
  tracker.panel:SetHeight(panelheight)

  tracker.btnquest = CreateButton("quests", "TOPLEFT", "Show Current Quests", function()
    tracker.mode = "QUEST_TRACKING"
    pfMap:UpdateNodes()
  end)

  tracker.btndatabase = CreateButton("database", "TOPLEFT", "Show Database Results", function()
    tracker.mode = "DATABASE_TRACKING"
    pfMap:UpdateNodes()
  end)

  tracker.btngiver = CreateButton("giver", "TOPLEFT", "Show Quest Givers", function()
    tracker.mode = "GIVER_TRACKING"
    pfMap:UpdateNodes()
  end)

  tracker.btnclose = CreateButton("close", "TOPRIGHT", "Close Tracker", function()
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffccpf|cffffffffQuest: Tracker is now hidden. Type `/db tracker` to show.")
    tracker:Hide()
  end)

  tracker.btnsettings = CreateButton("settings", "TOPRIGHT", "Open Settings", function()
    if pfQuestConfig then pfQuestConfig:Show() end
  end)

  tracker.btnclean = CreateButton("clean", "TOPRIGHT", "Clean Database Results", function()
    pfMap:DeleteNode("PFDB")
    pfMap:UpdateNodes()
  end)

  tracker.btnsearch = CreateButton("search", "TOPRIGHT", "Open Database Browser", function()
    if pfBrowser then pfBrowser:Show() end
  end)
end

function tracker.ButtonEnter()
  pfMap.highlight = this.title
  ShowTooltip()
end

function tracker.ButtonLeave()
  pfMap.highlight = nil
  HideTooltip()
end

function tracker.ButtonUpdate()
  if pfMap.highlight and pfMap.highlight == this.title then
    this.bg:SetAlpha(.5)
  else
    this.bg:SetAlpha(0)
  end
end

function tracker.ButtonClick()
  if IsShiftKeyDown() then
    -- mark as done if node is quest and not in questlog
    if this.node.questid and not this.node.qlogid then
      -- mark as done in history
      pfQuest_history[this.node.questid] = true
      UIErrorsFrame:AddMessage(string.format("The Quest |cffffcc00[%s]|r (id:%s) is now marked as done.", this.title, this.node.questid), 1,1,1)
    end

    pfMap:DeleteNode(this.node.addon, this.title)
    pfMap:UpdateNodes()

    pfQuest.updateQuestGivers = true
  elseif not WorldMapFrame:IsShown() then
    -- show world map
    WorldMapFrame:Show()
  elseif pfQuest_config["spawncolors"] == "0" then
    -- switch color
    pfQuest_colors[this.title] = { pfMap.str2rgb(this.title .. GetTime()) }
    pfMap:UpdateNodes()
  end
end

function tracker.ButtonEvent(self)
  local self   = self or this
  local title  = self.title
  local node   = self.node
  local id     = self.id

  self:SetHeight(0)

  -- we got an event on a hidden button
  if not title then return end
  if self.empty then return end

  self:SetHeight(entryheight)

  -- initialize and hide all objectives
  self.objectives = self.objectives or {}
  for id, obj in pairs(self.objectives) do obj:Hide() end

  -- update button icon
  if node.texture then
    self.icon:SetTexture(node.texture)

    local r, g, b = unpack(node.vertex or {0,0,0})
    if r > 0 or g > 0 or b > 0 then
      self.icon:SetVertexColor(unpack(node.vertex))
    else
      self.icon:SetVertexColor(1,1,1,1)
    end
  elseif pfQuest_config["spawncolors"] == "1" then
    self.icon:SetTexture(pfQuestConfig.path.."\\img\\available_c")
    self.icon:SetVertexColor(1,1,1,1)
  else
    self.icon:SetTexture(pfQuestConfig.path.."\\img\\node")
    self.icon:SetVertexColor(pfMap.str2rgb(title))
  end

  if tracker.mode == "QUEST_TRACKING" then
    tracker.buttons[id].tooltip = "|cff33ffcc<Click>|r Show Map / Toggle Color\n|cff33ffcc<Shift-Click>|r Hide Nodes"

    local qlogid = pfQuest.questlog[title].qlogid
    local qtitle, level, tag, header, collapsed, complete = compat.GetQuestLogTitle(qlogid)
    local objectives = GetNumQuestLeaderBoards(qlogid)
    local watched = IsQuestWatched(qlogid)
    local color = GetDifficultyColor(level)
    local cur,max = 0,0
    local percent = 0

    if objectives and objectives > 0 then
      for i=1, objectives, 1 do
        local text, _, done = GetQuestLogLeaderBoard(i, qlogid)
        local _, _, obj, objNum, objNeeded = strfind(text, "(.*):%s*([%d]+)%s*/%s*([%d]+)")
        if objNum and objNeeded then
          max = max + objNeeded
          cur = cur + objNum
        elseif not done then
          max = max + 1
        end
      end
    end

    if cur == max or complete then
      cur, max = 1, 1
      percent = 100
    else
      percent = cur/max*100
    end

    -- expand button to show objectives
    if objectives and percent > 0 and percent < 100 then
      self:SetHeight(entryheight + objectives*12)

      for i=1, objectives, 1 do
        local text, _, done = GetQuestLogLeaderBoard(i, qlogid)
        local _, _, obj, objNum, objNeeded = strfind(text, "(.*):%s*([%d]+)%s*/%s*([%d]+)")

        if not self.objectives[i] then
          self.objectives[i] = self:CreateFontString(nil, "HIGH", "GameFontNormal")
          self.objectives[i]:SetFont(pfUI.font_default, 12)
          self.objectives[i]:SetJustifyH("LEFT")
          self.objectives[i]:SetPoint("TOPLEFT", 20, -12*i-6)
          self.objectives[i]:SetPoint("TOPRIGHT", -10, -12*i-6)
        end

        if objNum and objNeeded then
          local r,g,b = pfMap.tooltip:GetColor(objNum, objNeeded)
          self.objectives[i]:SetTextColor(r+.2, g+.2, b+.2)
          self.objectives[i]:SetText(string.format("|cffffffff- %s:|r %s/%s", obj, objNum, objNeeded))
        else
          self.objectives[i]:SetTextColor(.8,.8,.8)
          self.objectives[i]:SetText("|cffffff- " .. text)
        end

        self.objectives[i]:Show()

      end
    end

    local r,g,b = pfMap.tooltip:GetColor(cur, max)
    local colorperc = string.format("|cff%02x%02x%02x", r*255, g*255, b*255)

    self.perc = percent
    self.text:SetText(string.format("%s |cffaaaaaa(%s%s%%|cffaaaaaa)", title or "", colorperc or "", ceil(percent)))
    self.text:SetTextColor(color.r, color.g, color.b)

    -- sort map tracker based on quest progress
    table.sort(tracker.buttons, function(a,b) return not a.empty and (a.perc or -1) > (b.perc or -1) end)
  elseif tracker.mode == "GIVER_TRACKING" then
    tracker.buttons[id].tooltip = "|cff33ffcc<Click>|r Show Map / Toggle Color\n|cff33ffcc<Shift-Click>|r Mark As Done"

    local level = node.qlvl or node.level or UnitLevel("player")
    local color = GetDifficultyColor(level)

    -- detect daily quests
    if node.qmin and node.qlvl and math.abs(node.qmin - node.qlvl) >= 30 then
      level, color = 0, { r = .2, g = .8, b = 1 }
    end

    -- red quests
    if node.qmin and node.qmin > UnitLevel("player") then
      level, color = -60, { r = 1, g = .2, b = .2 }
    end

    self.text:SetTextColor(color.r, color.g, color.b)
    self.text:SetText(title)
    self.level = tonumber(level)

    -- sort map tracker based on database names
    table.sort(tracker.buttons, function(a,b) return not a.empty and (a.level or -1) > (b.level or -1) end)
  elseif tracker.mode == "DATABASE_TRACKING" then
    tracker.buttons[id].tooltip = "|cff33ffcc<Click>|r Show Map / Toggle Color\n|cff33ffcc<Shift-Click>|r Hide Nodes"

    self.text:SetText(title)
    self.text:SetTextColor(1,1,1,1)
    self.text:SetTextColor(pfMap.str2rgb(title))

    -- sort map tracker based on database names
    table.sort(tracker.buttons, function(a,b) return not a.empty and (a.title or "") > (b.title or "") end)
  end

  self:Show()

  -- resize window and align buttons
  local height = panelheight
  for bid, button in pairs(tracker.buttons) do
    button:ClearAllPoints()
    button:SetPoint("TOPRIGHT", tracker, "TOPRIGHT", 0, -height)
    if not button.empty then height = height + button:GetHeight() end
  end
  tracker:SetHeight(height)
end

function tracker.ButtonAdd(title, node)
  if tracker.mode == "QUEST_TRACKING" then -- skip everything that isn't in questlog
    if node.addon ~= "PFQUEST" then return end
    if not pfQuest.questlog or not pfQuest.questlog[title] then return end
  elseif tracker.mode == "GIVER_TRACKING" then -- skip everything that isn't a questgiver
    if node.addon ~= "PFQUEST" then return end
    -- break on already taken quests
    if not pfQuest.questlog or pfQuest.questlog[title] then return end
    -- every layer above 2 is not a questgiver
    if node.layer > 2 then return end
  elseif tracker.mode == "DATABASE_TRACKING" then -- skip everything that isn't db query
    if node.addon ~= "PFDB" then return end
  end

  -- search for existing reusable buttons
  local id = table.getn(tracker.buttons)+1
  for bid, button in pairs(tracker.buttons) do
    if button.title == title then
      -- prefer node icons over questgivers
      if not node.texture and button.node.texture then
        id = bid
        break
      else
        return
      end
    end
    if button.empty then id = bid break end
  end

  -- create one if required
  if not tracker.buttons[id] then
    tracker.buttons[id] = CreateFrame("Button", "pfQuestMapButton"..id, tracker)
    tracker.buttons[id]:SetWidth(200)
    tracker.buttons[id]:SetHeight(entryheight)

    tracker.buttons[id].bg = tracker.buttons[id]:CreateTexture(nil, "BACKGROUND")
    tracker.buttons[id].bg:SetTexture(1,1,1,.2)
    tracker.buttons[id].bg:SetAllPoints()

    tracker.buttons[id].text = tracker.buttons[id]:CreateFontString("pfQuestIDButton", "HIGH", "GameFontNormal")
    tracker.buttons[id].text:SetFont(pfUI.font_default, 12)
    tracker.buttons[id].text:SetJustifyH("LEFT")
    tracker.buttons[id].text:SetPoint("TOPLEFT", 16, -4)
    tracker.buttons[id].text:SetPoint("TOPRIGHT", -10, -4)

    tracker.buttons[id].icon = tracker.buttons[id]:CreateTexture(nil, "BORDER")
    tracker.buttons[id].icon:SetPoint("TOPLEFT", 2, -4)
    tracker.buttons[id].icon:SetWidth(12)
    tracker.buttons[id].icon:SetHeight(12)

    tracker.buttons[id]:RegisterEvent("QUEST_WATCH_UPDATE")
    tracker.buttons[id]:RegisterEvent("QUEST_LOG_UPDATE")
    tracker.buttons[id]:RegisterEvent("QUEST_FINISHED")

    tracker.buttons[id]:SetScript("OnEnter", tracker.ButtonEnter)
    tracker.buttons[id]:SetScript("OnLeave", tracker.ButtonLeave)
    tracker.buttons[id]:SetScript("OnUpdate", tracker.ButtonUpdate)
    tracker.buttons[id]:SetScript("OnEvent", tracker.ButtonEvent)
    tracker.buttons[id]:SetScript("OnClick", tracker.ButtonClick)
  end

  -- set required data
  tracker.buttons[id].empty = nil
  tracker.buttons[id].title = title
  tracker.buttons[id].node = node
  tracker.buttons[id].id = id

  -- reload button data
  tracker.ButtonEvent(tracker.buttons[id])
end

function tracker.Reset()
  tracker:SetHeight(panelheight)
  for id, button in pairs(tracker.buttons) do
    button.level = nil
    button.title = nil
    button.perc = nil
    button.empty = true
    button:SetHeight(0)
    button:Hide()
  end
end

-- make global available
pfQuest.tracker = tracker
