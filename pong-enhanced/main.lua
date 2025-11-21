require('util')

local pi = 3.141592

local gameWidth, gameHeight = 640, 480

local batWidth = 20
local batHeight = 100
local batSpeed = 200
local ballSize = 30
local ballSpeed = 225

---expects self to have x, y, and radius
local function drawCircle(self)
  love.graphics.circle('fill', self.x, self.y, self.radius)
end

---simple AABB check
local function nearBat(ball, bat)
  return ball.x - ball.radius <= bat.x + bat.width / 2 and
      ball.x + ball.radius >= bat.x - bat.width / 2 and
      ball.y - ball.radius >= bat.y - bat.height / 2 and
      ball.y + ball.radius <= bat.y + bat.height / 2
end

local function dot(x1, y1, x2, y2)
  return x1 * x2 + y1 * y2
end

-- https://www.sevenson.com.au/programming/sat/
local function handleCollision(ball, bat)
  local minAxisOverlap = math.huge
  local minAxisX = nil
  local minAxisY = nil

  for ix = 1, #bat.shape, 2 do
    local x1 = bat.shape[ix]
    local y1 = bat.shape[ix + 1]

    local x2
    local y2

    if ix + 2 > #bat.shape then
      x2 = bat.shape[1]
      y2 = bat.shape[2]
    else
      x2 = bat.shape[ix + 2]
      y2 = bat.shape[ix + 3]
    end

    local axisX = -(y2 - y1)
    local axisY = x2 - x1

    local axisMag = math.sqrt(axisX ^ 2 + axisY ^ 2)

    if axisMag ~= 0 then
      axisX = axisX / axisMag
      axisY = axisY / axisMag
    end

    local p1min = dot(axisX, axisY, x1, y1)
    local p1max = p1min

    for j = 1, #bat.shape, 2 do
      local vertDot = dot(axisX, axisY, bat.shape[j], bat.shape[j + 1])
      p1min = math.min(p1min, vertDot)
      p1max = math.max(p1max, vertDot)
    end

    local centerProjection = dot(axisX, axisY, ball.x, ball.y)
    local p2min = centerProjection - ball.radius
    local p2max = centerProjection + ball.radius

    -- quick overlap test of the min and max from both polygons
    if (p1min - p2max > 0) or (p2min - p1max > 0) then
      -- there is a gap - bail
      return
    end

    -- keep track of which axis has the smallest shadow overlap (and how much of an overlap that was) then you can apply that value to the shapes to separate them.
    local minOverlap = math.min(p1min - p2max, p2min - p1max)

    if minOverlap < minAxisOverlap then
      minAxisOverlap = minOverlap
      minAxisX = axisX
      minAxisY = axisY
    end
  end

  ball.x = ball.x + minAxisX
  ball.y = ball.y + minAxisY
  -- ball:setSpeed(0, 0)

  local dotted = dot(ball.speedX, ball.speedY, minAxisX, minAxisY)

  local reflectX = ball.speedX - 2 * dotted * minAxisX
  local reflectY = ball.speedY - 2 * dotted * minAxisY

  ball:setSpeed(reflectX, reflectY)
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

local function buildBatVerticies(flipHoriz)
  -- shape math is done from 0 to 1
  local trArcCenter = { x = 0.5, y = 0.25 }
  local brArcCenter = { x = 0.5, y = 0.75 }
  local arcSteps = 4
  local arcSize = { x = 0.5, y = 0.25 }

  local verticies = {}

  -- tl
  table.insert(verticies, 0)
  table.insert(verticies, 0)

  -- tr
  for i = 0, arcSteps do
    local startRad = pi * 1.5 -- start at 3/4
    local rad = startRad + pi / 2 * i / arcSteps

    table.insert(verticies, trArcCenter.x + math.cos(rad) * arcSize.x)
    table.insert(verticies, trArcCenter.y + math.sin(rad) * arcSize.y)
  end

  -- br
  for i = 0, arcSteps do
    local startRad = 0 -- start at 0
    local rad = startRad + pi / 2 * i / arcSteps

    table.insert(verticies, brArcCenter.x + math.cos(rad) * arcSize.x)
    table.insert(verticies, brArcCenter.y + math.sin(rad) * arcSize.y)
  end

  -- bl
  table.insert(verticies, 0)
  table.insert(verticies, 1)

  if flipHoriz then
    for ix, val in ipairs(verticies) do
      -- 1 indexed, so start at 1 for checks
      if ix % 2 == 1 then
        verticies[ix] = 1 - val
      end
    end
  end

  return verticies
end

local function buildScaledBatShape(width, height, flipHoriz)
  local verticies = buildBatVerticies(flipHoriz)

  local scaledVerts = {}

  -- scale to bat size
  for ix, val in ipairs(verticies) do
    -- 1 indexed, so start at 1 for checks
    if ix % 2 == 1 then
      scaledVerts[ix] = val * width
    else
      scaledVerts[ix] = val * height
    end
  end

  return scaledVerts
end

local function drawBat(bat)
  love.graphics.polygon('fill', bat.shape)
end

local function updateBat(bat, dt)
  bat.x = bat.x + bat.speedX * batSpeed * dt
  bat.y = bat.y + bat.speedY * batSpeed * dt

  local newShape = {}

  for ix, val in ipairs(bat.baseShape) do
    -- 1 indexed, so start at 1 for checks
    if ix % 2 == 1 then
      newShape[ix] = val + bat.x - bat.width / 2
    else
      newShape[ix] = val + bat.y - bat.height / 2
    end
  end

  bat.shape = newShape
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
  baseShape = buildScaledBatShape(batWidth, batHeight),
  shape = {},
  draw = drawBat,
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
  baseShape = buildScaledBatShape(batWidth, batHeight, true),
  shape = {},
  draw = drawBat,
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
  if ball.x < gameWidth * 0.2 and nearBat(ball, bat1) then
    handleCollision(ball, bat1)
  end

  -- returning p2
  if ball.x > gameWidth * 0.8 and nearBat(ball, bat2) then
    handleCollision(ball, bat2)
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
