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
  local arcSteps = 1
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

  local verticies = buildScaledBatShape(batWidth, batHeight, args.flipHoriz)

  local b = {}

  b.body = love.physics.newBody(world, args.x, args.y, 'dynamic')
  b.body:setFixedRotation(true)
  b.shape = love.physics.newPolygonShape(verticies)
  b.fixture = love.physics.newFixture(b.body, b.shape)
  -- b.fixture:setRestitution(1)
  b.fixture:setUserData(b)

  setmetatable(b, self)
  self.__index = self
  return b
end

function Bat.draw(bat)
  love.graphics.polygon("fill", bat.body:getWorldPoints(bat.shape:getPoints()))
end

function Bat.update(bat, dt)
end

local Ball = {}

function Ball:new(args)
  args = args or {}

  local b = {
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
  ball.body:setPosition(gameWidth / 2, gameHeight / 2)
  ball.body:setLinearVelocity(0, 0)
  ball.trail = {}
  match.started = false
end

function love.load()
  love.graphics.setDefaultFilter('nearest')

  local font = love.graphics.newFont(56)
  font:setFilter('nearest')
  love.graphics.setFont(font)

  math.randomseed(os.time())

  world = love.physics.newWorld(0, 0, true)

  -- walls
  local wallTop = {}
  wallTop.body = love.physics.newBody(world, gameWidth / 2, -1, 'static')
  wallTop.shape = love.physics.newRectangleShape(gameWidth, 1)
  wallTop.fixture = love.physics.newFixture(wallTop.body, wallTop.shape)

  local wallBottom = {}
  wallBottom.body = love.physics.newBody(world, gameWidth / 2, gameHeight + 1, 'static')
  wallBottom.shape = love.physics.newRectangleShape(gameWidth, 1)
  wallBottom.fixture = love.physics.newFixture(wallBottom.body, wallBottom.shape)

  local wallLeft = {}
  wallLeft.body = love.physics.newBody(world, -1, gameHeight / 2, 'static')
  wallLeft.shape = love.physics.newRectangleShape(1, gameWidth)
  wallLeft.fixture = love.physics.newFixture(wallLeft.body, wallLeft.shape)
  -- wallLeft.fixture:setSensor(true)

  local wallRight = {}
  wallRight.body = love.physics.newBody(world, gameWidth + 1, gameHeight / 2, 'static')
  wallRight.shape = love.physics.newRectangleShape(1, gameWidth)
  wallRight.fixture = love.physics.newFixture(wallRight.body, wallRight.shape)
  -- wallRight.fixture:setSensor(true)


  -- love.physics.setMeter(1)
  bat1 = Bat:new({ x = 40, y = gameHeight / 2 })
  bat2 = Bat:new({ x = gameWidth - 40, y = gameHeight / 2, flipHoriz = true })
  ball = Ball:new({
    x = gameWidth / 2,
    y = gameHeight / 2,
    radius = ballSize / 2,
  })
end

function love.update(dt)
  world:update(dt)

  bat1.body:setLinearVelocity(controls.p1.x * 200, controls.p1.y * batSpeed)
  bat2.body:setLinearVelocity(controls.p2.x * 200, controls.p2.y * batSpeed)

  bat1:update(dt)
  bat2:update(dt)

  -- if bat1.y - bat1.height / 2 < 0 then
  --   bat1.y = bat1.height / 2
  -- elseif bat1.y + bat1.height / 2 > gameHeight then
  --   bat1.y = gameHeight - bat1.height / 2
  -- end

  -- if bat2.y - bat2.height / 2 < 0 then
  --   bat2.y = bat2.height / 2
  -- elseif bat2.y + bat2.height / 2 > gameHeight then
  --   bat2.y = gameHeight - bat2.height / 2
  -- end

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

  -- -- scoring
  -- if ball.x - ball.radius <= 0 then
  --   ball.speedX = -ball.speedX
  --   ball.x = ball.radius
  --   match.score2 = match.score2 + 1
  --   camera:bump('l')
  --   reset()
  -- elseif ball.x + ball.radius >= gameWidth then
  --   ball.speedX = -ball.speedX
  --   ball.x = gameWidth - ball.radius
  --   match.score1 = match.score1 + 1
  --   camera:bump('r')
  --   reset()
  -- end

  -- -- keeping in bounds
  -- if ball.y - ball.radius <= 0 then
  --   ball.speedY = -ball.speedY
  --   ball.y = ball.radius
  -- elseif ball.y + ball.radius >= gameHeight then
  --   ball.speedY = -ball.speedY
  --   ball.y = gameHeight - ball.radius
  -- end


  -- -- returning p1
  -- if ball.x < gameWidth * 0.2 and nearBat(ball, bat1) then
  --   handleCollision(ball, bat1)
  -- end

  -- -- returning p2
  -- if ball.x > gameWidth * 0.8 and nearBat(ball, bat2) then
  --   handleCollision(ball, bat2)
  -- end

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
