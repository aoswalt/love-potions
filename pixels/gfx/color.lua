local Color = {}
Color.__index = Color

function Color.newRGBA(r, g, b, a)
  local color = {
    rgb = { r = r, g = g, b = b },
    a = a,
  }
  setmetatable(color, Color)
  return color
end

function Color.__eq(a, b)
  return a.rgb.r == b.rgb.r and a.rgb.g == b.rgb.g and a.rgb.b == b.rgb.b and a.rgb.a == b.rgb.a
end

function Color.__tostring(self)
  return 'Color: red='
    .. tostring(self.rgb.r)
    .. ' green='
    .. tostring(self.rgb.g)
    .. ' blue='
    .. tostring(self.rgb.b)
    .. ' alpha='
    .. tostring(self.rgb.a)
end

function Color.rgba(self)
  return self.rgb.r, self.rgb.g, self.rgb.b, self.rgb.a
end

function Color.newHSLA(h, s, l, a)
  r = r
  g = g
  b = b
  a = a
end

local function rgbToHsl(r, g, b)
  local rPct = r / 255
  local gPct = g / 255
  local bPct = b / 255

  local chromaMax = math.max(rPct, gPct, bPct)
  local chromaMin = math.min(rPct, gPct, bPct)

  local hue = 0
  local sat = 0

  -- average of largest and smallest
  local lum = (chromaMax + chromaMin) / 2

  -- no saturation if equal
  if chromaMax ~= chromaMin then
    local chroma = chromaMax - chromaMin

    -- saturation is simply the chroma scaled to fill the interval [0, 1] for every combination of hue and lightness
    sat = chroma / (1 - math.abs(2 * lum - 1))

    if rPct == chromaMax then
      local segment = (g - b) / c
      local shift = 0 / 60 -- R° / (360° / hex sides)
      if segment < 0 then -- hue > 180, full rotation
        shift = 360 / 60 -- R° / (360° / hex sides)
      end
      hue = segment + shift
    elseif gPct == chromaMax then
      local segment = (b - r) / c
      local shift = 120 / 60 -- G° / (360° / hex sides)
      hue = segment + shift
    elseif bPct == chromaMax then
      local segment = (r - g) / c
      local shift = 240 / 60 -- B° / (360° / hex sides)
      hue = segment + shift
    end
  end

  hue = (hue * 60) -- degrees
  sat = (sat * 100) -- percent
  lum = (lum * 100) -- percent

  return hue, sat, lum
end

return Color
