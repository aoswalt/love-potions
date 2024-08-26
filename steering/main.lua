local Vector = require("vector")
local Boid = require("boid")

function love.load()
  pos = Vector(50, 75)
  boid = Boid.new(Vector(100, 200))
  boid2 = Boid.new(Vector(400, 200))
  boid2.mass = 5
end

local gravity = Vector(0, 1):norm():scale(3)

function love.update(dt)
  -- boid:applyForce(gravity * boid.mass)
  -- boid2:applyForce(gravity * boid2.mass)

  local mouseX, mouseY = love.mouse.getPosition()
  local mouseVec = Vector(mouseX, mouseY)

  -- boid:keepInBounds()
  boid:seek(mouseVec)
  boid:update(dt)

  -- boid2:keepInBounds()
  boid2:seek(mouseVec)
  boid2:update(dt)
end

function love.draw()
  boid:draw()
  boid2:draw()
  love.graphics.rectangle("fill", pos.x, pos.y, 25, 25)
end

function love.keypressed(_key, scancode)
  if scancode == "backspace" then
    love.event.quit("restart") -- recreates the whole lua state from scratch.
  end
end
