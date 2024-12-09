local Registry = require('registry')
local Vector = require('vector')
local Spark = require('effects.spark')

---@class (exact) Streak: Entity
---@field package facing Vector normalized facing direction
---@field package speed number
---@field package lifetime number remaining lifetime
---@field package trail_nodes { pos: Vector, facing: Vector}[] previous positions
---@field package next_trail_time number time until recording next trial position

---@class StreakModule: EntityModule
local Streak = {}

function Streak.type()
  return 'streak'
end

Registry.register(Streak.type(), Streak)

local trail_count = 10
local trail_time = 0.05

---create a streak
---@param opts table
---@return Streak
function Streak.new(opts)
  assert(opts.pos, 'streak does not have a position')

  ---@type Streak
  return {
    __entity__ = Streak.type(),
    pos = opts.pos:clone(),
    facing = Vector.clone(opts.facing or Vector.zero()),
    speed = opts.speed or 0,
    lifetime = opts.lifetime or 2,
    trail_nodes = {},
    next_trail_time = trail_time
  }
end

---update the streak
---@param streak Streak
---@param dt number
function Streak.update(streak, dt)
  if streak.dead then
    return
  end

  streak.lifetime = streak.lifetime - dt
  streak.next_trail_time = streak.next_trail_time - dt

  if streak.lifetime <= 0 then
    streak.dead = true

    add_entity(Spark.new({
      pos = streak.pos
    }))

    return
  end

  streak.pos = streak.pos + streak.facing * streak.speed * dt

  if streak.next_trail_time <= 0 then
    table.insert(streak.trail_nodes, 1, { pos = streak.pos:clone(), facing = streak.facing:clone() })
    streak.next_trail_time = trail_time

    if #streak.trail_nodes > trail_count then
      table.remove(streak.trail_nodes)
    end
  end
end

---@param streak Streak
local function draw_trail(streak)
  local vertices = {}
  local max_width = 15
  local half_width = max_width / 2

  for i = 1, #streak.trail_nodes - 1 do
    local offset_dist = half_width * ((#streak.trail_nodes - i) / #streak.trail_nodes)
    local past = streak.trail_nodes[i]
    local vert = past.pos + (Vector.perpendicular(past.facing) * offset_dist)
    table.insert(vertices, vert.x)
    table.insert(vertices, vert.y)
  end

  -- initial would have no nodes to index
  local endpoint = streak.trail_nodes[#streak.trail_nodes]
  if endpoint then
    table.insert(vertices, endpoint.pos.x)
    table.insert(vertices, endpoint.pos.y)
  end

  for i = #streak.trail_nodes - 1, 1, -1 do
    local offset_dist = half_width * ((#streak.trail_nodes - i) / #streak.trail_nodes)
    local past = streak.trail_nodes[i]
    local vert = past.pos + (Vector.perpendicular_opposite(past.facing) * offset_dist)
    table.insert(vertices, vert.x)
    table.insert(vertices, vert.y)
  end

  -- need at least 3 points to draw
  if #vertices > 6 then
    local color_r, color_g, color_b, color_a = love.graphics.getColor()
    love.graphics.setColor(0.2, 0.25, 0.3, 0.75)
    love.graphics.polygon('fill', vertices)
    love.graphics.setColor(color_r, color_g, color_b, color_a)
  end
end

---draw the streak
---@param streak Streak
function Streak.draw(streak)
  if streak.dead then
    return
  end

  draw_trail(streak)

  love.graphics.circle('fill', streak.pos.x, streak.pos.y, 10)
end

return Streak
