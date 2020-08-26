-- some abstraction to allow multi-client code
local _, _, _, client = GetBuildInfo()
client = client or 11200

local _G = _G or getfenv(0)
local gfind = string.gmatch or string.gfind

pfQuestCompat = {}
pfQuestCompat.mod = mod or math.mod
pfQuestCompat.gfind = string.gmatch or string.gfind
pfQuestCompat.itemsuffix = client > 11200 and ":0:0:0:0:0:0:0" or ":0:0:0"
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
  ChatFrameEditBox:Show()

  local name = pfDB["quests"]["loc"][questid] and pfDB["quests"]["loc"][questid]["T"] or fallback
  if pfQuest_config["questlinks"] == "1" then
    ChatFrameEditBox:Insert("|cffffff00|Hquest:" .. questid .. ":" .. level .. "|h[" .. name .. "]|h|r")
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
  if client > 11200 and GetCVar("rotateMinimap") ~= "0" then
    return (MiniMapCompassRing:GetFacing() * -1)
  else
    return minimaparrow:GetFacing()
  end
end

if client <= 11200 then
  -- add colors to quest links
  local ParseQuestLevels = function(frame, text, a1, a2, a3, a4, a5)
    if text then
      for questid, level in gfind(text, "|cffffff00|Hquest:(.-):(.-)|h") do
        local questid = tonumber(questid)
        local level = tonumber(level)

        if not level or level == 0 then
          level = pfDB["quests"]["data"][questid] and pfDB["quests"]["data"][questid]["lvl"] or 0
        end

        if level and level > 0 then
          local color = GetDifficultyColor(level)
          local r = ceil(color.r*255)
          local g = ceil(color.g*255)
          local b = ceil(color.b*255)
          local hex = "|c" .. string.format("ff%02x%02x%02x", r, g, b)

          text = string.gsub(text, "|cffffff00|Hquest:"..questid, hex.."|Hquest:"..questid)
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
