-- default config
pfDatabase_fav = { ["spawn"] = {}, ["item"] = {}, ["quest"] = {} }

local search_limit = 100

-- add database shortcuts
local items = pfDatabase["items"]
local quests = pfDatabase["quests"]
local vendors = pfDatabase["vendors"]
local spawns = pfDatabase["spawns"]

local function SelectView(view)
  for id, frame in pairs(pfBrowser.tabs) do
    frame:Hide()
  end
  view:Show()
end

local function RefreshView(i, key, caption)
  pfBrowser.tabs[key].list:SetHeight( i * 30 )
  pfBrowser.tabs[key].list:GetParent():SetScrollChild(pfBrowser.tabs[key].list)
  pfBrowser.tabs[key].list:GetParent():SetVerticalScroll(0)
  pfBrowser.tabs[key].list:GetParent():UpdateScrollState()

  pfBrowser.tabs[key].button:SetText(caption .. " " .. "|cffaaaaaa(" .. ((i == search_limit) and "..." or i) .. ")")
  for j=i+1,search_limit do
    if pfBrowser.tabs[key].buttons[j] then pfBrowser.tabs[key].buttons[j]:Hide() end
  end
end

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
  parent.tabs[fname].button:SetWidth(207)
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

local function CreateSpawnEntry(i)
  local f = CreateFrame("Button", nil, pfBrowser.tabs.spawn.list)
  f:SetPoint("TOPLEFT", pfBrowser.tabs.spawn.list, "TOPLEFT", 10, -i*30 + 5)
  f:SetPoint("BOTTOMRIGHT", pfBrowser.tabs.spawn.list, "TOPRIGHT", 10, -i*30 - 15)
  f.tex = f:CreateTexture("BACKGROUND")
  f.tex:SetAllPoints(f)

  if math.mod(i,2) == 1 then
    f.tex:SetTexture(1,1,1,.02)
  else
    f.tex:SetTexture(1,1,1,.04)
  end

  f:SetScript("OnEnter", function()
    this.tex:SetTexture(1,1,1,.1)

    local name = this.name
    local maps = { }

    GameTooltip:SetOwner(this.text, "ANCHOR_LEFT", -10, -5)
    GameTooltip:SetText("Located in", .3, 1, .8)

    if spawns[name] and spawns[name]["coords"] then
      for id, data in pairs(spawns[name]["coords"]) do
        local f, t, x, y, zone = strfind(data, "(.*),(.*),(.*)")
        maps[zone] = maps[zone] and maps[zone] + 1 or 1
      end
    else
      GameTooltip:AddLine(UNKNOWN, 1,.5,.5)
    end

    for zone, count in pairs(maps) do
      GameTooltip:AddDoubleLine(( zone and pfMap:GetMapNameByID(zone) or UNKNOWN), count .. "x", 1,1,1, .5,.5,.5)
    end

    GameTooltip:Show()
  end)

  f:SetScript("OnLeave", function()
    if math.mod(i,2) == 1 then
      this.tex:SetTexture(1,1,1,.02)
    else
      this.tex:SetTexture(1,1,1,.04)
    end
    GameTooltip:Hide()
  end)

  f:SetScript("OnClick", function()
    local map = pfDatabase:SearchMob(this.name)
    pfMap:UpdateNodes()
    pfMap:ShowMapID(map)
  end)

  f.text = f:CreateFontString("Caption", "LOW", "GameFontWhite")
  f.text:SetPoint("CENTER", 0, 0)
  f.text:SetJustifyH("CENTER")

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

  f.fav = CreateFrame("Button", nil, f)
  f.fav:SetHitRectInsets(-3,-3,-3,-3)
  f.fav:SetPoint("LEFT", 0, 0)
  f.fav:SetWidth(16)
  f.fav:SetHeight(16)
  f.fav.icon = f.fav:CreateTexture("OVERLAY")
  f.fav.icon:SetTexture("Interface\\AddOns\\pfQuest\\img\\fav")
  f.fav.icon:SetAllPoints(f.fav)

  f.fav:SetScript("OnClick", function()
    local name = this:GetParent().name
    if pfDatabase_fav["spawn"][name] then
      pfDatabase_fav["spawn"][name] = nil
      this.icon:SetVertexColor(1,1,1,.1)
    else
      pfDatabase_fav["spawn"][name] = true
      this.icon:SetVertexColor(1,1,1,1)
    end
  end)

  return f
end

local function CreateItemEntry(i)
  local f = CreateFrame("Button", nil, pfBrowser.tabs.item.list)
  f:SetPoint("TOPLEFT", pfBrowser.tabs.item.list, "TOPLEFT", 10, -i*30 + 5)
  f:SetPoint("BOTTOMRIGHT", pfBrowser.tabs.item.list, "TOPRIGHT", 10, -i*30 - 15)
  f.tex = f:CreateTexture("BACKGROUND")
  f.tex:SetAllPoints(f)

  if math.mod(i,2) == 1 then
    f.tex:SetTexture(1,1,1,.02)
  else
    f.tex:SetTexture(1,1,1,.04)
  end

  f:SetScript("OnEnter", function()
    this.tex:SetTexture(1,1,1,.1)

    GameTooltip:SetOwner(this.text, "ANCHOR_LEFT", -10, -5)
    GameTooltip:SetHyperlink("item:" .. this.itemID .. ":0:0:0")
    GameTooltip:Show()
  end)

  f:SetScript("OnLeave", function()
    if math.mod(i,2) == 1 then
      this.tex:SetTexture(1,1,1,.02)
    else
      this.tex:SetTexture(1,1,1,.04)
    end

    --this.text:SetTextColor(1,1,1,1)
    GameTooltip:Hide()
  end)

  f:SetScript("OnClick", function()
    if IsShiftKeyDown() then
      ChatFrameEditBox:Show()
      ChatFrameEditBox:Insert(this.itemColor .."|Hitem:"..this.itemID..":0:0:0|h["..this.itemName.."]|h|r")
    elseif IsControlKeyDown() then
      DressUpItemLink(this.itemID)
    else
      ShowUIPanel(ItemRefTooltip)
      ItemRefTooltip:SetOwner(UIParent, "ANCHOR_PRESERVE")
      ItemRefTooltip:SetHyperlink("item:" .. this.itemID .. ":0:0:0")
    end
  end)

  f.text = f:CreateFontString("Caption", "LOW", "GameFontWhite")
  f.text:SetPoint("CENTER", 0, 0)
  f.text:SetJustifyH("CENTER")

  f.fav = CreateFrame("Button", nil, f)
  f.fav:SetHitRectInsets(-3,-3,-3,-3)
  f.fav:SetPoint("LEFT", 0, 0)
  f.fav:SetWidth(16)
  f.fav:SetHeight(16)
  f.fav.icon = f.fav:CreateTexture("OVERLAY")
  f.fav.icon:SetTexture("Interface\\AddOns\\pfQuest\\img\\fav")
  f.fav.icon:SetAllPoints(f.fav)

  f.fav:SetScript("OnClick", function()
    local name = this:GetParent().itemName
    if pfDatabase_fav["item"][name] then
      pfDatabase_fav["item"][name] = nil
      this.icon:SetVertexColor(1,1,1,.1)
    else
      pfDatabase_fav["item"][name] = true
      this.icon:SetVertexColor(1,1,1,1)
    end
  end)

  f.loot = CreateFrame("Button", nil, f)
  f.loot:SetHitRectInsets(-3,-3,-3,-3)
  f.loot:SetPoint("RIGHT", -5, 0)
  f.loot:SetWidth(16)
  f.loot:SetHeight(16)
  f.loot.icon = f.loot:CreateTexture("OVERLAY")
  f.loot.icon:SetAllPoints(f.loot)

  f.loot:SetScript("OnClick", function()
    local name = this:GetParent().itemName
    local map = pfDatabase:SearchItem(name)
    pfMap:UpdateNodes()
    pfMap:ShowMapID(map)
  end)

  f.loot:SetScript("OnEnter", function()
    local name = this:GetParent().itemName
    local count = 0

    GameTooltip:SetOwner(pfBrowser, "ANCHOR_CURSOR")
    GameTooltip:SetText("Looted from", .3, 1, .8)

    for id, field in pairs(items[name]) do
      local f, t, mob, sellCount = strfind(field, "(.*),(.*)")
      count = count + 1
      if count > 5 then
        GameTooltip:AddLine("[...]", .8,.8,.8)
        break
      end

      if spawns[mob] then
        local zone = spawns[mob]["zone"]
        GameTooltip:AddDoubleLine(mob, ( zone and pfMap:GetMapNameByID(zone) or UNKNOWN), 1,1,1, .5,.5,.5)
      end
    end
    GameTooltip:Show()
  end)

  f.loot:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)

  f.vendor = CreateFrame("Button", nil, f)
  f.vendor:SetHitRectInsets(-3,-3,-3,-3)
  f.vendor:SetPoint("RIGHT", -24, 0)
  f.vendor:SetWidth(16)
  f.vendor:SetHeight(16)
  f.vendor.icon = f.vendor:CreateTexture("OVERLAY")
  f.vendor.icon:SetAllPoints(f.vendor)
  f.vendor.icon:SetTexture("Interface\\AddOns\\pfQuest\\img\\icon_vendor")

  f.vendor:SetScript("OnClick", function()
    local name = this:GetParent().itemName
    local map = pfDatabase:SearchVendor(name)
    pfMap:UpdateNodes()
    pfMap:ShowMapID(map)
  end)

  f.vendor:SetScript("OnEnter", function()
    local name = this:GetParent().itemName
    local count = 0
    GameTooltip:SetOwner(pfBrowser, "ANCHOR_CURSOR")
    GameTooltip:SetText("Sold by", .3, 1, .8)

    for id, field in pairs(vendors[name]) do
      local f, t, vendorName, sellCount = strfind(field, "(.*),(.*)")
      count = count + 1
      if count > 5 then
        GameTooltip:AddLine("[...]", .8,.8,.8)
        break
      end

      if spawns[vendorName] then
        local zone = spawns[vendorName]["zone"]
        GameTooltip:AddDoubleLine(vendorName, ( zone and pfMap:GetMapNameByID(zone) or UNKNOWN), 1,1,1, .5,.5,.5)
      end
    end
    GameTooltip:Show()
  end)

  f.vendor:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)

  return f
end

local function CreateQuestEntry(i)
  local f = CreateFrame("Button", nil, pfBrowser.tabs.quest.list)
  f:SetPoint("TOPLEFT", pfBrowser.tabs.quest.list, "TOPLEFT", 10, -i*30 + 5)
  f:SetPoint("BOTTOMRIGHT", pfBrowser.tabs.quest.list, "TOPRIGHT", 10, -i*30 - 15)
  f.tex = f:CreateTexture("BACKGROUND")
  f.tex:SetAllPoints(f)

  if math.mod(i,2) == 1 then
    f.tex:SetTexture(1,1,1,.02)
  else
    f.tex:SetTexture(1,1,1,.04)
  end

  f:SetScript("OnEnter", function()
    this.tex:SetTexture(1,1,1,.1)
  end)

  f:SetScript("OnLeave", function()
    if math.mod(i,2) == 1 then
      this.tex:SetTexture(1,1,1,.02)
    else
      this.tex:SetTexture(1,1,1,.04)
    end
  end)

  f:SetScript("OnClick", function()
    if IsShiftKeyDown() then
      ChatFrameEditBox:Show()
      ChatFrameEditBox:Insert("|cffffff00|Hquest:0:0:0:0|h[" .. this.quest .. "]|h|r")
    else
      local map = pfDatabase:SearchQuest(this.quest)
      pfMap:ShowMapID(map)
    end
  end)

  f.text = f:CreateFontString("Caption", "LOW", "GameFontWhite")
  f.text:SetAllPoints(f)
  f.text:SetJustifyH("CENTER")

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

  f.fav = CreateFrame("Button", nil, f)
  f.fav:SetHitRectInsets(-3,-3,-3,-3)
  f.fav:SetPoint("LEFT", 0, 0)
  f.fav:SetWidth(16)
  f.fav:SetHeight(16)
  f.fav.icon = f.fav:CreateTexture("OVERLAY")
  f.fav.icon:SetTexture("Interface\\AddOns\\pfQuest\\img\\fav")
  f.fav.icon:SetAllPoints(f.fav)

  f.fav:SetScript("OnClick", function()
    local name = this:GetParent().quest
    if pfDatabase_fav["quest"][name] then
      pfDatabase_fav["quest"][name] = nil
      this.icon:SetVertexColor(1,1,1,.1)
    else
      pfDatabase_fav["quest"][name] = true
      this.icon:SetVertexColor(1,1,1,1)
    end
  end)

  return f
end

pfBrowserIcon = CreateFrame('Button', "pfBrowserIcon", Minimap)
pfBrowserIcon:SetClampedToScreen(true)
pfBrowserIcon:SetMovable(true)
pfBrowserIcon:EnableMouse(true)
pfBrowserIcon:RegisterForDrag('LeftButton')
pfBrowserIcon:RegisterForClicks('LeftButtonUp', 'RightButtonUp')
pfBrowserIcon:SetScript("OnDragStart", function() this:StartMoving() end)
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

CreateBrowseWindow("spawn", "pfQuestBrowserSpawn", pfBrowser, "BOTTOMLEFT", 5, 5)
CreateBrowseWindow("item", "pfQuestBrowserItems", pfBrowser, "BOTTOM", 0, 5)
CreateBrowseWindow("quest", "pfQuestBrowserQuests", pfBrowser, "BOTTOMRIGHT", -5, 5)

SelectView(pfBrowser.tabs["spawn"])

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

pfBrowser.input:SetScript("OnTextChanged", function()
  local text = this:GetText()
  if text ~= "Search" then
    pfBrowser:SearchSpawn(text)
    pfBrowser:SearchItem(text)
    pfBrowser:SearchQuest(text)
  else
    pfBrowser:SearchSpawn("")
    pfBrowser:SearchItem("")
    pfBrowser:SearchQuest("")
  end
end)

pfUI.api.CreateBackdrop(pfBrowser.input, nil, true)

function pfBrowser:SearchSpawn(search)
  -- database selection
  local database = pfDatabase_fav["spawn"]
  if strlen(search) > 2 then database = spawns end

  local i = 0
  for name, object in pairs(database) do
    if (strfind(strlower(name), strlower(search))) then
      i = i + 1

      if i >= search_limit then break end

      local level, faction, zone

      if spawns[name] then
        level   = object == true and spawns[name]['level']   or object.level
        faction = object == true and spawns[name]['faction'] or object.faction
        zone    = tonumber(spawns[name]['zone'])
      else
        level = "??"
        faction = ""
        zone = ""
      end

      -- craeate button if necessary
      if not pfBrowser.tabs.spawn.buttons[i] then
         pfBrowser.tabs.spawn.buttons[i] = CreateSpawnEntry(i)
      end

      local button = pfBrowser.tabs.spawn.buttons[i]

      button.text:SetText(name .. "|cffaaaaaa (" .. level .. ")")
      button.text:SetWidth(button.text:GetStringWidth())

      if zone and pfMap:IsValidMap(zone) then
        button.text:SetTextColor(1,1,1)
      else
        button.text:SetTextColor(.5,.5,.5)
      end

      button.name = name

      -- set faction icon
      button.factionH:Hide()
      button.factionA:Hide()
      if faction ~= "HA" and faction ~= "AH" then
        if strfind(faction, "H") then
          button.factionH:Show()
        else
          button.factionH:Hide()
        end

        if strfind(faction, "A") then
          button.factionA:Show()
        else
          button.factionA:Hide()
        end
      end

      -- set fav
      if pfDatabase_fav["spawn"][name] then
        button.fav.icon:SetVertexColor(1,1,1,1)
      else
        button.fav.icon:SetVertexColor(1,1,1,.1)
      end

      button:Show()
    end
  end

  RefreshView(i, "spawn", "Mobs & Objects")
end

function pfBrowser:SearchItem(search)
  -- database selection
  local database = pfDatabase_fav["item"]
  if strlen(search) > 2 then database = items end

  local i = 0
  for item, object in pairs(database) do
    if (strfind(strlower(item), strlower(search))) then
      i = i + 1

      if i >= search_limit then break end

      -- determine if fav or default database is in use
      local id = object == true and items[item]['id'] or object.id
      local itemColor = "|cffffffff"

      -- trigger item scan
      GameTooltip:SetHyperlink("item:" .. id .. ":0:0:0")
      GameTooltip:Hide()

      -- craeate button if necessary
      if not pfBrowser.tabs.item.buttons[i] then
         pfBrowser.tabs.item.buttons[i] = CreateItemEntry(i)
      end

      local button = pfBrowser.tabs.item.buttons[i]
      button.text:SetText("|cffff5555[?] |cffffffff" .. item)
      button.text:SetWidth(button.text:GetStringWidth())

      button.itemID = id
      button.itemName = item

      if items[item][1] then
        local _, _, npc = strfind(items[item][1], "(.*),(.*)")
        if spawns[npc] and spawns[npc]['type'] == "NPC" then
          button.loot.icon:SetTexture("Interface\\AddOns\\pfQuest\\img\\icon_npc")
        else
          button.loot.icon:SetTexture("Interface\\AddOns\\pfQuest\\img\\icon_object")
        end
        button.loot:Show()
      else
        button.loot:Hide()
      end

      if vendors[item] then
        button.vendor:Show()
      else
        button.vendor:Hide()
      end

      if pfDatabase_fav["item"][item] then
        button.fav.icon:SetVertexColor(1,1,1,1)
      else
        button.fav.icon:SetVertexColor(1,1,1,.1)
      end

      -- refresh item quality
      button:SetScript("OnUpdate", function()
        local _, _, itemQuality = GetItemInfo(this.itemID)
        if itemQuality then
          this.itemColor = "|c" .. string.format("%02x%02x%02x%02x", 255,
              ITEM_QUALITY_COLORS[itemQuality].r * 255,
              ITEM_QUALITY_COLORS[itemQuality].g * 255,
              ITEM_QUALITY_COLORS[itemQuality].b * 255)

          this.text:SetText(this.itemColor .."|Hitem:"..this.itemID..":0:0:0|h[".. this.itemName.."]|h|r")
          this.text:SetWidth(this.text:GetStringWidth())
          this:SetScript("OnUpdate", nil)
        end
      end)

      button:Show()
    end
  end

  RefreshView(i, "item", "Items")
end

function pfBrowser:SearchQuest(search)
  -- database selection
  local database = pfDatabase_fav["quest"]
  if strlen(search) > 2 then database = quests end

  local i = 0
  for quest, object in pairs(database) do
    if (strfind(strlower(quest), strlower(search))) then
      i = i + 1

      if i >= search_limit then break end

      -- craeate button if necessary
      if not pfBrowser.tabs.quest.buttons[i] then
        pfBrowser.tabs.quest.buttons[i] = CreateQuestEntry(i)
      end

      local button = pfBrowser.tabs.quest.buttons[i]

      -- read faction
      local faction = ""
      button.factionA:Hide()
      button.factionH:Hide()

      if quests[quest] then
        for npc, monsterDrop in pairs(quests[quest]) do
          if spawns[npc] and spawns[npc]['faction'] then
            faction = faction .. spawns[npc]['faction']
          end
        end
      end

      if strfind(faction, "H") then
        button.factionH:Show()
      end

      if strfind(faction, "A") then
        button.factionA:Show()
      end

      if quests[quest] then
        button.text:SetText("|cffffcc00|Hquest:0:0:0:0|h[" .. quest .. "]|h|r")
      else
        button.text:SetText("|cffff5555[?] |cffffcc00|Hquest:0:0:0:0|h[" .. quest .. "]|h|r")
      end
      button.text:SetWidth(button.text:GetStringWidth())
      button.quest = quest

      if pfDatabase_fav["quest"][quest] then
        button.fav.icon:SetVertexColor(1,1,1,1)
      else
        button.fav.icon:SetVertexColor(1,1,1,.1)
      end

      button:Show()
    end
  end

  RefreshView(i, "quest", "Quests")
end
