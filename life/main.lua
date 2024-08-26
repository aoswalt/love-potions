local Board = require("board")

function love.load()
  board = Board.new()

  t = 0

  updateTime = 0.5
  nextUpdate = updateTime
end

function love.update(dt)
  t = t + dt

  nextUpdate = nextUpdate - dt


  if nextUpdate <= 0 then
    board:update()
    nextUpdate = updateTime
  end
end

function love.draw()
  love.graphics.setBackgroundColor(0.1, 0.1, 0.1)

  love.graphics.push()

  -- love.graphics.translate(10 * math.sin(t), 10)

  board:draw()

  love.graphics.pop()
end
