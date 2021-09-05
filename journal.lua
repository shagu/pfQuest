-- multi api compat
local compat = pfQuestCompat
local collapsed = {}

local function tablesize(tbl)
  local count = 0
  for _ in pairs(tbl) do count = count + 1 end
  return count
end

local function OnUpdate()
  if not this.column and MouseIsOver(this) then
    this.remove:Show()
    this.bg:Show()
  else
    this.remove:Hide()
    this.bg:Hide()
  end
end

local function OnEnter()
  if this.id then
    -- show extended quest tooltip
    pfDatabase:ShowExtendedTooltip(this.id, tooltip, parent, anchor, offx, offy)

    -- add level of completion
    if pfQuest_history[this.id] and pfQuest_history[this.id][2] then
      local level = pfQuest_history[this.id][2]
      local color = GetDifficultyColor(level)
      GameTooltip:AddLine("|cffffffff" .. pfQuest_Loc["Completed Level"] .. ": |r" .. level, color.r, color.g, color.b)
    end
    GameTooltip:Show()
  end
end

local function OnLeave()
  GameTooltip:Hide()
end

local function OnClick()
  if this.id and IsShiftKeyDown() then
    if tonumber(this.id) then
      pfQuestCompat.InsertQuestLink(this.id)
    else
      pfQuestCompat.InsertQuestLink(0, this.id)
    end
  elseif this.id then
    local maps = pfDatabase:SearchQuestID(this.id, meta)
    pfMap:ShowMapID(pfDatabase:GetBestMap(maps))
  elseif this.column then
    collapsed[this.column] = not collapsed[this.column]
    this.remove.view:ReloadJournal()
  end
end

local function RemoveOnClick()
  if this.entry.id then
    pfQuest_history[this.entry.id] = nil
    this.view:ReloadJournal()
  end
end

local function CreateEntry(self, index)
  if self[index] then return end

  self[index] = CreateFrame("Button", nil, self)
  self[index]:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -(index-1)*19-10)
  self[index]:SetPoint("TOPRIGHT", self, "TOPRIGHT", 0, -(index-1)*19-10)
  self[index]:SetHeight(18)

  self[index]:SetScript("OnEnter", OnEnter)
  self[index]:SetScript("OnLeave", OnLeave)
  self[index]:SetScript("OnClick", OnClick)
  self[index]:SetScript("OnUpdate", OnUpdate)

  self[index].text = self[index]:CreateFontString("Caption", "LOW", "GameFontWhite")
  self[index].text:SetFont(pfUI.font_default, pfUI_config.global.font_size, "OUTLINE")
  self[index].text:SetPoint("TOPLEFT", self[index], "TOPLEFT", 10, 0)
  self[index].text:SetPoint("BOTTOMRIGHT", self[index], "BOTTOMRIGHT", -10, 0)
  self[index].text:SetJustifyH("LEFT")

  self[index].bg = self[index]:CreateTexture(nil, "BACKGROUND")
  self[index].bg:SetAllPoints(self[index].text)
  self[index].bg:SetTexture(1,1,1,.02)

  self[index].remove = CreateFrame("Button", nil, self[index])
  self[index].remove:SetPoint("RIGHT", -5, 0)
  self[index].remove:SetHeight(20)
  self[index].remove:SetWidth(20)
  self[index].remove:SetScript("OnClick", RemoveOnClick)
  self[index].remove.entry = self[index]
  self[index].remove.view = self
  self[index].remove.texture = self[index].remove:CreateTexture("pfQuestionDialogCloseTex")
  self[index].remove.texture:SetTexture(pfQuestConfig.path.."\\compat\\close")
  self[index].remove.texture:ClearAllPoints()
  self[index].remove.texture:SetVertexColor(1,.25,.25,1)
  self[index].remove.texture:SetPoint("TOPLEFT", self[index].remove, "TOPLEFT", 4, -4)
  self[index].remove.texture:SetPoint("BOTTOMRIGHT", self[index].remove, "BOTTOMRIGHT", -4, 4)
end

local function UpdateEntry(self, index)
  if self[index].column then
    self[index].text:SetText((collapsed[self[index].column] and "|cff338855" or "|cff33ffcc")..self[index].column)
    self[index]:Show()
  elseif self[index].id then
    local qid = tonumber(self[index].id) or UNKNOWN
    local name = pfDB["quests"]["loc"][self[index].id] and pfDB["quests"]["loc"][self[index].id]["T"] or self[index].id
    local log = pfQuest_history[self[index].id][1]
    local level = pfQuest_history[self[index].id][2]
    self[index].text:SetText("  |cffffffff" .. date("%H:%M:%S", log) .. "  |cffffcc00[" .. (name or UNKNOWN) .. "]|cffaaaaaa (" .. qid ..")")
    self[index]:Show()
  else
    self[index]:Hide()
  end
end

local journal = {}
local function ReloadJournal(self)
  local self = self or this

  local index = 1
  local maxcolumns = 24
  local lastcolumn, column

  for questid, data in pfQuest:SortedPairs(pfQuest_history, 1) do
    column = data[1] == 0 and UNKNOWN or date("%A, %B %d (%Y)", data[1])

    if column ~= lastcolumn then -- add columns to the view
      lastcolumn = column
      journal[index] = journal[index] or { }
      journal[index].column = column
      journal[index].id = nil
      index = index + 1
    end

    if not collapsed[column] then -- add regular entries
      journal[index] = journal[index] or { }
      journal[index].column = nil
      journal[index].id = questid
      index = index + 1
    end
  end

  for index=index, table.getn(journal) do
    journal[index] = nil
  end

  -- push offset into limits
  self.offset = self.offset or 0
  self.offset = min(table.getn(journal) - maxcolumns + 1, self.offset)
  self.offset = max(0, self.offset)

  -- draw journal into view
  for id = 1, maxcolumns do
    CreateEntry(self, id)
    self[id].id = journal[id+self.offset] and journal[id+self.offset].id or nil
    self[id].column = journal[id+self.offset] and journal[id+self.offset].column or nil
    UpdateEntry(self, id)
  end
end

-- browser window
pfJournal = CreateFrame("Frame", "pfQuestJournal", UIParent)
pfJournal:Hide()
pfJournal:SetWidth(340)
pfJournal:SetHeight(520)
pfJournal:SetPoint("RIGHT", -80, 0)
pfJournal:SetFrameStrata("FULLSCREEN_DIALOG")
pfJournal:SetMovable(true)
pfJournal:EnableMouse(true)
pfJournal:SetScript("OnMouseDown",function()
  this:StartMoving()
end)

pfJournal:SetScript("OnMouseUp",function()
  this:StopMovingOrSizing()
end)

pfUI.api.CreateBackdrop(pfJournal, nil, true, 0.75)
table.insert(UISpecialFrames, "pfQuestJournal")

pfJournal.title = pfJournal:CreateFontString("Status", "LOW", "GameFontNormal")
pfJournal.title:SetFontObject(GameFontWhite)
pfJournal.title:SetPoint("TOP", pfJournal, "TOP", 0, -8)
pfJournal.title:SetJustifyH("LEFT")
pfJournal.title:SetFont(pfUI.font_default, 14)
pfJournal.title:SetText("|cff33ffccpf|rQuest " .. pfQuest_Loc["Journal"])

pfJournal.close = CreateFrame("Button", "pfQuestJournalClose", pfJournal)
pfJournal.close:SetPoint("TOPRIGHT", -5, -5)
pfJournal.close:SetHeight(20)
pfJournal.close:SetWidth(20)
pfJournal.close:SetScript("OnClick", function() this:GetParent():Hide() end)
pfJournal.close.texture = pfJournal.close:CreateTexture("pfQuestionDialogCloseTex")
pfJournal.close.texture:SetTexture(pfQuestConfig.path.."\\compat\\close")
pfJournal.close.texture:ClearAllPoints()
pfJournal.close.texture:SetVertexColor(1,.25,.25,1)
pfJournal.close.texture:SetPoint("TOPLEFT", pfJournal.close, "TOPLEFT", 4, -4)
pfJournal.close.texture:SetPoint("BOTTOMRIGHT", pfJournal.close, "BOTTOMRIGHT", -4, 4)
pfUI.api.SkinButton(pfJournal.close, 1, .5, .5)

pfJournal.entries = CreateFrame("Button", "pfQuestJournalEntries", pfJournal)
pfJournal.entries.ReloadJournal = ReloadJournal
pfJournal.entries:EnableMouseWheel(true)
pfJournal.entries:SetPoint("TOPLEFT", pfJournal, "TOPLEFT", 10, -35)
pfJournal.entries:SetPoint("BOTTOMRIGHT", pfJournal, "BOTTOMRIGHT", -10, 10)
pfJournal.entries:SetScript("OnMouseWheel", function()
  this.offset = this.offset and this.offset - arg1 or 0
  this:ReloadJournal()
end)

pfJournal.entries:SetScript("OnClick", pfJournal.entries.ReloadJournal)
pfJournal.entries:SetScript("OnUpdate", function()
  if ( this.tick or 1) > GetTime() then return else this.tick = GetTime() + 1 end
  this:ReloadJournal()
end)

pfUI.api.CreateBackdrop(pfJournal.entries)
