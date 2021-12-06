-- Initialize pfUI core table for non-pfUI environments
if not pfUI then
  pfUI = {
    ["api"] = {},
    ["cache"] = {},
    ["backdrop"] = {
      bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      tile = true, tileSize = 16, edgeSize = 16,
      insets = { left = 3, right = 3, top = 3, bottom = 3 }
    },
    ["backdrop_small"] = {
      bgFile = "Interface\\BUTTONS\\WHITE8X8", tile = false, tileSize = 0,
      edgeFile = "Interface\\BUTTONS\\WHITE8X8", edgeSize = 1,
      insets = {left = 0, right = 0, top = 0, bottom = 0},
    },
    ["font_default"] = STANDARD_TEXT_FONT,
   }

  pfUI_config = {
    ["appearance"] = {
      ["border"] = {
        ["default"] = "3",
      }
    },
    ["global"] = {
      ["font_size"] = 12
    },
    -- fix for old questie releases
    ["disabled"] = {
      ["minimap"] = "1"
    }
  }
end

-- Add API support non-pfUI environments and for old pfUI versions:
-- strsplit, SanitizePattern, CreateBackdrop, SkinButton, CreateScrollFrame, CreateScrollChild
if pfUI.api and pfUI.api.strsplit and pfUI.api.CreateBackdrop and
   pfUI.api.SkinButton and pfUI.api.CreateScrollFrame and
   pfUI.api.CreateScrollChild and pfUI.api.SanitizePattern then
     return
end

pfUI.api.emulated = true

function pfUI.api.strsplit(delimiter, subject)
  if not subject then return nil end
  local delimiter, fields = delimiter or ":", {}
  local pattern = string.format("([^%s]+)", delimiter)
  string.gsub(subject, pattern, function(c) fields[table.getn(fields)+1] = c end)
  return unpack(fields)
end

local sanitize_cache = {}
function pfUI.api.SanitizePattern(pattern, dbg)
  if not sanitize_cache[pattern] then
    local ret = pattern
    -- escape magic characters
    ret = gsub(ret, "([%+%-%*%(%)%?%[%]%^])", "%%%1")
    -- remove capture indexes
    ret = gsub(ret, "%d%$","")
    -- catch all characters
    ret = gsub(ret, "(%%%a)","%(%1+%)")
    -- convert all %s to .+
    ret = gsub(ret, "%%s%+",".+")
    -- set priority to numbers over strings
    ret = gsub(ret, "%(.%+%)%(%%d%+%)","%(.-%)%(%%d%+%)")
    -- cache it
    sanitize_cache[pattern] = ret
  end

  return sanitize_cache[pattern]
end

local er, eg, eb, ea = .4,.4,.4,1
local br, bg, bb, ba = 0,0,0,1
function pfUI.api.CreateBackdrop(f, inset, legacy, transp)
  -- exit if now frame was given
  if not f then return end

  -- use default inset if nothing is given
  local border = inset
  if not border then
    border = tonumber(pfUI_config.appearance.border.default)
  end

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

  -- create slider
  f.slider = CreateFrame("Slider", nil, f)
  f.slider:SetOrientation('VERTICAL')
  f.slider:SetPoint("TOPLEFT", f, "TOPRIGHT", -7, 0)
  f.slider:SetPoint("BOTTOMRIGHT", 0, 0)
  f.slider:SetThumbTexture("Interface\\BUTTONS\\WHITE8X8")
  f.slider.thumb = f.slider:GetThumbTexture()
  f.slider.thumb:SetHeight(50)
  f.slider.thumb:SetTexture(.3,1,.8,.5)

  f.slider:SetScript("OnValueChanged", function()
    f:SetVerticalScroll(this:GetValue())
    f.UpdateScrollState()
  end)

  f.UpdateScrollState = function()
    f.slider:SetMinMaxValues(0, f:GetVerticalScrollRange())
    f.slider:SetValue(f:GetVerticalScroll())

    local m = f:GetHeight()+f:GetVerticalScrollRange()
    local v = f:GetHeight()
    local ratio = v / m

    if ratio < 1 then
      local size = math.floor(v * ratio)
      f.slider.thumb:SetHeight(size)
      f.slider:Show()
    else
      f.slider:Hide()
    end
  end

  f.Scroll = function(self, step)
    local step = step or 0

    local current = f:GetVerticalScroll()
    local max = f:GetVerticalScrollRange()
    local new = current - step

    if new >= max then
      f:SetVerticalScroll(max)
    elseif new <= 0 then
      f:SetVerticalScroll(0)
    else
      f:SetVerticalScroll(new)
    end

    f:UpdateScrollState()
  end

  f:EnableMouseWheel(1)
  f:SetScript("OnMouseWheel", function()
    this:Scroll(arg1*10)
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

  f:SetScript("OnUpdate", function()
    this:GetParent():UpdateScrollState()
  end)

  return f
end

-- [ round ]
-- Rounds a float number into specified places after comma.
-- 'input'      [float]         the number that should be rounded.
-- 'places'     [int]           amount of places after the comma.
-- returns:     [float]         rounded number.
function pfUI.api.round(input, places)
  if not places then places = 0 end
  if type(input) == "number" and type(places) == "number" then
    local pow = 1
    for i = 1, places do pow = pow * 10 end
    return floor(input * pow + 0.5) / pow
  end
end

-- [ rgbhex ]
-- Returns color format from color info
-- 'r'          [table or number]  color table or r color component
-- 'g'          [number] optional g color component
-- 'b'          [number] optional b color component
-- 'a'          [number] optional alpha component
-- returns color string in the form of '|caaxxyyzz'
local hexcolor_cache = {}
function pfUI.api.rgbhex(r, g, b, a)
  local key
  if type(r)=="table" then
    local _r,_g,_b,_a
    if r.r then
      _r,_g,_b,_a = r.r, r.g, r.b, r.a or 1
    elseif table.getn(r) >= 3 then
      _r,_g,_b,_a = r[1], r[2], r[3], r[4] or 1
    end
    if _r and _g and _b and _a then
      key = string.format("%s%s%s%s",_r,_g,_b,_a)
      if hexcolor_cache[key] == nil then
        hexcolor_cache[key] = string.format("|c%02x%02x%02x%02x", _a*255, _r*255, _g*255, _b*255)
      end
    end
  elseif tonumber(r) and g and b then
    a = a or 1
    key = string.format("%s%s%s%s",r,g,b,a)
    if hexcolor_cache[key] == nil then
      hexcolor_cache[key] = string.format("|c%02x%02x%02x%02x", a*255, r*255, g*255, b*255)
    end
  end
  return hexcolor_cache[key] or ""
end

-- [ GetColorGradient ] --
-- 'perc'     percentage (0-1)
-- return r,g,b and hexcolor
local gradientcolors = {}
function pfUI.api.GetColorGradient(perc)
  perc = perc > 1 and 1 or perc
  perc = perc < 0 and 0 or perc
  perc = floor(perc*100)/100

  local index = perc
  if not gradientcolors[index] then
    local r1, g1, b1, r2, g2, b2

    if perc <= 0.5 then
      perc = perc * 2
      r1, g1, b1 = 1, 0, 0
      r2, g2, b2 = 1, 1, 0
    else
      perc = perc * 2 - 1
      r1, g1, b1 = 1, 1, 0
      r2, g2, b2 = 0, 1, 0
    end

    local r = pfUI.api.round(r1 + (r2 - r1) * perc, 4)
    local g = pfUI.api.round(g1 + (g2 - g1) * perc, 4)
    local b = pfUI.api.round(b1 + (b2 - b1) * perc, 4)
    local h = pfUI.api.rgbhex(r,g,b)

    gradientcolors[index] = {}
    gradientcolors[index].r = r
    gradientcolors[index].g = g
    gradientcolors[index].b = b
    gradientcolors[index].h = h
  end

  return gradientcolors[index].r,
    gradientcolors[index].g,
    gradientcolors[index].b,
    gradientcolors[index].h
end


-- [ GetBestAnchor ]
-- Returns the best anchor of a frame, based on its position
-- 'self'       [frame]        the frame that should be checked
-- returns:     [string]       the name of the best anchor
function pfUI.api.GetBestAnchor(self)
  local scale = self:GetScale()
  local x, y = self:GetCenter()
  local a = GetScreenWidth()  / scale / 3
  local b = GetScreenWidth()  / scale / 3 * 2
  local c = GetScreenHeight() / scale / 3 * 2
  local d = GetScreenHeight() / scale / 3
  if not x or not y then return end

  if x < a and y > c then
    return "TOPLEFT"
  elseif x > a and x < b and y > c then
    return "TOP"
  elseif x > b and y > c then
    return "TOPRIGHT"
  elseif x < a and y > d and y < c then
    return "LEFT"
  elseif x > a and x < b and y > d and y < c then
    return "CENTER"
  elseif x > b and y > d and y < c then
    return "RIGHT"
  elseif x < a and y < d then
    return "BOTTOMLEFT"
  elseif x > a and x < b and y < d then
    return "BOTTOM"
  elseif x > b and y < d then
    return "BOTTOMRIGHT"
  end
end

-- [ ConvertFrameAnchor ]
-- Converts a frame anchor into another one while preserving the frame position
-- 'self'       [frame]        the frame that should get another anchor.
-- 'anchor'     [string]       the new anchor that shall be used
-- returns:     anchor, x, y   can directly be used in SetPoint()
function pfUI.api.ConvertFrameAnchor(self, anchor)
  local scale, x, y, _ = self:GetScale(), nil, nil, nil

  if anchor == "CENTER" then
    x, y = self:GetCenter()
    x, y = x - GetScreenWidth()/2/scale, y - GetScreenHeight()/2/scale
  elseif anchor == "TOPLEFT" then
    x, y = self:GetLeft(), self:GetTop() - GetScreenHeight()/scale
  elseif anchor == "TOP" then
    x, _ = self:GetCenter()
    x, y = x - GetScreenWidth()/2/scale, self:GetTop() - GetScreenHeight()/scale
  elseif anchor == "TOPRIGHT" then
    x, y = self:GetRight() - GetScreenWidth()/scale, self:GetTop() - GetScreenHeight()/scale
  elseif anchor == "RIGHT" then
    _, y = self:GetCenter()
    x, y = self:GetRight() - GetScreenWidth()/scale, y - GetScreenHeight()/2/scale
  elseif anchor == "BOTTOMRIGHT" then
    x, y = self:GetRight() - GetScreenWidth()/scale, self:GetBottom()
  elseif anchor == "BOTTOM" then
    x, _ = self:GetCenter()
    x, y = x - GetScreenWidth()/2/scale, self:GetBottom()
  elseif anchor == "BOTTOMLEFT" then
    x, y = self:GetLeft(), self:GetBottom()
  elseif anchor == "LEFT" then
    _, y = self:GetCenter()
    x, y = self:GetLeft(), y - GetScreenHeight()/2/scale
  end

  return anchor, pfUI.api.round(x, 2), pfUI.api.round(y, 2)
end
