require('util')

local pi = 3.141592

local gameWidth, gameHeight = 640, 480

local batWidth = 20
local batHeight = 100
local batSpeed = 200
local ballSize = 30
local ballSpeed = 225

local world
local bat1
local bat2
local ball

local event

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

local shaders = {}

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

local Bat = {}

function Bat:new(args)
  args = args or {}

  local flipHoriz

  if args.label == 'p1' then
    flipHoriz = false
  elseif args.label == 'p2' then
    flipHoriz = true
  else
    error('invalid label for bat: ' .. tostring(args.label))
  end

  local verticies = buildScaledBatShape(batWidth, batHeight, flipHoriz)
  -- could explicitly build shapes instead of triangulating 1 large one
  local tris = love.math.triangulate(verticies)

  local b = {
    label = args.label
  }

  b.body = love.physics.newBody(world, args.x, args.y, 'dynamic')
  b.body:setFixedRotation(true)

  for _, tri in ipairs(tris) do
    local shape = love.physics.newPolygonShape(tri)
    local fixture = love.physics.newFixture(b.body, shape)
    fixture:setUserData(b)
  end

  setmetatable(b, self)
  self.__index = self
  return b
end

function Bat.draw(bat)
  for _, fix in ipairs(bat.body:getFixtures()) do
    local shape = fix:getShape()
    love.graphics.polygon("fill", bat.body:getWorldPoints(shape:getPoints()))
  end
end

function Bat.update(bat, dt)
end

local Ball = {}

function Ball:new(args)
  args = args or {}

  local b = {
    label = 'ball',
    radius = args.radius,
    trailDuration = 0.1,
    trailTimeout = 0,
    trailMaxLength = 40,
    trail = {}
  }

  b.body = love.physics.newBody(world, args.x, args.y, 'dynamic')
  b.shape = love.physics.newCircleShape(args.radius or ballSize / 2)
  b.fixture = love.physics.newFixture(b.body, b.shape)
  b.fixture:setRestitution(1)
  b.fixture:setUserData(b)

  setmetatable(b, self)
  self.__index = self
  return b
end

function Ball.draw(ball)
  local r, g, b, a = love.graphics.getColor()

  if #ball.trail > 1 then
    for i = #ball.trail, 2, -1 do
      local widthPct = ((#ball.trail - (i + 1)) / #ball.trail) * 0.8
      local width = widthPct * ball.radius * 2
      love.graphics.setLineWidth(width)
      love.graphics.setColor(widthPct * r, widthPct * g, widthPct * b)
      love.graphics.line(ball.trail[i - 1].x, ball.trail[i - 1].y, ball.trail[i].x, ball.trail[i].y)
      love.graphics.circle('fill', ball.trail[i].x, ball.trail[i].y, width / 2)
    end
  end

  love.graphics.setColor(r, g, b, a)
  love.graphics.circle('fill', ball.body:getX(), ball.body:getY(), ball.radius)
end

function Ball.update(ball, dt)
  local velX, velY = ball.body:getLinearVelocity()

  if velX ~= 0 or velY ~= 0 then
    table.insert(ball.trail, 1, { x = ball.body:getX(), y = ball.body:getY() })
  end

  ball.trailTimeout = ball.trailTimeout + dt

  if ball.trailTimeout >= ball.trailDuration then
    ball.trailTimeout = ball.trailTimeout - ball.trailDuration
    ball.trail[#ball.trail] = nil
  end

  while #ball.trail > ball.trailMaxLength do
    ball.trail[#ball.trail] = nil
  end
end

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
  event = nil
  ball.body:setPosition(gameWidth / 2, gameHeight / 2)
  ball.body:setLinearVelocity(0, 0)
  ball.trail = {}
  match.started = false
end

local function fixBallVelocity(body)
  local xVel, yVel = body:getLinearVelocity()
  local velLen = math.sqrt(xVel ^ 2 + yVel ^ 2)
  local xVelNorm = xVel / velLen
  local yVelNorm = yVel / velLen
  local xVelNew = xVelNorm * ballSpeed * 1.25
  local yVelNew = yVelNorm * ballSpeed * 1.25
  body:setLinearVelocity(xVelNew, yVelNew)
end

function love.load()
  love.graphics.setDefaultFilter('nearest')

  local font = love.graphics.newFont(56)
  font:setFilter('nearest')
  love.graphics.setFont(font)

  shaders.ballLight = love.graphics.newShader("ballLight.glsl")

  math.randomseed(os.time())

  world = love.physics.newWorld(0, 0)

  -- how to fix loss of x velocity when bouncing off of top/bottom wall? is it due to resolution?
  -- need info from contact or postSolve?
  world:setCallbacks(nil, function(a, b, _coll)
    local aData = a:getUserData()
    local aLabel = aData.label or aData
    local bData = b:getUserData()
    local bLabel = bData.label or aData

    -- scoring
    if aLabel == 'wallRight' and bLabel == 'ball' or aLabel == 'ball' and bLabel == 'wallRight' then
      event = 'p1_scored'
      return
    end

    if aLabel == 'wallLeft' and bLabel == 'ball' or aLabel == 'ball' and bLabel == 'wallLeft' then
      event = 'p2_scored'
      return
    end

    if aLabel == 'ball' then
      fixBallVelocity(a:getBody())
    end

    if bLabel == 'ball' then
      fixBallVelocity(b:getBody())
    end
  end)

  -- walls
  local wallTop = {}
  wallTop.body = love.physics.newBody(world, gameWidth / 2, -1, 'static')
  wallTop.shape = love.physics.newRectangleShape(gameWidth, 1)
  wallTop.fixture = love.physics.newFixture(wallTop.body, wallTop.shape)
  wallTop.fixture:setUserData('wallTop')

  local wallBottom = {}
  wallBottom.body = love.physics.newBody(world, gameWidth / 2, gameHeight + 1, 'static')
  wallBottom.shape = love.physics.newRectangleShape(gameWidth, 1)
  wallBottom.fixture = love.physics.newFixture(wallBottom.body, wallBottom.shape)
  wallBottom.fixture:setUserData('wallBottom')

  local wallLeft = {}
  wallLeft.body = love.physics.newBody(world, -1, gameHeight / 2, 'static')
  wallLeft.shape = love.physics.newRectangleShape(1, gameWidth)
  wallLeft.fixture = love.physics.newFixture(wallLeft.body, wallLeft.shape)
  wallLeft.fixture:setUserData('wallLeft')
  wallLeft.fixture:setSensor(true)

  local wallRight = {}
  wallRight.body = love.physics.newBody(world, gameWidth + 1, gameHeight / 2, 'static')
  wallRight.shape = love.physics.newRectangleShape(1, gameWidth)
  wallRight.fixture = love.physics.newFixture(wallRight.body, wallRight.shape)
  wallRight.fixture:setUserData('wallRight')
  wallRight.fixture:setSensor(true)

  bat1 = Bat:new({ label = 'p1', x = 20, y = gameHeight / 2 })
  bat2 = Bat:new({ label = 'p2', x = gameWidth - 40, y = gameHeight / 2 })
  ball = Ball:new({
    x = gameWidth / 2,
    y = gameHeight / 2,
    radius = ballSize / 2,
  })
end

function love.update(dt)
  if not event then
  elseif event == 'p1_scored' then
    match.score1 = match.score1 + 1
    camera:bump('r')
    reset()
  elseif event == 'p2_scored' then
    match.score2 = match.score2 + 1
    camera:bump('l')
    reset()
  else
    error('unknown event: ' .. tostring(event))
  end

  bat1.body:setLinearVelocity(controls.p1.x * 200, controls.p1.y * batSpeed)
  bat2.body:setLinearVelocity(controls.p2.x * 200, controls.p2.y * batSpeed)

  bat1:update(dt)
  bat2:update(dt)

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

    ball.body:setLinearVelocity(dir[dirNum].x * x * ballSpeed, dir[dirNum].y * y * ballSpeed)
  end

  ball:update(dt)

  camera:update(dt)

  world:update(dt)
end

function love.draw()
  local winWidth, winHeight = love.graphics.getDimensions()
  love.graphics.scale(winWidth / gameWidth, winHeight / gameHeight)

  love.graphics.push()

  love.graphics.translate(camera.offset.x, camera.offset.y)

  love.graphics.setColor(1, 1, 1)

  bat1:draw()
  bat2:draw()

  love.graphics.setColor(0.2, 1.0, 0.5, 1.0)
  love.graphics.setShader(shaders.ballLight)
  shaders.ballLight:send("ballPosition",
    { ball.body:getX() * (winWidth / gameWidth), ball.body:getY() * (winHeight / gameHeight) })
  shaders.ballLight:send("ballRadius", ball.radius)
  love.graphics.rectangle('fill', 0, 0, gameWidth, gameHeight)
  love.graphics.setShader()
  ball:draw()

  love.graphics.pop()

  love.graphics.setColor(1.0, 1.0, 1.0, 1.0)
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
