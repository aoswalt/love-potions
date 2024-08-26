local screen = require('gfx/screen')
local Color = require('gfx/color')

local M = {}

function M.pixel(x, y, r, g, b, a)
  if r.__index == Color then
    r, g, b, a = r:rgba()
    screen.setPixel(x, y, r, g, b, a)
  else
    screen.setPixel(x, y, r, g, b, a)
  end
end

return M
