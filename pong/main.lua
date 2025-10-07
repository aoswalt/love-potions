require('util')

local gameWidth, gameHeight = 640, 480

local batWidth = 20
local batHeight = 100
local batSpeed = 200
local ballSize = 30
local ballSpeed = 100

local function drawRect(self)
  love.graphics.rectangle('fill', self.x - self.width / 2, self.y - self.height / 2, self.width, self.height)
end

local bat1 = { x = 40, y = gameHeight / 2, width = batWidth, height = batHeight, draw = drawRect }
local bat2 = { x = gameWidth - 40, y = gameHeight / 2, width = batWidth, height = batHeight, draw = drawRect }
local ball = {
  x = gameWidth / 2,
  y = gameHeight / 2,
  width = ballSize,
  height = ballSize,
  speedX = 0,
  speedY = 0,
  draw = drawRect
}
local match = {
  started = false,
  score1 = 0,
  score2 = 0,
}

local function reset()
  ball.x = gameWidth / 2
  ball.y = gameHeight / 2
  ball.speedX = 0
  ball.speedY = 0
  match.started = false
end

function love.load()
  love.graphics.setDefaultFilter('nearest')

  local font = love.graphics.newFont(56)
  font:setFilter('nearest')
  love.graphics.setFont(font)

  math.randomseed(os.time())
end

function love.update(dt)
  if love.keyboard.isDown('w') then
    if bat1.y - bat1.height / 2 - batSpeed * dt > 0 then
      bat1.y = bat1.y - batSpeed * dt
    end
  elseif love.keyboard.isDown('s') then
    if bat1.y + bat1.height / 2 + batSpeed * dt < gameHeight then
      bat1.y = bat1.y + batSpeed * dt
    end
  end

  if love.keyboard.isDown('up') then
    if bat2.y - bat2.height / 2 - batSpeed * dt > 0 then
      bat2.y = bat2.y - batSpeed * dt
    end
  elseif love.keyboard.isDown('down') then
    if bat2.y + bat2.height / 2 + batSpeed * dt < gameHeight then
      bat2.y = bat2.y + batSpeed * dt
    end
  end

  if love.keyboard.isDown('space') and not match.started then
    match.started = true

    local speedMult = 1.5

    local dirNum = math.random(1, 4)

    local dir = {
      [1] = { x = 1, y = -1 },  -- TR
      [2] = { x = 1, y = 1 },   -- BR
      [3] = { x = -1, y = 1 },  -- BL
      [4] = { x = -1, y = -1 }, -- TL
    }

    ball.speedX = dir[dirNum].x * speedMult
    ball.speedY = dir[dirNum].y * speedMult
  end

  ball.x = ball.x + ball.speedX * ballSpeed * dt
  ball.y = ball.y + ball.speedY * ballSpeed * dt

  if ball.x - ball.width / 2 <= 0 then
    ball.speedX = -ball.speedX
    ball.x = ball.width / 2
    match.score2 = match.score2 + 1
    reset()
  elseif ball.x + ball.width / 2 >= gameWidth then
    ball.speedX = -ball.speedX
    ball.x = gameWidth - ball.width / 2
    match.score1 = match.score1 + 1
    reset()
  end

  if ball.y - ball.height / 2 <= 0 then
    ball.speedY = -ball.speedY
    ball.y = ball.height / 2
  elseif ball.y + ball.height / 2 >= gameHeight then
    ball.speedY = -ball.speedY
    ball.y = gameHeight - ball.height / 2
  end

  if ball.x - ball.width / 2 <= bat1.x + bat1.width / 2 and
      ball.x + ball.width / 2 >= bat1.x - bat1.width / 2 and
      ball.y - ball.height / 2 >= bat1.y - bat1.height / 2 and
      ball.y + ball.height / 2 <= bat1.y + bat1.height / 2
  then
    ball.x = ball.width / 2 + bat1.x + bat1.width / 2
    ball.speedX = -ball.speedX
  end

  if ball.x - ball.width / 2 <= bat2.x + bat2.width / 2 and
      ball.x + ball.width / 2 >= bat2.x - bat2.width / 2 and
      ball.y - ball.height / 2 >= bat2.y - bat2.height / 2 and
      ball.y + ball.height / 2 <= bat2.y + bat2.height / 2
  then
    ball.x = bat2.x - bat2.width / 2 - ball.width / 2
    ball.speedX = -ball.speedX
  end
end

function love.draw()
  local winWidth, winHeight = love.graphics.getDimensions()
  love.graphics.scale(winWidth / gameWidth, winHeight / gameHeight)

  bat1:draw()
  bat2:draw()
  ball:draw()

  love.graphics.print(tostring(match.score1), 25, 25)
  love.graphics.print(tostring(match.score2), gameWidth - 25 - 40, 25)
end

function love.keypressed(_key, scancode)
  if scancode == 'backspace' then
    love.event.quit('restart') -- recreates the whole lua state from scratch.
  elseif scancode == 'f1' then
    debug.debug()              -- pause and enter debug terminal
  end
end
