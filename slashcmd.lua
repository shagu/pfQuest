SLASH_PFDB1, SLASH_PFDB2, SLASH_PFDB3, SLASH_PFDB4 = "/db", "/shagu", "/pfquest", "/pfdb"
SlashCmdList["PFDB"] = function(input, editbox)
  local params = {}
  if (input == "" or input == nil) then
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffccpf|cffffffffQuest (v" .. tostring(GetAddOnMetadata("pfQuest", "Version")) .. "):")
    DEFAULT_CHAT_FRAME:AddMessage("/db show |cffaaaaaa - show database interface")
    DEFAULT_CHAT_FRAME:AddMessage("/db config |cffaaaaaa - show configuration interface")
    DEFAULT_CHAT_FRAME:AddMessage("/db spawn <mob|gameobject> |cffaaaaaa - search objects")
    DEFAULT_CHAT_FRAME:AddMessage("/db item <item> |cffaaaaaa - search loot")
    DEFAULT_CHAT_FRAME:AddMessage("/db vendor <item> |cffaaaaaa - vendors for item")
    DEFAULT_CHAT_FRAME:AddMessage("/db quest <questname> |cffaaaaaa - show specific questgiver")
    DEFAULT_CHAT_FRAME:AddMessage("/db quests <area> |cffaaaaaa - show all quest spots on the map")
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
    local map = pfDatabase:SearchItem(arg2)
    if not pfMap:ShowMapID(map) then
      DEFAULT_CHAT_FRAME:AddMessage("No matches.")
    end
  end

  -- argument: vendor
  if (arg1 == "vendor") then
    local map = pfDatabase:SearchVendor(arg2)
    if not pfMap:ShowMapID(map) then
      DEFAULT_CHAT_FRAME:AddMessage("No matches.")
    end
  end

  -- argument: spawn
  if (arg1 == "spawn") then
    local map = pfDatabase:SearchMob(arg2)
    if not pfMap:ShowMapID(map) then
      DEFAULT_CHAT_FRAME:AddMessage("No matches.")
    end
  end

  -- argument: quest
  if (arg1 == "quest") then
    local map = pfDatabase:SearchQuest(arg2)
    if not pfMap:ShowMapID(map) then
      DEFAULT_CHAT_FRAME:AddMessage("No matches.")
    end
  end

  -- argument: quests
  if (arg1 == "quests") then
    local map = pfDatabase:SearchQuests(arg2)
    if not pfMap:ShowMapID(map) then
      DEFAULT_CHAT_FRAME:AddMessage("No matches.")
    end
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
