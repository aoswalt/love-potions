---@class (exact) Vector
---@field x number x position
---@field y number y position

local Vector = {}

function Vector.tostring(v)
  return "V{x=" .. v.x .. ",y=" .. v.y .. "}"
end

---clone a Vector
---@param v Vector
---@return Vector
function Vector.clone(v)
  return { x = v.x, y = v.y }
end

---get the squared length of a vector
---@param v Vector
---@return number
function Vector.lengthSq(v)
  return v.x * v.x + v.y * v.y
end

---get the length of a vector
---@param v Vector
---@return number
function Vector.length(v)
  return math.sqrt(Vector.lengthSq(v))
end

Vector.magnitude = Vector.length
Vector.mag = Vector.length

---(mutate) normalize a vector
---@param v Vector
---@return  Vector
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

local zero = { x = 0, y = 0}

function Vector.zero()
  return zero
end

return Vector
