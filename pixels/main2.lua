function love.load()
  winWidth, winHeight = love.graphics.getDimensions()

  pos = { x = 0, y = 100 }
  box = { x = winWidth / 2, y = winHeight / 2, width = 50, height = 50 }
  dir = 1
  velocity = 150
end

function love.update(dt)
  pos.x = pos.x + velocity * dir * dt

  width, height = love.graphics.getDimensions()

  if pos.x > width then
    pos.x = width
    dir = dir * -1
  elseif pos.x < 0 then
    pos.x = 0
    dir = dir * -1
  end

  if love.keyboard.isDown('space') then
    pos.y = 400
  else
    pos.y = 200
  end

  mouseX, mouseY = love.mouse.getPosition()
  box.x = mouseX
  box.y = mouseY

  if love.mouse.isDown(1) then
    box.width = 75
    box.height = 75
  else
    box.width = 50
    box.height = 50
  end
end

function love.draw()
  love.graphics.setColor(0, 0, 0)
  love.graphics.print('Hello World', 400, 300)

  love.graphics.setColor(0, 0.6, 1)
  love.graphics.rectangle('fill', box.x, box.y, box.width, box.height)

  love.graphics.setColor(1, 0, 0)
  love.graphics.circle('line', pos.x, pos.y, 25)
end
