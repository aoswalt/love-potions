local Particle = require('particle')
local Vector = require('vector')
local Registry = require('registry')

---@class (exact) Rocket: Entity
---@field package source Vector source position
---@field package target Vector target position
---@field package facing Vector normalized facing direction
---@field package speed number
---@field package lifetime number remaining lifetime
---@field package trail_locations Vector[] past locations for a trail
---@field package next_trail_time number time remaining to record the next trail position

---@class RocketModule: EntityModule
local Rocket = {}

function Rocket.type()
  return 'rocket'
end

Registry.register(Rocket.type(), Rocket)

local distance_tolerance_sq = 10
local trail_time = 0.05
local max_trail_count = 10

---create a rocket
---@param opts table
---@return Rocket
function Rocket.new(opts)
  assert(opts.source, "missing source position")
  assert(opts.target, "missing target position")

  ---@type Rocket
  return {
    __entity__ = Rocket.type(),
    source = Vector(opts.source),
    target = Vector(opts.target),
    pos = Vector(opts.source),
    facing = Vector.norm(opts.target - opts.source),
    speed = opts.speed or 350,
    lifetime = opts.lifetime or 2,
    trail_locations = {},
    next_trail_time = trail_time,
  }
end

---general update
---@param rocket Rocket
---@param dt number
function Rocket.update(rocket, dt)
  if rocket.dead then
    return
  end

  rocket.lifetime = rocket.lifetime - dt
  rocket.next_trail_time = rocket.next_trail_time - dt

  rocket.pos = rocket.pos + rocket.facing * rocket.speed * dt

  if rocket.next_trail_time <= 0 then
    -- table.insert(rocket.trail_locations, 1, { x = rocket.pos.x, y = rocket.pos.y })
    table.insert(rocket.trail_locations, 1, rocket.pos:clone())
    rocket.next_trail_time = trail_time

    if #rocket.trail_locations > max_trail_count then
      table.remove(rocket.trail_locations)
    end
  end

  local distance_to_target_sq = Vector.length_sq(rocket.target - rocket.pos)

  if distance_to_target_sq <= distance_tolerance_sq or rocket.lifetime <= 0 then
    rocket.dead = true

    local count = 15
    for i = 0, count - 1 do
      local angle_rad = math.pi * 2 * (i / count)

      table.insert(new_entities,
        Particle.new({
          pos = rocket.pos:clone(),
          facing = Vector(math.cos(angle_rad), math.sin(angle_rad)),
          speed = 100
        }))
    end
  end
end

---general draw
---@param rocket Rocket
function Rocket.draw(rocket)
  if rocket.dead then
    return
  end

  for _, past in ipairs(rocket.trail_locations) do
    local color_r, color_g, color_b, color_a = love.graphics.getColor()
    love.graphics.setColor(0.2, 0.2, 0.25)
    love.graphics.circle('fill', past.x, past.y, 5)
    love.graphics.setColor(color_r, color_g, color_b, color_a)
  end

  love.graphics.circle('fill', rocket.pos.x, rocket.pos.y, 25)
end

return Rocket
