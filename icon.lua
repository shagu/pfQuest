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
  GameTooltip:AddDoubleLine(pfQuest_Loc["Left-Click"], pfQuest_Loc["Open Browser"], 1, 1, 1, 1, 1, 1)
  GameTooltip:AddDoubleLine(pfQuest_Loc["Right-Click"], pfQuest_Loc["Open Configuration"], 1, 1, 1, 1, 1, 1)
  GameTooltip:AddDoubleLine(pfQuest_Loc["Shift-Click"], pfQuest_Loc["Move Button"], 1, 1, 1, 1, 1, 1)
  GameTooltip:Show()
end)

pfBrowserIcon:SetScript("OnLeave", function()
  GameTooltip:Hide()
end)

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
pfBrowserIcon.icon:SetTexture(pfQuestConfig.path..'\\img\\logo')
pfBrowserIcon.icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)
pfBrowserIcon.icon:SetPoint('CENTER',1,1)
