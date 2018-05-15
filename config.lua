pfQuest_history = {}
pfQuest_colors = {}
pfQuest_config = {}

-- default config
pfQuest_defconfig = {
  ["trackingmethod"] = 1, -- 1: All Quests; 2: Tracked; 3: Manual; 4: Hide
  ["allquestgivers"] = "1", -- Show Available Questgivers
  ["currentquestgivers"] = "1", -- Show Current Questgiver Nodes
  ["showlowlevel"] = "0", -- Show Lowlevel Questgiver Nodes
  ["showhighlevel"] = "1", -- Show Level+3 Questgiver Nodes
  ["minimapnodes"] = "1", -- Show MiniMap Nodes
  ["cutoutminimap"] = "1", -- Use Cut-Out Minimap Node Icon
  ["questlogbuttons"] = "1", -- Show QuestLog Buttons
  ["worldmapmenu"] = "1", -- Show WorldMap Menu
  ["minimapbutton"] = "1", -- Show MiniMap Button
  ["showids"] = "0", -- Show IDs
  ["colorbyspawn"] = "1", -- Color Map Nodes By Spawn
  ["questlinks"] = "1", -- Enable Quest Links
  ["worldmaptransp"] = "1.0", -- WorldMap Node Transparency
  ["minimaptransp"] = "1.0", -- MiniMap Node Transparency
  ["mindropchance"] = "0", -- Minimum Drop Chance
}

pfQuestConfig = CreateFrame("Frame", "pfQuestConfig", UIParent)
pfQuestConfig:Hide()
pfQuestConfig:SetWidth(280)
pfQuestConfig:SetHeight(420)
pfQuestConfig:SetPoint("CENTER", 0, 0)
pfQuestConfig:SetFrameStrata("TOOLTIP")
pfQuestConfig:SetMovable(true)
pfQuestConfig:EnableMouse(true)
pfQuestConfig:RegisterEvent("ADDON_LOADED")
pfQuestConfig:SetScript("OnEvent", function()
  if arg1 == "pfQuest" then
    pfQuestConfig:LoadConfig()
    pfQuestConfig:MigrateHistory()

    pfQuestConfig:CreateConfigEntry("allquestgivers",      "Display Available Questgivers",  "checkbox")
    pfQuestConfig:CreateConfigEntry("currentquestgivers",  "Display Current Questgivers",    "checkbox")
    pfQuestConfig:CreateConfigEntry("showlowlevel",        "Display Lowlevel Questgivers",   "checkbox")
    pfQuestConfig:CreateConfigEntry("showhighlevel",       "Display Level+3 Questgivers",    "checkbox")
    pfQuestConfig:CreateConfigEntry("minimapnodes",        "Show MiniMap Nodes",             "checkbox")
    pfQuestConfig:CreateConfigEntry("cutoutminimap",        "Use Cut-Out MiniMap Node Icons","checkbox")
    pfQuestConfig:CreateConfigEntry("questlogbuttons",     "Show QuestLog Buttons",          "checkbox")
    pfQuestConfig:CreateConfigEntry("worldmapmenu",        "Show WorldMap Menu",             "checkbox")
    pfQuestConfig:CreateConfigEntry("minimapbutton",       "Show MiniMap Button",            "checkbox")
    pfQuestConfig:CreateConfigEntry("showids",             "Show IDs",                       "checkbox")
    pfQuestConfig:CreateConfigEntry("colorbyspawn",        "Color Map Nodes By Spawn",       "checkbox")
    pfQuestConfig:CreateConfigEntry("questlinks",          "Enable Quest Links",             "checkbox")
    pfQuestConfig:CreateConfigEntry("worldmaptransp",      "WorldMap Node Transparency",     "text")
    pfQuestConfig:CreateConfigEntry("minimaptransp",       "MiniMap Node Transparency",      "text")
    pfQuestConfig:CreateConfigEntry("mindropchance",       "Minimum Drop Chance",            "text")

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

pfQuestConfig.vpos = 30

pfUI.api.CreateBackdrop(pfQuestConfig, nil, true, 0.75)
table.insert(UISpecialFrames, "pfQuestConfig")

pfQuestConfig.title = pfQuestConfig:CreateFontString("Status", "LOW", "GameFontNormal")
pfQuestConfig.title:SetFontObject(GameFontWhite)
pfQuestConfig.title:SetPoint("TOP", pfQuestConfig, "TOP", 0, -8)
pfQuestConfig.title:SetJustifyH("LEFT")
pfQuestConfig.title:SetFont(pfUI.font_default, 14)
pfQuestConfig.title:SetText("|cff33ffccpf|rQuest Config")

pfQuestConfig.close = CreateFrame("Button", "pfQuestConfigClose", pfQuestConfig)
pfQuestConfig.close:SetPoint("TOPRIGHT", -5, -5)
pfQuestConfig.close:SetHeight(12)
pfQuestConfig.close:SetWidth(12)
pfQuestConfig.close.texture = pfQuestConfig.close:CreateTexture("pfQuestionDialogCloseTex")
pfQuestConfig.close.texture:SetTexture("Interface\\AddOns\\pfQuest\\compat\\close")
pfQuestConfig.close.texture:ClearAllPoints()
pfQuestConfig.close.texture:SetAllPoints(pfQuestConfig.close)
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
pfQuestConfig.clean.text:SetText("Close & Reload")
pfUI.api.SkinButton(pfQuestConfig.clean)

function pfQuestConfig:LoadConfig()
  if not pfQuest_config then pfQuest_config = {} end

  for key, val in pairs(pfQuest_defconfig) do
    if not pfQuest_config[key] then
      pfQuest_config[key] = val
    end
  end
end

function pfQuestConfig:MigrateHistory()
  local match = false

  for entry in pairs(pfQuest_history) do
    if type(entry) == "string" then
      match = true
      for id in pairs(pfDatabase:GetIDByName(entry, "quests")) do
        pfQuest_history[id] = true
      end
      pfQuest_history[entry] = nil
    end
  end

  if match == true then
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffccpf|cffffffffQuest|r: QuestHistory Migraten completed.")
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

    frame.input:SetWidth(12)
    frame.input:SetHeight(12)
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
