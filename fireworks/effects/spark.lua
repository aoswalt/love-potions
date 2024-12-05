local Registry = require('registry')
local Vector = require('vector')

---@class (exact) Spark: Entity
---@field package lifetime number remaining lifetime
---@field package size number maximum size
---@field package point_count number number of points
---@field package hue number hue color

---@class SparkModule: EntityModule
local Spark = {}

function Spark.type()
  return 'spark'
end

Registry.register(Spark.type(), Spark)

local max_lifetime = 1

---create a spark
---@param opts table
---@return Spark
function Spark.new(opts)
  assert(opts.pos, 'spark does not have a position')

  ---@type Spark
  return {
    __entity__ = Spark.type(),
    pos = opts.pos:clone(),
    lifetime = opts.lifetime or max_lifetime,
    size = opts.size or 10,
    point_count = opts.point_count or 6,
    hue = opts.hue or (1 / 6)
  }
end

---update the spark
---@param spark Spark
---@param dt number
function Spark.update(spark, dt)
  if spark.dead then
    return
  end

  spark.lifetime = spark.lifetime - dt

  if spark.lifetime <= 0 then
    spark.dead = true
    return
  end
end

---draw the spark
---@param spark Spark
function Spark.draw(spark)
  if spark.dead then
    return
  end

  local life_pct = spark.lifetime / max_lifetime
  local size = spark.size * life_pct

  local vertices = {}

  local segment_angle_rad = math.pi * 2 / spark.point_count
  local half_segment_angle_rad = segment_angle_rad / 2

  local angle_rad = 0

  for _ = 0, spark.point_count - 1 do
    -- inner point
    angle_rad = angle_rad + half_segment_angle_rad
    local offset = Vector(math.cos(angle_rad), math.sin(angle_rad))
    local point = spark.pos + offset * (size / 4)

    table.insert(vertices, point.x)
    table.insert(vertices, point.y)

    -- outer point
    angle_rad = angle_rad + half_segment_angle_rad
    offset = Vector(math.cos(angle_rad), math.sin(angle_rad))
    point = spark.pos + offset * size

    table.insert(vertices, point.x)
    table.insert(vertices, point.y)
  end

  local color_r, color_g, color_b, color_a = love.graphics.getColor()
  love.graphics.setColor(HSL(spark.hue, 0.5, 0.5, 1.0))
  love.graphics.polygon('fill', vertices)
  love.graphics.setColor(color_r, color_g, color_b, color_a)
end

return Spark
