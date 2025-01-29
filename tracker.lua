-- multi api compat
local compat = pfQuestCompat

local fontsize = 12
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
        GameTooltip:AddLine(pfDatabase:FormatQuestText(pfDB["quests"]["loc"][this.node.questid]["O"]), 1,1,1,1)
        GameTooltip:AddLine(" ")
      end

      local qlogid = pfQuest.questlog[this.node.questid] and pfQuest.questlog[this.node.questid].qlogid
      if qlogid then
        local objectives = GetNumQuestLeaderBoards(qlogid)
        if objectives and objectives > 0 then
          for i=1, objectives, 1 do
            local text, _, done = GetQuestLogLeaderBoard(i, qlogid)
            local _, _, obj, cur, req = strfind(gsub(text, "\239\188\154", ":"), "(.*):%s*([%d]+)%s*/%s*([%d]+)")
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

local expand_states = {}

tracker = CreateFrame("Frame", "pfQuestMapTracker", UIParent)
tracker:Hide()
tracker:SetPoint("LEFT", UIParent, "LEFT", 0, 0)
tracker:SetWidth(200)
tracker:SetMovable(true)
tracker:EnableMouse(true)
tracker:SetClampedToScreen(true)
tracker:RegisterEvent("PLAYER_ENTERING_WORLD")
tracker:SetScript("OnEvent", function()
  -- update font sizes according to config
  fontsize = tonumber(pfQuest_config["trackerfontsize"]) or 12
  entryheight = ceil(fontsize*1.6)

  -- restore tracker state
  if pfQuest_config["showtracker"] and pfQuest_config["showtracker"] == "0" then
    this:Hide()
  else
    this:Show()
  end
end)

tracker:SetScript("OnMouseDown",function()
  if not pfQuest_config.lock then
    this:StartMoving()
  end
end)

tracker:SetScript("OnMouseUp",function()
  this:StopMovingOrSizing()
  local anchor, x, y = pfUI.api.ConvertFrameAnchor(this, pfUI.api.GetBestAnchor(this))
  this:ClearAllPoints()
  this:SetPoint(anchor, x, y)

  -- save position
  pfQuest_config.trackerpos = { anchor, x, y }
end)

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

  local alpha = this.backdrop:GetAlpha()
  local content = tracker.buttons[1] and not tracker.buttons[1].empty and true or nil
  local goal = ( content and not MouseIsOver(this) ) and 0 or not content and not MouseIsOver(this) and 0.5 or 1
  if ceil(alpha*10) ~= ceil(goal*10)then
    this.backdrop:SetAlpha(alpha + ((goal - alpha) > 0 and .1 or (goal - alpha) < 0 and -.1 or 0))
  end

  if pfQuestCompat.QuestWatchFrame:IsShown() then
    pfQuestCompat.QuestWatchFrame:Hide()
  end
end)

tracker:SetScript("OnShow", function()
  pfQuest_config["showtracker"] = "1"

  -- load tracker position if exists
   if pfQuest_config.trackerpos then
     this:ClearAllPoints()
     this:SetPoint(unpack(pfQuest_config.trackerpos))
   end
end)

tracker:SetScript("OnHide", function()
  pfQuest_config["showtracker"] = "0"
end)

tracker.buttons = {}
tracker.mode = "QUEST_TRACKING"

tracker.backdrop = CreateFrame("Frame", nil, tracker)
tracker.backdrop:SetAllPoints(tracker)
tracker.backdrop.bg = tracker.backdrop:CreateTexture(nil, "BACKGROUND")
tracker.backdrop.bg:SetTexture(0,0,0,.2)
tracker.backdrop.bg:SetAllPoints()

do -- button panel
  tracker.panel = CreateFrame("Frame", nil, tracker.backdrop)
  tracker.panel:SetPoint("TOPLEFT", 0, 0)
  tracker.panel:SetPoint("TOPRIGHT", 0, 0)
  tracker.panel:SetHeight(panelheight)

  local anchors = {}
  local buttons = {}
  local function CreateButton(icon, anchor, tooltip, func)
    anchors[anchor] = anchors[anchor] and anchors[anchor] + 1 or 0
    local pos = 1+(panelheight+1)*anchors[anchor]
    pos = anchor == "TOPLEFT" and pos or pos*-1
    local func = func

    local b = CreateFrame("Button", nil, tracker.panel)
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

  tracker.btnquest = CreateButton("quests", "TOPLEFT", pfQuest_Loc["Show Current Quests"], function()
    tracker.mode = "QUEST_TRACKING"
    pfMap:UpdateNodes()
  end)

  tracker.btndatabase = CreateButton("database", "TOPLEFT", pfQuest_Loc["Show Database Results"], function()
    tracker.mode = "DATABASE_TRACKING"
    pfMap:UpdateNodes()
  end)

  tracker.btngiver = CreateButton("giver", "TOPLEFT", pfQuest_Loc["Show Quest Givers"], function()
    tracker.mode = "GIVER_TRACKING"
    pfMap:UpdateNodes()
  end)

  tracker.btnclose = CreateButton("close", "TOPRIGHT", pfQuest_Loc["Close Tracker"], function()
    DEFAULT_CHAT_FRAME:AddMessage(pfQuest_Loc["|cff33ffccpf|cffffffffQuest: Tracker is now hidden. Type `/db tracker` to show."])
    tracker:Hide()
  end)

  tracker.btnsettings = CreateButton("settings", "TOPRIGHT", pfQuest_Loc["Open Settings"], function()
    if pfQuestConfig then pfQuestConfig:Show() end
  end)

  tracker.btnclean = CreateButton("clean", "TOPRIGHT", pfQuest_Loc["Clean Database Results"], function()
    pfMap:DeleteNode("PFDB")
    pfMap:UpdateNodes()
  end)

  tracker.btnsearch = CreateButton("search", "TOPRIGHT", pfQuest_Loc["Open Database Browser"], function()
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
  local alpha = tonumber((pfQuest_config["trackeralpha"] or .2)) or .2

  if not this.alpha or this.alpha ~= alpha then
    this.bg:SetTexture(0,0,0,alpha)
    this.bg:SetAlpha(alpha)
    this.alpha = alpha
  end

  if pfMap.highlight and pfMap.highlight == this.title then
    if not this.highlight then
      this.bg:SetTexture(1,1,1,math.max(.2, alpha))
      this.bg:SetAlpha(math.max(.5, alpha))
      this.highlight = true
    end
  elseif this.highlight then
    this.bg:SetTexture(0,0,0,alpha)
    this.bg:SetAlpha(alpha)
    this.highlight = nil
  end
end

function tracker.ButtonClick()
  if arg1 == "RightButton" then
    for questid, data in pairs(pfQuest.questlog) do
      if data.title == this.title then
        -- show questlog
        HideUIPanel(QuestLogFrame)
        SelectQuestLogEntry(data.qlogid)
        ShowUIPanel(QuestLogFrame)
        break
      end
    end
  elseif IsShiftKeyDown() then
    -- mark as done if node is quest and not in questlog
    if this.node.questid and not this.node.qlogid then
      -- mark as done in history
      pfQuest_history[this.node.questid] = { time(), UnitLevel("player") }
      UIErrorsFrame:AddMessage(string.format("The Quest |cffffcc00[%s]|r (id:%s) is now marked as done.", this.title, this.node.questid), 1,1,1)
    end

    pfMap:DeleteNode(this.node.addon, this.title)
    pfMap:UpdateNodes()

    pfQuest.updateQuestGivers = true
  elseif IsControlKeyDown() and not WorldMapFrame:IsShown() then
    -- show world map
    if ToggleWorldMap then
      -- vanilla & tbc
      ToggleWorldMap()
    else
      -- wotlk
      WorldMapFrame:Show()
    end
  elseif IsControlKeyDown() and pfQuest_config["spawncolors"] == "0" then
    -- switch color
    pfQuest_colors[this.title] = { pfMap.str2rgb(this.title .. GetTime()) }
    pfMap:UpdateNodes()
  elseif expand_states[this.title] == 0 then
    expand_states[this.title] = 1
    tracker.ButtonEvent(this)
  elseif expand_states[this.title] == 1 then
    expand_states[this.title] = 0
    tracker.ButtonEvent(this)
  end
end

local function trackersort(a,b)
  if a.empty then
    return false
  elseif ( a.tracked and 1 or -1 ) ~= (b.tracked and 1 or -1) then
    return ( a.tracked and 1 or -1 ) > (b.tracked and 1 or -1)
  elseif ( a.level or -1 ) ~= ( b.level or -1 ) then
    return (a.level or -1) > (b.level or -1)
  elseif ( a.perc or -1 ) ~= ( b.perc or -1 ) then
    return (a.perc or -1) > (b.perc or -1)
  elseif ( a.title or "" ) ~= ( b.title or "" ) then
    return ( a.title or "" ) < ( b.title or "" )
  else
    return false
  end
end

function tracker.ButtonEvent(self)
  local self   = self or this
  local title  = self.title
  local node   = self.node
  local id     = self.id
  local qid    = self.questid

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
    local qlogid = pfQuest.questlog[qid] and pfQuest.questlog[qid].qlogid or 0
    local qtitle, level, tag, header, collapsed, complete = compat.GetQuestLogTitle(qlogid)
    if not qlogid or not qtitle then return end
    local objectives = GetNumQuestLeaderBoards(qlogid)
    local watched = IsQuestWatched(qlogid)
    local color = pfQuestCompat.GetDifficultyColor(level)
    local cur,max = 0,0
    local percent = 0

    -- write expand state
    if not expand_states[title] then
      expand_states[title] = pfQuest_config["trackerexpand"] == "1" and 1 or 0
    end

    local expanded = expand_states[title] == 1 and true or nil

    if objectives and objectives > 0 then
      for i=1, objectives, 1 do
        local text, _, done = GetQuestLogLeaderBoard(i, qlogid)
        local _, _, obj, objNum, objNeeded = strfind(gsub(text, "\239\188\154", ":"), "(.*):%s*([%d]+)%s*/%s*([%d]+)")
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
    if objectives and (expanded or ( percent > 0 and percent < 100 )) then
      self:SetHeight(entryheight + objectives * fontsize)

      for i=1, objectives, 1 do
        local text, _, done = GetQuestLogLeaderBoard(i, qlogid)
        local _, _, obj, objNum, objNeeded = strfind(gsub(text, "\239\188\154", ":"), "(.*):%s*([%d]+)%s*/%s*([%d]+)")

        if not self.objectives[i] then
          self.objectives[i] = self:CreateFontString(nil, "HIGH", "GameFontNormal")
          self.objectives[i]:SetFont(pfUI.font_default, fontsize)
          self.objectives[i]:SetJustifyH("LEFT")
          self.objectives[i]:SetPoint("TOPLEFT", 20, -fontsize*i-6)
          self.objectives[i]:SetPoint("TOPRIGHT", -10, -fontsize*i-6)
        end

        if objNum and objNeeded then
          local r,g,b = pfMap.tooltip:GetColor(objNum, objNeeded)
          self.objectives[i]:SetTextColor(r+.2, g+.2, b+.2)
          self.objectives[i]:SetText(string.format("|cffffffff- %s:|r %s/%s", obj, objNum, objNeeded))
        else
          self.objectives[i]:SetTextColor(.8,.8,.8)
          self.objectives[i]:SetText("|cffffffff- " .. text)
        end

        self.objectives[i]:Show()

      end
    end

    local r,g,b = pfMap.tooltip:GetColor(cur, max)
    local colorperc = string.format("|cff%02x%02x%02x", r*255, g*255, b*255)
    local showlevel = pfQuest_config["trackerlevel"] == "1" and "[" .. ( level or "??" ) .. ( tag and "+" or "") .. "] " or ""

    self.tracked = watched
    self.perc = percent
    self.text:SetText(string.format("%s%s |cffaaaaaa(%s%s%%|cffaaaaaa)|r", showlevel, title or "", colorperc or "", ceil(percent)))
    self.text:SetTextColor(color.r, color.g, color.b)
    self.tooltip = pfQuest_Loc["|cff33ffcc<Click>|r Unfold/Fold Objectives\n|cff33ffcc<Right-Click>|r Show In QuestLog\n|cff33ffcc<Ctrl-Click>|r Show Map / Toggle Color\n|cff33ffcc<Shift-Click>|r Hide Nodes"]
  elseif tracker.mode == "GIVER_TRACKING" then
    local level = node.qlvl or node.level or UnitLevel("player")
    local color = pfQuestCompat.GetDifficultyColor(level)

    -- red quests
    if node.qmin and node.qmin > UnitLevel("player") then
      color = { r = 1, g = 0, b = 0 }
    end

    -- detect daily quests
    if node.qmin and node.qlvl and math.abs(node.qmin - node.qlvl) >= 30 then
      level, color = 0, { r = .2, g = .8, b = 1 }
    end

    local showlevel = pfQuest_config["trackerlevel"] == "1" and "[" .. ( level or "??" ) .. "] " or ""
    self.text:SetTextColor(color.r, color.g, color.b)
    self.text:SetText(showlevel .. title)
    self.level = tonumber(level)
    self.tooltip = pfQuest_Loc["|cff33ffcc<Ctrl-Click>|r Show Map / Toggle Color\n|cff33ffcc<Shift-Click>|r Mark As Done"]
  elseif tracker.mode == "DATABASE_TRACKING" then
    self.text:SetText(title)
    self.text:SetTextColor(1,1,1,1)
    self.text:SetTextColor(pfMap.str2rgb(title))
    self.tooltip = pfQuest_Loc["|cff33ffcc<Ctrl-Click>|r Show Map / Toggle Color\n|cff33ffcc<Shift-Click>|r Hide Nodes"]
  end

  -- sort all tracker entries
  table.sort(tracker.buttons, trackersort)

  self:Show()

  -- resize window and align buttons
  local height = panelheight
  local width = 100

  for bid, button in pairs(tracker.buttons) do
    button:ClearAllPoints()
    button:SetPoint("TOPRIGHT", tracker, "TOPRIGHT", 0, -height)
    button:SetPoint("TOPLEFT", tracker, "TOPLEFT", 0, -height)
    if not button.empty then
      height = height + button:GetHeight()

      if button.text:GetStringWidth() > width then
        width = button.text:GetStringWidth()
      end

      for id, objective in pairs(button.objectives) do
        if objective:IsShown() and objective:GetStringWidth() > width then
          width = objective:GetStringWidth()
        end
      end
    end
  end

  width = min(width, 300) + 30
  tracker:SetHeight(height)
  tracker:SetWidth(width)
end

function tracker.ButtonAdd(title, node)
  if not title or not node then return end

  local questid = title
  for qid, data in pairs(pfQuest.questlog) do
    if data.title == title then
      questid = qid
      break
    end
  end

  if tracker.mode == "QUEST_TRACKING" then -- skip everything that isn't in questlog
    if node.addon ~= "PFQUEST" then return end
    if not pfQuest.questlog or not pfQuest.questlog[questid] then return end
  elseif tracker.mode == "GIVER_TRACKING" then -- skip everything that isn't a questgiver
    if node.addon ~= "PFQUEST" then return end
    -- break on already taken quests
    if not pfQuest.questlog or pfQuest.questlog[questid] then return end
    -- every layer above 2 is not a questgiver
    if not node.layer or node.layer > 2 then return end
  elseif tracker.mode == "DATABASE_TRACKING" then -- skip everything that isn't db query
    if node.addon ~= "PFDB" then return end
  end

  local id

  -- skip duplicate titles
  for bid, button in pairs(tracker.buttons) do
    if button.title and button.title == title then
      if node.dummy or not node.texture then
        -- We found a node icon (1st prio)
        -- use the ID and update the button
        id = bid
        break
      elseif node.cluster and ( not button.node or button.node.texture ) then
        -- We found a cluster icon (2nd prio)
        -- set the id, but still try to find a node icon
        id = bid
      else
        -- got none of the above, therefore
        -- no icon update required, skip here
        return
      end
    end
  end

  if not id then
    -- use maxcount + 1 as default id
    id = table.getn(tracker.buttons)+1

    -- detect a reusable button
    for bid, button in pairs(tracker.buttons) do
      if button.empty then id = bid break end
    end
  end

  if id > 25 then return end

  -- create one if required
  if not tracker.buttons[id] then
    tracker.buttons[id] = CreateFrame("Button", "pfQuestMapButton"..id, tracker)
    tracker.buttons[id]:SetHeight(entryheight)

    tracker.buttons[id].bg = tracker.buttons[id]:CreateTexture(nil, "BACKGROUND")
    tracker.buttons[id].bg:SetTexture(1,1,1,.2)
    tracker.buttons[id].bg:SetAllPoints()
    tracker.buttons[id].bg:SetAlpha(0)

    tracker.buttons[id].text = tracker.buttons[id]:CreateFontString("pfQuestIDButton", "HIGH", "GameFontNormal")
    tracker.buttons[id].text:SetFont(pfUI.font_default, fontsize)
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

    tracker.buttons[id]:RegisterForClicks("LeftButtonUp", "RightButtonUp")

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
  tracker.buttons[id].questid = questid

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

  -- add tracked quests
  local _, numQuests = GetNumQuestLogEntries()
  local found = 0

  -- iterate over all quests
  for qlogid=1,40 do
    local title, level, tag, header, collapsed, complete = compat.GetQuestLogTitle(qlogid)
    if title and not header then
      local watched = IsQuestWatched(qlogid)
      if watched then
        local img = complete and pfQuestConfig.path.."\\img\\complete_c" or pfQuestConfig.path.."\\img\\complete"
        pfQuest.tracker.ButtonAdd(title, { dummy = true, addon = "PFQUEST", texture = img })
      end

      found = found + 1
      if found >= numQuests then
        break
      end
    end
  end
end

-- make global available
pfQuest.tracker = tracker
