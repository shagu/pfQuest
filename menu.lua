do -- minimap icon
  pfQuestIcon = CreateFrame('Button', "pfQuestIcon", Minimap)
  pfQuestIcon:SetClampedToScreen(true)
  pfQuestIcon:SetMovable(true)
  pfQuestIcon:EnableMouse(true)
  pfQuestIcon:RegisterForDrag('LeftButton')
  pfQuestIcon:RegisterForClicks('LeftButtonUp', 'RightButtonUp')

  pfQuestIcon:SetWidth(31)
  pfQuestIcon:SetHeight(31)
  pfQuestIcon:SetFrameLevel(9)
  pfQuestIcon:SetHighlightTexture('Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight')
  pfQuestIcon:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 0, 0)

  pfQuestIcon:SetScript("OnDragStart", function()
    if IsShiftKeyDown() then
      this:StartMoving()
    end
  end)

  pfQuestIcon:SetScript("OnDragStop", function()
    this:StopMovingOrSizing()
  end)

  pfQuestIcon:SetScript("OnClick", function()
    if pfQuestMenu:IsShown() then
      pfQuestMenu:Hide()
    else
      pfQuestMenu:Show()
    end
  end)

  pfQuestIcon:SetScript("OnEnter", function()
    GameTooltip:SetOwner(this, ANCHOR_BOTTOMLEFT)
    GameTooltip:SetText("|cff33ffccpf|rQuest", 1, 1, 1, 1)
    GameTooltip:AddDoubleLine(pfQuest_Loc["Left-Click"], pfQuest_Loc["Shortcut Menu"], 1, 1, 1, 1, 1, 1)
    GameTooltip:AddDoubleLine(pfQuest_Loc["Shift-Click"], pfQuest_Loc["Move Button"], 1, 1, 1, 1, 1, 1)
    GameTooltip:Show()
  end)

  pfQuestIcon:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)

  pfQuestIcon.icon = pfQuestIcon:CreateTexture(nil, 'BACKGROUND')
  pfQuestIcon.icon:SetWidth(20)
  pfQuestIcon.icon:SetHeight(20)
  pfQuestIcon.icon:SetTexture(pfQuestConfig.path..'\\img\\logo')
  pfQuestIcon.icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)
  pfQuestIcon.icon:SetPoint('CENTER',1,1)

  pfQuestIcon.overlay = pfQuestIcon:CreateTexture(nil, 'OVERLAY')
  pfQuestIcon.overlay:SetWidth(53)
  pfQuestIcon.overlay:SetHeight(53)
  pfQuestIcon.overlay:SetTexture('Interface\\Minimap\\MiniMap-TrackingBorder')
  pfQuestIcon.overlay:SetPoint('TOPLEFT', 0,0)
end

do -- tracking menu
  local function MenuButtonEnter()
    this.title:SetTextColor(1,.8,0)
    this.highlight:Show()
  end

  local function MenuButtonLeave()
    this.title:SetTextColor(1,1,1)
    this.highlight:Hide()
  end

  local function MenuButtonClick()
    this.state = this.check and not this.check:GetChecked()

    if this.check then
      this.check:SetChecked(this.state)
    else
      this:GetParent():Hide()
    end

    if this.onclick then
      this.onclick(nil, this.name, this.state)
    end
  end

  local function CreateMenu(data, name)
    local top, width = 4, 0
    local frame = CreateFrame("Frame", name, UIParent)
    frame:SetFrameStrata("DIALOG")
    frame:SetClampedToScreen(true)
    frame:Hide()

    pfUI.api.CreateBackdrop(frame, nil, nil, .75)

    for id, tracking in pairs(data) do
      -- data shortcuts
      local name = tracking[1]
      local title = tracking[2]
      local onclick = tracking[3]
      local checkbox = tracking[4]

      if not title then
        -- draw separator line
        local line = frame:CreateTexture()
        line:SetTexture(.25 ,.25, .25, .25)
        line:SetPoint("TOPLEFT", 4, -top-2)
        line:SetPoint("TOPRIGHT", -4, -top-2)
        line:SetHeight(2)
      else
        -- create menu button
        frame[name] = CreateFrame("Button", nil, frame)
        frame[name]:SetPoint("TOPLEFT", 0, -top)
        frame[name]:SetPoint("TOPRIGHT", 0, -top)
        frame[name]:SetHeight(16)
        frame[name]:SetScript("OnEnter", MenuButtonEnter)
        frame[name]:SetScript("OnLeave", MenuButtonLeave)
        frame[name]:SetScript("OnClick", MenuButtonClick)
        frame[name].onclick = onclick
        frame[name].name = name

        -- title
        frame[name].title = frame[name]:CreateFontString(nil, "NORMAL", "GameFontWhite")
        frame[name].title:SetFont(pfUI.font_default, pfUI_config.global.font_size, "OUTLINE")
        frame[name].title:SetPoint("LEFT", 22, 0)
        frame[name].title:SetJustifyH("LEFT")
        frame[name].title:SetText(title)

        -- icon
        frame[name].icon = frame[name]:CreateTexture(nil, "OVERLAY")
        frame[name].icon:SetWidth(14)
        frame[name].icon:SetHeight(14)
        frame[name].icon:SetPoint("RIGHT", -8, 0)
        frame[name].icon:SetTexture(pfQuestConfig.path.."\\img\\tracking\\"..name)

        -- hover
        frame[name].highlight = frame[name]:CreateTexture(nil, "OVERLAY")
        frame[name].highlight:SetPoint("TOPLEFT", 4, 0)
        frame[name].highlight:SetPoint("BOTTOMRIGHT", -4, 0)
        frame[name].highlight:SetTexture(1,1,1,.1)
        frame[name].highlight:Hide()

        -- checkbox (optional)
        if checkbox then
          frame[name].check = CreateFrame("CheckButton", nil, frame[name], "UICheckButtonTemplate")
          frame[name].check:SetNormalTexture("")
          frame[name].check:SetPushedTexture("")
          frame[name].check:SetHighlightTexture("")
          frame[name].check:SetPoint("LEFT", 10, 0)
          frame[name].check:SetWidth(20)
          frame[name].check:SetHeight(20)
          frame[name].check:SetScale(.6)
          frame[name].check:EnableMouse(false)
          pfUI.api.CreateBackdrop(frame[name].check, nil, true)
        end

        -- save maximum menu width
        width = math.max(width, frame[name].title:GetStringWidth() + 60)
      end

      -- set next entry position
      top = top + (title and 16 or 6)
    end

    -- update frame size
    frame:SetWidth(width)
    frame:SetHeight(top + 4)

    -- the usual menu hide events
    table.insert(UIMenus, name)
    frame:RegisterEvent("CURSOR_UPDATE")
    frame:SetScript("OnEvent", function() this:Hide() end)

    return frame
  end

  local function ToggleFrame(frame)
    if frame:IsShown() then frame:Hide() else frame:Show() end
  end

  local menu = {
    {"database", pfQuest_Loc["Database"], function(list, state) ToggleFrame(pfBrowser) end },
    {"-"},
    {"chests", pfQuest_Loc["Chests & Treasures"], pfDatabase.TrackMeta, true},
    {"herbs", pfQuest_Loc["Herbs & Flowers"], pfDatabase.TrackMeta, true},
    {"mines", pfQuest_Loc["Mines & Ores"], pfDatabase.TrackMeta, true},
    {"fish", pfQuest_Loc["Fishing Pools"], pfDatabase.TrackMeta, true},
    {"rares", pfQuest_Loc["Rare Mobs"], pfDatabase.TrackMeta, true},
    {"-"},
    {"auctioneer", pfQuest_Loc["Auctioneer"], pfDatabase.TrackMeta, true},
    {"banker", pfQuest_Loc["Banker"], pfDatabase.TrackMeta, true},
    {"battlemaster", pfQuest_Loc["Battlemaster"], pfDatabase.TrackMeta, true},
    {"flight", pfQuest_Loc["Flight Master"], pfDatabase.TrackMeta, true},
    {"innkeeper", pfQuest_Loc["Innkeeper"], pfDatabase.TrackMeta, true},
    {"mailbox", pfQuest_Loc["Mailbox"], pfDatabase.TrackMeta, true},
    {"meetingstone", pfQuest_Loc["Meeting Stones"], pfDatabase.TrackMeta, true},
    {"repair", pfQuest_Loc["Repair"], pfDatabase.TrackMeta, true},
    {"spirithealer", pfQuest_Loc["Spirit Healer"], pfDatabase.TrackMeta, true},
    {"stablemaster", pfQuest_Loc["Stable Master"], pfDatabase.TrackMeta, true},
    {"vendor", pfQuest_Loc["Vendor"], pfDatabase.TrackMeta, true},
    {"-"},
    {"journal", pfQuest_Loc["Quest Journal"], function(list, state) ToggleFrame(pfJournal) end},
    {"welcome", pfQuest_Loc["Welcome Screen"], function(list, state) ToggleFrame(pfQuestInit) end},
    {"settings", pfQuest_Loc["Settings"], function(list, state) ToggleFrame(pfQuestConfig) end }
  }

  pfQuestMenu = CreateMenu(menu, "pfQuestMenu")
  pfQuestMenu:SetScript("OnShow", function()
    -- create shortcuts
    local anchor = this.anchor or pfQuestIcon
    local config = pfQuest_track
    local frame = this

    -- read virtual anchor position
    local x, y = anchor:GetCenter()
    x = x * anchor:GetEffectiveScale() / UIParent:GetScale()
    y = y * anchor:GetEffectiveScale() / UIParent:GetScale()

    -- read virtual screen resolution
    local width = UIParent:GetWidth() / UIParent:GetScale()
    local height = UIParent:GetHeight() / UIParent:GetScale()

    -- calculate menu position on screen
    local h = y > height / 2 and "TOP" or "BOTTOM"
    local hp = y > height / 2 and -8 or 8
    local w = x > width / 2 and "RIGHT" or "LEFT"
    local wp = x > width / 2 and -8 or 8

    -- set frame position
    frame:ClearAllPoints()
    frame:SetPoint(h..w, anchor, "CENTER", wp, hp)

    -- align menu entries to config state
    for id, data in pairs(menu) do
      if frame[data[1]] and frame[data[1]].check then
        frame[data[1]].check:SetChecked(config[data[1]] and true or false)
      end
    end
  end)
end
