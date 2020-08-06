-- multi api compat
local compat = pfQuestCompat

pfQuest_history = {}
pfQuest_colors = {}
pfQuest_config = {}

-- default config
pfQuest_defconfig = {
  ["trackingmethod"] = {
    -- 1: All Quests; 2: Tracked; 3: Manual; 4: Hide
    text = nil, default = 1, type = nil, pos = nil,
  },
  ["allquestgivers"] = {
    text = pfQuest_Loc["Display Available Questgivers"],
    default = "1", type = "checkbox", pos = {},
  },
  ["currentquestgivers"] = { -- Show Current Questgiver Nodes
    text = pfQuest_Loc["Display Current Questgivers"],
    default = "1", type = "checkbox", pos = {},
  },
  ["showlowlevel"] = { -- Show Lowlevel Questgiver Nodes
    text = pfQuest_Loc["Display Lowlevel Questgivers"],
    default = "0", type = "checkbox", pos = {},
  },
  ["showhighlevel"] = { -- Show Level+3 Questgiver Nodes
    text = pfQuest_Loc["Display Level+3 Questgivers"],
    default = "1", type = "checkbox", pos = {},
  },
  ["showfestival"] = { -- Show Event Questgiver Nodes
    text = pfQuest_Loc["Display Event & Daily Quests"],
    default = "0", type = "checkbox", pos = {},
  },
  ["minimapnodes"] = { -- Show MiniMap Nodes
    text = pfQuest_Loc["Show MiniMap Nodes"],
    default = "1", type = "checkbox", pos = {},
  },
  ["cutoutminimap"] = { -- Use Cut-Out Minimap Node Icon
    text = pfQuest_Loc["Use Cut-Out MiniMap Node Icons"],
    default = "1", type = "checkbox", pos = {},
  },
  ["questlogbuttons"] = { -- Show QuestLog Buttons
    text = pfQuest_Loc["Show QuestLog Buttons"],
    default = "1", type = "checkbox", pos = {},
  },
  ["worldmapmenu"] = { -- Show WorldMap Menu
    text = pfQuest_Loc["Show WorldMap Menu"],
    default = "1", type = "checkbox", pos = {},
  },
  ["minimapbutton"] = { -- Show MiniMap Button
    text = pfQuest_Loc["Show MiniMap Button"],
    default = "1", type = "checkbox", pos = {},
  },
  ["showids"] = { -- Show IDs
    text = pfQuest_Loc["Show IDs"],
    default = "0", type = "checkbox", pos = {},
  },
  ["spawncolors"] = { -- Color Map Nodes By Spawn
    text = pfQuest_Loc["Color Map Nodes By Spawn"],
    default = "0", type = "checkbox", pos = {},
  },
  ["questlinks"] = { -- Enable Quest Links
    text = pfQuest_Loc["Enable Quest Links"],
    default = "1", type = "checkbox", pos = {},
  },
  ["worldmaptransp"] = { -- WorldMap Node Transparency
    text = pfQuest_Loc["WorldMap Node Transparency"],
    default = "1.0", type = "text", pos = {},
  },
  ["minimaptransp"] = { -- MiniMap Node Transparency
    text = pfQuest_Loc["MiniMap Node Transparency"],
    default = "1.0", type = "text", pos = {},
  },
  ["mindropchance"] = { -- Minimum Drop Chance
    text = pfQuest_Loc["Minimum Drop Chance"],
    default = "1", type = "text", pos = {},
  },
  ["mouseover"] = { -- Highlight Nodes On Mouseover
    text = pfQuest_Loc["Highlight Nodes On Mouseover"],
    default = "1", type = "checkbox", pos = {},
  },
  ["showtracker"] = { -- Show Map Tracker
    text = pfQuest_Loc["Show Quest Tracker"],
    default = "1", type = "checkbox", pos = {},
  },
  ["showcluster"] = { -- Show Quest Clusters
    text = pfQuest_Loc["Unified Quest Location Marker"],
    default = "1", type = "checkbox", pos = {},
  },
}

StaticPopupDialogs["PFQUEST_RESET"] = {
  button1 = YES,
  button2 = NO,
  timeout = 0,
  whileDead = 1,
  hideOnEscape = 1,
}

pfQuestConfig = CreateFrame("Frame", "pfQuestConfig", UIParent)
pfQuestConfig:Hide()
pfQuestConfig:SetWidth(280)
pfQuestConfig:SetHeight(550)
pfQuestConfig:SetPoint("CENTER", 0, 0)
pfQuestConfig:SetFrameStrata("TOOLTIP")
pfQuestConfig:SetMovable(true)
pfQuestConfig:EnableMouse(true)
pfQuestConfig:RegisterEvent("ADDON_LOADED")
pfQuestConfig:SetScript("OnEvent", function()
  if arg1 == "pfQuest" or arg1 == "pfQuest-tbc" or arg1 == "pfQuest-wotlk" then
    pfQuestConfig:LoadConfig()
    pfQuestConfig:MigrateHistory()

    pfQuest_history = pfQuest_history or {}
    pfQuest_colors = pfQuest_colors or {}
    pfQuest_config = pfQuest_config or {}
    pfBrowser_fav = pfBrowser_fav or {["units"] = {}, ["objects"] = {}, ["items"] = {}, ["quests"] = {}}

    for opt, data in pairs(pfQuest_defconfig) do
      if data.text and data.type then
        pfQuestConfig:CreateConfigEntry(opt, data.text, data.type)
      end
    end

    if pfBrowserIcon and pfQuest_config["minimapbutton"] == "0" then
      pfBrowserIcon:Hide()
    end
  end
end)

pfQuestConfig:SetScript("OnMouseDown",function()
  this:StartMoving()
end)

pfQuestConfig:SetScript("OnMouseUp",function()
  this:StopMovingOrSizing()
end)

pfQuestConfig.vpos = 40

pfUI.api.CreateBackdrop(pfQuestConfig, nil, true, 0.75)
table.insert(UISpecialFrames, "pfQuestConfig")

-- detect current addon path
local tocs = { "", "-master", "-tbc", "-wotlk" }
for _, name in pairs(tocs) do
  local current = string.format("pfQuest%s", name)
  local _, title = GetAddOnInfo(current)
  if title then
    pfQuestConfig.path = "Interface\\AddOns\\" .. current
    break
  end
end

pfQuestConfig.title = pfQuestConfig:CreateFontString("Status", "LOW", "GameFontNormal")
pfQuestConfig.title:SetFontObject(GameFontWhite)
pfQuestConfig.title:SetPoint("TOP", pfQuestConfig, "TOP", 0, -8)
pfQuestConfig.title:SetJustifyH("LEFT")
pfQuestConfig.title:SetFont(pfUI.font_default, 14)
pfQuestConfig.title:SetText("|cff33ffccpf|rQuest " .. pfQuest_Loc["Config"])

pfQuestConfig.close = CreateFrame("Button", "pfQuestConfigClose", pfQuestConfig)
pfQuestConfig.close:SetPoint("TOPRIGHT", -5, -5)
pfQuestConfig.close:SetHeight(20)
pfQuestConfig.close:SetWidth(20)
pfQuestConfig.close.texture = pfQuestConfig.close:CreateTexture("pfQuestionDialogCloseTex")
pfQuestConfig.close.texture:SetTexture(pfQuestConfig.path.."\\compat\\close")
pfQuestConfig.close.texture:ClearAllPoints()
pfQuestConfig.close.texture:SetPoint("TOPLEFT", pfQuestConfig.close, "TOPLEFT", 4, -4)
pfQuestConfig.close.texture:SetPoint("BOTTOMRIGHT", pfQuestConfig.close, "BOTTOMRIGHT", -4, 4)

pfQuestConfig.close.texture:SetVertexColor(1,.25,.25,1)
pfUI.api.SkinButton(pfQuestConfig.close, 1, .5, .5)
pfQuestConfig.close:SetScript("OnClick", function()
 this:GetParent():Hide()
end)

pfQuestConfig.clean = CreateFrame("Button", "pfQuestConfigReload", pfQuestConfig)
pfQuestConfig.clean:SetWidth(260)
pfQuestConfig.clean:SetHeight(30)
pfQuestConfig.clean:SetPoint("BOTTOM", 0, 10)
pfQuestConfig.clean:SetScript("OnClick", function()
  ReloadUI()
end)
pfQuestConfig.clean.text = pfQuestConfig.clean:CreateFontString("Caption", "LOW", "GameFontWhite")
pfQuestConfig.clean.text:SetAllPoints(pfQuestConfig.clean)
pfQuestConfig.clean.text:SetFont(pfUI.font_default, pfUI_config.global.font_size, "OUTLINE")
pfQuestConfig.clean.text:SetText(pfQuest_Loc["Close & Reload"])
pfUI.api.SkinButton(pfQuestConfig.clean)

pfQuestConfig.history = CreateFrame("Button", "pfQuestConfigResetHistory", pfQuestConfig)
pfQuestConfig.history:SetWidth(125)
pfQuestConfig.history:SetHeight(30)
pfQuestConfig.history:SetPoint("BOTTOMLEFT", 10, 50)
pfQuestConfig.history:SetScript("OnClick", function()
  local dialog = StaticPopupDialogs["PFQUEST_RESET"]
  dialog.text = pfQuest_Loc["Do you really want to reset the quest history?"]
  dialog.OnAccept = function()
    pfQuest_history = nil
    ReloadUI()
  end

  StaticPopup_Show("PFQUEST_RESET")
end)
pfQuestConfig.history.text = pfQuestConfig.history:CreateFontString("Caption", "LOW", "GameFontWhite")
pfQuestConfig.history.text:SetAllPoints(pfQuestConfig.history)
pfQuestConfig.history.text:SetFont(pfUI.font_default, pfUI_config.global.font_size, "OUTLINE")
pfQuestConfig.history.text:SetText(pfQuest_Loc["Reset History"])
pfUI.api.SkinButton(pfQuestConfig.history)

pfQuestConfig.reset = CreateFrame("Button", "pfQuestConfigReset", pfQuestConfig)
pfQuestConfig.reset:SetWidth(125)
pfQuestConfig.reset:SetHeight(30)
pfQuestConfig.reset:SetPoint("BOTTOMRIGHT", -10, 50)
pfQuestConfig.reset:SetScript("OnClick", function()
  local dialog = StaticPopupDialogs["PFQUEST_RESET"]
  dialog.text = pfQuest_Loc["Do you really want to reset everything?"]
  dialog.OnAccept = function()
    pfQuest_config, pfBrowser_fav, pfQuest_history, pfQuest_colors, pfQuest_server = nil
    ReloadUI()
  end

  StaticPopup_Show("PFQUEST_RESET")
end)
pfQuestConfig.reset.text = pfQuestConfig.reset:CreateFontString("Caption", "LOW", "GameFontWhite")
pfQuestConfig.reset.text:SetAllPoints(pfQuestConfig.reset)
pfQuestConfig.reset.text:SetFont(pfUI.font_default, pfUI_config.global.font_size, "OUTLINE")
pfQuestConfig.reset.text:SetText(pfQuest_Loc["Reset Everything"])
pfUI.api.SkinButton(pfQuestConfig.reset)

function pfQuestConfig:LoadConfig()
  if not pfQuest_config then pfQuest_config = {} end

  for opt, data in pairs(pfQuest_defconfig) do
    if not pfQuest_config[opt] then
      pfQuest_config[key] = data.default
    end
  end
end

function pfQuestConfig:MigrateHistory()
  if not pfQuest_history then return end

  local match = false

  for entry, data in pairs(pfQuest_history) do
    if type(entry) == "string" then
      match = true
      for id in pairs(pfDatabase:GetIDByName(entry, "quests")) do
        pfQuest_history[id] = { 0, 0 }
      end
      pfQuest_history[entry] = nil
    elseif data == true then
      pfQuest_history[entry] = { 0, 0 }
    elseif type(data) == "table" and not data[1] then
      pfQuest_history[entry] = { 0, 0 }
    end
  end

  if match == true then
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffccpf|cffffffffQuest|r: " .. pfQuest_Loc["Quest history migration completed."])
  end
end

function pfQuestConfig:CreateConfigEntry(config, description, type)
  -- basic frame
  local frame = getglobal("pfQuestConfig" .. config) or CreateFrame("Frame", "pfQuestConfig" .. config, pfQuestConfig)
  frame:SetWidth(280)
  frame:SetHeight(25)
  frame:SetPoint("TOP", 0, -pfQuestConfig.vpos)

  -- caption
  frame.caption = frame.caption or frame:CreateFontString("Status", "LOW", "GameFontWhite")
  frame.caption:SetFont(pfUI.font_default, pfUI_config.global.font_size, "OUTLINE")
  frame.caption:SetPoint("LEFT", 20, 0)
  frame.caption:SetJustifyH("LEFT")
  frame.caption:SetText(description)

  -- checkbox
  if type == "checkbox" then
    frame.input = frame.input or CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
    frame.input:SetNormalTexture("")
    frame.input:SetPushedTexture("")
    frame.input:SetHighlightTexture("")
    pfUI.api.CreateBackdrop(frame.input, nil, true)

    frame.input:SetWidth(20)
    frame.input:SetHeight(20)
    frame.input:SetPoint("RIGHT" , -20, 0)

    frame.input.config = config
    if pfQuest_config[config] == "1" then
      frame.input:SetChecked()
    end

    frame.input:SetScript("OnClick", function ()
      if this:GetChecked() then
        pfQuest_config[this.config] = "1"
      else
        pfQuest_config[this.config] = "0"
      end

      pfQuest:ResetAll()
    end)

  elseif type == "text" then
    -- input field
    frame.input = frame.input or CreateFrame("EditBox", nil, frame)
    frame.input:SetTextColor(.2,1,.8,1)
    frame.input:SetJustifyH("RIGHT")

    frame.input:SetWidth(50)
    frame.input:SetHeight(20)
    frame.input:SetPoint("RIGHT" , -20, 0)
    frame.input:SetFontObject(GameFontNormal)
    frame.input:SetAutoFocus(false)
    frame.input:SetScript("OnEscapePressed", function(self)
      this:ClearFocus()
    end)

    frame.input.config = config
    frame.input:SetText(pfQuest_config[config])

    frame.input:SetScript("OnTextChanged", function(self)
      pfQuest_config[this.config] = this:GetText()
    end)
  end

  pfQuestConfig.vpos = pfQuestConfig.vpos + 23
end
