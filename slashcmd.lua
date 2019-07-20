-- multi api compat
local compat = pfQuestCompat

SLASH_PFDB1, SLASH_PFDB2, SLASH_PFDB3, SLASH_PFDB4 = "/db", "/shagu", "/pfquest", "/pfdb"
SlashCmdList["PFDB"] = function(input, editbox)
  local params = {}
  local meta = { ["addon"] = "PFDB" }

  if (input == "" or input == nil) then
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffccpf|cffffffffQuest (v" .. tostring(GetAddOnMetadata("pfQuest", "Version")) .. "):")
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc/db|cffffffff show |cffcccccc - " .. pfQuest_Loc["show database interface"])
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc/db|cffffffff config |cffcccccc - " .. pfQuest_Loc["show configuration interface"])
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc/db|cffffffff unit <unit> |cffcccccc - " .. pfQuest_Loc["search units"])
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc/db|cffffffff object <gameobject> |cffcccccc - " .. pfQuest_Loc["search objects"])
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc/db|cffffffff item <item> |cffcccccc - " .. pfQuest_Loc["search loot"])
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc/db|cffffffff vendor <item> |cffcccccc - " .. pfQuest_Loc["vendors for item"])
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc/db|cffffffff quest <questname> |cffcccccc - " .. pfQuest_Loc["show specific questgiver"])
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc/db|cffffffff quests |cffcccccc - " .. pfQuest_Loc["show all quests on the map"])
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc/db|cffffffff clean |cffcccccc - " .. pfQuest_Loc["clean map"])
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc/db|cffffffff locale |cffcccccc - " .. pfQuest_Loc["display the addon locales"])
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc/db|cffffffff meta <relation> [min, [max]] |cffcccccc - " .. pfQuest_Loc["show related objects on the map"])
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc/db|cffffffff scan |cffcccccc - " .. pfQuest_Loc["scan the server for items"])
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc ->|cffffffff " .. pfQuest_Loc["Available relations"] .. ": |cff33ffccchests|r, |cff33ffccherbs|r, |cff33ffccmines|r")
    return
  end

  local commandlist = { }
  local command

  for command in compat.gfind(input, "[^ ]+") do
    table.insert(commandlist, command)
  end

  local arg1, arg2 = commandlist[1], ""

  -- handle whitespace mob- and item names correctly
  for i in pairs(commandlist) do
    if (i ~= 1) then
      arg2 = arg2 .. commandlist[i]
      if (commandlist[i+1] ~= nil) then
        arg2 = arg2 .. " "
      end
    end
  end

  -- argument: item
  if (arg1 == "item") then
    local maps = pfDatabase:SearchItem(arg2, meta, "LOWER")
    pfMap:ShowMapID(pfDatabase:GetBestMap(maps))
    return
  end

  -- argument: vendor
  if (arg1 == "vendor") then
    local maps = pfDatabase:SearchVendor(arg2, meta, "LOWER")
    pfMap:ShowMapID(pfDatabase:GetBestMap(maps))
    return
  end

  -- argument: unit
  if (arg1 == "unit") then
    local maps = pfDatabase:SearchMob(arg2, meta, "LOWER")
    pfMap:ShowMapID(pfDatabase:GetBestMap(maps))
    return
  end

  -- argument: object
  if (arg1 == "object") then
    local maps = pfDatabase:SearchObject(arg2, meta, "LOWER")
    pfMap:ShowMapID(pfDatabase:GetBestMap(maps))
    return
  end

  -- argument: quest
  if (arg1 == "quest") then
    local maps = pfDatabase:SearchQuest(arg2, meta, "LOWER")
    pfMap:ShowMapID(pfDatabase:GetBestMap(maps))
    return
  end

  -- argument: quests
  if (arg1 == "quests") then
    local maps = pfDatabase:SearchQuests(meta)
    pfMap:UpdateNodes()
    return
  end

  -- argument: meta
  if (arg1 == "meta") then
    local maps = pfDatabase:SearchMetaRelation({ commandlist[2], commandlist[3], commandlist[4] }, meta)
    pfMap:ShowMapID(pfDatabase:GetBestMap(maps))
    return
  end

  -- argument: clean
  if (arg1 == "clean") then
    pfMap:DeleteNode("PFDB")
    pfMap:UpdateNodes()
    return
  end

  -- argument: show
  if (arg1 == "show") then
    if pfBrowser then pfBrowser:Show() end
    return
  end

  -- argument: show
  if (arg1 == "config") then
    if pfQuestConfig then pfQuestConfig:Show() end
    return
  end

  -- argument: locale
  if (arg1 == "locale") then
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffccLocales|r:" .. pfDatabase.dbstring)
    return
  end

  -- argument: scan
  if (arg1 == "scan") then
    pfDatabase:ScanServer()
    return
  end

  -- argument: <text>
  if (type(arg1)=="string") then
    if pfBrowser then
      pfBrowser:Show()
      pfBrowser.input:SetText((string.gsub(string.format("%s %s",arg1,arg2),"^%s*(.-)%s*$", "%1")))
    end
    return
  end
end
