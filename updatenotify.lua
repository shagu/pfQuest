local function strsplit(delimiter, subject)
  if not subject then return nil end
  local delimiter, fields = delimiter or ":", {}
  local pattern = string.format("([^%s]+)", delimiter)
  string.gsub(subject, pattern, function(c) fields[table.getn(fields)+1] = c end)
  return unpack(fields)
end

local channels = { "BATTLEGROUND", "RAID", "GUILD" }
local version, remote, major, minor, fix, displayed, available
local versioncheck = CreateFrame("Frame")
versioncheck:RegisterEvent("ADDON_LOADED")
versioncheck:RegisterEvent("CHAT_MSG_ADDON")
versioncheck:RegisterEvent("PARTY_MEMBERS_CHANGED")
versioncheck:RegisterEvent("PLAYER_ENTERING_WORLD")
versioncheck:SetScript("OnEvent", function()
  if event == "ADDON_LOADED" then
    if arg1 == "pfQuest" or arg1 == "pfQuest-tbc" or arg1 == "pfQuest-wotlk" then
      major, minor, fix = strsplit(".", tostring(GetAddOnMetadata(arg1, "Version")))
      major = tonumber(major) or 0
      minor = tonumber(minor) or 0
      fix = tonumber(fix) or 0

      version = major*10000 + minor*100 + fix
    end

    return
  elseif event == "CHAT_MSG_ADDON" and arg1 == "pfQuest" then
    local v, remoteversion = strsplit(":", arg2)
    local remoteversion = tonumber(remoteversion)
    if v == "VERSION" and remoteversion then
      remote = remote and max(remote, remoteversion) or remoteversion
      if remote > version then pfQuest_config.latest = remote end
    end
    return
  elseif event == "CHAT_MSG_ADDON" then
    return
  end

  -- abort here without local version
  if not version then return end

  -- send updates
  for _, chan in pairs(channels) do SendAddonMessage("pfQuest", "VERSION:" .. version, chan) end

  -- abort here on group member events
  if event == "PARTY_MEMBERS_CHANGED" then return end

  -- display available update
  if version and version > 0 and pfQuest_config.latest and pfQuest_config.latest > version and not displayed then
    DEFAULT_CHAT_FRAME:AddMessage(pfQuest_Loc["|cff33ffccpf|rQuest: New version available! Have a look at http://shagu.org !"])
    displayed = true
  end
end)
