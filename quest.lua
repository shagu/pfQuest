-- multi api compat
local compat = pfQuestCompat
local _, _, _, client = GetBuildInfo()
client = client or 11200
local _G = client == 11200 and getfenv(0) or _G

pfQuest = CreateFrame("Frame")
pfQuest.icons = {}

if client >= 30300 then
  pfQuest.dburl = "https://www.wowhead.com/wotlk/quest="
elseif client >= 20400 then
  pfQuest.dburl = "https://www.wowhead.com/tbc/quest="
else
  pfQuest.dburl = "https://www.wowhead.com/classic/quest="
end

function pfQuest:Debug(msg)
  -- only show debug output if enabled
  if not pfQuest_config.debug and pfQuest.debugwin then
    pfQuest.debugwin:Hide()
    return
  elseif not pfQuest_config.debug then
    return
  end

  if not pfQuest.debugwin then
    pfQuest.debugwin = CreateFrame("ScrollingMessageFrame", nil, UIParent)
    pfQuest.debugwin:SetWidth(320)
    pfQuest.debugwin:SetHeight(320)
    pfQuest.debugwin:SetPoint("RIGHT", -42, 0)
    pfQuest.debugwin:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
    pfQuest.debugwin:SetFading(false)
    pfQuest.debugwin:SetMaxLines(150)
    pfQuest.debugwin:SetJustifyH("RIGHT")
    pfQuest.debugwin:SetJustifyV("CENTER")
  end

  pfQuest.debugwin:AddMessage(msg)
  pfQuest.debugwin:Show()
end

function pfQuest:SortedPairs(t, index, reverse)
  -- collect the keys
  local keys = {}
  for k, v in pairs(t) do
    if v then keys[table.getn(keys)+1] = k end
  end

  local order
  if reverse then
    order = function(t,a,b) return t[a][index] < t[b][index] end
  else
    order = function(t,a,b) return t[a][index] > t[b][index] end
  end
  table.sort(keys, function(a,b) return order(t, a, b) end)

  -- return the iterator function
  local i = 0
  return function()
    i = i + 1
    if keys[i] then
      return keys[i], t[keys[i]]
    end
  end
end

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

local skillstate = ""
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
      this.lock = GetTime() + 10
    else
      return
    end
  elseif event == "SKILL_LINES_CHANGED" then
    local skills = ""
    for i=0, GetNumSkillLines() do
      skills = skills .. (GetSkillLineInfo(i) or "")
    end

    -- update quest givers when new skills or
    -- professions became available
    if skills ~= skillstate then
      pfQuest.updateQuestGivers = true
      skillstate = skills
    end
  elseif event == "PLAYER_LEVEL_UP" or event == "PLAYER_ENTERING_WORLD" then
    pfQuest.updateQuestGivers = true
  else
    pfQuest.updateQuestLog = true
  end

  if event == "QUEST_LOG_UPDATE" then
    -- lock initial scan during incoming events
    if this.lock and this.lock > GetTime() then
      this.lock = GetTime() + 1.5
    end
  end
end)

pfQuest:SetScript("OnUpdate", function()
  if this.lock and this.lock > GetTime() then return end
  if not pfDatabase.localized then return end

  if ( this.tick or .05) > GetTime() then return else this.tick = GetTime() + .05 end

  -- check questlog each second
  if ( this.qlogtick or 1) < GetTime() then
    if pfQuest:UpdateQuestlog() then
      pfQuest:Debug("Update Quest|cff33ffcc Log|r [|cffff3333Tick|r]")
    end
    this.qlogtick = GetTime() + 1
  end

  if this.updateQuestLog == true and tsize(this.queue) == 0 then
    pfQuest:Debug("Update Quest|cff33ffcc Log")
    pfQuest:UpdateQuestlog()
    this.updateQuestLog = false
  end

  if this.updateQuestGivers == true then
    pfQuest:Debug("Update Quest|cff33ffcc Givers")
    if pfQuest_config["trackingmethod"] ~= 4 and
      pfQuest_config["allquestgivers"] == "1"
    then
      local meta = { ["addon"] = "PFQUEST" }
      pfDatabase:SearchQuests(meta)
    end
    this.updateQuestGivers = false
  end

  if tsize(this.queue) == 0 then return end

  -- process queue
  for id, entry in pairs(this.queue) do

    -- remove quest
    if entry[4] == "REMOVE" then
      pfQuest:Debug("|cffff5555Remove Quest: " .. entry[1] .. " (" .. entry[2] .. ")")

      -- write pfQuest.questlog history
      if entry[1] == pfQuest.abandon then
        pfQuest_history[entry[2]] = nil
      else
        pfQuest_history[entry[2]] = { time(), UnitLevel("player") }
      end

      if pfQuest_config["trackingmethod"] ~= 4 then
        -- delete nodes by title
        pfMap:DeleteNode("PFQUEST", entry[1])

        -- also delete nodes by quest ids for servers with different names
        if entry[2] and pfDB["quests"]["loc"][entry[2]] and pfDB["quests"]["loc"][entry[2]].T then
          pfMap:DeleteNode("PFQUEST", pfDB["quests"]["loc"][entry[2]].T)
        end
      end

      pfQuest.abandon = ""
    else
      if entry[4] == "NEW" then
        pfQuest:Debug("|cff55ff55New Quest: " .. entry[1] .. " (" .. entry[2] .. ")")
      else
        pfQuest:Debug("|cffffff55Update Quest: " .. entry[1] .. " (" .. entry[2] .. ")")
      end

      -- update quest nodes
      if pfQuest_config["trackingmethod"] ~= 4 then
        -- delete node by title
        pfMap:DeleteNode("PFQUEST", entry[1])

        -- delete nodes by quest ids for servers with different names
        if entry[2] and pfDB["quests"]["loc"][entry[2]] and pfDB["quests"]["loc"][entry[2]].T then
          pfMap:DeleteNode("PFQUEST", pfDB["quests"]["loc"][entry[2]].T)
        end

        -- skip quest objective detection on manual and tacked mode
        if pfQuest_config["trackingmethod"] ~= 3 and
          (pfQuest_config["trackingmethod"] ~= 2 or IsQuestWatched(entry[3]))
        then
          local meta = { ["addon"] = "PFQUEST", ["qlogid"] = entry[3] }
          pfDatabase:SearchQuestID(entry[2], meta)
        end
      end
    end

    -- remove entry from queue
    pfQuest.queue[id] = nil

    -- only return when other entries exist
    -- otherwise, continue and update questgivers
    for id, entry in pairs(this.queue) do
      return
    end
  end

  -- trigger questgiver update
  if tsize(this.queue) == 0 then
    this.updateQuestLog = true
    this.updateQuestGivers = true
  end
end)

local questlog_flip, questlog_flop = {}, {}
function pfQuest:UpdateQuestlog()
  -- initialize flip flop if not yet defined
  pfQuest.questlog_tmp = pfQuest.questlog_tmp or questlog_flip

  local _, numQuests = GetNumQuestLogEntries()
  local found = 0
  local change = nil

  -- iterate over all quests
  for qlogid=1,40 do
    local title, _, _, header, _, complete = compat.GetQuestLogTitle(qlogid)
    local objectives = GetNumQuestLeaderBoards(qlogid)
    local watched, questid, state

    if title and not header then
      questid = pfDatabase:GetQuestIDs(qlogid)
      questid = questid and tonumber(questid[1]) or title
      watched = IsQuestWatched(qlogid)
      state = watched and "track" or ""

      -- build state string
      if objectives then
        for i=1, objectives, 1 do
          local text, _, done = GetQuestLogLeaderBoard(i, qlogid)
          state = state .. i .. (done and "done" or "todo")
        end
      end

      -- add new quest to the questlog
      if not pfQuest.questlog[questid] then
        table.insert(pfQuest.queue, { title, questid, qlogid, "NEW" })
        pfQuest.questlog_tmp[questid] = {
          title = title,
          qlogid = qlogid,
          state = state,
        }
        change = true
      elseif pfQuest.questlog[questid].qlogid ~= qlogid then
        table.insert(pfQuest.queue, { title, questid, qlogid, "RELOAD" })
        pfQuest.questlog_tmp[questid] = pfQuest.questlog[questid]
        pfQuest.questlog_tmp[questid].qlogid = qlogid
        pfQuest.questlog_tmp[questid].state = state
        change = true
      elseif pfQuest.questlog[questid].state ~= state then
        table.insert(pfQuest.queue, { title, questid, qlogid, "RELOAD" })
        pfQuest.questlog_tmp[questid] = pfQuest.questlog[questid]
        pfQuest.questlog_tmp[questid].qlogid = qlogid
        pfQuest.questlog_tmp[questid].state = state
        change = true
      else
        pfQuest.questlog_tmp[questid] = pfQuest.questlog[questid]
      end

      found = found + 1
      if found >= numQuests then
        break
      end
    end
  end

  -- quest removal events
  for questid, data in pairs(pfQuest.questlog) do
    if not pfQuest.questlog_tmp[questid] then
      table.insert(pfQuest.queue, { data.title, questid, nil, "REMOVE" })
      change = true
    end
  end

  -- set questlog to current flip flop
  pfQuest.questlog = pfQuest.questlog_tmp

  -- switch tmp to the other flip flop
  if pfQuest.questlog_tmp == questlog_flip then
    pfQuest.questlog_tmp = questlog_flop
  else
    pfQuest.questlog_tmp = questlog_flip
  end

  -- clear next temporary questlog entries
  for k, v in pairs(pfQuest.questlog_tmp) do
    pfQuest.questlog_tmp[k] = nil
  end

  return change
end

function pfQuest:ResetAll()
  -- force reload all quests
  pfMap:DeleteNode("PFQUEST")
  pfQuest.questlog = {}
  pfQuest.updateQuestLog = true
  pfQuest.updateQuestGivers = true
end

-- register popup dialog to copy urls
StaticPopupDialogs["PFQUEST_URLCOPY"] = {
  text = "|cff33ffccpf|cffffffffQuest " .. pfQuest_Loc["Online Search"],
  button1 = "Close",
  hasEditBox = 1,
  hasWideEditBox = 1,
  timeout = 0,
  exclusive = 1,
  whileDead = 1,
  hideOnEscape = 1,
  OnShow = function()
    local editBox = _G[this:GetName().."WideEditBox"]
    editBox:SetText(StaticPopupDialogs["PFQUEST_URLCOPY"].data)
    editBox:HighlightText()
  end,
  OnHide = function()
    _G[this:GetName().."WideEditBox"]:SetText("")
  end,
  EditBoxOnEnterPressed = function()
    this:GetParent():Hide()
  end,
  EditBoxOnEscapePressed = function()
    this:GetParent():Hide()
  end,
  EditBoxOnTextChanged = function()
    this:SetText(StaticPopupDialogs["PFQUEST_URLCOPY"].data)
    this:HighlightText()
  end,
}

function pfQuest:AddQuestLogIntegration()
  if pfQuest_config["questlogbuttons"] ==  "0" then return end

  local dockFrame = EQL3_QuestLogDetailScrollChildFrame or ShaguQuest_QuestLogDetailScrollChildFrame or QuestLogDetailScrollChildFrame
  local dockTitle = EQL3_QuestLogDescriptionTitle or ShaguQuest_QuestLogDescriptionTitle or pfQuestCompat.QuestLogDescriptionTitle

  dockTitle:SetHeight(dockTitle:GetHeight() + 30)
  dockTitle:SetJustifyV("BOTTOM")

  pfQuest.buttonOnline = pfQuest.buttonOnline or CreateFrame("Button", "pfQuestOnline", dockFrame)
  pfQuest.buttonOnline:SetWidth(18)
  pfQuest.buttonOnline:SetHeight(15)
  pfQuest.buttonOnline:SetPoint("TOPRIGHT", dockFrame, "TOPRIGHT", -12, -10)
  pfQuest.buttonOnline:SetScript("OnClick", function()
    if pfUI and pfUI.chat then
      pfUI.chat.urlcopy.text:SetText(pfQuest.dburl .. (this:GetID() or 0))
      pfUI.chat.urlcopy:Show()
    else
      StaticPopupDialogs["PFQUEST_URLCOPY"].data = pfQuest.dburl .. (this:GetID() or 0)
      local dialog = StaticPopup_Show("PFQUEST_URLCOPY")
      _G[dialog:GetName().."Button1"]:ClearAllPoints()
      _G[dialog:GetName().."Button1"]:SetPoint("BOTTOM", dialog, "BOTTOM", 0, 16)
      _G[dialog:GetName().."WideEditBox"]:SetScript('OnTextChanged', StaticPopup_EditBoxOnTextChanged)
      dialog:SetWidth(420)
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
      local QuestLogQuestTitle = EQL3_QuestLogQuestTitle or pfQuestCompat.QuestLogQuestTitle
      local QuestLogObjectivesText = EQL3_QuestLogObjectivesText or pfQuestCompat.QuestLogObjectivesText
      local QuestLogQuestDescription = EQL3_QuestLogQuestDescription or pfQuestCompat.QuestLogQuestDescription
      local QuestLogDetailScrollFrame = EQL3_QuestLogDetailScrollFrame or QuestLogDetailScrollFrame

      QuestLogQuestTitle:SetText(pfDatabase:FormatQuestText(pfDB["quests"][lang][id]["T"]))
      QuestLogObjectivesText:SetText(pfDatabase:FormatQuestText(pfDB["quests"][lang][id]["O"]))
      QuestLogQuestDescription:SetText(pfDatabase:FormatQuestText(pfDB["quests"][lang][id]["D"]))
      QuestLogDetailScrollFrame:UpdateScrollChildRect()
    end
  end)

  pfQuest.buttonShow = pfQuest.buttonShow or CreateFrame("Button", "pfQuestShow", dockFrame, "UIPanelButtonTemplate")
  pfQuest.buttonShow:SetWidth(70)
  pfQuest.buttonShow:SetHeight(20)
  pfQuest.buttonShow:SetText(pfQuest_Loc["Show"])
  pfQuest.buttonShow:SetPoint("TOP", dockTitle, "TOP", -110, 0)
  pfQuest.buttonShow:SetScript("OnClick", function()
    local questIndex = GetQuestLogSelection()
    local questids = pfDatabase:GetQuestIDs(questIndex)
    local title, _, _, header, _, complete = compat.GetQuestLogTitle(questIndex)
    local id = questids and tonumber(questids[1])
    if header or not id then return end

    local maps, meta = {}, { ["addon"] = "PFQUEST", ["qlogid"] = questIndex }
    maps = pfDatabase:SearchQuestID(id, meta, maps)
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
  end)

  pfQuest.buttonClean = pfQuest.buttonClean or CreateFrame("Button", "pfQuestClean", dockFrame, "UIPanelButtonTemplate")
  pfQuest.buttonClean:SetWidth(70)
  pfQuest.buttonClean:SetHeight(20)
  pfQuest.buttonClean:SetText(pfQuest_Loc["Clean"])
  pfQuest.buttonClean:SetPoint("TOP", dockTitle, "TOP", 37, 0)
  pfQuest.buttonClean:SetScript("OnClick", function()
    pfMap:DeleteNode("PFQUEST")
  end)

  pfQuest.buttonReset = pfQuest.buttonReset or CreateFrame("Button", "pfQuestReset", dockFrame, "UIPanelButtonTemplate")
  pfQuest.buttonReset:SetWidth(70)
  pfQuest.buttonReset:SetHeight(20)
  pfQuest.buttonReset:SetText(pfQuest_Loc["Reset"])
  pfQuest.buttonReset:SetPoint("TOP", dockTitle, "TOP", 110, 0)
  pfQuest.buttonReset:SetScript("OnClick", function()
    pfQuest:ResetAll()
  end)

  -- use pfUI buttons in native mode
  if not pfUI.api.emulated then
    pfUI.api.SkinButton(pfQuest.buttonShow)
    pfUI.api.SkinButton(pfQuest.buttonHide)
    pfUI.api.SkinButton(pfQuest.buttonClean)
    pfUI.api.SkinButton(pfQuest.buttonReset)
  end
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
    if client >= 30300 then
      UIDropDownMenu_SetWidth(pfQuest.mapButton, 120)
      UIDropDownMenu_SetButtonWidth(pfQuest.mapButton, 125)
      UIDropDownMenu_JustifyText(pfQuest.mapButton, "RIGHT")
    else
      UIDropDownMenu_SetWidth(120, pfQuest.mapButton)
      UIDropDownMenu_SetButtonWidth(125, pfQuest.mapButton)
      UIDropDownMenu_JustifyText("RIGHT", pfQuest.mapButton)
    end
    UIDropDownMenu_SetSelectedID(pfQuest.mapButton, pfQuest.mapButton.current)
  end
end

-- [[ Hook UI Functions ]] --
-- Set certain events on quest watch
local pfHookRemoveQuestWatch = RemoveQuestWatch
RemoveQuestWatch = function(questIndex)
  local ret = pfHookRemoveQuestWatch(questIndex)

  if questIndex then
    local title, _, _, header, _, complete = compat.GetQuestLogTitle(questIndex)
    pfMap:DeleteNode("PFQUEST", title)
  end

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

local function UpdateQuestLevel(button, id)
  local title, level, tag, header = compat.GetQuestLogTitle(id)
  if header or not title then return end
  button:SetText(" [" .. ( level or "??" ) .. ( tag and "+" or "") .. "] " .. title)
  if not QuestLogTitleButton_Resize then return end
  QuestLogTitleButton_Resize(button)
end

-- Update quest id button
local pfHookQuestLog_Update = QuestLog_Update
QuestLog_Update = function()
  pfHookQuestLog_Update()

  if pfQuest_config["questloglevel"] == "1" then
    if client >= 30300 then
      for i, button in pairs(QuestLogScrollFrame.buttons) do
        UpdateQuestLevel(button, button:GetID())
      end
    else
      for i=1, QUESTS_DISPLAYED, 1 do
        UpdateQuestLevel(_G["QuestLogTitle"..i], i + FauxScrollFrame_GetOffset(QuestLogListScrollFrame))
      end
    end
  end

  if pfQuest_config["questlogbuttons"] ==  "1" then
    local questids = pfDatabase:GetQuestIDs(GetQuestLogSelection())
    if questids and questids[1] and tonumber(questids[1]) and pfQuest.questlog[questids[1]] then
      pfQuest.buttonOnline:SetID(questids[1])
      pfQuest.buttonOnline:Show()
      pfQuest.buttonLanguage:Show()
      -- enable buttons
      pfQuest.buttonShow:Enable()
      pfQuest.buttonHide:Enable()

      if pfQuest_config.showids == "1" then
        pfQuest.buttonOnline.txt:SetText("|cff000000[|cffaa2222id: " .. questids[1] .. "|cff000000]")
        pfQuest.buttonOnline:SetWidth(pfQuest.buttonOnline.txt:GetStringWidth())
      end
    else
      pfQuest.buttonOnline:Hide()
      pfQuest.buttonLanguage:Hide()
      -- disable buttons
      pfQuest.buttonShow:Disable()
      pfQuest.buttonHide:Disable()
    end
  end
end

-- attach the new function to the scroll frame
if QuestLogScrollFrame then
  QuestLogScrollFrame.update = QuestLog_Update
end

-- refresh language and url on quest selection
local pfHookQuestLogTitleButton_OnClick = QuestLogTitleButton_OnClick
QuestLogTitleButton_OnClick = function(self, button)
  pfHookQuestLogTitleButton_OnClick(self, button)
  QuestLog_Update()
end

if not GetQuestLink then -- Allow to send questlinks from questlog
  local pfHookQuestLogTitleButton_OnClick = QuestLogTitleButton_OnClick
  QuestLogTitleButton_OnClick = function(button)
    local scrollFrame = EQL3_QuestLogListScrollFrame or ShaguQuest_QuestLogListScrollFrame or QuestLogListScrollFrame
    local questIndex = this:GetID() + FauxScrollFrame_GetOffset(scrollFrame)
    local questName, questLevel = compat.GetQuestLogTitle(questIndex)
    local questids = pfDatabase:GetQuestIDs(questIndex)
    local questid = questids and tonumber(questids[1]) or 0

    if IsShiftKeyDown() and not this.isHeader and ChatFrameEditBox:IsVisible() then
      pfQuestCompat.InsertQuestLink(questid, questName)
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
      if IsShiftKeyDown() and ChatFrameEditBox:IsVisible() then
        ChatFrameEditBox:Insert(text)
        return
      end

      if ItemRefTooltip:IsShown() and ItemRefTooltip.pfQtext == text then
        HideUIPanel(ItemRefTooltip)
        return
      end

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
        local questlevel = tonumber(pfDB["quests"]["data"][id]["lvl"])
        local color = pfQuestCompat.GetDifficultyColor(questlevel)
        ItemRefTooltip:AddLine(pfDB["quests"]["loc"][id].T, color.r, color.g, color.b)
      elseif hasTitle then
        ItemRefTooltip:AddLine(questTitle, 1,1,0)
      end

      -- scan for active quests
      local queststate = pfQuest_history[id] and 2 or 0
      queststate = pfQuest.questlog[id] and 1 or queststate

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
          local color = pfQuestCompat.GetDifficultyColor(questlevel)
          ItemRefTooltip:AddLine("|cffffffff" .. pfQuest_Loc["Required Level"] .. ": |r" .. questlevel, color.r, color.g, color.b)
        end

        if pfDB["quests"]["data"][id]["lvl"] then
          local questlevel = tonumber(pfDB["quests"]["data"][id]["lvl"])
          local color = pfQuestCompat.GetDifficultyColor(questlevel)
          ItemRefTooltip:AddLine("|cffffffff" .. pfQuest_Loc["Quest Level"] .. ": |r" .. questlevel, color.r, color.g, color.b)
        end
      end

      ItemRefTooltip:Show()
    else
      pfQuestHookSetItemRef(link, text, button)
    end
    ItemRefTooltip.pfQtext = text
  end
else
  -- patch itemref to show known quest levels on tbc
  local pfQuestHookSetItemRef = SetItemRef
  SetItemRef = function(link, text, button)
    pfQuestHookSetItemRef(link, text, button)

    -- skip modifier clicks
    if IsAltKeyDown() or IsControlKeyDown() or IsShiftKeyDown() then return end

    local quest, _, id = string.find(link, "quest:(%d+):.*")
    if not quest then return end
    id = tonumber(id)

    -- adjust text color to level color
    if id and id > 0 and pfDB["quests"]["loc"][id] then
      local questlevel = tonumber(pfDB["quests"]["data"][id]["lvl"])
      local color = pfQuestCompat.GetDifficultyColor(questlevel)
      ItemRefTooltipTextLeft1:SetTextColor(color.r, color.g, color.b)
    end

    -- add quest levels to tooltip
    if pfDB["quests"]["loc"][id] then
      ItemRefTooltip:AddLine(" ")

      if pfDB["quests"]["data"][id]["min"] then
        local questlevel = tonumber(pfDB["quests"]["data"][id]["min"])
        local color = pfQuestCompat.GetDifficultyColor(questlevel)
        ItemRefTooltip:AddLine("|cffffffff" .. pfQuest_Loc["Required Level"] .. ": |r" .. questlevel, color.r, color.g, color.b)
      end

      if pfDB["quests"]["data"][id]["lvl"] then
        local questlevel = tonumber(pfDB["quests"]["data"][id]["lvl"])
        local color = pfQuestCompat.GetDifficultyColor(questlevel)
        ItemRefTooltip:AddLine("|cffffffff" .. pfQuest_Loc["Quest Level"] .. ": |r" .. questlevel, color.r, color.g, color.b)
      end
    end

    ItemRefTooltip:Show()
  end
end
