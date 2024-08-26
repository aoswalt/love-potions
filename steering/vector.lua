local Vector = {}

Vector.mt = {}
Vector.mt.__index = Vector.mt

function Vector.new(x, y)
  local v = { x = x, y = y }
  setmetatable(v, Vector.mt)
  return v
end

setmetatable(Vector, {
  __call = function(_, ...)
    return Vector.new(...)
  end,
})

function Vector.clone(v)
  return Vector.new(v.x, v.y)
end

Vector.mt.clone = Vector.clone

function Vector.tostring(v)
  return "V{x=" .. v.x .. ",y=" .. v.y .. "}"
end

Vector.mt.__tostring = Vector.tostring

function Vector.equal(v1, v2)
  return v1.x == v2.x and v1.y == v2.y
end

function Vector.add(v1, v2)
  return Vector.new(v1.x + v2.x, v1.y + v2.y)
end

Vector.mt.__add = Vector.add

function Vector.subtract(v1, v2)
  return Vector.new(v1.x - v2.x, v1.y - v2.y)
end

Vector.sub = Vector.subtract
Vector.mt.__sub = Vector.subtract

function Vector.scale(v1, amount)
  return Vector.new(v1.x * amount, v1.y * amount)
end

Vector.mul = Vector.scale
Vector.mt.scale = Vector.scale
Vector.mt.mul = Vector.scale
Vector.mt.__mul = Vector.scale

function Vector.div(v1, amount)
  return Vector.new(v1.x / amount, v1.y / amount)
end

Vector.mt.__div = Vector.div

function Vector.negate(v1)
  return Vector.new(-v1.x, -v1.y)
end

Vector.neg = Vector.negate
Vector.mt.__unm = Vector.negate

function Vector.lengthSq(v)
  return v.x * v.x + v.y * v.y
end

Vector.magnitudeSq = Vector.lengthSq
Vector.magSq = Vector.lengthSq
Vector.mt.lengthSq = Vector.lengthSq
Vector.mt.magnitudeSq = Vector.lengthSq
Vector.mt.magSq = Vector.lengthSq

function Vector.length(v)
  return math.sqrt(Vector.lengthSq(v))
end

Vector.magnitude = Vector.length
Vector.mag = Vector.length
Vector.mt.length = Vector.length
Vector.mt.magnitude = Vector.length
Vector.mt.mag = Vector.length
Vector.mt.__len = Vector.length

function Vector.norm(v)
  local mag = Vector.mag(v)
  if mag == 0 then
    return Vector(0, 0)
  else
    return v / mag
  end
end

Vector.mt.norm = Vector.norm

function Vector.limit(v, limit)
  if v:magSq() > limit * limit then
    return v:norm() * limit
  else
    return v
  end
end

Vector.mt.limit = Vector.limit

function Vector.random()
  return Vector.new(math.random(), math.random()):norm()
end

local zeroVector = Vector(0, 0)
function Vector.zero()
  return zeroVector
end

return Vector
