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

  local facing = Vector.norm_mut({
    x = opts.target.x - opts.source.x,
    y = opts.target.y - opts.source.y
  })

  ---@type Rocket
  return {
    __type__ = Rocket.type(),
    source = Vector.clone(opts.source),
    target = Vector.clone(opts.target),
    pos = Vector.clone(opts.source),
    facing = facing,
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

  rocket.pos.x = rocket.pos.x + rocket.facing.x * rocket.speed * dt
  rocket.pos.y = rocket.pos.y + rocket.facing.y * rocket.speed * dt

  if rocket.next_trail_time <= 0 then
    -- table.insert(rocket.trail_locations, 1, { x = rocket.pos.x, y = rocket.pos.y })
    table.insert(rocket.trail_locations, 1, Vector.clone(rocket.pos))
    rocket.next_trail_time = trail_time

    if #rocket.trail_locations > max_trail_count then
      table.remove(rocket.trail_locations)
    end
  end

  local distance_to_target_sq =
      (rocket.target.x - rocket.pos.x) * (rocket.target.x - rocket.pos.x) +
      (rocket.target.y - rocket.pos.y) * (rocket.target.y - rocket.pos.y)

  if distance_to_target_sq <= distance_tolerance_sq or rocket.lifetime <= 0 then
    rocket.dead = true

    local count = 15
    for i = 0, count - 1 do
      local angle_rad = math.pi * 2 * (i / count)

      table.insert(new_entities,
        Particle.new({
          pos = Vector.clone(rocket.pos),
          facing = {
            x = math.cos(angle_rad),
            y = math.sin(angle_rad),
          },
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
