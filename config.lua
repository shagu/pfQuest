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

  ["_General_"] = {
    text = pfQuest_Loc["General"],
    default = nil, type = "header", pos = { 1, 1 },
  },
  ["worldmapmenu"] = { -- Enable World Map Menu
    text = pfQuest_Loc["Enable World Map Menu"],
    default = "1", type = "checkbox", pos = { 1, 2 },
  },
  ["minimapbutton"] = { -- Enable Minimap Button
    text = pfQuest_Loc["Enable Minimap Button"],
    default = "1", type = "checkbox", pos = { 1, 3 },
  },
  ["showtracker"] = { -- Enable Quest Tracker
    text = pfQuest_Loc["Enable Quest Tracker"],
    default = "1", type = "checkbox", pos = { 1, 4},
  },
  ["questlogbuttons"] = { -- Enable Quest Log Buttons
    text = pfQuest_Loc["Enable Quest Log Buttons"],
    default = "1", type = "checkbox", pos = { 1, 5},
  },
  ["questlinks"] = { -- Enable Quest Link Support
    text = pfQuest_Loc["Enable Quest Link Support"],
    default = "1", type = "checkbox", pos = { 1, 6},
  },
  ["showids"] = { -- Show Database IDs
    text = pfQuest_Loc["Show Database IDs"],
    default = "0", type = "checkbox", pos = { 1, 7},
  },
  ["favonlogin"] = { -- Draw Favorites On Login
    text = pfQuest_Loc["Draw Favorites On Login"],
    default = "0", type = "checkbox", pos = { 1, 8 },
  },
  ["mindropchance"] = { -- Minimum Item Drop Chance
    text = pfQuest_Loc["Minimum Item Drop Chance"],
    default = "1", type = "text", pos = { 1, 9 },
  },
  ["tooltiphelp"] = { -- Show Help On Tooltips
    text = pfQuest_Loc["Show Help On Tooltips"],
    default = "1", type = "checkbox", pos = { 1, 10 },
  },

  ["_Map & Minimap_"] = {
    text = pfQuest_Loc["Map & Minimap"],
    default = nil, type = "header", pos = { 1, 12 },
  },
  ["minimapnodes"] = { -- Enable Minimap Nodes
    text = pfQuest_Loc["Enable Minimap Nodes"],
    default = "1", type = "checkbox", pos = { 1, 13 },
  },
  ["cutoutminimap"] = { -- Use Cut-Out Minimap Node Icons
    text = pfQuest_Loc["Use Cut-Out Minimap Node Icons"],
    default = "1", type = "checkbox", pos = { 1, 14 },
  },
  ["cutoutworldmap"] = { -- Use Cut-Out World Map Node Icons
    text = pfQuest_Loc["Use Cut-Out World Map Node Icons"],
    default = "0", type = "checkbox", pos = { 1, 15 },
  },
  ["spawncolors"] = { -- Color Map Nodes By Spawn
    text = pfQuest_Loc["Color Map Nodes By Spawn"],
    default = "0", type = "checkbox", pos = { 1, 16 },
  },
  ["worldmaptransp"] = { -- World Map Node Transparency
    text = pfQuest_Loc["World Map Node Transparency"],
    default = "1.0", type = "text", pos = { 1, 17 },
  },
  ["minimaptransp"] = { -- Minimap Node Transparency
    text = pfQuest_Loc["Minimap Node Transparency"],
    default = "1.0", type = "text", pos = { 1, 18 },
  },
  ["nodefade"] = { -- Node Fade Transparency
    text = pfQuest_Loc["Node Fade Transparency"],
    default = "0.3", type = "text", pos = { 1, 19 },
  },
  ["mouseover"] = { -- Highlight Nodes On Mouseover
    text = pfQuest_Loc["Highlight Nodes On Mouseover"],
    default = "1", type = "checkbox", pos = { 1, 20 },
  },

  ["_Questing_"] = {
    text = pfQuest_Loc["Questing"],
    default = nil, type = "header", pos = { 2, 1 },
  },
  ["showcluster"] = { -- Unified Quest Location Markers
    text = pfQuest_Loc["Unified Quest Location Markers"],
    default = "1", type = "checkbox", pos = { 2, 2 },
  },
  ["allquestgivers"] = { -- Display Available Quest Givers
    text = pfQuest_Loc["Display Available Quest Givers"],
    default = "1", type = "checkbox", pos = { 2, 3 },
  },
  ["currentquestgivers"] = { -- Display Current Quest Givers
    text = pfQuest_Loc["Display Current Quest Givers"],
    default = "1", type = "checkbox", pos = { 2, 4 },
  },
  ["showlowlevel"] = { -- Display Low Level Quest Givers
    text = pfQuest_Loc["Display Low Level Quest Givers"],
    default = "0", type = "checkbox", pos = { 2, 5 },
  },
  ["showhighlevel"] = { -- Display Level+3 Questgivers
    text = pfQuest_Loc["Display Level+3 Quest Givers"],
    default = "1", type = "checkbox", pos = { 2, 6 },
  },
  ["showfestival"] = { -- Display Event & Daily Quests
    text = pfQuest_Loc["Display Event & Daily Quests"],
    default = "0", type = "checkbox", pos = { 2, 7 },
  },

  ["_Routes_"] = {
    text = pfQuest_Loc["Routes"],
    default = nil, type = "header", pos = { 2, 9 },
  },
  ["routes"] = { -- Show Route Between Objects
    text = pfQuest_Loc["Show Route Between Objects"],
    default = "1", type = "checkbox", pos = { 2, 10 },
  },
  ["routecluster"] = { -- Include Unified Quest Locations
    text = pfQuest_Loc["Include Unified Quest Locations"],
    default = "1", type = "checkbox", pos = { 2, 11 },
  },
  ["routeender"] = { -- Include Quest Enders
    text = pfQuest_Loc["Include Quest Enders"],
    default = "1", type = "checkbox", pos = { 2, 12 },
  },
  ["routestarter"] = { -- Include Quest Starters
    text = pfQuest_Loc["Include Quest Starters"],
    default = "0", type = "checkbox", pos = { 2, 13 },
  },
  ["routeminimap"] = { -- Show Route On Minimap
    text = pfQuest_Loc["Show Route On Minimap"],
    default = "0", type = "checkbox", pos = { 2, 14 },
  },
  ["arrow"] = { -- Show Arrow Along Routes
    text = pfQuest_Loc["Show Arrow Along Routes"],
    default = "1", type = "checkbox", pos = { 2, 15 },
  },

  ["_User Data_"] = {
    text = pfQuest_Loc["User Data"],
    default = nil, type = "header", pos = { 2, 17 },
  },
  ["btn_settings"] = {
    text = pfQuest_Loc["Reset Configuration"],
    default = "1", type = "button", pos = { 2, 18 }, func = function()
      local dialog = StaticPopupDialogs["PFQUEST_RESET"]
      dialog.text = pfQuest_Loc["Do you really want to reset the configuration?"]
      dialog.OnAccept = function()
        pfQuest_config = nil
        ReloadUI()
      end

      StaticPopup_Show("PFQUEST_RESET")
    end
  },
  ["btn_history"] = {
    text = pfQuest_Loc["Reset Quest History"],
    default = "1", type = "button", pos = { 2, 19 }, func = function()
      local dialog = StaticPopupDialogs["PFQUEST_RESET"]
      dialog.text = pfQuest_Loc["Do you really want to reset the quest history?"]
      dialog.OnAccept = function()
        pfQuest_history = nil
        ReloadUI()
      end

      StaticPopup_Show("PFQUEST_RESET")
    end
  },
  ["btn_everything"] = {
    text = pfQuest_Loc["Reset Everything"],
    default = "1", type = "button", pos = { 2, 20 }, func = function()
      local dialog = StaticPopupDialogs["PFQUEST_RESET"]
      dialog.text = pfQuest_Loc["Do you really want to reset everything?"]
      dialog.OnAccept = function()
        pfQuest_config, pfBrowser_fav, pfQuest_history, pfQuest_colors, pfQuest_server = nil
        ReloadUI()
      end

      StaticPopup_Show("PFQUEST_RESET")
    end
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
pfQuestConfig:SetFrameStrata("HIGH")
pfQuestConfig:SetMovable(true)
pfQuestConfig:EnableMouse(true)
pfQuestConfig:RegisterEvent("ADDON_LOADED")
pfQuestConfig:SetScript("OnEvent", function()
  if arg1 == "pfQuest" or arg1 == "pfQuest-tbc" or arg1 == "pfQuest-wotlk" then
    pfQuestConfig:LoadConfig()
    pfQuestConfig:MigrateHistory()
    pfQuestConfig:CreateConfigEntries(pfQuest_defconfig)

    pfQuest_history = pfQuest_history or {}
    pfQuest_colors = pfQuest_colors or {}
    pfQuest_config = pfQuest_config or {}
    pfBrowser_fav = pfBrowser_fav or {["units"] = {}, ["objects"] = {}, ["items"] = {}, ["quests"] = {}}

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

pfQuestConfig.save = CreateFrame("Button", "pfQuestConfigReload", pfQuestConfig)
pfQuestConfig.save:SetWidth(160)
pfQuestConfig.save:SetHeight(28)
pfQuestConfig.save:SetPoint("BOTTOM", 0, 10)
pfQuestConfig.save:SetScript("OnClick", ReloadUI)
pfQuestConfig.save.text = pfQuestConfig.save:CreateFontString("Caption", "LOW", "GameFontWhite")
pfQuestConfig.save.text:SetAllPoints(pfQuestConfig.save)
pfQuestConfig.save.text:SetFont(pfUI.font_default, pfUI_config.global.font_size, "OUTLINE")
pfQuestConfig.save.text:SetText(pfQuest_Loc["Close & Reload"])
pfUI.api.SkinButton(pfQuestConfig.save)

function pfQuestConfig:LoadConfig()
  if not pfQuest_config then pfQuest_config = {} end
  for opt, data in pairs(pfQuest_defconfig) do
    if not pfQuest_config[opt] then
      pfQuest_config[opt] = data.default
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

local maxh, maxw = 0, 0
local width, height = 230, 22
local maxtext = 130
local configframes = {}
function pfQuestConfig:CreateConfigEntries(config)
  local count = 1
  for entry, data in pairs(config) do
    if data.pos and data.type then
      local spacer = (data.pos[1]-1)*20

      -- basic frame
      local frame = CreateFrame("Frame", "pfQuestConfig" .. count, pfQuestConfig)
      configframes[entry] = frame

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

        frame.input.config = entry
        if pfQuest_config[entry] == "1" then
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

        frame.input.config = entry
        frame.input:SetText(pfQuest_config[entry])

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

      maxw, maxh = max(maxw, data.pos[1]), max(maxh, data.pos[2])
      count = count + 1
    end
  end

  -- update sizes
  width = maxtext + 100
  for entry, data in pairs(config) do
    if data.pos and data.type then
      local spacer = (data.pos[1]-1)*20
      local x, y = (data.pos[1]-1)*width, -(data.pos[2]-1)*height
      local frame = configframes[entry]
      frame:SetWidth(width)
      frame:SetHeight(height)
      frame:SetPoint("TOPLEFT", pfQuestConfig, "TOPLEFT", x + spacer + 10, y - 40)
    end
  end

  local spacer = (maxw-1)*20
  pfQuestConfig:SetWidth(maxw*width + spacer + 20)
  pfQuestConfig:SetHeight(maxh*height + 100)
end
