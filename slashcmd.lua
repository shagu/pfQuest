SLASH_PFDB1, SLASH_PFDB2, SLASH_PFDB3, SLASH_PFDB4 = "/db", "/shagu", "/pfquest", "/pfdb"
SlashCmdList["PFDB"] = function(input, editbox)
  local params = {}
  local meta = { ["addon"] = "PFDB" }

  if (input == "" or input == nil) then
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffccpf|cffffffffQuest (v" .. tostring(GetAddOnMetadata("pfQuest", "Version")) .. "):")
    DEFAULT_CHAT_FRAME:AddMessage("/db show |cffaaaaaa - show database interface")
    DEFAULT_CHAT_FRAME:AddMessage("/db config |cffaaaaaa - show configuration interface")
    DEFAULT_CHAT_FRAME:AddMessage("/db unit <unit> |cffaaaaaa - search units")
    DEFAULT_CHAT_FRAME:AddMessage("/db object <gameobject> |cffaaaaaa - search objects")
    DEFAULT_CHAT_FRAME:AddMessage("/db item <item> |cffaaaaaa - search loot")
    DEFAULT_CHAT_FRAME:AddMessage("/db vendor <item> |cffaaaaaa - vendors for item")
    DEFAULT_CHAT_FRAME:AddMessage("/db quest <questname> |cffaaaaaa - show specific questgiver")
    DEFAULT_CHAT_FRAME:AddMessage("/db quests |cffaaaaaa - show all quests on the map")
    DEFAULT_CHAT_FRAME:AddMessage("/db clean |cffaaaaaa - clean map")
  end

  local commandlist = { }
  local command

  for command in string.gfind(input, "[^ ]+") do
    table.insert(commandlist, command)
  end

  local arg1, arg2 = commandlist[1], ""

  -- handle whitespace mob- and item names correctly
  for i in commandlist do
    if (i ~= 1) then
      arg2 = arg2 .. commandlist[i]
      if (commandlist[i+1] ~= nil) then
        arg2 = arg2 .. " "
      end
    end
  end

  -- argument: item
  if (arg1 == "item") then
    local maps = pfDatabase:SearchItem(arg2, meta)
    pfMap:ShowMapID(pfDatabase:GetBestMap(maps))
  end

  -- argument: vendor
  if (arg1 == "vendor") then
    local maps = pfDatabase:SearchVendor(arg2, meta)
    pfMap:ShowMapID(pfDatabase:GetBestMap(maps))
  end

  -- argument: unit
  if (arg1 == "unit") then
    local maps = pfDatabase:SearchMob(arg2, meta)
    pfMap:ShowMapID(pfDatabase:GetBestMap(maps))
  end

  -- argument: object
  if (arg1 == "object") then
    local maps = pfDatabase:SearchObject(arg2, meta)
    pfMap:ShowMapID(pfDatabase:GetBestMap(maps))
  end

  -- argument: quest
  if (arg1 == "quest") then
    local maps = pfDatabase:SearchQuest(arg2)
    pfMap:ShowMapID(pfDatabase:GetBestMap(maps))
  end

  -- argument: quests
  if (arg1 == "quests") then
    local maps = pfDatabase:SearchQuests(meta)
    pfMap:UpdateNodes()
  end

  -- argument: clean
  if (arg1 == "clean") then
    pfMap:DeleteNode("PFDB")
    pfMap:UpdateNodes()
  end

  -- argument: show
  if (arg1 == "show") then
    if pfBrowser then pfBrowser:Show() end
  end

  -- argument: show
  if (arg1 == "config") then
    if pfQuestConfig then pfQuestConfig:Show() end
  end
end
