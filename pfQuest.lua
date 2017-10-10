-- default config
pfQuest_defconfig = {
  ["trackingmethod"] = 3,
  ["allquestgivers"] = "0",
  ["currentquestgivers"] = "1", -- show quest givers for active quests
  ["minimapnodes"] = "1", -- hide all minimap entries
  ["questlogbuttons"] = "1", -- shows buttons inside the questlog
  ["worldmapmenu"] = "1", -- shows the dropdown selection in worldmap
  ["worldmaptransp"] = "1.0",
  ["minimaptransp"] = "1.0",
}

pfQuest_config = {}

local function LoadConfig()
  if not pfQuest_config then pfQuest_config = {} end

  for key, val in pairs(pfQuest_defconfig) do
    if not pfQuest_config[key] then
      pfQuest_config[key] = val
    end
  end
end

LoadConfig()

local questParse = {
  ["deDE"] = {
    [1] = "(.*) getötet",
  },
  ["esES"] = {
    [1] = "Muertes de (.*)",
  },
  ["enUS"] = {
    [1] = "(.*) killed",
    [2] = "(.*) slain",
  },
}

local questCache = {}

local locale = GetLocale()
if not questParse[locale] then
  locale = "enUS"
end

local function NeedQuestUpdate(questIndex)
  local title, level = GetQuestLogTitle(questIndex)

  if not title then return nil end

  local watched = IsQuestWatched(questIndex)
  local objectives = GetNumQuestLeaderBoards(questIndex)
  local hash = title

  questCache[title] = questCache[title] or "init"

  if objectives then
    for i=1, objectives, 1 do
      local text, _, finished = GetQuestLogLeaderBoard(i, questIndex)
      local i, j, itemName, numItems, numNeeded = strfind(text, "(.*):%s*([%d]+)%s*/%s*([%d]+)")
      if itemName then
        hash = hash .. itemName .. ( finished and "DONE" or "TODO" )
      end
    end
  end

  if questCache[title] ~= hash then
    questCache[title] = hash
    return true
  else
    return nil
  end
end

local function UpdateQuestLogID(questIndex, action)
  if pfQuest_config["trackingmethod"] == 4 then return end

  local title, level = GetQuestLogTitle(questIndex)
  local watched = IsQuestWatched(questIndex)

  if action == "REMOVE" or
  ( not action and not watched and pfQuest_config["trackingmethod"] == 2 ) or
  ( not action and pfQuest_config["trackingmethod"] == 3 ) then
    pfMap:DeleteNode("PFQUEST", title)
    return nil
  end

  -- abort with available cache when no action was given
  if not action and not NeedQuestUpdate(questIndex) then return nil end

  -- clean map and apply changes
  pfMap:DeleteNode("PFQUEST", title)

  local objectives = GetNumQuestLeaderBoards(questIndex)
  local meta = { ["quest"] = title, ["addon"] = "PFQUEST" }
  local zone, score, maps = nil, 0, {}

  if objectives then
    for i=1, objectives, 1 do
      local text, type, finished = GetQuestLogLeaderBoard(i, questIndex)
      local i, j, itemName, numItems, numNeeded = strfind(text, "(.*):%s*([%d]+)%s*/%s*([%d]+)")

      if not finished then
        -- spawn data
        if type == "monster" then
          local i, j, monsterName = strfind(itemName, "(.*)")
          zone, score = pfDatabase:SearchMob(monsterName, meta)
          if zone then maps[zone] = maps[zone] and maps[zone] + score or 1 end

          for id, query in pairs(questParse[locale]) do
            local i, j, monsterName = strfind(itemName, query)
            zone, score = pfDatabase:SearchMob(monsterName, meta)
            if zone then maps[zone] = maps[zone] and maps[zone] + score or 1 end
          end
        end

        -- item data
        if type == "item" then
          zone, score = pfDatabase:SearchItem(itemName, meta)
          if zone then maps[zone] = maps[zone] and maps[zone] + score or 1 end

          zone, score = pfDatabase:SearchVendor(itemName, meta)
          if zone then maps[zone] = maps[zone] and maps[zone] + score or 1 end
        end
      end
    end
  end

  -- show quest givers
  if pfQuest_config["currentquestgivers"] ==  "1" then
    zone, score = pfDatabase:SearchQuest(title, meta)
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

  return bestmap, bestscore
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

    questCache = {}
    pfQuest:Show()
  end)
end

local function AddWorldMapIntegration()
  if pfQuest_config["worldmapmenu"] ==  "0" then return end

  -- Quest Update Indicator
  pfQuest.mapUpdate = WorldMapButton:CreateFontString("Status", "OVERLAY", "GameFontNormalSmall")
  pfQuest.mapUpdate:SetPoint("BOTTOMLEFT", 10, 10)
  pfQuest.mapUpdate:SetJustifyH("LEFT")
  pfQuest.mapUpdate:SetJustifyV("BOTTOM")

  pfQuest.mapUpdate:SetWidth(150)
  pfQuest.mapUpdate:SetHeight(15)
  pfQuest.mapUpdate:SetFontObject(GameFontWhite)
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
        questCache = {}
        pfQuest:Show()
      end
      UIDropDownMenu_AddButton(info)

      local info = {}
      info.text = "Tracked Quests"
      info.checked = false
      info.func = function()
        UIDropDownMenu_SetSelectedID(pfQuest.mapButton, this:GetID(), 0)
        pfQuest_config["trackingmethod"] = this:GetID()
        questCache = {}
        pfQuest:Show()
      end
      UIDropDownMenu_AddButton(info)

      local info = {}
      info.text = "Manual Selection"
      info.checked = false
      info.func = function()
        UIDropDownMenu_SetSelectedID(pfQuest.mapButton, this:GetID(), 0)
        pfQuest_config["trackingmethod"] = this:GetID()
        questCache = {}
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
    pfMap:UpdateNodes()
  end
  return pfHookRemoveQuestWatch(questIndex)
end

local pfHookAddQuestWatch = AddQuestWatch
AddQuestWatch = function(questIndex)
  if pfQuest_config["trackingmethod"] ~= 3 then
    local map = UpdateQuestLogID(questIndex, "ADD")
    pfMap:UpdateNodes()
    pfMap:SetMapByID(map)
  end
  return pfHookAddQuestWatch(questIndex)
end

pfQuest = CreateFrame("Frame")
pfQuest:RegisterEvent("QUEST_LOG_UPDATE")
pfQuest:RegisterEvent("QUEST_WATCH_UPDATE")
pfQuest:RegisterEvent("ADDON_LOADED")

pfQuest:SetScript("OnEvent", function()
  if event == "ADDON_LOADED" then
    if arg1 == "pfQuest" then
      LoadConfig()
      AddQuestLogIntegration()
      AddWorldMapIntegration()
    else
      return
    end
  end

  if event == "QUEST_LOG_UPDATE" or "QUEST_FINISHED" then
    this:Show()
  elseif event == "QUEST_WATCH_UPDATE" then
    UpdateQuestLogID(arg1)
    pfMap:UpdateNodes()
  end
end)

pfQuest:SetScript("OnUpdate", function()
  if pfQuest_config["trackingmethod"] == 4 then this:Hide() return end

  this.scan = this.scan and this.scan + 1 or 1
  this.smax = GetNumQuestLogEntries()

  if pfQuest.mapUpdate then
    pfQuest.mapUpdate:Show()
    pfQuest.mapUpdate:SetText("Quest Update [ " .. this.scan .. " / " .. this.smax .. " ]")
  end

  UpdateQuestLogID(this.scan)

  if this.scan >= this.smax then

    if pfQuest_config["allquestgivers"] == "1" then
      local meta = { ["allquests"] = true }
      pfDatabase:SearchQuests(nil, meta)
    end

    pfMap:UpdateNodes()
    this:Hide()
    this.scan = nil

    if pfQuest.mapUpdate then
      pfQuest.mapUpdate:Hide()
    end
  end
end)

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
  local isQuest, _, _    = string.find(link, "quest:(%d+):.*")
  local isQuest2, _, _   = string.find(link, "quest2:.*")
  local _, _, questLevel = string.find(link, "quest:%d+:(%d+)")

  local playerHasQuest = false

  if isQuest or isQuest2 then
    ShowUIPanel(ItemRefTooltip)
    ItemRefTooltip:SetOwner(UIParent, "ANCHOR_PRESERVE")

    local hasTitle, _, questTitle = string.find(text, ".*|h%[(.*)%]|h.*")
    if hasTitle then ItemRefTooltip:AddLine(questTitle, 1,1,0) end

    for i=1, GetNumQuestLogEntries() do
      if GetQuestLogTitle(i) == questTitle then
        playerHasQuest = true
        SelectQuestLogEntry(i)
        local _, text = GetQuestLogQuestText()
        ItemRefTooltip:AddLine(text,1,1,1,true)

        for j=1, GetNumQuestLeaderBoards() do
          if j == 1 and GetNumQuestLeaderBoards() > 0 then ItemRefTooltip:AddLine("|cffffffff ") end
          local desc, type, done = GetQuestLogLeaderBoard(j)
          if done then ItemRefTooltip:AddLine("|cffaaffaa"..desc.."|r")
          else ItemRefTooltip:AddLine("|cffffffff"..desc.."|r") end
        end
      end
    end

    if playerHasQuest == false then
      ItemRefTooltip:AddLine("You don't have this quest.", 1, .8, .8)
    end

    if questLevel and questLevel ~= 0 and questLevel ~= "0" then
      local color = GetDifficultyColor(questLevel)
      ItemRefTooltip:AddLine("Quest Level " .. questLevel, color.r, color.g, color.b)
    end

    ItemRefTooltip:Show()
  else
    pfQuestHookSetItemRef(link, text, button)
  end
end
