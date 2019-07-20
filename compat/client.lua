-- some abstraction to allow multi-client code
local _, _, _, client = GetBuildInfo()
client = client or 11200

pfQuestCompat = {}
pfQuestCompat.mod = mod or math.mod
pfQuestCompat.gfind = string.gmatch or string.gfind
pfQuestCompat.GetQuestLogTitle = function(id)
  local title, level, tag, group, header, collapsed, complete, daily, _
  if client <= 11200 then -- vanilla
    title, level, tag, header, collapsed, complete = GetQuestLogTitle(id)
  elseif client > 11200 then -- tbc
    title, level, tag, group, header, collapsed, complete, daily = GetQuestLogTitle(id)
  end

  return title, level, tag, header, collapsed, complete
end
