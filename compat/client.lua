-- some abstraction to allow multi-client code
local _, _, _, client = GetBuildInfo()
client = client or 11200

local _G = client == 11200 and getfenv(0) or _G
local gfind = string.gmatch or string.gfind

pfQuestCompat = {}
pfQuestCompat.mod = mod or math.mod
pfQuestCompat.gfind = string.gmatch or string.gfind
pfQuestCompat.itemsuffix = client > 11200 and ":0:0:0:0:0:0:0" or ":0:0:0"
pfQuestCompat.rotateMinimap = client > 11200 and GetCVar("rotateMinimap") ~= "0" and true or nil
pfQuestCompat.client = client

-- use and cache the original function if CTMod overwrites global API calls
local GetQuestLogTitle = CT_QuestLevels_oldGetQuestLogTitle or GetQuestLogTitle

pfQuestCompat.GetQuestLogTitle = function(id)
  local title, level, tag, group, header, collapsed, complete, daily, _
  if client <= 11200 then -- vanilla
    title, level, tag, header, collapsed, complete = GetQuestLogTitle(id)
  elseif client > 11200 then -- tbc
    title, level, tag, group, header, collapsed, complete, daily = GetQuestLogTitle(id)
  end

  return title, level, tag, header, collapsed, complete
end

pfQuestCompat.InsertQuestLink = function(questid, name)
  local questid = questid or 0
  local fallback = name or UNKNOWN
  local level = pfDB["quests"]["data"][questid] and pfDB["quests"]["data"][questid]["lvl"] or 0
  local name = pfDB["quests"]["loc"][questid] and pfDB["quests"]["loc"][questid]["T"] or fallback
  local hex = pfUI.api.rgbhex(GetDifficultyColor(level))

  ChatFrameEditBox:Show()
  if pfQuest_config["questlinks"] == "1" then
    ChatFrameEditBox:Insert(hex .. "|Hquest:" .. questid .. ":" .. level .. "|h[" .. name .. "]|h|r")
  else
    ChatFrameEditBox:Insert("[" .. name .. "]")
  end
end

-- do the best to detect the minimap arrow on vanilla and tbc
local minimaparrow = ({Minimap:GetChildren()})[9]
for k, v in pairs({Minimap:GetChildren()}) do
  if v:IsObjectType("Model") and not v:GetName() then
    if string.find(strlower(v:GetModel()), "interface\\minimap\\minimaparrow") then
      minimaparrow = v
      break
    end
  end
end

-- return the player facing based on the minimap arrow
function pfQuestCompat.GetPlayerFacing()
  if pfQuestCompat.rotateMinimap then
    return (MiniMapCompassRing:GetFacing() * -1)
  else
    return minimaparrow:GetFacing()
  end
end

if client <= 11200 then
  -- overwrite the out-of-memory popup on vanilla clients, to provide some help
  -- on how to increase the limits, and also displaying a link to an example.
  local memlimit = "The user interface is using more than %dMB of memory.\n\n" ..
    "Set '|cffffee55Script Memory|r' to '|cffffee550|r' in the character selection screen:"

  local striptex = function(frame)
    for _,v in ipairs({frame:GetRegions()}) do
      if v.GetTexture and string.find(v:GetTexture(), "ChatInputBorder") then v:Hide() end
    end
  end

  _G.StaticPopupDialogs["MEMORY_EXHAUSTED"] = {
    text = TEXT(memlimit),
    button1 = TEXT(QUIT_NOW),
    button2 = TEXT(CANCEL),
    hasEditBox = 1,
    showAlert = 1,
    OnShow = function()
      pfUI.api.CreateBackdrop(getglobal(this:GetName().."EditBox"), 3, true)
      getglobal(this:GetName().."EditBox"):SetText("https://i.imgur.com/rZXwaK0.jpg")
      getglobal(this:GetName().."EditBox"):SetTextInsets(5, 5, 5, 5)
      getglobal(this:GetName().."EditBox"):SetJustifyH("CENTER")
      getglobal(this:GetName().."EditBox"):SetWidth(220)
      getglobal(this:GetName().."EditBox"):SetFocus()
      getglobal(this:GetName().."Button2"):Disable()
      striptex(getglobal(this:GetName().."EditBox"))
    end,
    OnAccept = function()
      ForceQuit()
    end,
    timeout = 0,
    whileDead = 1,
  }

  -- add colors to quest links
  local ParseQuestLevels = function(frame, text, a1, a2, a3, a4, a5)
    if text then
      for oldhex, questid, level in gfind(text, "(|c%x+)|Hquest:(.-):(.-)|h") do
        local questid = tonumber(questid)
        local level = tonumber(level)

        if not level or level == 0 then
          level = pfDB["quests"]["data"][questid] and pfDB["quests"]["data"][questid]["lvl"] or 0
        end

        if level and level > 0 then
          local newhex = pfUI.api.rgbhex(GetDifficultyColor(level))
          text = string.gsub(text, oldhex .. "|Hquest:"..questid, newhex.."|Hquest:"..questid)
        end
      end
    end

    frame.pfQuestHookAddMessage(frame, text, a1, a2, a3, a4, a5)
  end

  for i=1,NUM_CHAT_WINDOWS do
    _G["ChatFrame"..i].pfQuestHookAddMessage = _G["ChatFrame"..i].pfQuestHookAddMessage or _G["ChatFrame"..i].AddMessage
    _G["ChatFrame"..i].AddMessage = ParseQuestLevels
  end
end
