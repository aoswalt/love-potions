local system = {
  state = {},
  doSave = false,
  doLoad = false,
  waitMax = 2,
  wait = 0
}

local radius = 20

-- function love.load(args)
--   if args[1] == 'debug' then
--     print(dump(args))
--   end
-- end

function stringify_recursive(data)
  local t = type(data)

  if t == 'string' then
    return string.format('%q', data)
  elseif t == 'number' then
    return data
  elseif t == 'boolean' then
    return data and 'true' or 'false'
  elseif t == 'table' then
    local str = '{'
    for k, v in pairs(data) do
      str = str .. "[" .. stringify_recursive(k) .. "]=" .. stringify_recursive(v) .. ","
    end
    return str .. "}"
  elseif t == 'nil' then
    error('stringify nil')
  elseif t == 'function' then
    error('stringify function')
  elseif t == 'thread' then
    error('stringify thread')
  elseif t == 'userdata' then
    error('stringify userdata')
  end
end

function love.update(dt)
  if system.doSave then
    local stateStr = stringify_recursive(system.state)
    love.filesystem.write('state.lua', stateStr)
    system.doSave = false
  elseif system.doLoad then
    local str = love.filesystem.read('state.lua')
    if str ~= nil then
      system.state = assert(loadstring('return ' .. str))()
    end
    system.doLoad = false
  end
end

function love.mousereleased(x, y, button)
  if button == 1 then
    table.insert(system.state,
      { x = x, y = y, color = { r = math.random(), g = math.random(), b = math.random(), a = 1 } })
  end

  if button == 2 then
    local foundIndex

    for ix, entry in ipairs(system.state) do
      if math.abs(entry.x - x) <= radius and math.abs(entry.y - y) <= radius then
        foundIndex = ix
        break
      end
    end

    if foundIndex then
      table.remove(system.state, foundIndex)
    end
  end
end

local font = love.graphics.newFont(18)

function love.draw()
  for _, entry in ipairs(system.state) do
    love.graphics.setColor(entry.color.r, entry.color.g, entry.color.b, entry.color.a)
    love.graphics.circle("fill", entry.x, entry.y, radius)
  end

  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.print('Saved', font, 10, 10, 0)
end

local function save()
  system.doSave = true
end

local function load()
  system.doLoad = true
end

function love.keypressed(_key, scancode)
  if scancode == 'backspace' then
    love.event.quit('restart') -- recreates the whole lua state from scratch.
  elseif scancode == 'f5' then
    save()
  elseif scancode == 'f8' then
    load()
  elseif scancode == 'f1' then
    debug.debug() -- pause and enter debug terminal
  end
end
