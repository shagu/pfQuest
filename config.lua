-- multi api compat
local compat = pfQuestCompat
local L = pfQuest_Loc

pfQuest_history = {}
pfQuest_colors = {}
pfQuest_config = {}

local reset = {
  config = function()
    local dialog = StaticPopupDialogs["PFQUEST_RESET"]
    dialog.text = L["Do you really want to reset the configuration?"]
    dialog.OnAccept = function()
      pfQuest_config = nil
      ReloadUI()
    end

    StaticPopup_Show("PFQUEST_RESET")
  end,
  history = function()
    local dialog = StaticPopupDialogs["PFQUEST_RESET"]
    dialog.text = L["Do you really want to reset the quest history?"]
    dialog.OnAccept = function()
      pfQuest_history = nil
      ReloadUI()
    end

    StaticPopup_Show("PFQUEST_RESET")
  end,
  cache = function()
    local dialog = StaticPopupDialogs["PFQUEST_RESET"]
    dialog.text = L["Do you really want to reset the caches?"]
    dialog.OnAccept = function()
      pfQuest_questcache = nil
      ReloadUI()
    end

    StaticPopup_Show("PFQUEST_RESET")
  end,
  everything = function()
    local dialog = StaticPopupDialogs["PFQUEST_RESET"]
    dialog.text = L["Do you really want to reset everything?"]
    dialog.OnAccept = function()
      pfQuest_config, pfBrowser_fav, pfQuest_history, pfQuest_colors, pfQuest_server = nil
      ReloadUI()
    end

    StaticPopup_Show("PFQUEST_RESET")
  end,
}

-- default config
pfQuest_defconfig = {
  { -- 1: All Quests; 2: Tracked; 3: Manual; 4: Hide
    config = "trackingmethod",
    text = nil, default = 1, type = nil
  },

  { text = L["General"],
    default = nil, type = "header" },
  { text = L["Enable World Map Menu"],
    default = "1", type = "checkbox", config = "worldmapmenu" },
  { text = L["Enable Minimap Button"],
    default = "1", type = "checkbox", config = "minimapbutton" },
  { text = L["Enable Quest Tracker"],
    default = "1", type = "checkbox", config = "showtracker" },
  { text = L["Enable Quest Log Buttons"],
    default = "1", type = "checkbox", config = "questlogbuttons" },
  { text = L["Enable Quest Link Support"],
    default = "1", type = "checkbox", config = "questlinks" },
  { text = L["Show Database IDs"],
    default = "0", type = "checkbox", config = "showids" },
  { text = L["Draw Favorites On Login"],
    default = "0", type = "checkbox", config = "favonlogin" },
  { text = L["Minimum Item Drop Chance"],
    default = "1", type = "text", config = "mindropchance" },
  { text = L["Show Tooltips"],
    default = "1", type = "checkbox", config = "showtooltips" },
  { text = L["Show Help On Tooltips"],
    default = "1", type = "checkbox", config = "tooltiphelp" },
  { text = L["Show Level On Quest Tracker"],
    default = "1", type = "checkbox", config = "trackerlevel" },
  { text = L["Show Level On Quest Log"],
    default = "0", type = "checkbox", config = "questloglevel" },

  { text = L["Map & Minimap"],
    default = nil, type = "header" },
  { text = L["Enable Minimap Nodes"],
    default = "1", type = "checkbox", config = "minimapnodes" },
  { text = L["Use Monochrome Cluster Icons"],
    default = "0", type = "checkbox", config = "clustermono" },
  { text = L["Use Cut-Out Minimap Node Icons"],
    default = "1", type = "checkbox", config = "cutoutminimap" },
  { text = L["Use Cut-Out World Map Node Icons"],
    default = "0", type = "checkbox", config = "cutoutworldmap" },
  { text = L["Color Map Nodes By Spawn"],
    default = "0", type = "checkbox", config = "spawncolors" },
  { text = L["World Map Node Transparency"],
    default = "1.0", type = "text", config = "worldmaptransp" },
  { text = L["Minimap Node Transparency"],
    default = "1.0", type = "text", config = "minimaptransp" },
  { text = L["Node Fade Transparency"],
    default = "0.3", type = "text", config = "nodefade" },
  { text = L["Highlight Nodes On Mouseover"],
    default = "1", type = "checkbox", config = "mouseover" },

  { text = L["Questing"],
    default = nil, type = "header" },
  { text = L["Quest Tracker Visibility"],
    default = "0", type = "text", config = "trackeralpha" },
  { text = L["Quest Tracker Font Size"],
    default = "12", type = "text", config = "trackerfontsize", },
  { text = L["Show Individual Spawn Points"],
    default = "1", type = "checkbox", config = "showspawn" },
  { text = L["Unified Quest Location Markers"],
    default = "1", type = "checkbox", config = "showcluster" },
  { text = L["Display Available Quest Givers"],
    default = "1", type = "checkbox", config = "allquestgivers" },
  { text = L["Display Current Quest Givers"],
    default = "1", type = "checkbox", config = "currentquestgivers" },
  { text = L["Display Low Level Quest Givers"],
    default = "0", type = "checkbox", config = "showlowlevel" },
  { text = L["Display Level+3 Quest Givers"],
    default = "0", type = "checkbox", config = "showhighlevel" },
  { text = L["Display Event & Daily Quests"],
    default = "0", type = "checkbox", config = "showfestival" },

  { text = L["Routes"],
    default = nil, type = "header" },
  { text = L["Show Route Between Objects"],
    default = "1", type = "checkbox", config = "routes" },
  { text = L["Include Unified Quest Locations"],
    default = "1", type = "checkbox", config = "routecluster" },
  { text = L["Include Quest Enders"],
    default = "1", type = "checkbox", config = "routeender" },
  { text = L["Include Quest Starters"],
    default = "0", type = "checkbox", config = "routestarter" },
  { text = L["Show Route On Minimap"],
    default = "0", type = "checkbox", config = "routeminimap" },
  { text = L["Show Arrow Along Routes"],
    default = "1", type = "checkbox", config = "arrow" },

  { text = L["User Data"],
    default = nil, type = "header" },
  { text = L["Reset Configuration"],
    default = "1", type = "button", func = reset.config },
  { text = L["Reset Quest History"],
    default = "1", type = "button", func = reset.history },
  { text = L["Reset Cache"],
    default = "1", type = "button", func = reset.cache },
  { text = L["Reset Everything"],
    default = "1", type = "button", func = reset.everything },
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
pfQuestConfig:SetFrameStrata("HIGH")
pfQuestConfig:SetMovable(true)
pfQuestConfig:EnableMouse(true)
pfQuestConfig:SetClampedToScreen(true)
pfQuestConfig:RegisterEvent("ADDON_LOADED")
pfQuestConfig:SetScript("OnEvent", function()
  if arg1 == "pfQuest" or arg1 == "pfQuest-tbc" or arg1 == "pfQuest-wotlk" then
    pfQuestConfig:LoadConfig()
    pfQuestConfig:MigrateHistory()
    pfQuestConfig:CreateConfigEntries(pfQuest_defconfig)

    pfQuest_questcache = pfQuest_questcache or {}
    pfQuest_history = pfQuest_history or {}
    pfQuest_colors = pfQuest_colors or {}
    pfQuest_config = pfQuest_config or {}
    pfBrowser_fav = pfBrowser_fav or {["units"] = {}, ["objects"] = {}, ["items"] = {}, ["quests"] = {}}

    -- clear quest history on new characters
    if UnitXP("player") == 0 and UnitLevel("player") == 1 then
      pfQuest_history = {}
    end

    if pfBrowserIcon and pfQuest_config["minimapbutton"] == "0" then
      pfBrowserIcon:Hide()
    end
  end
end)

pfQuestConfig:SetScript("OnMouseDown", function()
  this:StartMoving()
end)

pfQuestConfig:SetScript("OnMouseUp", function()
  this:StopMovingOrSizing()
end)

pfQuestConfig:SetScript("OnShow", function()
  this:UpdateConfigEntries()
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
    pfQuestConfig.version = tostring(GetAddOnMetadata(current, "Version"))
    break
  end
end

pfQuestConfig.title = pfQuestConfig:CreateFontString("Status", "LOW", "GameFontNormal")
pfQuestConfig.title:SetFontObject(GameFontWhite)
pfQuestConfig.title:SetPoint("TOP", pfQuestConfig, "TOP", 0, -8)
pfQuestConfig.title:SetJustifyH("LEFT")
pfQuestConfig.title:SetFont(pfUI.font_default, 14)
pfQuestConfig.title:SetText("|cff33ffccpf|rQuest " .. L["Config"])

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

pfQuestConfig.save = CreateFrame("Button", "pfQuestConfigReload", pfQuestConfig)
pfQuestConfig.save:SetWidth(160)
pfQuestConfig.save:SetHeight(28)
pfQuestConfig.save:SetPoint("BOTTOM", 0, 10)
pfQuestConfig.save:SetScript("OnClick", ReloadUI)
pfQuestConfig.save.text = pfQuestConfig.save:CreateFontString("Caption", "LOW", "GameFontWhite")
pfQuestConfig.save.text:SetAllPoints(pfQuestConfig.save)
pfQuestConfig.save.text:SetFont(pfUI.font_default, pfUI_config.global.font_size, "OUTLINE")
pfQuestConfig.save.text:SetText(L["Close & Reload"])
pfUI.api.SkinButton(pfQuestConfig.save)

function pfQuestConfig:LoadConfig()
  if not pfQuest_config then pfQuest_config = {} end
  for id, data in pairs(pfQuest_defconfig) do
    if data.config and not pfQuest_config[data.config] then
      pfQuest_config[data.config] = data.default
    end
  end
end

function pfQuestConfig:MigrateHistory()
  if not pfQuest_history then return end

  local match = false

  for entry, data in pairs(pfQuest_history) do
    if type(entry) == "string" then
      for id in pairs(pfDatabase:GetIDByName(entry, "quests")) do
        pfQuest_history[id] = { 0, 0 }
        pfQuest_history[entry] = nil
        match = true
      end
    elseif data == true then
      pfQuest_history[entry] = { 0, 0 }
    elseif type(data) == "table" and not data[1] then
      pfQuest_history[entry] = { 0, 0 }
    end
  end

  if match == true then
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffccpf|cffffffffQuest|r: " .. L["Quest history migration completed."])
  end
end

local maxh, maxw = 0, 0
local width, height = 230, 22
local maxtext = 130
local configframes = {}
function pfQuestConfig:CreateConfigEntries(config)
  local count = 1

  for _, data in pairs(config) do
    if data.type then
      -- basic frame
      local frame = CreateFrame("Frame", "pfQuestConfig" .. count, pfQuestConfig)
      configframes[data.text] = frame

      -- caption
      frame.caption = frame:CreateFontString("Status", "LOW", "GameFontWhite")
      frame.caption:SetFont(pfUI.font_default, pfUI_config.global.font_size, "OUTLINE")
      frame.caption:SetPoint("LEFT", 20, 0)
      frame.caption:SetJustifyH("LEFT")
      frame.caption:SetText(data.text)
      maxtext = max(maxtext, frame.caption:GetStringWidth())

      -- header
      if data.type == "header" then
        frame.caption:SetPoint("LEFT", 10, 0)
        frame.caption:SetTextColor(.3,1,.8)
        frame.caption:SetFont(pfUI.font_default, pfUI_config.global.font_size+2, "OUTLINE")

      -- checkbox
      elseif data.type == "checkbox" then
        frame.input = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
        frame.input:SetNormalTexture("")
        frame.input:SetPushedTexture("")
        frame.input:SetHighlightTexture("")
        pfUI.api.CreateBackdrop(frame.input, nil, true)

        frame.input:SetWidth(16)
        frame.input:SetHeight(16)
        frame.input:SetPoint("RIGHT" , -20, 0)

        frame.input.config = data.config
        if pfQuest_config[data.config] == "1" then
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
      elseif data.type == "text" then
        -- input field
        frame.input = CreateFrame("EditBox", nil, frame)
        frame.input:SetTextColor(.2,1,.8,1)
        frame.input:SetJustifyH("RIGHT")
        frame.input:SetTextInsets(5,5,5,5)
        frame.input:SetWidth(32)
        frame.input:SetHeight(16)
        frame.input:SetPoint("RIGHT", -20, 0)
        frame.input:SetFontObject(GameFontNormal)
        frame.input:SetAutoFocus(false)
        frame.input:SetScript("OnEscapePressed", function(self)
          this:ClearFocus()
        end)

        frame.input.config = data.config
        frame.input:SetText(pfQuest_config[data.config])

        frame.input:SetScript("OnTextChanged", function(self)
          pfQuest_config[this.config] = this:GetText()
        end)

        pfUI.api.CreateBackdrop(frame.input, nil, true)
      elseif data.type == "button" and data.func then
        frame.input = CreateFrame("Button", nil, frame)
        frame.input:SetWidth(32)
        frame.input:SetHeight(16)
        frame.input:SetPoint("RIGHT", -20, 0)
        frame.input:SetScript("OnClick", data.func)
        frame.input.text = frame.input:CreateFontString("Caption", "LOW", "GameFontWhite")
        frame.input.text:SetAllPoints(frame.input)
        frame.input.text:SetFont(pfUI.font_default, pfUI_config.global.font_size, "OUTLINE")
        frame.input.text:SetText("OK")
        pfUI.api.SkinButton(frame.input)
      end

      -- increase size and zoom back due to blizzard backdrop reasons...
      if frame.input and pfUI.api.emulated then
        frame.input:SetWidth(frame.input:GetWidth()/.6)
        frame.input:SetHeight(frame.input:GetHeight()/.6)
        frame.input:SetScale(.8)
        if frame.input.SetTextInsets then
          frame.input:SetTextInsets(8,8,8,8)
        end
      end

      count = count + 1
    end
  end

  -- update sizes / positions
  width = maxtext + 100
  local column, row = 1, 0

  for _, data in pairs(config) do
    if data.type then
      -- empty line for headers, next column for > 20 entries
      row = row + ( data.type == "header" and row > 1 and 2 or 1 )
      if row > 20 and data.type == "header" then
        column, row = column + 1, 1
      end

      -- update max size values
      maxw, maxh = max(maxw, column), max(maxh, row)

      -- align frames to sizings
      local spacer = (column-1)*20
      local x, y = (column-1)*width, -(row-1)*height
      local frame = configframes[data.text]
      frame:SetWidth(width)
      frame:SetHeight(height)
      frame:SetPoint("TOPLEFT", pfQuestConfig, "TOPLEFT", x + spacer + 10, y - 40)
    end
  end

  local spacer = (maxw-1)*20
  pfQuestConfig:SetWidth(maxw*width + spacer + 20)
  pfQuestConfig:SetHeight(maxh*height + 100)
end

function pfQuestConfig:UpdateConfigEntries()
  for _, data in pairs(pfQuest_defconfig) do
    if data.type and configframes[data.text] then
      if data.type == "checkbox" then
        configframes[data.text].input:SetChecked((pfQuest_config[data.config] == "1" and true or nil))
      elseif data.type == "text" then
        configframes[data.text].input:SetText(pfQuest_config[data.config])
      end
    end
  end
end
