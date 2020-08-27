-- multi api compat
local compat = pfQuestCompat
local _, _, _, client = GetBuildInfo()
client = client or 11200

pfQuest = CreateFrame("Frame")

pfQuest.queue = {}
pfQuest.abandon = ""
pfQuest.questlog = {}
pfQuest.questlog_tmp = {}

local function tsize(tbl)
  if not tbl or not type(tbl) == "table" then return 0 end
  local c = 0
  for _ in pairs(tbl) do c = c + 1 end
  return c
end

pfQuest:RegisterEvent("QUEST_WATCH_UPDATE")
pfQuest:RegisterEvent("QUEST_LOG_UPDATE")
pfQuest:RegisterEvent("QUEST_FINISHED")
pfQuest:RegisterEvent("PLAYER_LEVEL_UP")
pfQuest:RegisterEvent("PLAYER_ENTERING_WORLD")
pfQuest:RegisterEvent("SKILL_LINES_CHANGED")
pfQuest:RegisterEvent("ADDON_LOADED")
pfQuest:SetScript("OnEvent", function()
  if event == "ADDON_LOADED" then
    if arg1 == "pfQuest" or arg1 == "pfQuest-tbc" or arg1 == "pfQuest-wotlk" then
      pfQuest:AddQuestLogIntegration()
      pfQuest:AddWorldMapIntegration()
    else
      return
    end
  elseif event == "PLAYER_LEVEL_UP" or event == "PLAYER_ENTERING_WORLD" or event == "SKILL_LINES_CHANGED" then
    pfQuest.updateQuestGivers = true
  else
    pfQuest.updateQuestLog = true
  end
end)

pfQuest:SetScript("OnUpdate", function()
  if ( this.tick or .2) > GetTime() then return else this.tick = GetTime() + .2 end

  if this.updateQuestLog == true then
    pfQuest:UpdateQuestlog()
    this.updateQuestLog = false
  end

  if this.updateQuestGivers == true then
    if pfQuest_config["trackingmethod"] == 4 then return end
    if pfQuest_config["allquestgivers"] == "1" then
      local meta = { ["addon"] = "PFQUEST" }
      pfDatabase:SearchQuests(meta)
      pfMap:UpdateNodes()
      this.updateQuestGivers = false
    end
  end

  if pfQuest_config["trackingmethod"] == 4 then return end
  if tsize(this.queue) == 0 then return end

  -- process queue
  local match = false
  for id, entry in pairs(this.queue) do
    match = true

    if pfQuest_config["trackingmethod"] ~= 3 and (pfQuest_config["trackingmethod"] ~= 2 or IsQuestWatched(entry[3])) then
      pfMap:DeleteNode("PFQUEST", entry[1])
      local meta = { ["addon"] = "PFQUEST", ["qlogid"] = entry[3] }
      for _, id in pairs(entry[2]) do
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

  local _, numQuests = GetNumQuestLogEntries()
  local found = 0

  -- iterate over all quests
  for qlogid=1,40 do

    local title, _, _, header, _, complete = compat.GetQuestLogTitle(qlogid)
    local objectives = GetNumQuestLeaderBoards(qlogid)
    local watched

    if title and not header then
      watched = IsQuestWatched(qlogid)
      -- add new quest to the questlog
      if not pfQuest.questlog[title] then
        local questID = pfDatabase:GetQuestIDs(qlogid)
        pfQuest.questlog_tmp[title] = { ids = questID, qlogid = qlogid, state = "init" }
      elseif pfQuest.questlog[title].qlogid ~= qlogid then
        pfQuest.questlog_tmp[title] = { ids = pfQuest.questlog[title].ids, qlogid = qlogid, state = pfQuest.questlog[title].state }
      else
        pfQuest.questlog_tmp[title] = { ids = pfQuest.questlog[title].ids, qlogid = pfQuest.questlog[title].qlogid, state = pfQuest.questlog[title].state }
      end

      -- update progress state
      if objectives then
        local state = watched and "trck" or ""
        for i=1, objectives, 1 do
          local text, _, done = GetQuestLogLeaderBoard(i, qlogid)
          local _, _, obj, objNum, objNeeded = strfind(text, "(.*):%s*([%d]+)%s*/%s*([%d]+)")
          if obj then
            state = state .. i .. (((objNum + 0 >= objNeeded + 0) or done ) and "done" or "todo")
          end
        end
        pfQuest.questlog_tmp[title].state = state
      end

      found = found + 1
      if found >= numQuests then
        break
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
          pfQuest_history[qid] = { time(), UnitLevel("player") }
        end
      end

      pfQuest.abandon = ""
      pfQuest.updateQuestGivers = true
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
  pfMap:UpdateNodes()
end

function pfQuest:AddQuestLogIntegration()
  if pfQuest_config["questlogbuttons"] ==  "0" then return end

  local dockFrame = EQL3_QuestLogDetailScrollChildFrame or ShaguQuest_QuestLogDetailScrollChildFrame or QuestLogDetailScrollChildFrame
  local dockTitle = EQL3_QuestLogDescriptionTitle or ShaguQuest_QuestLogDescriptionTitle or QuestLogDescriptionTitle

  dockTitle:SetHeight(dockTitle:GetHeight() + 30)
  dockTitle:SetJustifyV("BOTTOM")

  pfQuest.buttonOnline = pfQuest.buttonOnline or CreateFrame("Button", "pfQuestOnline", dockFrame)
  pfQuest.buttonOnline:SetWidth(18)
  pfQuest.buttonOnline:SetHeight(15)
  pfQuest.buttonOnline:SetPoint("TOPRIGHT", dockFrame, "TOPRIGHT", -12, -10)
  pfQuest.buttonOnline:SetScript("OnClick", function()

    local questurl = "https://vanilla-twinhead.twinstar.cz/?quest="
    if client > 11200 then
      questurl = "https://tbc-twinhead.twinstar.cz/?quest="
    end

    if pfUI and pfUI.chat then
      pfUI.chat.urlcopy.text:SetText(questurl .. (this:GetID() or 0))
      pfUI.chat.urlcopy:Show()
    else
      DEFAULT_CHAT_FRAME:AddMessage("|cff33ffccpf|cffffffff" .. pfQuest_Loc["Online quest search"] .. ":|cffcccccc " .. questurl .. (this:GetID() or 0))
    end
  end)

  pfQuest.buttonOnline.txt = pfQuest.buttonOnline:CreateFontString("pfQuestIDButton", "HIGH", "GameFontWhite")
  pfQuest.buttonOnline.txt:SetAllPoints(pfQuest.buttonOnline)
  pfQuest.buttonOnline.txt:SetJustifyH("RIGHT")
  pfQuest.buttonOnline.txt:SetText("|cff000000[|cffaa2222?|cff000000]")

  pfQuest.buttonLanguage = pfQuest.buttonLanguage or CreateFrame("Button", "pfQuestLanguage", dockFrame)
  pfQuest.buttonLanguage:SetWidth(75)
  pfQuest.buttonLanguage:SetHeight(15)
  pfQuest.buttonLanguage:SetPoint("RIGHT", pfQuest.buttonOnline, "LEFT", 0, 0)

  pfQuest.buttonLanguage.txt = pfQuest.buttonLanguage:CreateFontString("pfQuestIDButton", "HIGH", "GameFontWhite")
  pfQuest.buttonLanguage.txt:SetAllPoints(pfQuest.buttonLanguage)
  pfQuest.buttonLanguage.txt:SetJustifyH("RIGHT")
  pfQuest.buttonLanguage.txt:SetText("|cff000000[|cff333333" .. pfQuest_Loc["Translate"] .. "|cff000000]")

  pfQuest.buttonLanguage:SetScript("OnClick", function()
    UIDropDownMenu_Initialize(self, function()
      local func = function() pfQuest_config.translate = this.value end
      local info = {}
      info.text = "|cffaaaaaa" .. pfQuest_Loc["Reset Language"]
      info.value = nil
      info.func = func
      UIDropDownMenu_AddButton(info);

      for loc, caption in pairs(pfDB.locales) do
        local info = {}
        info.text = caption
        info.value = loc
        info.func = func
        UIDropDownMenu_AddButton(info);
      end
    end)
    ToggleDropDownMenu(1, nil, self, "cursor", 3, -3)
  end)

  pfQuest.buttonLanguage:SetScript("OnUpdate", function()
    local id = pfQuest.buttonOnline:GetID()
    local lang = pfQuest_config.translate

    if this.translate ~= pfQuest_config.translate then
      pfQuest.buttonLanguage.txt:SetText("|cff000000[|cff3333ff" .. (pfDB.locales[pfQuest_config.translate] or "|cff333333" .. pfQuest_Loc["Translate"]) .. "|cff000000]")
      this.translate = pfQuest_config.translate
      QuestLog_UpdateQuestDetails(true)
      return
    end

    if id and pfDB["quests"][lang] and pfDB["quests"][lang][id] then
      local QuestLogQuestTitle = EQL3_QuestLogQuestTitle or QuestLogQuestTitle
      local QuestLogObjectivesText = EQL3_QuestLogObjectivesText or QuestLogObjectivesText
      local QuestLogQuestDescription = EQL3_QuestLogQuestDescription or QuestLogQuestDescription
      QuestLogQuestTitle:SetText(pfDatabase:FormatQuestText(pfDB["quests"][lang][id]["T"]))
      QuestLogObjectivesText:SetText(pfDatabase:FormatQuestText(pfDB["quests"][lang][id]["O"]))
      QuestLogQuestDescription:SetText(pfDatabase:FormatQuestText(pfDB["quests"][lang][id]["D"]))
    end
  end)

  pfQuest.buttonShow = pfQuest.buttonShow or CreateFrame("Button", "pfQuestShow", dockFrame, "UIPanelButtonTemplate")
  pfQuest.buttonShow:SetWidth(70)
  pfQuest.buttonShow:SetHeight(20)
  pfQuest.buttonShow:SetText(pfQuest_Loc["Show"])
  pfQuest.buttonShow:SetPoint("TOP", dockTitle, "TOP", -110, 0)
  pfQuest.buttonShow:SetScript("OnClick", function()
    local questIndex = GetQuestLogSelection()
    local title, _, _, header, _, complete = compat.GetQuestLogTitle(questIndex)
    if header then return end

    local ids = pfQuest.questlog[title].ids
    local maps, meta = {}, { ["addon"] = "PFQUEST", ["qlogid"] = questIndex }
    for _, id in pairs(ids) do
      maps = pfDatabase:SearchQuestID(id, meta, maps)
    end
    pfMap:ShowMapID(pfDatabase:GetBestMap(maps))
  end)

  pfQuest.buttonHide = pfQuest.buttonHide or CreateFrame("Button", "pfQuestHide", dockFrame, "UIPanelButtonTemplate")
  pfQuest.buttonHide:SetWidth(70)
  pfQuest.buttonHide:SetHeight(20)
  pfQuest.buttonHide:SetText(pfQuest_Loc["Hide"])
  pfQuest.buttonHide:SetPoint("TOP", dockTitle, "TOP", -37, 0)
  pfQuest.buttonHide:SetScript("OnClick", function()
    local questIndex = GetQuestLogSelection()
    local title, _, _, header, _, complete = compat.GetQuestLogTitle(questIndex)
    if header then return end

    pfMap:DeleteNode("PFQUEST", title)
    pfMap:UpdateNodes()
  end)

  pfQuest.buttonClean = pfQuest.buttonClean or CreateFrame("Button", "pfQuestClean", dockFrame, "UIPanelButtonTemplate")
  pfQuest.buttonClean:SetWidth(70)
  pfQuest.buttonClean:SetHeight(20)
  pfQuest.buttonClean:SetText(pfQuest_Loc["Clean"])
  pfQuest.buttonClean:SetPoint("TOP", dockTitle, "TOP", 37, 0)
  pfQuest.buttonClean:SetScript("OnClick", function()
    pfMap:DeleteNode("PFQUEST")
    pfMap:UpdateNodes()
  end)

  pfQuest.buttonReset = pfQuest.buttonReset or CreateFrame("Button", "pfQuestReset", dockFrame, "UIPanelButtonTemplate")
  pfQuest.buttonReset:SetWidth(70)
  pfQuest.buttonReset:SetHeight(20)
  pfQuest.buttonReset:SetText(pfQuest_Loc["Reset"])
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
      info.text = pfQuest_Loc["All Quests"]
      info.checked = false
      info.func = function()
        UIDropDownMenu_SetSelectedID(pfQuest.mapButton, this:GetID(), 0)
        pfQuest_config["trackingmethod"] = this:GetID()
        pfQuest:ResetAll()
      end
      UIDropDownMenu_AddButton(info)

      local info = {}
      info.text = pfQuest_Loc["Tracked Quests"]
      info.checked = false
      info.func = function()
        UIDropDownMenu_SetSelectedID(pfQuest.mapButton, this:GetID(), 0)
        pfQuest_config["trackingmethod"] = this:GetID()
        pfQuest:ResetAll()
      end
      UIDropDownMenu_AddButton(info)

      local info = {}
      info.text = pfQuest_Loc["Manual Selection"]
      info.checked = false
      info.func = function()
        UIDropDownMenu_SetSelectedID(pfQuest.mapButton, this:GetID(), 0)
        pfQuest_config["trackingmethod"] = this:GetID()
        pfQuest:ResetAll()
      end
      UIDropDownMenu_AddButton(info)

      local info = {}
      info.text = pfQuest_Loc["Hide Quests"]
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

-- [[ Hook UI Functions ]] --
-- Set certain events on quest watch
local pfHookRemoveQuestWatch = RemoveQuestWatch
RemoveQuestWatch = function(questIndex)
  local ret = pfHookRemoveQuestWatch(questIndex)
  local title, _, _, header, _, complete = compat.GetQuestLogTitle(questIndex)
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

-- Update quest id button
local pfHookQuestLog_Update = QuestLog_Update
QuestLog_Update = function()
  pfHookQuestLog_Update()
  if pfQuest_config["questlogbuttons"] ==  "1" then
    local questName = compat.GetQuestLogTitle(GetQuestLogSelection())
    if pfQuest.questlog[questName] and pfQuest.questlog[questName].ids[1] then
      local id = pfQuest.questlog[questName].ids[1]
      pfQuest.buttonOnline:SetID(id)
      pfQuest.buttonOnline:Show()
      if pfQuest_config.showids == "1" then
        pfQuest.buttonOnline.txt:SetText("|cff000000[|cffaa2222id: " .. id .. "|cff000000]")
        pfQuest.buttonOnline:SetWidth(pfQuest.buttonOnline.txt:GetStringWidth())
      end
    else
      pfQuest.buttonOnline:Hide()
    end
  end
end

if not GetQuestLink then -- Allow to send questlinks from questlog
  local pfHookQuestLogTitleButton_OnClick = QuestLogTitleButton_OnClick
  QuestLogTitleButton_OnClick = function(button)
    local scrollFrame = EQL3_QuestLogListScrollFrame or ShaguQuest_QuestLogListScrollFrame or QuestLogListScrollFrame
    local questIndex = this:GetID() + FauxScrollFrame_GetOffset(scrollFrame)
    local questName, questLevel = compat.GetQuestLogTitle(questIndex)
    if IsShiftKeyDown() and not this.isHeader and ChatFrameEditBox:IsVisible() then
      local id = pfQuest.questlog[questName] and pfQuest.questlog[questName].ids[1] or nil
      pfQuestCompat.InsertQuestLink(id, questName)
      QuestLog_SetSelection(questIndex)
      QuestLog_Update()
      return
    end

    pfHookQuestLogTitleButton_OnClick(button)
  end

  -- Patch ItemRef to display Questlinks
  local pfQuestHookSetItemRef = SetItemRef
  SetItemRef = function(link, text, button)
    local isQuest, _, id    = string.find(link, "quest:(%d+):.*")
    local isQuest2, _, _   = string.find(link, "quest2:.*")

    if isQuest or isQuest2 then
      ShowUIPanel(ItemRefTooltip)
      ItemRefTooltip:SetOwner(UIParent, "ANCHOR_PRESERVE")

      local hasTitle, _, questTitle = string.find(text, ".*|h%[(.*)%]|h.*")

      id = tonumber(id)

      if not id or id == 0 then
        for scanID, data in pairs(pfDB["quests"]["loc"]) do
          if data.T == questTitle then
            id = scanID
            break
          end
        end
      end

      -- read and set title
      if id and id > 0 and pfDB["quests"]["loc"][id] then
        ItemRefTooltip:AddLine(pfDB["quests"]["loc"][id].T, 1,1,0)
      elseif hasTitle then
        ItemRefTooltip:AddLine(questTitle, 1,1,0)
      end

      -- scan for active quests
      local queststate = pfQuest_history[id] and 2 or 0
      for title, data in pairs(pfQuest.questlog) do
        for _, qid in pairs(pfQuest.questlog[title].ids) do
          if qid == id then
            queststate = 1
          end
        end
      end

      if queststate == 0 then
        ItemRefTooltip:AddLine(pfQuest_Loc["You don't have this quest."] .. "\n\n", 1, .5, .5)
      elseif queststate == 1 then
        ItemRefTooltip:AddLine(pfQuest_Loc["You are on this quest."] .. "\n\n", 1, 1, .5)
      elseif queststate == 2 then
        ItemRefTooltip:AddLine(pfQuest_Loc["You already did this quest."] .. "\n\n", .5, 1, .5)
      end

      -- add database entries if existing
      if pfDB["quests"]["loc"][id] then
        if pfDB["quests"]["loc"][id]["O"] then
          ItemRefTooltip:AddLine(pfDatabase:FormatQuestText(pfDB["quests"]["loc"][id]["O"]), 1,1,1,true)
        end

        if pfDB["quests"]["loc"][id]["O"] and pfDB["quests"]["loc"][id]["D"] then
          ItemRefTooltip:AddLine(" ", 0,0,0)
        end

        if pfDB["quests"]["loc"][id]["D"] then
          ItemRefTooltip:AddLine(pfDatabase:FormatQuestText(pfDB["quests"]["loc"][id]["D"]), .8,.8,.8,true)
        end

        if pfDB["quests"]["data"][id]["lvl"] or pfDB["quests"]["data"][id]["min"] then
          ItemRefTooltip:AddLine(" ", 0,0,0)
        end

        if pfDB["quests"]["data"][id]["min"] then
          local questlevel = tonumber(pfDB["quests"]["data"][id]["min"])
          local color = GetDifficultyColor(questlevel)
          ItemRefTooltip:AddLine("|cffffffff" .. pfQuest_Loc["Required Level"] .. ": |r" .. questlevel, color.r, color.g, color.b)
        end

        if pfDB["quests"]["data"][id]["lvl"] then
          local questlevel = tonumber(pfDB["quests"]["data"][id]["lvl"])
          local color = GetDifficultyColor(questlevel)
          ItemRefTooltip:AddLine("|cffffffff" .. pfQuest_Loc["Quest Level"] .. ": |r" .. questlevel, color.r, color.g, color.b)
        end
      end

      ItemRefTooltip:Show()
    else
      pfQuestHookSetItemRef(link, text, button)
    end
  end
end
