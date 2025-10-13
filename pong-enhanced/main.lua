require('util')

local gameWidth, gameHeight = 640, 480

local batWidth = 20
local batHeight = 100
local batSpeed = 200
local ballSize = 30
local ballSpeed = 225

---expects self to have x, y, width, and height
local function drawRect(self)
  love.graphics.rectangle('fill', self.x - self.width / 2, self.y - self.height / 2, self.width, self.height)
end

---expects self to have x, y, and radius
local function drawCircle(self)
  love.graphics.circle('fill', self.x, self.y, self.radius)
end

---AABB
local function intersectRectRect(r1, r2)
  return r1.x - r1.width / 2 <= r2.x + r2.width / 2 and
      r1.x + r1.width / 2 >= r2.x - r2.width / 2 and
      r1.y - r1.height / 2 >= r2.y - r2.height / 2 and
      r1.y + r1.height / 2 <= r2.y + r2.height / 2
end

-- https://stackoverflow.com/a/402010
local function intersectCircleRect(circle, rect)
  -- simplify to only have to work in a single quadrant
  local circleDistX = math.abs(circle.x - rect.x)
  local circleDistY = math.abs(circle.y - rect.y)

  -- check easy far enough away
  if circleDistX > (rect.width / 2 + circle.radius) then return false end
  if circleDistY > (rect.height / 2 + circle.radius) then return false end

  -- check easy close enugh to guarantee
  if (circleDistX <= (rect.width / 2)) then return true end
  if (circleDistY <= (rect.height / 2)) then return true end

  -- calculate corner range that could overlap
  local cornerDistSq = (circleDistX - rect.width / 2) ^ 2 +
      (circleDistY - rect.height / 2) ^ 2

  -- compare corner range to radius
  return cornerDistSq <= (circle.radius ^ 2)
end

local controls = {
  p1 = {
    x = 0.0,
    y = 0.0,
  },
  p2 = {
    x = 0.0,
    y = 0.0,
  },
  confirm = false,
}

local function updateBat(bat, dt)
  bat.x = bat.x + bat.speedX * batSpeed * dt
  bat.y = bat.y + bat.speedY * batSpeed * dt
end

local function setBatSpeed(bat, x, y)
  bat.speedX = x
  bat.speedY = y
end

local bat1 = {
  x = 40,
  y = gameHeight / 2,
  speedX = 0,
  speedY = 0,
  width = batWidth,
  height = batHeight,
  draw = drawRect,
  update = updateBat,
  setSpeed = setBatSpeed,
}

local bat2 = {
  x = gameWidth - 40,
  y = gameHeight / 2,
  speedX = 0,
  speedY = 0,
  width = batWidth,
  height = batHeight,
  draw = drawRect,
  update = updateBat,
  setSpeed = setBatSpeed,
}


local ball = {
  x = gameWidth / 2,
  y = gameHeight / 2,
  radius = ballSize / 2,
  trail = {},
  trailDuration = 0.1,
  trailTimeout = 0,
  trailMaxLength = 40,
  speedX = 0,
  speedY = 0,
  draw = function(ball)
    if #ball.trail > 1 then
      for i = #ball.trail, 2, -1 do
        local widthPct = ((#ball.trail - (i + 1)) / #ball.trail) * 0.8
        local width = widthPct * ball.radius * 2
        love.graphics.setLineWidth(width)
        love.graphics.setColor(widthPct, widthPct, widthPct)
        love.graphics.line(ball.trail[i - 1].x, ball.trail[i - 1].y, ball.trail[i].x, ball.trail[i].y)
        love.graphics.circle('fill', ball.trail[i].x, ball.trail[i].y, width / 2)
      end
    end

    love.graphics.setColor(1, 1, 1)
    drawCircle(ball)
  end,
  update = function(ball, dt)
    ball.x = ball.x + ball.speedX * ballSpeed * dt
    ball.y = ball.y + ball.speedY * ballSpeed * dt

    if ball.speedX ~= 0 or ball.speedY ~= 0 then
      table.insert(ball.trail, 1, { x = ball.x, y = ball.y })
    end

    ball.trailTimeout = ball.trailTimeout + dt

    if ball.trailTimeout >= ball.trailDuration then
      ball.trailTimeout = ball.trailTimeout - ball.trailDuration
      ball.trail[#ball.trail] = nil
    end

    while #ball.trail > ball.trailMaxLength do
      ball.trail[#ball.trail] = nil
    end
  end,
  setSpeed = function(ball, x, y)
    ball.speedX = x
    ball.speedY = y
  end
}

local match = {
  started = false,
  score1 = 0,
  score2 = 0,
}

local function lerp(pct)
  return pct
end

local camera = {
  offset = { x = 0.0, y = 0.0 },
  motion = {
    x = {
      fn = lerp,
      pct = 1.0,
      mag = 0,
      speed = 1.0,
    },
    y = {
      fn = lerp,
      pct = 1.0,
      mag = 0,
      speed = 1.0,
    },
  },
  update = function(camera, dt)
    camera.motion.x.pct = camera.motion.x.pct + (dt * camera.motion.x.speed)

    if camera.motion.x.pct < 1 then
      local off = camera.motion.x.fn(camera.motion.x.pct) * camera.motion.x.mag
      camera.offset.x = off
    else
      camera.offset.x = 0
    end

    camera.motion.y.pct = camera.motion.y.pct + (dt * camera.motion.y.speed)

    if camera.motion.y.pct < 1 then
      local off = camera.motion.y.fn(camera.motion.y.pct) * camera.motion.y.mag
      camera.offset.y = off
    else
      camera.offset.y = 0
    end
  end,
  -- TODO fn to accept force and use spring to settle
  bump = function(camera, dir)
    local dirNum

    -- flipped to deal with given easing function not returning to 0
    if dir == 'l' then
      dirNum = 1
    elseif dir == 'r' then
      dirNum = -1
    else
      error(dir)
    end

    camera.motion.x.mag = dirNum * 50
    camera.motion.x.pct = 0
    camera.motion.x.speed = 1.5
    camera.motion.x.fn = function(pct)
      local c4 = (2 * math.pi) / 3

      return math.pow(2, -10 * pct) * math.sin((pct * 10 - 0.75) * c4)
    end
  end
}

local function reset()
  ball.x = gameWidth / 2
  ball.y = gameHeight / 2
  ball.speedX = 0
  ball.speedY = 0
  ball.trail = {}
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
  bat1:setSpeed(controls.p1.x, controls.p1.y)
  bat2:setSpeed(controls.p2.x, controls.p2.y)

  bat1:update(dt)
  bat2:update(dt)

  if bat1.y - bat1.height / 2 < 0 then
    bat1.y = bat1.height / 2
  elseif bat1.y + bat1.height / 2 > gameHeight then
    bat1.y = gameHeight - bat1.height / 2
  end

  if bat2.y - bat2.height / 2 < 0 then
    bat2.y = bat2.height / 2
  elseif bat2.y + bat2.height / 2 > gameHeight then
    bat2.y = gameHeight - bat2.height / 2
  end

  if controls.confirm and not match.started then
    controls.confirm = false
    match.started = true

    -- 45 deg angle range + 25 deg from orig
    local angleRad = math.random() * math.pi / 4 + math.pi / 8

    local x = math.cos(angleRad)
    local y = math.sin(angleRad)

    local dirNum = math.random(1, 4)

    local dir = {
      [1] = { x = 1, y = -1 },  -- TR
      [2] = { x = 1, y = 1 },   -- BR
      [3] = { x = -1, y = 1 },  -- BL
      [4] = { x = -1, y = -1 }, -- TL
    }

    ball:setSpeed(dir[dirNum].x * x, dir[dirNum].y * y)
  end

  ball:update(dt)

  -- scoring
  if ball.x - ball.radius <= 0 then
    ball.speedX = -ball.speedX
    ball.x = ball.radius
    match.score2 = match.score2 + 1
    camera:bump('l')
    reset()
  elseif ball.x + ball.radius >= gameWidth then
    ball.speedX = -ball.speedX
    ball.x = gameWidth - ball.radius
    match.score1 = match.score1 + 1
    camera:bump('r')
    reset()
  end

  -- keeping in bounds
  if ball.y - ball.radius <= 0 then
    ball.speedY = -ball.speedY
    ball.y = ball.radius
  elseif ball.y + ball.radius >= gameHeight then
    ball.speedY = -ball.speedY
    ball.y = gameHeight - ball.radius
  end

  -- returning p1
  if intersectCircleRect(ball, bat1) then
    ball.x = ball.radius + bat1.x + bat1.width / 2
    ball.speedX = -ball.speedX
  end

  -- returning p2
  if intersectCircleRect(ball, bat2) then
    ball.x = bat2.x - bat2.width / 2 - ball.radius
    ball.speedX = -ball.speedX
  end

  camera:update(dt)
end

function love.draw()
  local winWidth, winHeight = love.graphics.getDimensions()
  love.graphics.scale(winWidth / gameWidth, winHeight / gameHeight)

  love.graphics.push()

  love.graphics.translate(camera.offset.x, camera.offset.y)

  love.graphics.setColor(1, 1, 1)

  bat1:draw()
  bat2:draw()
  ball:draw()

  love.graphics.pop()

  love.graphics.print(tostring(match.score1), 25, 25)
  love.graphics.print(tostring(match.score2), gameWidth - 25 - 40, 25)
end

function love.keypressed(_key, scancode)
  local switch = {
    w = function() controls.p1.y = -1.0 end,
    s = function() controls.p1.y = 1.0 end,
    up = function() controls.p2.y = -1.0 end,
    down = function() controls.p2.y = 1.0 end,
    space = function() controls.confirm = true end,
    backspace = function() love.event.quit('restart') end, -- recreates the whole lua state from scratch.
    f1 = function() debug.debug() end,                     -- pause and enter debug terminal
  }

  local fn = switch[scancode]

  if fn then
    fn()
  end
end

function love.keyreleased(_key, scancode)
  local switch = {
    w = function() controls.p1.y = 0.0 end,
    s = function() controls.p1.y = 0.0 end,
    up = function() controls.p2.y = 0.0 end,
    down = function() controls.p2.y = 0.0 end,
  }

  local fn = switch[scancode]

  if fn then
    fn()
  end
end
