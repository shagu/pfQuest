-- default config
pfQuest_defconfig = {
  ["trackingmethod"] = 1,
  ["allquestgivers"] = "1",
  ["currentquestgivers"] = "1", -- show quest givers for active quests
  ["showlowlevel"] = "1",
  ["minimapnodes"] = "1", -- hide all minimap entries
  ["questlogbuttons"] = "1", -- shows buttons inside the questlog
  ["worldmapmenu"] = "1", -- shows the dropdown selection in worldmap
  ["worldmaptransp"] = "1.0",
  ["minimaptransp"] = "1.0",
}

pfQuest_history = {}
pfQuest_config = {}
pfQuest_colors = {}

local function LoadConfig()
  if not pfQuest_config then pfQuest_config = {} end

  for key, val in pairs(pfQuest_defconfig) do
    if not pfQuest_config[key] then
      pfQuest_config[key] = val
    end
  end
end

LoadConfig()

local questLogCache     = { }
local questTrackedCache = { }

local function ClearQuest(quest)
  pfMap:DeleteNode("PFQUEST", quest)
  questTrackedCache[quest] = nil
end

local function QuestNeedsUpdate(questIndex)
  local title, level = GetQuestLogTitle(questIndex)

  if not title then return nil end

  local watched = IsQuestWatched(questIndex)
  local objectives = GetNumQuestLeaderBoards(questIndex)
  local hash = title

  questTrackedCache[title] = questTrackedCache[title] or "init"

  if objectives then
    for i=1, objectives, 1 do
      local text, _, finished = GetQuestLogLeaderBoard(i, questIndex)
      local i, j, itemName, numItems, numNeeded = strfind(text, "(.*):%s*([%d]+)%s*/%s*([%d]+)")
      if itemName then
        hash = hash .. itemName .. ( finished and "DONE" or "TODO" )
      end
    end
  end

  if questTrackedCache[title] ~= hash then
    questTrackedCache[title] = hash
    return true
  else
    return nil
  end
end

local function UpdateQuestLogID(questIndex, action)
  -- never add nodes in hidden mode
  if pfQuest_config["trackingmethod"] == 4 then return end

  -- specified index
  if questIndex then
    --local title, level = GetQuestLogTitle(questIndex)
    local title, level, _, header, _, complete = GetQuestLogTitle(questIndex)
    if header or not title then return end

    local watched = IsQuestWatched(questIndex)
    if not title then return end

    -- read questtext and objectives
    local oldID = GetQuestLogSelection()
    SelectQuestLogEntry(questIndex)
    local qtxt, qobj = GetQuestLogQuestText()
    SelectQuestLogEntry(oldID)

    if action == "REMOVE" or
    ( not action and not watched and pfQuest_config["trackingmethod"] == 2 ) or
    ( not action and pfQuest_config["trackingmethod"] == 3 ) then
      ClearQuest(title)
      return nil
    end

    -- abort with available cache when no action was given
    if not action and not QuestNeedsUpdate(questIndex) then return nil end

    -- hide old nodes and apply changes
    pfMap:DeleteNode("PFQUEST", title)

    local objectives = GetNumQuestLeaderBoards(questIndex)
    local zone, score, maps, meta = nil, 0, {}, {}
    local dbobj = nil

    if objectives then
      for i=1, objectives, 1 do
        local text, type, finished = GetQuestLogLeaderBoard(i, questIndex)

        local match = nil
        if not finished then
          -- spawn data
          if type == "monster" then
            local i, j, monsterName, objNum, objNeeded = strfind(text, pfUI.api.SanitizePattern(QUEST_MONSTERS_KILLED))
            meta = { ["quest"] = title, ["addon"] = "PFQUEST" }
            zone, score = pfDatabase:SearchMob(monsterName, meta)
            if zone then
              match = true
              maps[zone] = maps[zone] and maps[zone] + score or 1
            end
          end

          -- item data
          if type == "item" then
            local i, j, itemName, objNum, objNeeded = strfind(text, pfUI.api.SanitizePattern(QUEST_OBJECTS_FOUND))
            meta = { ["quest"] = title, ["addon"] = "PFQUEST", ["item"] = itemName }
            zone, score = pfDatabase:SearchItem(itemName, meta)
            if zone then
              match = true
              maps[zone] = maps[zone] and maps[zone] + score or 1
            end

            meta = { ["quest"] = title, ["addon"] = "PFQUEST", ["item"] = itemName }
            zone, score = pfDatabase:SearchVendor(itemName, meta)
            if zone then
              match = true
              maps[zone] = maps[zone] and maps[zone] + score or 1
            end
          end

          if not match then dbobj = true end
        end
      end
    end

    -- show quest givers
    if pfQuest_config["currentquestgivers"] ==  "1" then
      local meta = { ["quest"] = title, ["addon"] = "PFQUEST" }
      if complete or objectives == 0 then
        meta.qstate = "done"
      else
        meta.qstate = "progress"
      end

      local questIndex = title .. "," .. string.sub(qobj, 1, 10)
      zone, score = pfDatabase:SearchQuest(questIndex, meta, dbobj)
      if zone then maps[zone] = maps[zone] and maps[zone] + score or 1 end
    end

    -- calculate best map results
    local bestmap, bestscore = nil, 0
    for map, count in pairs(maps) do
      if count > bestscore then
        bestscore = count
        bestmap   = map
      end
    end

    pfMap:UpdateNodes()

    return bestmap, bestscore
  else
    -- check for questlog changes
    local cur = {}
    for id=1, GetNumQuestLogEntries() do
      local title = GetQuestLogTitle(id)
      cur[title] = true
    end

    -- remove already deleted or done quests
    local exists = nil
    for quest in pairs(questLogCache) do
      if not cur[quest] then
        pfQuest_history[quest] = true
        ClearQuest(quest)
      end
    end

    -- trigger update loop
    pfQuest:Show()

    -- update questlog cache
    questLogCache = cur
  end
end

local function AddQuestLogIntegration()
  if pfQuest_config["questlogbuttons"] ==  "0" then return end

  local dockFrame = EQL3_QuestLogDetailScrollChildFrame or ShaguQuest_QuestLogDetailScrollChildFrame or QuestLogDetailScrollChildFrame
  local dockTitle = EQL3_QuestLogDescriptionTitle or ShaguQuest_QuestLogDescriptionTitle or QuestLogDescriptionTitle

  dockTitle:SetHeight(dockTitle:GetHeight() + 30)
  dockTitle:SetJustifyV("BOTTOM")

  pfQuest.buttonShow = pfQuest.buttonShow or CreateFrame("Button", "pfQuestShow", dockFrame, "UIPanelButtonTemplate")
  pfQuest.buttonShow:SetWidth(90)
  pfQuest.buttonShow:SetHeight(23)
  pfQuest.buttonShow:SetText("Show")
  pfQuest.buttonShow:SetPoint("TOP", dockTitle, "TOP", -95, 0)
  pfQuest.buttonShow:SetScript("OnClick", function()
    local map = UpdateQuestLogID(GetQuestLogSelection(), "ADD")
    pfMap:ShowMapID(map)
  end)

  pfQuest.buttonClean = pfQuest.buttonClean or CreateFrame("Button", "pfQuestClean", dockFrame, "UIPanelButtonTemplate")
  pfQuest.buttonClean:SetWidth(90)
  pfQuest.buttonClean:SetHeight(23)
  pfQuest.buttonClean:SetText("Clean")
  pfQuest.buttonClean:SetPoint("TOP", dockTitle, "TOP", 0, 0)
  pfQuest.buttonClean:SetScript("OnClick", function()
    pfMap:DeleteNode("PFQUEST")
    pfMap:UpdateNodes()
  end)

  pfQuest.buttonReset = pfQuest.buttonReset or CreateFrame("Button", "pfQuestHide", dockFrame, "UIPanelButtonTemplate")
  pfQuest.buttonReset:SetWidth(90)
  pfQuest.buttonReset:SetHeight(23)
  pfQuest.buttonReset:SetText("Reset")
  pfQuest.buttonReset:SetPoint("TOP", dockTitle, "TOP", 95, 0)
  pfQuest.buttonReset:SetScript("OnClick", function()
    pfMap:DeleteNode("PFQUEST")
    pfMap:UpdateNodes()

    questTrackedCache = {}
    pfQuest:Show()
  end)
end

local function AddWorldMapIntegration()
  if pfQuest_config["worldmapmenu"] ==  "0" then return end

  -- Quest Update Indicator
  pfQuest.mapUpdate = WorldMapButton:CreateFontString(nil, "OVERLAY")
  pfQuest.mapUpdate:SetPoint("BOTTOMLEFT", 10, 10)
  pfQuest.mapUpdate:SetFont(pfUI.font_default, pfUI_config.global.font_size, "OUTLINE")
  pfQuest.mapUpdate:SetTextColor(1, 1, 1)

  pfQuest.mapUpdate:SetJustifyH("LEFT")
  pfQuest.mapUpdate:SetJustifyV("BOTTOM")

  pfQuest.mapUpdate:SetWidth(150)
  pfQuest.mapUpdate:SetHeight(15)
  pfQuest.mapUpdate:Show()

  -- Quest Display Selection
  pfQuest.mapButton = CreateFrame("Frame", "pfQuestMapDropdown", WorldMapButton, "UIDropDownMenuTemplate")
  pfQuest.mapButton:ClearAllPoints()
  pfQuest.mapButton:SetPoint("TOPRIGHT" , 0, -10)
  pfQuest.mapButton:SetScript("OnShow", function()
    pfQuest.mapButton.current = tonumber(pfQuest_config["trackingmethod"])
    pfQuest.mapButton:UpdateMenu()
  end)

  pfQuest.mapButton.point = "TOPLEFT"
  pfQuest.mapButton.relativePoint = "BOTTOMLEFT"

  function pfQuest.mapButton:UpdateMenu()
    local function CreateEntries()
      local info = {}
      info.text = "All Quests"
      info.checked = false
      info.func = function()
        UIDropDownMenu_SetSelectedID(pfQuest.mapButton, this:GetID(), 0)
        pfQuest_config["trackingmethod"] = this:GetID()

        -- rescan
        questTrackedCache = {}
        pfQuest:Show()
      end
      UIDropDownMenu_AddButton(info)

      local info = {}
      info.text = "Tracked Quests"
      info.checked = false
      info.func = function()
        UIDropDownMenu_SetSelectedID(pfQuest.mapButton, this:GetID(), 0)
        pfQuest_config["trackingmethod"] = this:GetID()
        questTrackedCache = {}
        pfQuest:Show()
      end
      UIDropDownMenu_AddButton(info)

      local info = {}
      info.text = "Manual Selection"
      info.checked = false
      info.func = function()
        UIDropDownMenu_SetSelectedID(pfQuest.mapButton, this:GetID(), 0)
        pfQuest_config["trackingmethod"] = this:GetID()
        questTrackedCache = {}
        pfQuest:Show()
      end
      UIDropDownMenu_AddButton(info)

      local info = {}
      info.text = "Hide Quests"
      info.checked = false
      info.func = function()
        UIDropDownMenu_SetSelectedID(pfQuest.mapButton, this:GetID(), 0)
        pfQuest_config["trackingmethod"] = this:GetID()
        pfMap:DeleteNode("PFQUEST")
        pfMap:UpdateNodes()
      end
      UIDropDownMenu_AddButton(info)
    end

    UIDropDownMenu_Initialize(pfQuest.mapButton, CreateEntries)
    UIDropDownMenu_SetWidth(120, pfQuest.mapButton)
    UIDropDownMenu_SetButtonWidth(125, pfQuest.mapButton)
    UIDropDownMenu_JustifyText("RIGHT", pfQuest.mapButton)
    UIDropDownMenu_SetSelectedID(pfQuest.mapButton, pfQuest.mapButton.current)
  end
end

local pfHookRemoveQuestWatch = RemoveQuestWatch
RemoveQuestWatch = function(questIndex)
  if pfQuest_config["trackingmethod"] == 2 then
    UpdateQuestLogID(questIndex, "REMOVE")
  end
  return pfHookRemoveQuestWatch(questIndex)
end

local pfHookAddQuestWatch = AddQuestWatch
AddQuestWatch = function(questIndex)
  if pfQuest_config["trackingmethod"] ~= 3 then
    local map = UpdateQuestLogID(questIndex, "ADD")
    pfMap:SetMapByID(map)
  end
  return pfHookAddQuestWatch(questIndex)
end

pfQuest = CreateFrame("Frame")
pfQuest:RegisterEvent("QUEST_LOG_UPDATE")
pfQuest:RegisterEvent("QUEST_FINISHED")
pfQuest:RegisterEvent("QUEST_WATCH_UPDATE")
pfQuest:RegisterEvent("PLAYER_LEVEL_UP")
pfQuest:RegisterEvent("ADDON_LOADED")

pfQuest:SetScript("OnEvent", function()
  if event == "ADDON_LOADED" then
    if arg1 == "pfQuest" then
      if tostring(GetAddOnMetadata("pfQuest", "Version")) == "NORELEASE" then
        DEFAULT_CHAT_FRAME:AddMessage("|cff33ffccWARNING:|r You're using a development snapshot of pfQuest which leads to a higher RAM-Usage and increased loading times. Please choose an official release instead: https://github.com/shagu/pfQuest/releases")
      end

      LoadConfig()
      AddQuestLogIntegration()
      AddWorldMapIntegration()
    else
      return
    end
  else
    -- never update in manual and hidden mode
    if pfQuest_config["trackingmethod"] == 3 then return end
    if pfQuest_config["trackingmethod"] == 4 then return end
    if event == "PLAYER_LEVEL_UP" then
      pfMap:DeleteNode("PFQUEST")
      pfMap:UpdateNodes()

      questTrackedCache = {}
      pfQuest:Show()
    elseif event == "QUEST_FINISHED" then
      UpdateQuestLogID(nil)
    elseif not arg1 or type(arg1) == "number" then
      UpdateQuestLogID(arg1)
    end
  end
end)

pfQuest:SetScript("OnShow", function()
  this.hadUpdate = nil
end)

pfQuest:SetScript("OnUpdate", function()
  if pfQuest_config["trackingmethod"] == 4 then this:Hide() return end

  this.scan = this.scan and this.scan + 1 or 1
  this.smax = GetNumQuestLogEntries()

  if pfQuest.mapUpdate then
    pfQuest.mapUpdate:Show()
    pfQuest.mapUpdate:SetText("Quest Update [ " .. this.scan .. " / " .. this.smax .. " ]")
  end

  if UpdateQuestLogID(this.scan) then
    this.hadUpdate = true
  end

  if this.scan >= this.smax then
    if this.hadUpdate or GetNumQuestLogEntries() == 0 then
      local meta = { }

      -- show all questgivers
      if pfQuest_config["allquestgivers"] == "1" then
        meta.allquests = true

        -- show lowlevel quests
        if  pfQuest_config["showlowlevel"] == "0" then
          meta.hidelow = true
        end

        pfDatabase:SearchQuests(nil, meta)
      end
      pfMap:UpdateNodes()
    end

    this:Hide()
    this.scan = nil

    if pfQuest.mapUpdate then
      pfQuest.mapUpdate:Hide()
    end
  end
end)

local HookAbandonQuest = AbandonQuest
function AbandonQuest()
  local quest = GetAbandonQuestName()
  questLogCache[quest] = nil
  pfQuest_history[quest] = nil
  questTrackedCache[quest] = "ABANDONED"
  pfMap:DeleteNode("PFQUEST", quest)
  HookAbandonQuest()
end

-- questlink integration
local pfHookQuestLogTitleButton_OnClick = QuestLogTitleButton_OnClick
function QuestLogTitleButton_OnClick(button)
	local questIndex = this:GetID() + FauxScrollFrame_GetOffset(QuestLogListScrollFrame);
  local questName, questLevel = GetQuestLogTitle(questIndex)
	if IsShiftKeyDown() and not this.isHeader then
		if ( ChatFrameEditBox:IsVisible() ) then
      ChatFrameEditBox:Insert("|cffffff00|Hquest:0:" .. questLevel .. ":0:0|h[" .. questName .. "]|h|r")
      QuestLog_SetSelection(questIndex)
      QuestLog_Update();
      return
    end
  end

  pfHookQuestLogTitleButton_OnClick(button)
end

local pfQuestHookSetItemRef = SetItemRef
function SetItemRef(link, text, button)
  local isQuest, _, id    = string.find(link, "quest:(%d+):.*")
  local isQuest2, _, _   = string.find(link, "quest2:.*")
  local _, _, questLevel = string.find(link, "quest:%d+:(%d+)")

  local playerHasQuest = false

  if isQuest or isQuest2 then
    local quests = pfDatabase["quests"]

    ShowUIPanel(ItemRefTooltip)
    ItemRefTooltip:SetOwner(UIParent, "ANCHOR_PRESERVE")

    local hasTitle, _, questTitle = string.find(text, ".*|h%[(.*)%]|h.*")
    if hasTitle then ItemRefTooltip:AddLine(questTitle, 1,1,0) end

    -- scan for questdb entry
    local qname = nil
    for name, tab in pairs(quests) do
      local f, t, questname, _ = strfind(name, "(.*),.*")
      if questname == questTitle then
        qname = name
        if id and tab.id == id then break end
      end
    end

    -- add database entries if existing
    if quests[qname] then
      if quests[qname]["obj"] then
        ItemRefTooltip:AddLine(quests[qname]["obj"], 1,1,1,true)
      end

      if quests[qname]["log"] and quests[qname]["objectives"] then
        ItemRefTooltip:AddLine(" ", 0,0,0)
      end

      if quests[qname]["log"] then
        ItemRefTooltip:AddLine(quests[qname]["log"], .6,1,.9,true)
      end
    end

    -- check questlog for active quest
    for i=1, GetNumQuestLogEntries() do
      if GetQuestLogTitle(i) == questTitle then
        playerHasQuest = true
      end
    end

    if playerHasQuest == false then
      ItemRefTooltip:AddLine("You don't have this quest.", 1, .8, .8)
    end

    -- extract quest level
    if questLevel and questLevel ~= 0 and questLevel ~= "0" then
      local color = GetDifficultyColor(questLevel)
      ItemRefTooltip:AddLine("Quest Level " .. questLevel, color.r, color.g, color.b)
    end

    ItemRefTooltip:Show()
  else
    pfQuestHookSetItemRef(link, text, button)
  end
end
