local Registry = require('registry')
local Rocket = require('rocket')
local Vector = require('vector')

---@type Entity[]
local entities = {}
---@type Entity[]
new_entities = {}

function love.load()
end

function love.update(dt)
  for _, ent in ipairs(entities) do
    Registry.lookup(ent).update(ent, dt)
  end

  ---@type Entity[]
  local still_alive = {}

  for _, ent in ipairs(entities) do
    if not ent.dead then
      table.insert(still_alive, ent)
    end
  end

  entities = still_alive

  for _, new_part in ipairs(new_entities) do
    table.insert(entities, new_part)
  end

  new_entities = {}
end

function love.mousepressed(x, y, button)
  if button == 1 then
    local source = Vector({ x = love.graphics.getWidth() / 2, y = love.graphics.getHeight() })
    table.insert(entities, Rocket.new({ source = source, target = Vector(x, y) }))
  end
end

function love.draw()
  for _, ent in ipairs(entities) do
    Registry.lookup(ent).draw(ent)
  end
end

function love.keypressed(_key, scancode)
  if scancode == 'backspace' then
    love.event.quit('restart') -- recreates the whole lua state from scratch.
  end
end
