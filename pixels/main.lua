-- luacheck: new globals r rDir doG

local screen = require('gfx/screen')
local draw = require('gfx/draw')
local Color = require('gfx/color')

function love.load()
  love.graphics.setDefaultFilter('nearest')

  screen.setup(40, 30)

  r = 0
  rDir = 1
end

function love.update(dt)
  local winWidth, winHeight = love.graphics.getDimensions()
  local drawWidth, drawHeight = screen.getDimensions()

  r = r + rDir * dt / 2

  if r >= 1 then
    rDir = -1
    r = 1
  elseif r <= 0 then
    rDir = 1
    r = 0
  end

  if love.keyboard.isDown('space') then
    doG = 1.0
  else
    doG = 0
  end

  local mouseX = math.floor(love.mouse.getX() / winWidth * drawWidth)
  local mouseY = math.floor(love.mouse.getY() / winHeight * drawHeight)

  for x = 0, drawWidth - 1 do
    for y = 0, drawHeight - 1 do
      local g = doG * y / drawHeight

      local b

      if love.mouse.isDown(1) then
        b = mouseX / x * mouseY / y
      else
        b = x / mouseX * y / mouseY
      end

      local c = Color.newRGBA(r, g, b)

      draw.pixel(x, y, c)
    end
  end
end

function love.draw()
  screen.redraw()
end

function love.keypressed(_key, scancode)
  if scancode == 'backspace' then
    love.event.quit('restart') -- recreates the whole lua state from scratch.
  end
end
