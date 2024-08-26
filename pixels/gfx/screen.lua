local M = {}

local drawWidth
local drawHeight

local pixels = nil
local img = nil

function M.setup(width, height)
  drawWidth = width
  drawHeight = height

  pixels = love.image.newImageData(drawWidth, drawHeight)
  img = love.graphics.newImage(pixels)
end

function M.getDimensions()
  return drawWidth, drawHeight
end

function M.redraw()
  img:replacePixels(pixels)

  local winWidth, winHeight = love.graphics.getDimensions()
  love.graphics.draw(img, 0, 0, 0, winWidth / drawWidth, winHeight / drawHeight)
end

function M.setPixel(x, y, r, g, b, a)
  pixels:setPixel(x, y, r, g, b)
end

return M
