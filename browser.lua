-- default config
pfBrowser_fav = {["units"] = {}, ["objects"] = {}, ["items"] = {}, ["quests"] = {}}

local search_limit = 100
local tooltip_limit = 5

-- add database shortcuts
local items = pfDB["items"]["data"]
local units = pfDB["units"]["data"]
local objects = pfDB["objects"]["data"]
local quests = pfDB["quests"]["data"]
local zones = pfDB["zones"]["loc"]

local function SelectView(view)
  for id, frame in pairs(pfBrowser.tabs) do
    frame:Hide()
  end
  view:Show()
end

-- sets the browser result values when they change
local function RefreshView(i, key, caption)
  pfBrowser.tabs[key].list:SetHeight(((search_limit > 0 and i >= search_limit) and search_limit or i) * 30 )
  pfBrowser.tabs[key].list:GetParent():SetScrollChild(pfBrowser.tabs[key].list)
  pfBrowser.tabs[key].list:GetParent():SetVerticalScroll(0)
  pfBrowser.tabs[key].list:GetParent():UpdateScrollState()

  pfBrowser.tabs[key].button:SetText(caption .. " " .. "|cffaaaaaa(" .. ((search_limit > 0 and i >= search_limit) and search_limit.."/"..i or i) .. ")")
  for j=i+1,search_limit do
    if pfBrowser.tabs[key].buttons[j] then pfBrowser.tabs[key].buttons[j]:Hide() end
  end
end

-- sets up all the browse windows and their activation buttons
local function CreateBrowseWindow(fname, name, parent, anchor, x, y)
  if not parent.tabs then parent.tabs = {} end
  parent.tabs[fname] = pfUI.api.CreateScrollFrame(name, parent)
  parent.tabs[fname]:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -65)
  parent.tabs[fname]:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -10, 45)
  parent.tabs[fname].buttons = { }

  parent.tabs[fname].backdrop = CreateFrame("Frame", name .. "Backdrop", parent.tabs[fname])
  parent.tabs[fname].backdrop:SetFrameLevel(1)
  parent.tabs[fname].backdrop:SetPoint("TOPLEFT", parent.tabs[fname], "TOPLEFT", -5, 5)
  parent.tabs[fname].backdrop:SetPoint("BOTTOMRIGHT", parent.tabs[fname], "BOTTOMRIGHT", 5, -5)
  pfUI.api.CreateBackdrop(parent.tabs[fname].backdrop, nil, true)

  parent.tabs[fname].button = CreateFrame("Button", name .. "Button", parent)
  parent.tabs[fname].button:SetPoint(anchor, x, y)
  parent.tabs[fname].button:SetWidth(153)
  parent.tabs[fname].button:SetHeight(30)
  parent.tabs[fname].button:SetScript("OnClick", function()
    SelectView(parent.tabs[fname])
  end)

  parent.tabs[fname].button.text = parent.tabs[fname].button:CreateFontString("Caption", "LOW", "GameFontWhite")
  parent.tabs[fname].button.text:SetAllPoints(parent.tabs[fname].button)
  parent.tabs[fname].button.text:SetFont(pfUI.font_default, pfUI_config.global.font_size, "OUTLINE")
  pfUI.api.SkinButton(parent.tabs[fname].button)

  parent.tabs[fname].list = pfUI.api.CreateScrollChild(name .. "Scroll", parent.tabs[fname])
  parent.tabs[fname].list:SetWidth(600)
end

local function ReplaceQuestDetailWildcards(questText)
  questText = string.gsub(questText, "$[Nn]", UnitName("player"))
  questText = string.gsub(questText, "$[Cc]", strlower(UnitClass("player")))
  questText = string.gsub(questText, "$[Rr]", strlower(UnitRace("player")))
  questText = string.gsub(questText, "$[Bb]", "\n") -- new lines
  -- UnitSex("player") returns 2 for male and 3 for female
  -- that's why there is an unused capture group around the $[Gg]
  return string.gsub(questText, "($[Gg])(.+):(.+);", "%"..UnitSex("player"))
end


-- creates a result button for an arbitrary type (units/objects/items/quests)
-- returns the button frame
local function CreateResultEntry(i, resultType)
  local f = CreateFrame("Button", nil, pfBrowser.tabs[resultType].list)
  f:SetPoint("TOPLEFT", pfBrowser.tabs[resultType].list, "TOPLEFT", 10, -i*30 + 5)
  f:SetPoint("BOTTOMRIGHT", pfBrowser.tabs[resultType].list, "TOPRIGHT", 10, -i*30 - 15)
  f.tex = f:CreateTexture("BACKGROUND")
  f.tex:SetAllPoints(f)

-- Common logic

  -- line coloring
  if math.mod(i,2) == 1 then
    f.tex:SetTexture(1,1,1,.02)
  else
    f.tex:SetTexture(1,1,1,.04)
  end

  -- un-highlight and hide tooltip
  f:SetScript("OnLeave", function()
    if math.mod(i,2) == 1 then
      this.tex:SetTexture(1,1,1,.02)
    else
      this.tex:SetTexture(1,1,1,.04)
    end
    GameTooltip:Hide()
  end)

  -- text properties
  f.text = f:CreateFontString("Caption", "LOW", "GameFontWhite")
  f.text:SetAllPoints(f)
  f.text:SetJustifyH("CENTER")
  f.idText = f:CreateFontString("ID", "LOW", "GameFontDisable")
  f.idText:SetPoint("LEFT", f, "LEFT", 30, 0)

  -- favourite button
  f.fav = CreateFrame("Button", nil, f)
  f.fav:SetHitRectInsets(-3,-3,-3,-3)
  f.fav:SetPoint("LEFT", 0, 0)
  f.fav:SetWidth(16)
  f.fav:SetHeight(16)
  f.fav.icon = f.fav:CreateTexture("OVERLAY")
  f.fav.icon:SetTexture("Interface\\AddOns\\pfQuest\\img\\fav")
  f.fav.icon:SetAllPoints(f.fav)
  f.fav:SetScript("OnClick", function()
    local id = this:GetParent().id
    if pfBrowser_fav[resultType][id] then
      pfBrowser_fav[resultType][id] = nil
      this.icon:SetVertexColor(1,1,1,.1)
    else
      pfBrowser_fav[resultType][id] = true
      this.icon:SetVertexColor(1,1,1,1)
    end
  end)

-- Type specific logic

  -- faction icons
  -- unused by items, but used by units, objects and quests
  if resultType ~= "items" then
    f.factionA = f:CreateTexture("OVERLAY")
    f.factionA:SetTexture("Interface\\AddOns\\pfQuest\\img\\icon_alliance")
    f.factionA:SetWidth(16)
    f.factionA:SetHeight(16)
    f.factionA:SetPoint("RIGHT", -5, 0)
    f.factionH = f:CreateTexture("OVERLAY")
    f.factionH:SetTexture("Interface\\AddOns\\pfQuest\\img\\icon_horde")
    f.factionH:SetWidth(16)
    f.factionH:SetHeight(16)
    f.factionH:SetPoint("RIGHT", -24, 0)
  end

  -- items only
  if resultType == "items" then
    f:SetScript("OnEnter", function()
      this.tex:SetTexture(1,1,1,.1)
      GameTooltip:SetOwner(this.text, "ANCHOR_LEFT", -10, -5)
      GameTooltip:SetHyperlink("item:" .. this.id .. ":0:0:0")
      GameTooltip:AddLine("\nID: "..this.id, 0.8,0.8,0.8)
      GameTooltip:Show()
    end)

    f:SetScript("OnClick", function()
      local link = "item:"..this.id..":0:0:0"
      local text = ( this.itemColor or "|cffffffff" ) .."|H" .. link .. "|h["..this.name.."]|h|r"
      SetItemRef(link, text, arg1)
    end)

    -- definitions for the small drop/sell/quest icons at the end of the button
    local buttons = {
      ["U"] = {
        ["offset"] = -5,
        ["icon"] = "icon_npc",
        ["parameter"] = "id",
        ["OnEnter"] = function()
          local id = this:GetParent().id
          GameTooltip:SetOwner(pfBrowser, "ANCHOR_CURSOR")
          local count = 0
          local skip = false
          if items[id]["U"] then
            GameTooltip:SetText("Looted from", .3, 1, .8)
            for unitID, chance in pairs(items[id]["U"]) do
              count = count + 1
              if count > tooltip_limit then
                skip = true
              end
              if units[unitID] and not skip then
                local name = pfDB.units.loc[unitID]
                local zone = nil
                if units[unitID].coords then
                  zone = units[unitID].coords[1][3]
                end
                GameTooltip:AddDoubleLine(name, ( zone and pfMap:GetMapNameByID(zone) or UNKNOWN), 1,1,1, .5,.5,.5)
              end
            end
            if count > tooltip_limit then GameTooltip:AddLine("\nand "..(count - tooltip_limit).." others.",.8,.8,.8) end
            GameTooltip:Show()
          end
        end,
      },
      ["O"] = {
        ["offset"] = -24,
        ["icon"] = "icon_object",
        ["parameter"] = "id",
        ["OnEnter"] = function()
          local id = this:GetParent().id
          GameTooltip:SetOwner(pfBrowser, "ANCHOR_CURSOR")
          local count = 0
          local skip = false
          if items[id]["O"] then
            GameTooltip:SetText("Looted from", .3, 1, .8)
            for objectID, chance in pairs(items[id]["O"]) do
              count = count + 1
              if count > tooltip_limit then
                skip = true
              end
              if objects[objectID] and not skip then
                local name = pfDB.objects.loc[objectID] or objectID
                local zone = nil
                if objects[objectID].coords then
                  zone = objects[objectID].coords[1][3]
                end
                GameTooltip:AddDoubleLine(name, ( zone and pfMap:GetMapNameByID(zone) or UNKNOWN), 1,1,1, .5,.5,.5)
              elseif not skip then
                GameTooltip:AddLine((pfDB.objects.loc[objectID] or "ID: "..objectID).." (missing Data)")
              end
            end
            if count > tooltip_limit then GameTooltip:AddLine("\nand "..(count - tooltip_limit).." others.",.8,.8,.8) end
            GameTooltip:Show()
          end
        end,
      },
      ["V"] = {
        ["offset"] = -43,
        ["icon"] = "icon_vendor",
        ["parameter"] = "name",
        ["OnEnter"] = function()
          local id = this:GetParent().id
          GameTooltip:SetOwner(pfBrowser, "ANCHOR_CURSOR")
          local count = 0
          local skip = false
          if items[id]["V"] then
            GameTooltip:SetText("Sold by", .3, 1, .8)
            for unitID, sellcount in pairs(items[id]["V"]) do
              count = count + 1
              if count > tooltip_limit then
                skip = true
              end
              if units[unitID] and not skip then
                local name = pfDB.units.loc[unitID]
                if sellcount ~= 0 then name = name .. " (" .. sellcount .. ")" end
                local zone = units[unitID].coords[1][3]
                GameTooltip:AddDoubleLine(name, ( zone and pfMap:GetMapNameByID(zone) or UNKNOWN), 1,1,1, .5,.5,.5)
              end
            end
            if count > tooltip_limit then GameTooltip:AddLine("\nand "..(count - tooltip_limit).." others.",.8,.8,.8) end
          end
          GameTooltip:Show()
        end,
      },
      --[[TODO: add extractor support
      ["Q"] = {
        ["offset"] = -62,
        ["icon"] = "available",
        ["parameter"] = "id",
        ["OnEnter"] = function()
        end),
      },
      ["I"] = {
        ["offset"] = -81,
        ["icon"] = nil,
        ["parameter"] = "id",
        ["OnEnter"] = function()
        end),
      },--]]
    }
    for key, values in pairs(buttons) do
      f[key] = CreateFrame("Button", nil, f)
      f[key]:SetHitRectInsets(-3,-3,-3,-3)
      f[key]:SetPoint("RIGHT", values.offset, 0)
      f[key]:SetWidth(16)
      f[key]:SetHeight(16)
      f[key].buttonType = key
      f[key].parameter = values.parameter
      f[key].icon = f[key]:CreateTexture("OVERLAY")
      f[key].icon:SetAllPoints(f[key])
      f[key].icon:SetTexture("Interface\\AddOns\\pfQuest\\img\\"..values.icon)
      f[key]:SetScript("OnClick", function()
        local param = this:GetParent()[this.parameter]
        local maps
        if this.buttonType == "O" or this.buttonType == "U" then
          maps = pfDatabase:SearchItemID(param, nil, nil, {[this.buttonType]=true})
        elseif this.buttonType == "V" then
          maps = pfDatabase:SearchVendor(param)
        --[[TODO: add extractor support and implement functions
        elseif this.buttonType == "Q" then
          maps = pfDatabase:SearchQuestRewards(param)
        elseif this.buttonType == "I" then
          maps = pfDatabase:SearchItemsInItems(param)--]]
        end
        pfMap:UpdateNodes()
        pfMap:ShowMapID(pfDatabase:GetBestMap(maps))
      end)
      f[key]:SetScript("OnEnter", values.OnEnter)
      f[key]:SetScript("OnLeave", function()
        GameTooltip:Hide()
      end)
    end -- end of items
  -- quests only
  elseif resultType == "quests" then
    f:SetScript("OnEnter", function()
      this.tex:SetTexture(1,1,1,.1)
      GameTooltip:SetOwner(this.text, "ANCHOR_LEFT", -10, -5)
      GameTooltip:SetText(this.name, .3, 1, .8)
      local questTexts = pfDB[resultType]["loc"][this.id]
      local questData = pfDB[resultType]["data"][this.id]
      GameTooltip:AddLine(" ")
      if questData.lvl then
        GameTooltip:AddDoubleLine("|cffffff00Quest Level: |r", questData.lvl, 1,1,1, 1,1,1)
      end
      if questData.min then
        GameTooltip:AddDoubleLine("|cffffff00Required Level: |r", questData.min, 1,1,1, 1,1,1)
      end
      if questData["start"] or questData["end"] then
        local function StartAndFinish(startOrFinish, types)
          local strings = {["start"]="Started by ", ["end"]="Finished by "}
          for _, key in ipairs(types) do
            if questData[startOrFinish] and questData[startOrFinish][key] then
              local typeName = {["U"]="units",["O"]="objects",["I"]="items"}
              GameTooltip:AddLine("\n|cffffff00"..strings[startOrFinish]..typeName[key]..":|r")
              for _,id in ipairs(questData[startOrFinish][key]) do
                local name = pfDB[typeName[key]]["loc"][id] or id
                GameTooltip:AddDoubleLine(" ", name, 0,0,0, 1,1,1)
              end
            end
          end
        end
        StartAndFinish("start", {"U","O","I"})
        StartAndFinish("end", {"U","O"})
      end
      if questTexts["O"] and questTexts["O"] ~= "" then
        GameTooltip:AddLine("\n|cffffff00Objectives: |r"..ReplaceQuestDetailWildcards(questTexts["O"]), 1,1,1,true)
      end
      if questTexts["D"] and questTexts["D"] ~= "" then
        GameTooltip:AddLine("\n|cffffff00Details: |r"..ReplaceQuestDetailWildcards(questTexts["D"]), .6,1,.9,true)
      end
      GameTooltip:AddLine("\nID: "..this.id, 0.8,0.8,0.8)
      GameTooltip:Show()
    end)

    f:SetScript("OnClick", function()
      if IsShiftKeyDown() then
        ChatFrameEditBox:Show()
        ChatFrameEditBox:Insert("|cffffff00|Hquest:0:0:0:0|h[" .. this.name .. "]|h|r")
      else
        local meta = { ["addon"] = "PFDB" }
        local maps = pfDatabase:SearchQuestID(this.id, meta)
        pfMap:ShowMapID(pfDatabase:GetBestMap(maps))
      end
    end) -- end of quests
  -- units and objects
  elseif resultType == "units" or resultType == "objects" then
    f:SetScript("OnEnter", function()
      this.tex:SetTexture(1,1,1,.1)
      local id = this.id
      local name = this.name
      local maps = {}
      GameTooltip:SetOwner(this.text, "ANCHOR_LEFT", -10, -5)
      GameTooltip:SetText(name, .3, 1, .8)
      if resultType == "units" then
        local unitData = units[id]
        if unitData.lvl then
          GameTooltip:AddDoubleLine("|cffffff00Level:|r", unitData.lvl, 0,0,0, 1,1,1)
        end
        local reactionStringA = "|c00ff0000Hostile|r"
        local reactionStringH = "|c00ff0000Hostile|r"
        if unitData.fac then
          if unitData.fac == "AH" then
            reactionStringA = "|c0000ff00Friendly|r"
            reactionStringH = "|c0000ff00Friendly|r"
          elseif unitData.fac == "A" then
            reactionStringA = "|c0000ff00Friendly|r"
          elseif unitData.fac == "H" then
            reactionStringH = "|c0000ff00Friendly|r"
          end
        end
        GameTooltip:AddLine("|cffffff00Reactions:|r", 1,1,1)
        GameTooltip:AddDoubleLine("Alliance", reactionStringA, 1,1,1, 0,0,0)
        GameTooltip:AddDoubleLine("Horde", reactionStringH, 1,1,1, 0,0,0)
      end
      GameTooltip:AddLine("\n|cffffff00Located in:|r", 1,1,1)
      if pfDB[resultType]["data"][id] and pfDB[resultType]["data"][id]["coords"] then
        for _, data in pairs(pfDB[resultType]["data"][id]["coords"]) do
          local zone = data[3]
          maps[zone] = maps[zone] and maps[zone] + 1 or 1
        end
      else
        GameTooltip:AddLine(UNKNOWN, 1,.5,.5)
      end
      for zone, count in pairs(maps) do
        GameTooltip:AddDoubleLine(( zone and pfMap:GetMapNameByID(zone) or UNKNOWN), count .. "x", 1,1,1, .5,.5,.5)
      end
      GameTooltip:AddLine("\nID: "..this.id, 0.8,0.8,0.8)
      GameTooltip:Show()
    end)

    if resultType == "units" then
      f:SetScript("OnClick", function()
        local maps = pfDatabase:SearchMobID(this.id)
        pfMap:UpdateNodes()
        pfMap:ShowMapID(pfDatabase:GetBestMap(maps))
      end)
    elseif resultType == "objects" then
      f:SetScript("OnClick", function()
        local maps = pfDatabase:SearchObjectID(this.id)
        pfMap:UpdateNodes()
        pfMap:ShowMapID(pfDatabase:GetBestMap(maps))
      end)
    end
  end -- end of units and objects
  return f
end

-- minimap icon

pfBrowserIcon = CreateFrame('Button', "pfBrowserIcon", Minimap)
pfBrowserIcon:SetClampedToScreen(true)
pfBrowserIcon:SetMovable(true)
pfBrowserIcon:EnableMouse(true)
pfBrowserIcon:RegisterForDrag('LeftButton')
pfBrowserIcon:RegisterForClicks('LeftButtonUp', 'RightButtonUp')
pfBrowserIcon:SetScript("OnDragStart", function()
  if IsShiftKeyDown() then
    this:StartMoving()
  end
end)
pfBrowserIcon:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
pfBrowserIcon:SetScript("OnClick", function()
  if arg1 == "RightButton" then
    if pfQuestConfig:IsShown() then pfQuestConfig:Hide() else pfQuestConfig:Show() end
  else
    if pfBrowser:IsShown() then pfBrowser:Hide() else pfBrowser:Show() end
  end
end)

pfBrowserIcon:SetScript("OnEnter", function()
  GameTooltip:SetOwner(this, ANCHOR_BOTTOMLEFT)
  GameTooltip:SetText("pfQuest")
  GameTooltip:AddDoubleLine("Left-Click", "Open Browser", 1, 1, 1, 1, 1, 1)
  GameTooltip:AddDoubleLine("Right-Click", "Open Configuration", 1, 1, 1, 1, 1, 1)
  GameTooltip:AddDoubleLine("Shift-Click", "Move Button", 1, 1, 1, 1, 1, 1)
  GameTooltip:Show()
end)

pfBrowserIcon:SetScript("OnLeave", function()
  GameTooltip:Hide()
end)

pfBrowserIcon:SetFrameStrata('LOW')
pfBrowserIcon:SetWidth(31)
pfBrowserIcon:SetHeight(31)
pfBrowserIcon:SetFrameLevel(9)
pfBrowserIcon:SetHighlightTexture('Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight')
pfBrowserIcon:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 0, 0)

pfBrowserIcon.overlay = pfBrowserIcon:CreateTexture(nil, 'OVERLAY')
pfBrowserIcon.overlay:SetWidth(53)
pfBrowserIcon.overlay:SetHeight(53)
pfBrowserIcon.overlay:SetTexture('Interface\\Minimap\\MiniMap-TrackingBorder')
pfBrowserIcon.overlay:SetPoint('TOPLEFT', 0,0)

pfBrowserIcon.icon = pfBrowserIcon:CreateTexture(nil, 'BACKGROUND')
pfBrowserIcon.icon:SetWidth(20)
pfBrowserIcon.icon:SetHeight(20)
pfBrowserIcon.icon:SetTexture('Interface\\AddOns\\pfQuest\\img\\logo')
pfBrowserIcon.icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)
pfBrowserIcon.icon:SetPoint('CENTER',1,1)

-- browser window

pfBrowser = CreateFrame("Frame", "pfQuestBrowser", UIParent)
pfBrowser:Hide()
pfBrowser:SetWidth(640)
pfBrowser:SetHeight(480)
pfBrowser:SetPoint("CENTER", 0, 0)
pfBrowser:SetFrameStrata("FULLSCREEN_DIALOG")
pfBrowser:SetMovable(true)
pfBrowser:EnableMouse(true)
pfBrowser:SetScript("OnMouseDown",function()
  this:StartMoving()
end)

pfBrowser:SetScript("OnMouseUp",function()
  this:StopMovingOrSizing()
end)

pfUI.api.CreateBackdrop(pfBrowser, nil, true, 0.75)
table.insert(UISpecialFrames, "pfQuestBrowser")

pfBrowser.title = pfBrowser:CreateFontString("Status", "LOW", "GameFontNormal")
pfBrowser.title:SetFontObject(GameFontWhite)
pfBrowser.title:SetPoint("TOP", pfBrowser, "TOP", 0, -8)
pfBrowser.title:SetJustifyH("LEFT")
pfBrowser.title:SetFont(pfUI.font_default, 14)
pfBrowser.title:SetText("|cff33ffccpf|rQuest")

-- close button

pfBrowser.close = CreateFrame("Button", "pfQuestBrowserClose", pfBrowser)
pfBrowser.close:SetPoint("TOPRIGHT", -5, -5)
pfBrowser.close:SetHeight(12)
pfBrowser.close:SetWidth(12)
pfBrowser.close.texture = pfBrowser.close:CreateTexture("pfQuestionDialogCloseTex")
pfBrowser.close.texture:SetTexture("Interface\\AddOns\\pfQuest\\compat\\close")
pfBrowser.close.texture:ClearAllPoints()
pfBrowser.close.texture:SetAllPoints(pfBrowser.close)
pfBrowser.close.texture:SetVertexColor(1,.25,.25,1)
pfUI.api.SkinButton(pfBrowser.close, 1, .5, .5)
pfBrowser.close:SetScript("OnClick", function()
 this:GetParent():Hide()
end)

-- clean button

pfBrowser.clean = CreateFrame("Button", "pfQuestBrowserClean", pfBrowser)
pfBrowser.clean:SetPoint("TOPLEFT", pfBrowser, "TOPLEFT", 545, -30)
pfBrowser.clean:SetPoint("BOTTOMRIGHT", pfBrowser, "TOPRIGHT", -5, -55)
pfBrowser.clean:SetScript("OnClick", function()
  pfMap:DeleteNode("PFDB")
  pfMap:UpdateNodes()
end)
pfBrowser.clean.text = pfBrowser.clean:CreateFontString("Caption", "LOW", "GameFontWhite")
pfBrowser.clean.text:SetAllPoints(pfBrowser.clean)
pfBrowser.clean.text:SetFont(pfUI.font_default, pfUI_config.global.font_size, "OUTLINE")
pfBrowser.clean.text:SetText("Clean Map")
pfUI.api.SkinButton(pfBrowser.clean)

-- browser tabs

CreateBrowseWindow("units", "pfQuestBrowserUnits", pfBrowser, "BOTTOMLEFT", 5, 5)
CreateBrowseWindow("objects", "pfQuestBrowserObjects", pfBrowser, "BOTTOMLEFT", 164, 5)
CreateBrowseWindow("items", "pfQuestBrowserItems", pfBrowser, "BOTTOMRIGHT", -164, 5)
CreateBrowseWindow("quests", "pfQuestBrowserQuests", pfBrowser, "BOTTOMRIGHT", -5, 5)

SelectView(pfBrowser.tabs["units"])

-- input frame

pfBrowser.input = CreateFrame("EditBox", "pfQuestBrowserSearch", pfBrowser)
pfBrowser.input:SetFont(pfUI.font_default, pfUI_config.global.font_size, "OUTLINE")
pfBrowser.input:SetAutoFocus(false)
pfBrowser.input:SetText("Search")
pfBrowser.input:SetJustifyH("LEFT")
pfBrowser.input:SetPoint("TOPLEFT", pfBrowser, "TOPLEFT", 5, -30)
pfBrowser.input:SetPoint("BOTTOMRIGHT", pfBrowser, "TOPRIGHT", -100, -55)
pfBrowser.input:SetTextInsets(10,10,5,5)
pfBrowser.input:SetScript("OnEscapePressed", function() this:ClearFocus() end)
pfBrowser.input:SetScript("OnEditFocusGained", function()
  if this:GetText() == "Search" then this:SetText("") end
end)

pfBrowser.input:SetScript("OnEditFocusLost", function()
  if this:GetText() == "" then this:SetText("Search") end
end)

-- This script updates all the search tabs when the search text changes
pfBrowser.input:SetScript("OnTextChanged", function()
  local text = this:GetText() -- get search query
  if (text == "Search") then text = "" end -- catch empty input without focus
  -- for each search type, get the matching IDs and add buttons for them
  for _, caption in ipairs({"Units","Objects","Items","Quests"}) do
    local searchType = strlower(caption)
    local ids = pfDatabase:GenericSearch(text, searchType)
    local i = 0;
    local skip = false
    -- iterate the IDs and create/re-use buttons
    for id, _ in pairs(ids) do
      -- count towards limit, abort if limit is set and reached
      i = i + 1
      if (search_limit > 0) and (i >= search_limit) then skip = true end
      if not skip then
        --create button if neccessary
        if (not pfBrowser.tabs[searchType].buttons[i]) then
          pfBrowser.tabs[searchType].buttons[i] = CreateResultEntry(i, searchType)
        end
        local button = pfBrowser.tabs[searchType].buttons[i]
        button.id = id
        if pfQuest_config.showids == "1" then
          button.idText:SetText("ID: "..id)
          button.idText:Show()
        else
          button.idText:Hide()
        end
        local nameOrQuestLoc = pfDB[searchType]["loc"][id]
        -- handle faction icons
        if (searchType ~= "items") then
          button.factionA:Hide()
          button.factionH:Hide()
          -- 64 + 8 + 4 + 1 = 77 = Alliance
          -- 128 + 32 + 16 + 2 = 178 = Horde
          local factionMap = {["A"]=77,["H"]=178,["AH"]=255,["HA"]=255}
          local raceMask = 0
          if (searchType == "quests") then
            -- get the quest raceMask
            if (quests[id]["race"]) then
              raceMask = quests[id]["race"]
            end
            -- TODO get this data during extraction
            -- horribly hack for quests with unassigned/wrong raceMask
            if (quests[id]["start"]) then
              local questStartRaceMask = 0
              -- check units starting this quest for being friendly
              if (quests[id]["start"]["U"]) then
                for _, startUnitId in ipairs(quests[id]["start"]["U"]) do
                  if (units[startUnitId]["fac"]) then
                    questStartRaceMask = bit.bor(factionMap[units[startUnitId]["fac"]])
                  end
                end
              end
              -- check objects starting this quest for being friendly
              if (quests[id]["start"]["O"]) then
                for _, startObjectId in ipairs(quests[id]["start"]["O"]) do
                  if (objects[startObjectId]["fac"]) then
                    questStartRaceMask = bit.bor(factionMap[objects[startObjectId]["fac"]])
                  end
                end
              end
              if (questStartRaceMask > 0) and (questStartRaceMask ~= raceMask) then
                raceMask = questStartRaceMask
              end
            end
          else
            -- get unit/object race mask
            if (pfDB[searchType]["data"]["fac"]) then
              raceMask = factionMap[pfDB[searchType]["data"]["fac"]]
            end
          end
          -- show faction buttons if needed
          if (bit.band(77, raceMask) > 0)  or (raceMask == 0 and searchType == "quests") then
            button.factionA:Show()
          end
          if (bit.band(178, raceMask) > 0)  or (raceMask == 0 and searchType == "quests") then
            button.factionH:Show()
          end
        end
        -- activate fav buttons if needed
        if pfBrowser_fav[searchType][id] then
          button.fav.icon:SetVertexColor(1,1,1,1)
        else
          button.fav.icon:SetVertexColor(1,1,1,.1)
        end
        -- actions by search type
        if searchType == "quests" then
          button.name = pfDB[searchType]["loc"][id]["T"]
          button.text:SetText("|cffffcc00|Hquest:0:0:0:0|h[" .. button.name .. "]|h|r")
        elseif searchType == "units" or searchType == "objects" then
          local level = pfDB[searchType]["data"][id]["lvl"] or ""
          if level ~= "" then level = " ("..level..")" end
          button.name = nameOrQuestLoc
          button.text:SetText(nameOrQuestLoc .. "|cffaaaaaa" .. level)
          if pfDB[searchType]["data"][id]["coords"] then
            button.text:SetTextColor(1,1,1)
          else
            button.text:SetTextColor(.5,.5,.5)
          end
        elseif searchType == "items" then
          button.name = nameOrQuestLoc
          -- trigger item scan
          GameTooltip:SetHyperlink("item:" .. id .. ":0:0:0")
          GameTooltip:Hide()
          button.text:SetText("|cffff5555[?] |cffffffff" .. nameOrQuestLoc)
          --TODO extractor update for quests and items from items
          for _, key in ipairs({"U","O","V"}) do
            if items[id][key] then
              button[key]:Show()
            else
              button[key]:Hide()
            end
          end
        end
        -- refresh item quality
        button:SetScript("OnUpdate", function()
          local _, _, itemQuality = GetItemInfo(this.id)
          if itemQuality then
            this.itemColor = "|c" .. string.format("%02x%02x%02x%02x", 255,
                ITEM_QUALITY_COLORS[itemQuality].r * 255,
                ITEM_QUALITY_COLORS[itemQuality].g * 255,
                ITEM_QUALITY_COLORS[itemQuality].b * 255)

            this.text:SetText(this.itemColor .."|Hitem:"..this.id..":0:0:0|h[".. this.name.."]|h|r")
            this.text:SetWidth(this.text:GetStringWidth())
            this:SetScript("OnUpdate", nil)
          end
        end)
        button.text:SetWidth(button.text:GetStringWidth())
        button:Show()
      end
    end
    RefreshView(i, searchType, caption)
  end
end)

pfUI.api.CreateBackdrop(pfBrowser.input, nil, true)
