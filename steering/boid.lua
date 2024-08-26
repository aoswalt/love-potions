local Vector = require("vector")

local Boid = {}

Boid.mt = {}
Boid.mt.__index = Boid.mt

function Boid.new(pos)
  local b = {
    pos = pos,
    vel = Vector(0, 0),
    acc = Vector(0, 0),
    maxSpeed = 300,
    maxForce = 10,
    mass = 1,
  }
  setmetatable(b, Boid.mt)
  return b
end

function Boid.update(boid, dt)
  boid.vel = boid.vel + boid.acc
  boid.acc = Vector.zero()

  boid.vel = boid.vel:limit(boid.maxSpeed)
  boid.pos = boid.pos + boid.vel * dt
end

Boid.mt.update = Boid.update

local halfPi = math.pi / 2

function Boid.draw(boid)
  love.graphics.push()
  love.graphics.translate(boid.pos.x, boid.pos.y)

  -- offset rotation by 90* to deal with drawing as facing upwards
  local angle = math.atan2(boid.vel.y, boid.vel.x) + halfPi
  love.graphics.rotate(angle)

  local h = 20 * boid.mass
  local w = 15 * boid.mass

  love.graphics.polygon("fill", { 0, 0, w / 2, h, -w / 2, h })
  love.graphics.pop()
end

Boid.mt.draw = Boid.draw

function Boid.applyForce(boid, force)
  boid.acc = boid.acc + (force / boid.mass)
end

Boid.mt.applyForce = Boid.applyForce

function Boid.keepInBounds(boid)
  if boid.pos.x < 0 then
    boid.pos.x = 0
    boid.vel.x = -boid.vel.x
  end

  if boid.pos.x > love.graphics.getWidth() then
    boid.pos.x = love.graphics.getWidth()
    boid.vel.x = -boid.vel.x
  end

  if boid.pos.y < 0 then
    boid.pos.y = 0
    boid.vel.y = -boid.vel.y
  end

  if boid.pos.y > love.graphics.getHeight() then
    boid.pos.y = love.graphics.getHeight()
    boid.vel.y = -boid.vel.y
  end
end

Boid.mt.keepInBounds = Boid.keepInBounds

function Boid.getFriction(boid)
  return boid.vel:norm() * -1 * 0.1
end

Boid.mt.getFriction = Boid.getFriction

function Boid.seek(boid, target)
  local desired = target - boid.pos

  local steer = desired - boid.vel
  steer = steer:limit(boid.maxForce)

  boid:applyForce(steer)
end

Boid.mt.seek = Boid.seek

return Boid
