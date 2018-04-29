pfQuest = CreateFrame("Frame")

pfQuest.queue = {}
pfQuest.abandon = ""
pfQuest.questlog = {}
pfQuest.questlog_tmp = {}
pfQuest.debugmode  = true

pfQuest:RegisterEvent("QUEST_WATCH_UPDATE")
pfQuest:RegisterEvent("QUEST_LOG_UPDATE")
pfQuest:RegisterEvent("QUEST_FINISHED")
pfQuest:RegisterEvent("PLAYER_LEVEL_UP")
pfQuest:RegisterEvent("PLAYER_ENTERING_WORLD")
pfQuest:RegisterEvent("ADDON_LOADED")
pfQuest:SetScript("OnEvent", function()
  if event == "ADDON_LOADED" then
    if arg1 == "pfQuest" then
      if tostring(GetAddOnMetadata("pfQuest", "Version")) == "NORELEASE" then
        DEFAULT_CHAT_FRAME:AddMessage("|cff33ffccWARNING:|r You're using a development snapshot of pfQuest which leads to a higher RAM-Usage and increased loading times. Please choose an official release instead: https://github.com/shagu/pfQuest/releases")
      end

      pfQuest:AddQuestLogIntegration()
      pfQuest:AddWorldMapIntegration()
    else
      return
    end
  elseif event == "PLAYER_LEVEL_UP" or event == "PLAYER_ENTERING_WORLD" then
    pfQuest.updateQuestGivers = true
  else
    pfQuest.updateQuestLog = true
  end
end)

pfQuest:SetScript("OnUpdate", function()
  if pfQuest_config["trackingmethod"] == 4 then return end
  if ( this.tick or .2) > GetTime() then return else this.tick = GetTime() + .2 end

  if this.updateQuestGivers == true then
    if pfQuest_config["trackingmethod"] == 4 then return end
    if pfQuest_config["allquestgivers"] == "1" then
      pfQuest.debug("Loading Questgivers")
      local meta = { ["addon"] = "PFQUEST" }
      pfDatabase:SearchQuests(meta)
      pfMap:UpdateNodes()
      this.updateQuestGivers = false
    end
  end

  if this.updateQuestLog == true then
    pfQuest:UpdateQuestlog()
    this.updateQuestLog = false
  end

  if table.getn(this.queue) == 0 then return end

  -- process queue
  local match = false
  for id, entry in pairs(this.queue) do
    match = true

    if pfQuest_config["trackingmethod"] ~= 3 and (pfQuest_config["trackingmethod"] ~= 2 or IsQuestWatched(entry[3])) then
      pfMap:DeleteNode("PFQUEST", entry[1])
      pfQuest.debug("Loading |cff33ffcc" .. entry[1])
      local meta = { ["addon"] = "PFQUEST", ["qlogid"] = entry[3] }
      for _, id in entry[2] do
        pfDatabase:SearchQuestID(id, meta)
      end
    end

    pfQuest.queue[id] = nil
    return
  end

  -- trigger questgiver update
  if match == false then
    this.updateQuestGivers = true
    this.queue = {}
  end
end)

function pfQuest:UpdateQuestlog()
  pfQuest.questlog_tmp = {}

  -- iterate over all quests
  for qlogid=1, GetNumQuestLogEntries() do
    local title, _, _, header, _, complete = GetQuestLogTitle(qlogid)
    local objectives = GetNumQuestLeaderBoards(qlogid)
    local watched = IsQuestWatched(qlogid)

    if title and not header then
      -- add new quest to the questlog
      if not pfQuest.questlog[title] then
        local questID = pfDatabase:GetQuestIDs(qlogid)
        pfQuest.questlog_tmp[title] = { ids = questID, qlogid = qlogid, state = "init" }
      else
        pfQuest.questlog_tmp[title] = { ids = pfQuest.questlog[title].ids, qlogid = pfQuest.questlog[title].qlogid, state = pfQuest.questlog[title].state }
      end

      -- update progress state
      if objectives then
        local state = watched and "trck" or ""
        for i=1, objectives, 1 do
          local text, _, finished = GetQuestLogLeaderBoard(i, qlogid)
          local _, _, itemName, numItems, numNeeded = strfind(text, "(.*):%s*([%d]+)%s*/%s*([%d]+)")
          if itemName then
            state = state .. i .. ( finished and "done" or "todo" )
          end
        end
        pfQuest.questlog_tmp[title].state = state
      end
    end
  end

  -- quest add events
  for title, data in pairs(pfQuest.questlog_tmp) do
    if not pfQuest.questlog[title] then
      table.insert(pfQuest.queue, { title, data.ids, data.qlogid })
    elseif pfQuest.questlog_tmp[title].state ~= pfQuest.questlog[title].state then
      table.insert(pfQuest.queue, { title, data.ids, data.qlogid })
    end
  end

  -- quest removal events
  for title, data in pairs(pfQuest.questlog) do
    if not pfQuest.questlog_tmp[title] then
      pfMap:DeleteNode("PFQUEST", title)
      pfMap:UpdateNodes()

      for _, qid in pairs(pfQuest.questlog[title].ids) do
        -- write pfQuest.questlog history
        if title == pfQuest.abandon then
          pfQuest_history[qid] = nil
        else
          pfQuest_history[qid] = true
        end
      end
    end
  end

  -- set new questlog
  pfQuest.questlog = pfQuest.questlog_tmp
end

function pfQuest:ResetAll()
  -- force reload all quests
  pfMap:DeleteNode("PFQUEST")
  pfQuest.questlog = {}
  pfQuest.updateQuestLog = true
  pfQuest.updateQuestGivers = true
end

function pfQuest:AddQuestLogIntegration()
  if pfQuest_config["questlogbuttons"] ==  "0" then return end

  local dockFrame = EQL3_QuestLogDetailScrollChildFrame or ShaguQuest_QuestLogDetailScrollChildFrame or QuestLogDetailScrollChildFrame
  local dockTitle = EQL3_QuestLogDescriptionTitle or ShaguQuest_QuestLogDescriptionTitle or QuestLogDescriptionTitle

  dockTitle:SetHeight(dockTitle:GetHeight() + 30)
  dockTitle:SetJustifyV("BOTTOM")

  pfQuest.buttonShow = pfQuest.buttonShow or CreateFrame("Button", "pfQuestShow", dockFrame, "UIPanelButtonTemplate")
  pfQuest.buttonShow:SetWidth(70)
  pfQuest.buttonShow:SetHeight(20)
  pfQuest.buttonShow:SetText("Show")
  pfQuest.buttonShow:SetPoint("TOP", dockTitle, "TOP", -110, 0)
  pfQuest.buttonShow:SetScript("OnClick", function()
    local questIndex = GetQuestLogSelection()
    local title, _, _, header, _, complete = GetQuestLogTitle(questIndex)
    if header then return end

    local ids = pfDatabase:GetQuestIDs(questIndex)
    local maps, meta = {}, { ["addon"] = "PFQUEST", ["qlogid"] = questIndex }
    for _, id in ids do
      maps = pfDatabase:SearchQuestID(id, meta, maps)
    end
    pfMap:ShowMapID(pfDatabase:GetBestMap(maps))
  end)

  pfQuest.buttonHide = pfQuest.buttonHide or CreateFrame("Button", "pfQuestHide", dockFrame, "UIPanelButtonTemplate")
  pfQuest.buttonHide:SetWidth(70)
  pfQuest.buttonHide:SetHeight(20)
  pfQuest.buttonHide:SetText("Hide")
  pfQuest.buttonHide:SetPoint("TOP", dockTitle, "TOP", -37, 0)
  pfQuest.buttonHide:SetScript("OnClick", function()
    local questIndex = GetQuestLogSelection()
    local title, _, _, header, _, complete = GetQuestLogTitle(questIndex)
    if header then return end

    pfMap:DeleteNode("PFQUEST", title)
    pfMap:UpdateNodes()
  end)

  pfQuest.buttonClean = pfQuest.buttonClean or CreateFrame("Button", "pfQuestClean", dockFrame, "UIPanelButtonTemplate")
  pfQuest.buttonClean:SetWidth(70)
  pfQuest.buttonClean:SetHeight(20)
  pfQuest.buttonClean:SetText("Clean")
  pfQuest.buttonClean:SetPoint("TOP", dockTitle, "TOP", 37, 0)
  pfQuest.buttonClean:SetScript("OnClick", function()
    pfMap:DeleteNode("PFQUEST")
    pfMap:UpdateNodes()
  end)

  pfQuest.buttonReset = pfQuest.buttonReset or CreateFrame("Button", "pfQuestHide", dockFrame, "UIPanelButtonTemplate")
  pfQuest.buttonReset:SetWidth(70)
  pfQuest.buttonReset:SetHeight(20)
  pfQuest.buttonReset:SetText("Reset")
  pfQuest.buttonReset:SetPoint("TOP", dockTitle, "TOP", 110, 0)
  pfQuest.buttonReset:SetScript("OnClick", function()
    pfQuest:ResetAll()
  end)
end

function pfQuest:AddWorldMapIntegration()
  if pfQuest_config["worldmapmenu"] ==  "0" then return end

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
        pfQuest:ResetAll()
      end
      UIDropDownMenu_AddButton(info)

      local info = {}
      info.text = "Tracked Quests"
      info.checked = false
      info.func = function()
        UIDropDownMenu_SetSelectedID(pfQuest.mapButton, this:GetID(), 0)
        pfQuest_config["trackingmethod"] = this:GetID()
        pfQuest:ResetAll()
      end
      UIDropDownMenu_AddButton(info)

      local info = {}
      info.text = "Manual Selection"
      info.checked = false
      info.func = function()
        UIDropDownMenu_SetSelectedID(pfQuest.mapButton, this:GetID(), 0)
        pfQuest_config["trackingmethod"] = this:GetID()
        pfQuest:ResetAll()
      end
      UIDropDownMenu_AddButton(info)

      local info = {}
      info.text = "Hide Quests"
      info.checked = false
      info.func = function()
        UIDropDownMenu_SetSelectedID(pfQuest.mapButton, this:GetID(), 0)
        pfQuest_config["trackingmethod"] = this:GetID()
        pfQuest:ResetAll()
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

function pfQuest.debug(msg)
  if pfQuest.debugmode  == true then
    UIErrorsFrame:AddMessage("|cff33ffccpf|cffffffffQuest: " .. msg)
  end
end

-- [[ Hook UI Functions ]] --
-- Set certain events on quest watch
local pfHookRemoveQuestWatch = RemoveQuestWatch
RemoveQuestWatch = function(questIndex)
  local ret = pfHookRemoveQuestWatch(questIndex)
  local title, _, _, header, _, complete = GetQuestLogTitle(questIndex)
  pfMap:DeleteNode("PFQUEST", title)
  pfQuest.updateQuestLog = true
  pfQuest.updateQuestGivers = true
  return ret
end

-- Set certain events on quest unwatch
local pfHookAddQuestWatch = AddQuestWatch
AddQuestWatch = function(questIndex)
  local ret = pfHookAddQuestWatch(questIndex)
  pfQuest.updateQuestLog = true
  pfQuest.updateQuestGivers = true
  return ret
end

-- Save the abandoned questname to remove from history
local HookAbandonQuest = AbandonQuest
AbandonQuest = function()
  pfQuest.abandon = GetAbandonQuestName()
  HookAbandonQuest()
end

-- Allow to send questlinks from questlog
local pfHookQuestLogTitleButton_OnClick = QuestLogTitleButton_OnClick
QuestLogTitleButton_OnClick = function(button)
	local questIndex = this:GetID() + FauxScrollFrame_GetOffset(QuestLogListScrollFrame);
  local questName, questLevel = GetQuestLogTitle(questIndex)
	if IsShiftKeyDown() and not this.isHeader then
		if ( ChatFrameEditBox:IsVisible() ) then
      if pfQuest_config["questlinks"] == "1" then
        ChatFrameEditBox:Insert("|cffffff00|Hquest:0:" .. questLevel .. ":0:0|h[" .. questName .. "]|h|r")
      else
        ChatFrameEditBox:Insert("[" .. questName .. "]")
      end
      QuestLog_SetSelection(questIndex)
      QuestLog_Update();
      return
    end
  end

  pfHookQuestLogTitleButton_OnClick(button)
end

-- Patch ItemRef to display Questlinks
local pfQuestHookSetItemRef = SetItemRef
SetItemRef = function(link, text, button)
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

    -- check pfQuest.questlog for active quest
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
