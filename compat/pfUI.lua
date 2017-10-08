-- Initialize pfUI core table for non-pfUI environments
if not pfUI then
  pfUI = {
    ["api"] = {},
    ["cache"] = {},
    ["backdrop"] = {
      bgFile = "Interface\\AddOns\\pfQuest\\compat\\col", tile = true, tileSize = 8,
      edgeFile = "Interface\\AddOns\\pfQuest\\compat\\border", edgeSize = 8,
      insets = {left = -1, right = -1, top = -1, bottom = -1},
    },
    ["backdrop_small"] = {
      bgFile = "Interface\\AddOns\\pfQuest\\compat\\col", tile = true, tileSize = 8,
      insets = {left = -1, right = -1, top = -1, bottom = -1},
    },
    ["font_default"] = "Fonts\\ARIALN.TTF",
   }

  pfUI_config = {
    ["appearance"] = {
      ["border"] = {
        ["background"] = "0,0,0,1",
        ["color"] = "0.3,0.3,0.3,1",
        ["default"] = "3",
      }
    },
    ["global"] = {
      ["font_size"] = 12
    }
  }
end

-- Add API support non-pfUI environments and for old pfUI versions:
-- strsplit, CreateBackdrop, SkinButton, CreateScrollFrame, CreateScrollChild
if pfUI.api and pfUI.api.strsplit and pfUI.api.CreateBackdrop and
   pfUI.api.SkinButton and pfUI.api.CreateScrollFrame and
   pfUI.api.CreateScrollChild then
     return
end

function pfUI.api.strsplit(delimiter, subject)
  local delimiter, fields = delimiter or ":", {}
  local pattern = string.format("([^%s]+)", delimiter)
  string.gsub(subject, pattern, function(c) fields[table.getn(fields)+1] = c end)
  return unpack(fields)
end

function pfUI.api.CreateBackdrop(f, inset, legacy, transp)
  -- exit if now frame was given
  if not f then return end

  -- use default inset if nothing is given
  local border = inset
  if not border then
    border = tonumber(pfUI_config.appearance.border.default)
  end

  -- bg and edge colors
  if not pfUI.cache.br then
    local br, bg, bb, ba = pfUI.api.strsplit(",", pfUI_config.appearance.border.background)
    local er, eg, eb, ea = pfUI.api.strsplit(",", pfUI_config.appearance.border.color)
    pfUI.cache.br, pfUI.cache.bg, pfUI.cache.bb, pfUI.cache.ba = br, bg, bb, ba
    pfUI.cache.er, pfUI.cache.eg, pfUI.cache.eb, pfUI.cache.ea = er, eg, eb, ea
  end

  local br, bg, bb, ba =  pfUI.cache.br, pfUI.cache.bg, pfUI.cache.bb, pfUI.cache.ba
  local er, eg, eb, ea = pfUI.cache.er, pfUI.cache.eg, pfUI.cache.eb, pfUI.cache.ea
  if transp then ba = transp end

  -- use legacy backdrop handling
  if legacy then
    f:SetBackdrop(pfUI.backdrop)
    f:SetBackdropColor(br, bg, bb, ba)
    f:SetBackdropBorderColor(er, eg, eb , ea)
    return
  end

  -- increase clickable area if available
  if f.SetHitRectInsets then
    f:SetHitRectInsets(-border,-border,-border,-border)
  end

  -- use new backdrop behaviour
  if not f.backdrop then
    f:SetBackdrop(nil)

    local border = tonumber(border) - 1
    local backdrop = pfUI.backdrop
    if border < 1 then backdrop = pfUI.backdrop_small end
  	local b = CreateFrame("Frame", nil, f)
  	b:SetPoint("TOPLEFT", f, "TOPLEFT", -border, border)
  	b:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", border, -border)

    local level = f:GetFrameLevel()
    if level < 1 then
  	  --f:SetFrameLevel(level + 1)
      b:SetFrameLevel(level)
    else
      b:SetFrameLevel(level - 1)
    end

    f.backdrop = b
    b:SetBackdrop(backdrop)
  end

  local b = f.backdrop
  b:SetBackdropColor(br, bg, bb, ba)
  b:SetBackdropBorderColor(er, eg, eb , ea)
end

function pfUI.api.SkinButton(button, cr, cg, cb)
  local b = getglobal(button)
  if not b then b = button end
  if not b then return end
  if not cr or not cg or not cb then
    _, class = UnitClass("player")
    local color = RAID_CLASS_COLORS[class]
    cr, cg, cb = color.r , color.g, color.b
  end
  pfUI.api.CreateBackdrop(b, nil, true)
  b:SetNormalTexture(nil)
  b:SetHighlightTexture(nil)
  b:SetPushedTexture(nil)
  b:SetDisabledTexture(nil)
  local funce = b:GetScript("OnEnter")
  local funcl = b:GetScript("OnLeave")
  b:SetScript("OnEnter", function()
    if funce then funce() end
    pfUI.api.CreateBackdrop(b, nil, true)
    b:SetBackdropBorderColor(cr,cg,cb,1)
  end)
  b:SetScript("OnLeave", function()
    if funcl then funcl() end
    pfUI.api.CreateBackdrop(b, nil, true)
  end)
  b:SetFont(pfUI.font_default, pfUI_config.global.font_size, "OUTLINE")
end

function pfUI.api.CreateScrollFrame(name, parent)
  local f = CreateFrame("ScrollFrame", name, parent)

  f.Scroll = function(self, step)
    local current = self:GetVerticalScroll()
    local new = current + step*-25
    local max = self:GetVerticalScrollRange() + 25

    if max > 25 then
      if new < 0 then
        self:SetVerticalScroll(0)
      elseif new > max then
        self:SetVerticalScroll(max)
      else
        self:SetVerticalScroll(new)
      end
    end

    self:UpdateScrollState()
  end

  f:EnableMouseWheel(1)

  f.deco_up = CreateFrame("Frame", nil, f)
  f.deco_up:SetPoint("TOPLEFT", f, "TOPLEFT", -4, 4)
  f.deco_up:SetPoint("BOTTOMRIGHT", f, "TOPRIGHT", 4, -25)

  f.deco_up.fader = f.deco_up:CreateTexture("OVERLAY")
  f.deco_up.fader:SetTexture(1,1,1,1)
  f.deco_up.fader:SetGradientAlpha("VERTICAL", 0, 0, 0, 0, 0, 0, 0, 1)
  f.deco_up.fader:SetAllPoints(f.deco_up)

  f.deco_up_indicator = CreateFrame("Button", nil, f.deco_up)
  f.deco_up_indicator:SetFrameLevel(128)
  f.deco_up_indicator:Hide()
  f.deco_up_indicator:SetPoint("TOP", f.deco_up, "TOP", 0, -6)
  f.deco_up_indicator:SetHeight(12)
  f.deco_up_indicator:SetWidth(12)
  f.deco_up_indicator.modifier = 0.03
  f.deco_up_indicator:SetScript("OnClick", function()
    local f = this:GetParent():GetParent()
    f:Scroll(3)
  end)

  f.deco_up_indicator:SetScript("OnUpdate", function()
    local alpha = this:GetAlpha()
    local fpsmod = GetFramerate() / 30

    if alpha >= .75 then
      this.modifier = -0.03 / fpsmod
    elseif alpha <= .25 then
      this.modifier = 0.03  / fpsmod
    end

    this:SetAlpha(alpha + this.modifier)
  end)

  f.deco_up_indicator.tex = f.deco_up_indicator:CreateTexture("OVERLAY")
  f.deco_up_indicator.tex:SetTexture("Interface\\AddOns\\pfQuest\\compat\\up")
  f.deco_up_indicator.tex:SetAllPoints(f.deco_up_indicator)

  f.deco_down = CreateFrame("Frame", nil, f)
  f.deco_down:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", -4, -4)
  f.deco_down:SetPoint("TOPRIGHT", f, "BOTTOMRIGHT", 4, 25)

  f.deco_down.fader = f.deco_down:CreateTexture("OVERLAY")
  f.deco_down.fader:SetTexture(1,1,1,1)
  f.deco_down.fader:SetGradientAlpha("VERTICAL", 0, 0, 0, 1, 0, 0, 0, 0)
  f.deco_down.fader:SetAllPoints(f.deco_down)

  f.deco_down_indicator = CreateFrame("Button", nil, f.deco_down)
  f.deco_down_indicator:SetFrameLevel(128)
  f.deco_down_indicator:Hide()
  f.deco_down_indicator:SetPoint("BOTTOM", f.deco_down, "BOTTOM", 0, 6)
  f.deco_down_indicator:SetHeight(12)
  f.deco_down_indicator:SetWidth(12)
  f.deco_down_indicator.modifier = 0.03
  f.deco_down_indicator:SetScript("OnClick", function()
    local f = this:GetParent():GetParent()
    f:Scroll(-3)
  end)

  f.deco_down_indicator:SetScript("OnUpdate", function()
    local alpha = this:GetAlpha()
    local fpsmod = GetFramerate() / 30

    if alpha >= .75 then
      this.modifier = -0.03 / fpsmod
    elseif alpha <= .25 then
      this.modifier = 0.03 / fpsmod
    end

    this:SetAlpha(alpha + this.modifier)
  end)

  f.deco_down_indicator.tex = f.deco_down_indicator:CreateTexture("OVERLAY")
  f.deco_down_indicator.tex:SetTexture("Interface\\AddOns\\pfQuest\\compat\\down")
  f.deco_down_indicator.tex:SetAllPoints(f.deco_down_indicator)

  f.UpdateScrollState = function(self)
    -- Update Scroll Indicators: Hide/Show if required.
    local current = floor(self:GetVerticalScroll())
    local max = floor(self:GetVerticalScrollRange() + 25)

    if current > 0 then
      self.deco_up_indicator:Show()
    else
      self.deco_up_indicator:Hide()
    end

    if max > 25 and current < max then
      self.deco_down_indicator:Show()
      self.deco_down_indicator:SetAlpha(.75)
    else
      self.deco_down_indicator:Hide()
    end
  end

  f:SetScript("OnMouseWheel", function()
    this:Scroll(arg1)
  end)

  return f
end

function pfUI.api.CreateScrollChild(name, parent)
  local f = CreateFrame("Frame", name, parent)

  -- dummy values required
  f:SetWidth(1)
  f:SetHeight(1)
  f:SetAllPoints(parent)

  parent:SetScrollChild(f)

  -- OnShow is fired too early, postpone to the first frame draw
  f:SetScript("OnUpdate", function()
    this:GetParent():UpdateScrollState()
    this:SetScript("OnUpdate", nil)
  end)

  return f
end
