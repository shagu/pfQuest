-- multi api compat
local compat = pfQuestCompat

SLASH_PFDB1, SLASH_PFDB2, SLASH_PFDB3, SLASH_PFDB4 = "/db", "/shagu", "/pfquest", "/pfdb"
SlashCmdList["PFDB"] = function(input, editbox)
  local params = {}
  local meta = { ["addon"] = "PFDB" }

  if (input == "" or input == nil) then
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffccpf|cffffffffQuest (v" .. pfQuestConfig.version .. "):")
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc/db|cffffffff lock |cffcccccc - " .. pfQuest_Loc["Lock map tracker"])
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc/db|cffffffff tracker |cffcccccc - " .. pfQuest_Loc["Show map tracker"])
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc/db|cffffffff journal |cffcccccc - " .. pfQuest_Loc["Show quest journal"])
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc/db|cffffffff arrow |cffcccccc - " .. pfQuest_Loc["Show quest arrow"])
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc/db|cffffffff show |cffcccccc - " .. pfQuest_Loc["Show database interface"])
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc/db|cffffffff config |cffcccccc - " .. pfQuest_Loc["Show configuration interface"])
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc/db|cffffffff locale |cffcccccc - " .. pfQuest_Loc["Display addon locales"])
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc/db|cffffffff unit <unit> |cffcccccc - " .. pfQuest_Loc["Search unit"])
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc/db|cffffffff object <gameobject> |cffcccccc - " .. pfQuest_Loc["Search object"])
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc/db|cffffffff item <item> |cffcccccc - " .. pfQuest_Loc["Search loot"])
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc/db|cffffffff vendor <item> |cffcccccc - " .. pfQuest_Loc["Search item vendors"])
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc/db|cffffffff quest <questname> |cffcccccc - " .. pfQuest_Loc["Show specific quest"])
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc/db|cffffffff quests |cffcccccc - " .. pfQuest_Loc["Show all quests on map"])
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc/db|cffffffff clean |cffcccccc - " .. pfQuest_Loc["Clean Map"])
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc/db|cffffffff reset |cffcccccc - " .. pfQuest_Loc["Reset Map"])
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc/db|cffffffff chests |cffcccccc - " .. pfQuest_Loc["Show all chests on map"])
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc/db|cffffffff taxi [faction]|cffcccccc - " .. pfQuest_Loc["Show all taxi nodes of [faction]"])
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc/db|cffffffff rares [min, [max]]|cffcccccc - " .. pfQuest_Loc["Show all rare mobs of Level [min] to [max]"])
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc/db|cffffffff mines [min, [max]] |cffcccccc - " .. pfQuest_Loc["Show mines with skill range of [min] to [max]"])
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc/db|cffffffff mines auto |cffcccccc - " .. pfQuest_Loc["Show mines with an appropriate skill level for your character"])
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc/db|cffffffff herbs [min, [max]] |cffcccccc - " .. pfQuest_Loc["Show herbs with skill range of [min] to [max]"])
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc/db|cffffffff herbs auto |cffcccccc - " .. pfQuest_Loc["Show herbs with an appropriate skill level for your character"])
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc/db|cffffffff scan |cffcccccc - " .. pfQuest_Loc["Scan the server for custom items"])
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc/db|cffffffff query |cffcccccc - " .. pfQuest_Loc["Query the server for completed quests"])
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

  -- argument: debug
  if (arg1 == "debug") then
    pfQuest_config.debug = not pfQuest_config.debug
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffccpf|cffffffffQuest Debug Mode: " .. ( pfQuest_config.debug and "|cff33ff33ON" or "|cffff3333OFF" ))
    pfQuest:Debug("Debug Mode Changed")
    return
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
    local query = {
      name = commandlist[2],
      min = commandlist[3],
      max = commandlist[4],
      faction = commandlist[3],
    }

    local maps = pfDatabase:SearchMetaRelation(query, meta)
    pfMap:ShowMapID(pfDatabase:GetBestMap(maps))
    return
  end

  -- argument: chests
  if (arg1 == "chests") then
    local query = {
      name = commandlist[1],
    }

    local maps = pfDatabase:SearchMetaRelation(query, meta)
    pfMap:ShowMapID(pfDatabase:GetBestMap(maps))
    return
  end

  -- argument: taxi
  if (arg1 == "taxi") then
    local query = {
      name = commandlist[1],
      faction = commandlist[2],
    }

    meta["texture"] = "Interface\\TaxiFrame\\UI-Taxi-Icon-White"
    local maps = pfDatabase:SearchMetaRelation(query, meta)
    pfMap:ShowMapID(pfDatabase:GetBestMap(maps))
    return
  end

  -- argument: rares
  if (arg1 == "rares") then
    local query = {
      name = "rares",
      min = commandlist[2],
      max = commandlist[3],
    }

    meta["texture"] = pfQuestConfig.path.."\\img\\fav"
    local maps = pfDatabase:SearchMetaRelation(query, meta)
    pfMap:ShowMapID(pfDatabase:GetBestMap(maps))
    return
  end

  -- argument: mines
  if (arg1 == "mines") then
    local query = {
      name = "mines",
      min = commandlist[2],
      max = commandlist[3],
    }

    if (arg2 == "auto") then
      query.max = pfDatabase:GetPlayerSkill(186) or 0
      query.min = query.max - 100
    end

    local maps = pfDatabase:SearchMetaRelation(query, meta)
    pfMap:ShowMapID(pfDatabase:GetBestMap(maps))
    return
  end

  -- argument: herbs
  if (arg1 == "herbs") then
    local query = {
      name = "herbs",
      min = commandlist[2],
      max = commandlist[3],
    }

    if (arg2 == "auto") then
      query.max = pfDatabase:GetPlayerSkill(182) or 0
      query.min = query.max - 100
    end

    local maps = pfDatabase:SearchMetaRelation(query, meta)
    pfMap:ShowMapID(pfDatabase:GetBestMap(maps))
    return
  end

  -- argument: clean
  if (arg1 == "clean") then
    pfMap:DeleteNode("PFDB")
    pfMap:UpdateNodes()
    return
  end

  -- argument: reset
  if (arg1 == "reset") then
    pfQuest:ResetAll()
    return
  end

  -- argument: show
  if (arg1 == "show") then
    if pfBrowser then pfBrowser:Show() end
    return
  end

  -- argument: tracker
  if (arg1 == "tracker") then
    if pfQuest.tracker then pfQuest.tracker:Show() end
    return
  end

  -- argument: lock
  if (arg1 == "lock") then
    pfQuest_config.lock = not pfQuest_config.lock
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffccpf|cffffffffQuest Tracker: " .. ( pfQuest_config.lock and "Locked" or "Unlocked" ))
    return
  end

  -- argument: journal
  if (arg1 == "journal") then
    if pfJournal then pfJournal:Show() end
    return
  end

  -- argument: arrow
  if (arg1 == "arrow") then
    if pfQuest_config["arrow"] == "1" then
      pfQuest_config["arrow"] = "0"
      pfQuest.route.arrow:Hide()
    else
      pfQuest_config["arrow"] = "1"
    end
    return
  end

  -- argument: show
  if (arg1 == "config") then
    if pfQuestConfig then pfQuestConfig:Show() end
    return
  end

  -- argument: locale
  if (arg1 == "locale") then
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc" .. pfQuest_Loc["Locales"] .. "|r:" .. pfDatabase.dbstring)
    return
  end

  -- argument: scan
  if (arg1 == "scan") then
    pfDatabase:ScanServer()
    return
  end

    -- argument: query
  if (arg1 == "query") then
    pfDatabase:QueryServer()
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
