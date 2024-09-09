---@class (exact) Vector: VectorModule
---@field x number x position
---@field y number y position

---@alias Vectorish Vector | {x: number, y: number}

---@class VectorModule: metatable
---@field mt VectorModule
local Vector = {}

Vector.mt = Vector
Vector.mt.__index = Vector.mt

function Vector.type()
  return 'vector'
end

---construct a new Vector
---@param x_or_vec number | Vectorish
---@param y number | nil
---@return table
function Vector.new(x_or_vec, y)
  assert(x_or_vec, "no argument given")

  local v

  if type(x_or_vec) == 'number' then
    assert(y, "no y given with x")
    v = { x = x_or_vec, y = y }
  elseif type(x_or_vec) == 'table' then
    assert(y == nil, 'unexpected second argument given with table')
    assert(x_or_vec.x, 'no x on given table')
    assert(x_or_vec.y, 'no y on given table')
    v = { __type__ = Vector.type(), x = x_or_vec.x, y = x_or_vec.y }
  else
    error('unexpected type of argument, got ' .. type(x_or_vec))
  end

  setmetatable(v, Vector.mt)
  return v
end

setmetatable(Vector, {
  __call = function(_, ...)
    return Vector.new(...)
  end
})

function Vector.tostring(v)
  return "#Vector{x=" .. v.x .. ",y=" .. v.y .. "}"
end

Vector.mt.__tostring = Vector.tostring

---clone a Vector
---@param v Vectorish
---@return Vector
function Vector.clone(v)
  return Vector({ x = v.x, y = v.y })
end

Vector.copy = Vector.clone

Vector.mt.clone = Vector.clone
Vector.mt.copy = Vector.clone

---@param v1 Vectorish
---@param v2 Vectorish
---@return boolean
function Vector.equal(v1, v2)
  return v1.x == v2.x and v1.y == v2.y
end

Vector.mt.__eq = Vector.equal

---add 2 vectors or a number to both elements of a vector and return a new vector
---@param v1 Vectorish
---@param v2 Vectorish | number
---@return Vector
function Vector.add(v1, v2)
  if type(v2) == 'table' then
    return Vector(v1.x + v2.x, v1.y + v2.y)
  elseif type(v2) == 'number' then
    return Vector(v1.x + v2, v1.y + v2)
  else
    error('unknown type for Vector.add, got ' .. type(v2))
  end
end

Vector.mt.__add = Vector.add

---(mutate) add 2 vectors or a number to both elements of a vector, mutating the vector
---@param v1 Vectorish
---@param v2 Vectorish | number
---@return Vectorish
function Vector.add_mut(v1, v2)
  if type(v2) == 'table' then
    v1.x = v1.x + v2.x
    v1.y = v1.y + v2.y
    return v1
  elseif type(v2) == 'number' then
    v1.x = v1.x + v2
    v1.y = v1.y + v2
    return v1
  else
    error('unknown type for Vector.add_mut, got ' .. type(v2))
  end
end

---subtract 2 vectors or a number to both elements of a vector and return a new vector
---@param v1 Vectorish
---@param v2 Vectorish | number
---@return Vector
function Vector.subtract(v1, v2)
  if type(v2) == 'table' then
    return Vector(v1.x - v2.x, v1.y - v2.y)
  elseif type(v2) == 'number' then
    return Vector(v1.x - v2, v1.y - v2)
  else
    error('unknown type for Vector.subtract, got ' .. type(v2))
  end
end

Vector.sub = Vector.subtract
Vector.mt.__sub = Vector.subtract

---(mutate) subtract 2 vectors or a number from both elements of a vector, mutating the vector
---@param v1 Vectorish
---@param v2 Vectorish | number
---@return Vectorish
function Vector.subtract_mut(v1, v2)
  if type(v2) == 'table' then
    v1.x = v1.x - v2.x
    v1.y = v1.y - v2.y
    return v1
  elseif type(v2) == 'number' then
    v1.x = v1.x - v2
    v1.y = v1.y - v2
    return v1
  else
    error('unknown type for Vector.subtract_mut, got ' .. type(v2))
  end
end

Vector.sub_mut = Vector.subtract_mut

---multiply 2 vectors or a number with both elements of a vector and return a new vector
---@param v1 Vectorish
---@param v2 Vectorish | number
---@return Vector
function Vector.multiply(v1, v2)
  if type(v2) == 'table' then
    return Vector(v1.x * v2.x, v1.y * v2.y)
  elseif type(v2) == 'number' then
    return Vector(v1.x * v2, v1.y * v2)
  else
    error('unknown type for Vector.multiply, got ' .. type(v2))
  end
end

Vector.mul = Vector.multiply
Vector.scale = Vector.multiply
Vector.mt.__mul = Vector.multiply

---(mutate) multiply 2 vectors or a number with both elements of a vector, mutating the vector
---@param v1 Vectorish
---@param v2 Vectorish | number
---@return Vectorish
function Vector.multiply_mut(v1, v2)
  if type(v2) == 'table' then
    v1.x = v1.x * v2.x
    v1.y = v1.y * v2.y
    return v1
  elseif type(v2) == 'number' then
    v1.x = v1.x * v2
    v1.y = v1.y * v2
    return v1
  else
    error('unknown type for Vector.multiply_mut, got ' .. type(v2))
  end
end

Vector.mul_mut = Vector.multiply_mut
Vector.scale_mut = Vector.multiply_mut

---get the squared length of a vector
---@param v Vectorish
---@return number
function Vector.length_sq(v)
  return v.x * v.x + v.y * v.y
end

Vector.magnitude_sq = Vector.length_sq
Vector.mag_sq = Vector.length_sq
Vector.mt.magnitude_sq = Vector.length_sq
Vector.mt.mag_sq = Vector.length_sq

---get the length of a vector
---@param v Vectorish
---@return number
function Vector.length(v)
  return math.sqrt(Vector.length_sq(v))
end

Vector.magnitude = Vector.length
Vector.mag = Vector.length
Vector.mt.magnitude = Vector.length
Vector.mt.mag = Vector.length

Vector.mt.__len = Vector.length

---get a normalized vector
---@param v Vectorish
---@return Vector
function Vector.norm(v)
  local mag = Vector.mag(v)
  if mag == 0 then
    return Vector.zero():clone()
  else
    return Vector(v.x / mag, v.y / mag)
  end
end

---(mutate) normalize a vector
---@param v Vectorish
---@return Vectorish
function Vector.norm_mut(v)
  local mag = Vector.mag(v)
  if mag == 0 then
    v.x = 0
    v.y = 0
  else
    v.x = v.x / mag
    v.y = v.y / mag
  end

  return v
end

local zeroVector = Vector({ x = 0, y = 0 })

function Vector.zero()
  return zeroVector
end

return Vector
